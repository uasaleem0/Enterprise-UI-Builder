#!/usr/bin/env node

/**
 * Clone/Build Orchestrator
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const http = require('http');
const { executeProtocol30 } = require('../protocols/protocol-3.0/integrated-protocol-3.0.js');
const { extractTarget } = require('./extractor');
const { synthesizeFromExtraction } = require('./synthesis');
const { extractPages } = require('./extract-pages');
const { generateTokens } = require('./tokens');
const { synthesizeNext } = require('./synthesize-next');
const { bootstrapNext } = require('./bootstrap-next');
const { crawl, saveSiteMap } = require('./crawler');
const { buildPrd, savePrd } = require('./prd');
// Ensure visual engines/adapters are wired
try { require('../hooks/microsoft-sim-adapter.js'); } catch {}
try { require('../hooks/playwright-mcp-adapter.js'); } catch {}
const { runPreflight } = require('./preflight');
const { appendEvent } = require('./logger');

function generateProjectName(url) {
  try { const u = new URL(url); const domain = u.hostname.replace('www.', ''); return domain.split('.')[0] + '-protocol30-clone'; } catch { return 'website-protocol30-clone-' + Date.now(); }
}

async function ensureDir(p){ await fsp.mkdir(p,{recursive:true}); }

function nowStamp(){ const d=new Date(); const pad=n=>String(n).padStart(2,'0'); return `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`; }

async function backupIfExists(projectPath, backupsRoot){
  if (!fs.existsSync(projectPath)) return null;
  const stamp = nowStamp();
  const dest = path.join(backupsRoot, path.basename(projectPath) + '-' + stamp);
  await ensureDir(dest);
  if (fs.cp) { await fsp.cp(projectPath, dest, { recursive: true }); }
  else {
    const copyRecursive = async (src, dst)=>{ const stat=await fsp.stat(src); if (stat.isDirectory()){ await ensureDir(dst); const entries=await fsp.readdir(src); for(const e of entries){ await copyRecursive(path.join(src,e), path.join(dst,e)); } } else { await fsp.copyFile(src,dst); } };
    await copyRecursive(projectPath, dest);
  }
  return dest;
}

async function writeCandidate(projectPath, port){
  await ensureDir(projectPath);
  const html = `<!doctype html><html lang="en"><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><title>Enterprise Candidate</title><style>body{font-family:Arial,sans-serif;margin:0;padding:2rem;}header,footer{padding:1rem 0}.container{max-width:960px;margin:0 auto}.hero{padding:3rem 0;background:#f5f5f5;margin:1rem 0}</style><body><div class="container"><header><h1>Enterprise Candidate</h1></header><section class="hero"><h2>Placeholder Hero</h2><p>This is a bootstrap candidate page served locally on port ${port}.</p></section><footer><small>Enterprise System · Candidate</small></footer></div></body></html>`;
  await fsp.writeFile(path.join(projectPath,'index.html'), html, 'utf8');
  const pkg = { name: path.basename(projectPath), version:'0.0.1', private:true, scripts:{ start:'node server.js' } };
  await fsp.writeFile(path.join(projectPath,'package.json'), JSON.stringify(pkg,null,2),'utf8');
}

function createServer(projectPath, port){
  const indexPath = path.join(projectPath, 'index.html');
  const server = http.createServer((req,res)=>{
    try { const html = fs.readFileSync(indexPath,'utf8'); res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'}); res.end(html); }
    catch { res.writeHead(500,{'Content-Type':'text/plain'}); res.end('Server error'); }
  });
  return new Promise(resolve=> server.listen(port,()=>resolve(server)));
}

async function runOrchestration(targetUrl, opts = {}){
  const baseDir = process.cwd();
  const projectsRoot = path.join(baseDir, 'projects');
  await ensureDir(projectsRoot);

  const projectName = opts.projectName || generateProjectName(targetUrl);
  const port = parseInt(opts.port || (opts.localUrl ? new URL(opts.localUrl).port || '3000' : '3000'), 10);
  const localUrl = opts.localUrl || `http://localhost:${port}`;
  const projectPath = path.join(projectsRoot, projectName);
  const backupsRoot = path.join(baseDir, '.backups', 'projects');
  await ensureDir(backupsRoot);
  const backupPath = await backupIfExists(projectPath, backupsRoot);
  if (backupPath) { console.log(`[backup] Existing project backed up to: ${backupPath}`); await appendEvent(projectPath, { level:'info', stage:'backup', msg:'backup-created', path: backupPath }); }

  // Optional PRD persist for app flow
  try { if (opts.describe) { const prd = buildPrd(opts.describe); const prdPaths = await savePrd(projectPath, prd); console.log(`[prd] Saved: ${prdPaths.mdPath}`); await appendEvent(projectPath, { level:'info', stage:'prd', msg:'saved', md: prdPaths.mdPath }); } } catch {}

  // Preflight
  try { const pf = await runPreflight(); await appendEvent(projectPath, { level:'info', stage:'preflight', msg:'results', data: pf }); console.log('[preflight]', JSON.stringify(pf.rows)); if (pf.warnings?.length) console.log('[preflight-warn]', pf.warnings.join(' | ')); } catch {}

  // Crawl (clone) and extract
  let site = { pages: [] };
  try { site = await crawl(targetUrl, parseInt(opts.crawlLimit || '8',10)); const sm = await saveSiteMap(projectPath, site); console.log(`[crawl] Site map: ${sm}`); await appendEvent(projectPath, { level:'info', stage:'crawl', msg:'site-map', path: sm, pages: site.pages?.length||0 }); } catch (e) { console.log(`[crawl] Skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'crawl', msg:'skipped', error: e.message||String(e) }); }
  try { const ex = await extractTarget(targetUrl, projectPath); console.log(`[extract] Artifacts at ${ex.evidenceDir}`); await appendEvent(projectPath, { level:'info', stage:'extract', msg:'done', dir: ex.evidenceDir }); } catch (e) { console.log(`[extract] Skipped or failed: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'extract', msg:'failed', error: e.message||String(e) }); }
  try { const px = await extractPages(site, projectPath); console.log(`[extract] Per-page data at ${px.outDir}`); await appendEvent(projectPath, { level:'info', stage:'extract', msg:'per-page', dir: px.outDir }); } catch (e) { console.log(`[extract] pages skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'extract', msg:'per-page-skipped', error: e.message||String(e) }); }

  // Load structure and generate tokens
  let struct = null; let tokens = null;
  try { const extraction = require(path.join(projectPath,'evidence','extraction','extraction.json')); struct = extraction.structure || null; } catch {}
  try { const tk = await generateTokens(projectPath); tokens = tk.tokens || null; console.log(`[tokens] Generated ${tk.jsonPath}`); await appendEvent(projectPath, { level:'info', stage:'tokens', msg:'generated', path: tk.jsonPath }); } catch (e) { console.log(`[tokens] skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'tokens', msg:'skipped', error: e.message||String(e) }); }

  // Synthesize minimal static HTML for server fallback
  let synthOk = false; let synthesizedHtml = null;
  try { const s = await synthesizeFromExtraction(projectPath); synthOk = s.ok; if (s.ok) { synthesizedHtml = await fsp.readFile(s.indexPath,'utf8'); await appendEvent(projectPath, { level:'info', stage:'synthesis', msg:'static-updated', index: s.indexPath }); } console.log(s.ok ? `[synthesis] index.html updated (${s.indexPath})` : `[synthesis] ${s.reason}`); } catch (e) { console.log(`[synthesis] Error: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'error', stage:'synthesis', msg:'static-error', error: e.message||String(e) }); }
  if (!synthOk) await writeCandidate(projectPath, port);

  // Next.js bootstrap (if requested)
  let nextProc = null; let server = null;
  const wantNext = (opts.template === 'next') || (process.env.ENT_TEMPLATE === 'next');
  if (wantNext && synthesizedHtml) {
    try { if (site && struct) await synthesizeNext(projectPath, site, struct, tokens || {}); } catch {}
    try {
      const nx = await bootstrapNext(projectPath, synthesizedHtml, port, { auth: !!opts.auth });
      if (nx.ok && nx.proc) { nextProc = nx.proc; console.log(`[orchestrator] Next.js dev server starting on ${localUrl}`); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'next-dev-start' }); await new Promise(r=>setTimeout(r,3000)); }
      else console.log(`[orchestrator] Next bootstrap skipped: ${nx.note || 'unknown'}`);
    } catch (e) { console.log(`[orchestrator] Next bootstrap error: ${e.message||String(e)}`); }
  }
  if (!nextProc) { server = await createServer(projectPath, port); console.log(`[orchestrator] Local server started at ${localUrl}`); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'static-start' }); }

  // Protocol 3.0 + Iteration v2
  let result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result });
  const targetSim = parseInt(opts.targetSimilarity || '90', 10);
  if (!result.success && (result.finalSimilarity || 0) < targetSim) {
    try { const s2 = await synthesizeFromExtraction(projectPath); if (s2.ok) { console.log('[iterate] Re-synthesized candidate; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'resynth' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchContentFromExtraction } = require('./patcher-content'); const pc = await patchContentFromExtraction(projectPath); if (pc.changed) { console.log(`[iterate] Page content patched (${pc.files.length}); re-validate`); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'content-patch', files: pc.files.length }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchHeroComponent } = require('./patcher-hero'); const ph = await patchHeroComponent(projectPath); if (ph.changed) { console.log('[iterate] Hero patched; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'hero-patch' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchTokens } = require('./patcher'); const pr = await patchTokens(projectPath); if (pr.changed) { console.log('[iterate] Tokens patched; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'token-patch' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
  }

  // Stop preview
  if (server) { await new Promise(resolve=> server.close(()=>resolve())); console.log('[orchestrator] Server stopped'); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'static-stop' }); }
  if (nextProc) { try { nextProc.kill(); } catch {}; console.log('[orchestrator] Next.js server stopped'); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'next-dev-stop' }); }

  // Log
  const log = { timestamp: new Date().toISOString(), targetUrl, localUrl, projectName, projectPath, result };
  const logPath = path.join(projectPath,'orchestrator-log.json'); await fsp.writeFile(logPath, JSON.stringify(log,null,2),'utf8'); console.log(`[orchestrator] Result written: ${logPath}`);
  await appendEvent(projectPath, { level:'info', stage:'summary', msg:'complete', log: logPath });

  // Validation summaries
  let mvSummary = null;
  try { const { summarizeMultiViewport } = require('./multi-viewport-validate'); const mv = await summarizeMultiViewport(targetUrl, localUrl, path.join(projectPath,'evidence','validation'), { visualEngine: opts.visualEngine || 'auto' }); if (mv && mv.summaryPath) { console.log(`[validation] Multi-viewport summary: ${mv.summaryPath}`); mvSummary = JSON.parse(fs.readFileSync(mv.summaryPath,'utf8')); } } catch {}
  try { const { validateIntegrity } = require('./validate-integrity'); const iv = await validateIntegrity(projectPath, localUrl, path.join(projectPath,'evidence','validation')); if (iv && iv.reportPath) console.log(`[validation] Integrity: ${iv.reportPath}`); } catch {}
  try { const extracted = require(path.join(projectPath,'evidence','extraction','extraction.json')); const { validateStructure } = require('./validate-structure'); const sv = await validateStructure(extracted, localUrl); const p = path.join(projectPath,'evidence','validation','dom-parity.json'); await ensureDir(path.dirname(p)); await fsp.writeFile(p, JSON.stringify(sv,null,2),'utf8'); console.log(`[validation] DOM parity: ${p}`); } catch {}

  // Budgets/gating
  try { const { enforceBudgets } = require('./budgets'); const gated = await enforceBudgets({ targetUrl, localUrl, projectPath, result }); if (gated && gated.updated) { result = gated.result; console.log(`[gating] Budgets applied: success=${result.success}`); } } catch {}

  // Deploy/rollback
  try { if (opts.deploy) { const { deployVercel } = require('./deploy'); const dep = await deployVercel(projectPath,false); console.log(dep.ok ? `[deploy] Vercel preview: ${dep.url || 'see output'}` : '[deploy] Skipped or failed'); } } catch {}
  try { if (opts.rollback) { const { rollbackVercel } = require('./rollback'); const rb = await rollbackVercel(projectPath); console.log(rb.ok ? '[deploy] Rollback executed' : '[deploy] Rollback failed or unavailable'); } } catch {}

  // Evidence index
  try { const { writeEvidenceIndex } = require('./evidence-index'); const idx = await writeEvidenceIndex(projectPath); console.log(`[evidence] Index: ${idx}`); } catch {}

  // Pause for human feedback if threshold reached and not auto
  try {
    const threshold = parseInt(process.env.ENT_TARGET_MV_MIN || '90', 10);
    const score = (result && typeof result.finalSimilarity === 'number') ? result.finalSimilarity : (mvSummary ? mvSummary.minScore : 0);
    if (!opts.auto && (opts.pauseAfterThreshold || true) && score >= threshold) {
      const fbDir = path.join(projectPath,'feedback'); await ensureDir(fbDir);
      const fbPath = path.join(fbDir,'REQUEST.md');
      const note = `# Feedback Requested\n\n- Similarity score: ${score}\n- Evidence index: evidence/index.html\n\nPlease describe desired changes (e.g., hero padding, CTA text, colors).`;
      await fsp.writeFile(fbPath, note, 'utf8');
      console.log(`[feedback] Threshold met (${score}%). Awaiting feedback at ${fbPath}`);
    }
  } catch {}

  return { projectPath, localUrl, result, logPath };
}

module.exports = { runOrchestration };
