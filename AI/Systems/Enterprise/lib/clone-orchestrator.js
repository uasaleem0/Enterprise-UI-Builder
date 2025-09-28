#!/usr/bin/env node

/**
 * Clone/Build Orchestrator
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
// Orchestrator delegates execution to Protocol 3.0 after preflight/setup
const { executeProtocol30 } = require('../protocols/protocol-3.0/integrated-protocol-3.0.js');
const { buildPrd, savePrd } = require('./prd');
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
    console.log(`[done] ${stage} (${elapsed})`);
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
  const server = http.createServer((req,res)=>{
    try {
      const url = decodeURIComponent(req.url || '/');
      let relPath = (url.split('?')[0] || '/');
      if (relPath === '/' || relPath === '') relPath = 'index.html';
      // Prevent path traversal
      const safeRel = path.normalize(relPath).replace(/^([.][.][\\/])+/, '');
      const filePath = path.join(projectPath, safeRel);
      const projectNorm = path.normalize(projectPath + path.sep);
      const fileNorm = path.normalize(filePath);
      if (!fileNorm.startsWith(projectNorm)) {
        res.writeHead(403, { 'Content-Type': 'text/plain' });
        res.end('Forbidden');
        return;
      }
      const ext = path.extname(filePath).toLowerCase();
      const contentTypes = {
        '.html': 'text/html; charset=utf-8',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.svg': 'image/svg+xml',
        '.webp': 'image/webp',
        '.woff2': 'font/woff2',
        '.woff': 'font/woff',
        '.ttf': 'font/ttf'
      };
      const type = contentTypes[ext] || 'application/octet-stream';
      if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
        res.writeHead(200, { 'Content-Type': type });
        res.end(fs.readFileSync(filePath));
      } else {
        // Fallback: serve index.html for unknown routes (SPA-like)
        const indexPath = path.join(projectPath, 'index.html');
        if (fs.existsSync(indexPath)) {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(fs.readFileSync(indexPath, 'utf8'));
        } else {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('Not found');
        }
      }
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Server error');
    }
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
  // Backup once per top-level run: skip if marker exists or disabled by env
  const backupMarker = path.join(projectPath, '.backup-done');
  let backupPath = null;
  try {
    const noBackups = process.env.ENT_NO_BACKUPS === '1';
    const hasMarker = fs.existsSync(backupMarker);
    if (!noBackups && !hasMarker) {
      backupPath = await backupIfExists(projectPath, backupsRoot);
      if (backupPath) {
        console.log(`[backup] Existing project backed up to: ${backupPath}`);
        await appendEvent(projectPath, { level:'info', stage:'backup', msg:'backup-created', path: backupPath });
        try { await fsp.writeFile(backupMarker, String(Date.now()), 'utf8'); } catch {}
      }
    } else if (hasMarker) {
      console.log('[backup] Skipped (marker present)');
    } else if (noBackups) {
      console.log('[backup] Skipped (ENT_NO_BACKUPS=1)');
    }
  } catch {}

  // Optional PRD persist for app flow
  try { if (opts.describe) { const prd = buildPrd(opts.describe); const prdPaths = await savePrd(projectPath, prd); console.log(`[prd] Saved: ${prdPaths.mdPath}`); await appendEvent(projectPath, { level:'info', stage:'prd', msg:'saved', md: prdPaths.mdPath }); } } catch {}

  // Preflight
  try {
    const pf = await runPreflight();
    await appendEvent(projectPath, { level:'info', stage:'preflight', msg:'results', data: pf });
    if (process.env.ENT_QUIET !== '1') {
      console.log('[preflight]', JSON.stringify(pf.rows));
      if (pf.warnings?.length) console.log('[preflight-warn]', pf.warnings.join(' | '));
    }
    // Critical fail if Playwright missing or no visual engine (ms-sim or MCP) available
    const hasPlaywright = pf.rows.find(r=>r.label==='Playwright')?.ok;
    const hasMs = pf.rows.find(r=>r.label==='ms-similarity-adapter')?.ok;
    const hasMcp = pf.rows.find(r=>r.label==='mcp-visual-validator')?.ok;
    const missing = [];
    if (!hasPlaywright) missing.push('Playwright');
    if (!(hasMs || hasMcp)) missing.push('visual-engine');
    if (missing.length) {
      const msg = `[fatal] Missing critical visual requirements: ${missing.join(', ')}`;
      console.log(msg);
      await appendEvent(projectPath, { level:'error', stage:'preflight', msg:'fatal-missing', missing });
      return { projectPath, localUrl, result: { success:false, finalSimilarity:0, error: 'critical-missing-visual-engines', missing }, logPath: path.join(projectPath,'orchestrator-log.json') };
    }
  } catch {}

  // Delegate to Protocol 3.0 for cloning/validation/iteration
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[delegate] protocol-30');
    const protocolRes = await executeProtocol30(targetUrl, {
      projectName,
      projectPath,
      localUrl,
      targetSimilarity: parseInt(opts.targetSimilarity || '90', 10),
      visualEngine: opts.visualEngine || process.env.ENT_VISUAL_ENGINE || 'auto'
    });

    let result = { success: protocolRes.success, finalSimilarity: protocolRes.finalSimilarity };
    try {
      const { enforceBudgets } = require('./budgets');
      const applied = await enforceBudgets({ targetUrl, localUrl, projectPath, result });
      if (applied && applied.updated) {
        result = applied.result;
      }
    } catch {}

    const log = { timestamp: new Date().toISOString(), targetUrl, localUrl, projectName, projectPath, result };
    const logPath = path.join(projectPath,'orchestrator-log.json'); await fsp.writeFile(logPath, JSON.stringify(log,null,2),'utf8'); console.log(`[orchestrator] Result written: ${logPath}`);
    await appendEvent(projectPath, { level:'info', stage:'summary', msg:'complete', log: logPath });
    return { projectPath, localUrl, result, logPath };
  } catch (e) {
    const result = { success:false, finalSimilarity:0, error: e.message||String(e) };
    const log = { timestamp: new Date().toISOString(), targetUrl, localUrl, projectName, projectPath, result };
    const logPath = path.join(projectPath,'orchestrator-log.json'); await fsp.writeFile(logPath, JSON.stringify(log,null,2),'utf8'); console.log(`[orchestrator] Result written: ${logPath}`);
    await appendEvent(projectPath, { level:'error', stage:'summary', msg:'failed', log: logPath, error: result.error });
    return { projectPath, localUrl, result, logPath };
  }

  // Delegate to Protocol 3.0 for cloning/validation/iteration
  try {
    if (process.env.ENT_QUIET !== '1') console.log('[delegate] protocol-3.0');
    const protocolRes = await executeProtocol30(targetUrl, {
      projectName,
      projectPath,
      localUrl,
      targetSimilarity: parseInt(opts.targetSimilarity || '90', 10),
      visualEngine: opts.visualEngine || process.env.ENT_VISUAL_ENGINE || 'auto'
    });

    // Optionally enforce budgets here for compatibility
    let result = { success: protocolRes.success, finalSimilarity: protocolRes.finalSimilarity };
    try {
      const { enforceBudgets } = require('./budgets');
      const applied = await enforceBudgets({ targetUrl, localUrl, projectPath, result });
      if (applied && applied.updated) {
        result = applied.result;
      }
    } catch {}

    // Log
    const log = { timestamp: new Date().toISOString(), targetUrl, localUrl, projectName, projectPath, result };
    const logPath = path.join(projectPath,'orchestrator-log.json'); await fsp.writeFile(logPath, JSON.stringify(log,null,2),'utf8'); console.log(`[orchestrator] Result written: ${logPath}`);
    await appendEvent(projectPath, { level:'info', stage:'summary', msg:'complete', log: logPath });
    return { projectPath, localUrl, result, logPath };
  } catch (e) {
    const result = { success:false, finalSimilarity:0, error: e.message||String(e) };
    const log = { timestamp: new Date().toISOString(), targetUrl, localUrl, projectName, projectPath, result };
    const logPath = path.join(projectPath,'orchestrator-log.json'); await fsp.writeFile(logPath, JSON.stringify(log,null,2),'utf8'); console.log(`[orchestrator] Result written: ${logPath}`);
    await appendEvent(projectPath, { level:'error', stage:'summary', msg:'failed', log: logPath, error: result.error });
    return { projectPath, localUrl, result, logPath };
  }
}

module.exports = { runOrchestration };
