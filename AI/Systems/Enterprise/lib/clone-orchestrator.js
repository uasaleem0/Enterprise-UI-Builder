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

// -------- Heartbeat / Timeout helpers --------
function nowMs() { return Date.now(); }
function fmtSecs(ms) { return Math.round(ms/1000)+'s'; }

function startHeartbeat(stage) {
  if (process.env.ENT_QUIET === '1') return null;
  const intervalMs = 10000; // 10s
  const start = nowMs();
  const t = setInterval(() => {
    process.stdout.write(`\n[tick] ${stage} elapsed=${fmtSecs(nowMs()-start)}`);
  }, intervalMs);
  return { t, start };
}

function stopHeartbeat(hb, stage) {
  if (hb && hb.t) clearInterval(hb.t);
  if (process.env.ENT_QUIET !== '1') {
    const elapsed = hb ? fmtSecs(nowMs()-hb.start) : '0s';
    console.log(`\n[done] ${stage} (${elapsed})`);
  }
}

async function withTimeout(promiseFactory, ms, stage, projectPath) {
  const hb = startHeartbeat(stage);
  const timeout = new Promise((resolve) => setTimeout(() => resolve({ __timeout: true }), ms));
  const result = await Promise.race([ promiseFactory(), timeout ]);
  stopHeartbeat(hb, stage);
  if (result && result.__timeout) {
    const msg = `[error] ${stage} timeout after ${fmtSecs(ms)}`;
    console.log(msg);
    await appendEvent(projectPath, { level:'error', stage, msg:'timeout', ms });
    return { __timeout: true };
  }
  return result;
}

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
  try { const pf = await runPreflight(); await appendEvent(projectPath, { level:'info', stage:'preflight', msg:'results', data: pf }); if (process.env.ENT_QUIET !== '1') { console.log('[preflight]', JSON.stringify(pf.rows)); if (pf.warnings?.length) console.log('[preflight-warn]', pf.warnings.join(' | ')); } } catch {}

  // Crawl (clone) and extract
  let site = { pages: [] };
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[stage] crawl');
    const r = await withTimeout(() => crawl(targetUrl, parseInt(opts.crawlLimit || '8',10)), 120000, 'crawl', projectPath);
    if (!r || r.__timeout) throw new Error('crawl-timeout');
    site = r; const sm = await saveSiteMap(projectPath, site);
    if (process.env.ENT_QUIET !== '1') console.log(`[crawl] Site map: ${sm}`);
    await appendEvent(projectPath, { level:'info', stage:'crawl', msg:'site-map', path: sm, pages: site.pages?.length||0 });
  } catch (e) { console.log(`[crawl] Skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'crawl', msg:'skipped', error: e.message||String(e) }); }
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[stage] extract');
    const ex = await withTimeout(() => extractTarget(targetUrl, projectPath), 180000, 'extract', projectPath);
    if (!ex || ex.__timeout) throw new Error('extract-timeout');
    if (process.env.ENT_QUIET !== '1') console.log(`[extract] Artifacts at ${ex.evidenceDir}`);
    await appendEvent(projectPath, { level:'info', stage:'extract', msg:'done', dir: ex.evidenceDir });
  } catch (e) { console.log(`[extract] Skipped or failed: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'extract', msg:'failed', error: e.message||String(e) }); }
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[stage] extract-pages');
    const px = await withTimeout(() => extractPages(site, projectPath), 120000, 'extract-pages', projectPath);
    if (!px || px.__timeout) throw new Error('extract-pages-timeout');
    if (process.env.ENT_QUIET !== '1') console.log(`[extract] Per-page data at ${px.outDir}`);
    await appendEvent(projectPath, { level:'info', stage:'extract', msg:'per-page', dir: px.outDir });
  } catch (e) { console.log(`[extract] pages skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'extract', msg:'per-page-skipped', error: e.message||String(e) }); }

  // Load structure and generate tokens
  let struct = null; let tokens = null;
  try { const extraction = require(path.join(projectPath,'evidence','extraction','extraction.json')); struct = extraction.structure || null; } catch {}
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[stage] tokens');
    const tk = await withTimeout(() => generateTokens(projectPath), 60000, 'tokens', projectPath);
    if (!tk || tk.__timeout) throw new Error('tokens-timeout');
    tokens = tk.tokens || null;
    if (process.env.ENT_QUIET !== '1') console.log(`[tokens] Generated ${tk.jsonPath}`);
    await appendEvent(projectPath, { level:'info', stage:'tokens', msg:'generated', path: tk.jsonPath });
  } catch (e) { console.log(`[tokens] skipped: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'warn', stage:'tokens', msg:'skipped', error: e.message||String(e) }); }

  // Synthesize minimal static HTML for server fallback
  let synthOk = false; let synthesizedHtml = null;
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[stage] synth-static');
    const s = await withTimeout(() => synthesizeFromExtraction(projectPath), 60000, 'synth-static', projectPath);
    if (!s || s.__timeout) throw new Error('synth-timeout');
    synthOk = s.ok;
    if (s.ok) { synthesizedHtml = await fsp.readFile(s.indexPath,'utf8'); await appendEvent(projectPath, { level:'info', stage:'synthesis', msg:'static-updated', index: s.indexPath }); }
    if (process.env.ENT_QUIET !== '1') console.log(s.ok ? `[synthesis] index.html updated (${s.indexPath})` : `[synthesis] ${s.reason}`);
  } catch (e) { console.log(`[synthesis] Error: ${e.message||String(e)}`); await appendEvent(projectPath, { level:'error', stage:'synthesis', msg:'static-error', error: e.message||String(e) }); }
  if (!synthOk) await writeCandidate(projectPath, port);

  // Next.js bootstrap (if requested)
  let nextProc = null; let server = null;
  const wantNext = (opts.template === 'next') || (process.env.ENT_TEMPLATE === 'next');
  if (wantNext && synthesizedHtml) {
    try { if (site && struct) await synthesizeNext(projectPath, site, struct, tokens || {}); } catch {}
    try {
      if (process.env.ENT_QUIET !== '1') console.log('[stage] next-bootstrap');
      const nx = await withTimeout(() => bootstrapNext(projectPath, synthesizedHtml, port, { auth: !!opts.auth }), 300000, 'next-bootstrap', projectPath);
      if (nx.ok && nx.proc) { nextProc = nx.proc; console.log(`[orchestrator] Next.js dev server starting on ${localUrl}`); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'next-dev-start' }); await new Promise(r=>setTimeout(r,3000)); }
      else console.log(`[orchestrator] Next bootstrap skipped: ${nx.note || 'unknown'}`);
    } catch (e) { console.log(`[orchestrator] Next bootstrap error: ${e.message||String(e)}`); }
  }
  if (!nextProc) { server = await createServer(projectPath, port); console.log(`[orchestrator] Local server started at ${localUrl}`); await appendEvent(projectPath, { level:'info', stage:'serve', msg:'static-start' }); }

  // Protocol 3.0 + Iteration v2
  if (process.env.ENT_QUIET !== '1') console.log('[stage] validate:protocol30');
  let result = await withTimeout(() => executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }), 300000, 'validate:protocol30', projectPath);
  if (!result || result.__timeout) result = { success:false, finalSimilarity:0 };
  await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result });
  const targetSim = parseInt(opts.targetSimilarity || '90', 10);
  if (!result.success && (result.finalSimilarity || 0) < targetSim) {
    try { if (process.env.ENT_QUIET !== '1') console.log('[stage] iterate:resynth'); const s2 = await withTimeout(() => synthesizeFromExtraction(projectPath), 60000, 'iterate:resynth', projectPath); if (s2 && !s2.__timeout && s2.ok) { console.log('[iterate] Re-synthesized candidate; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'resynth' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchContentFromExtraction } = require('./patcher-content'); if (process.env.ENT_QUIET !== '1') console.log('[stage] iterate:content-patch'); const pc = await withTimeout(() => patchContentFromExtraction(projectPath), 60000, 'iterate:content-patch', projectPath); if (pc && !pc.__timeout && pc.changed) { console.log(`[iterate] Page content patched (${pc.files.length}); re-validate`); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'content-patch', files: pc.files.length }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchHeroComponent } = require('./patcher-hero'); if (process.env.ENT_QUIET !== '1') console.log('[stage] iterate:hero-patch'); const ph = await withTimeout(() => patchHeroComponent(projectPath), 60000, 'iterate:hero-patch', projectPath); if (ph && !ph.__timeout && ph.changed) { console.log('[iterate] Hero patched; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'hero-patch' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
    try { const { patchTokens } = require('./patcher'); if (process.env.ENT_QUIET !== '1') console.log('[stage] iterate:token-patch'); const pr = await withTimeout(() => patchTokens(projectPath), 60000, 'iterate:token-patch', projectPath); if (pr && !pr.__timeout && pr.changed) { console.log('[iterate] Tokens patched; re-validate'); await appendEvent(projectPath, { level:'info', stage:'iterate', msg:'token-patch' }); result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity }); await appendEvent(projectPath, { level:'info', stage:'validate', msg:'protocol30', result }); } } catch {}
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
  try { const { summarizeMultiViewport } = require('./multi-viewport-validate'); if (process.env.ENT_QUIET !== '1') console.log('[stage] validate:multi-viewport'); const mv = await withTimeout(() => summarizeMultiViewport(targetUrl, localUrl, path.join(projectPath,'evidence','validation'), { visualEngine: opts.visualEngine || 'auto' }), 120000, 'validate:multi-viewport', projectPath); if (mv && mv.summaryPath) { console.log(`[validation] Multi-viewport summary: ${mv.summaryPath}`); mvSummary = JSON.parse(fs.readFileSync(mv.summaryPath,'utf8')); } } catch {}
  try { const { validateIntegrity } = require('./validate-integrity'); if (process.env.ENT_QUIET !== '1') console.log('[stage] validate:integrity'); const iv = await withTimeout(() => validateIntegrity(projectPath, localUrl, path.join(projectPath,'evidence','validation')), 60000, 'validate:integrity', projectPath); if (iv && iv.reportPath) console.log(`[validation] Integrity: ${iv.reportPath}`); } catch {}
  try { const extracted = require(path.join(projectPath,'evidence','extraction','extraction.json')); const { validateStructure } = require('./validate-structure'); if (process.env.ENT_QUIET !== '1') console.log('[stage] validate:dom-parity'); const sv = await withTimeout(() => validateStructure(extracted, localUrl), 60000, 'validate:dom-parity', projectPath); const p = path.join(projectPath,'evidence','validation','dom-parity.json'); await ensureDir(path.dirname(p)); await fsp.writeFile(p, JSON.stringify(sv,null,2),'utf8'); console.log(`[validation] DOM parity: ${p}`); } catch {}

  // Budgets/gating
  try { const { enforceBudgets } = require('./budgets'); const gated = await enforceBudgets({ targetUrl, localUrl, projectPath, result }); if (gated && gated.updated) { result = gated.result; console.log(`[gating] Budgets applied: success=${result.success}`); } } catch {}

  // Deploy/rollback
  try { if (opts.deploy) { if (process.env.ENT_QUIET !== '1') console.log('[stage] deploy'); const { deployVercel } = require('./deploy'); const dep = await withTimeout(() => deployVercel(projectPath,false), 300000, 'deploy', projectPath); console.log(dep.ok ? `[deploy] Vercel preview: ${dep.url || 'see output'}` : '[deploy] Skipped or failed'); } } catch {}
  try { if (opts.rollback) { if (process.env.ENT_QUIET !== '1') console.log('[stage] rollback'); const { rollbackVercel } = require('./rollback'); const rb = await withTimeout(() => rollbackVercel(projectPath), 180000, 'rollback', projectPath); console.log(rb.ok ? '[deploy] Rollback executed' : '[deploy] Rollback failed or unavailable'); } } catch {}

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
