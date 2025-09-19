#!/usr/bin/env node

/**
 * Clone Orchestrator (Milestone 1)
 * - Creates a simple candidate project (no external deps)
 * - Starts a local HTTP server
 * - Runs Protocol 3.0 validation against target URL
 * - Stops server and writes a result log
 * - Creates timestamped backups when reusing an existing project name
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const http = require('http');
const { executeProtocol30 } = require('../protocols/protocol-3.0/integrated-protocol-3.0.js');
const { extractTarget } = require('./extractor');
const { synthesizeFromExtraction } = require('./synthesis');
const { synthesizeNext } = require('./synthesize-next');
const { bootstrapNext } = require('./bootstrap-next');

function generateProjectName(url) {
  try {
    const u = new URL(url);
    const domain = u.hostname.replace('www.', '');
    return domain.split('.')[0] + '-protocol30-clone';
  } catch {
    return 'website-protocol30-clone-' + Date.now();
  }
}

async function ensureDir(p) {
  await fsp.mkdir(p, { recursive: true });
}

function nowStamp() {
  const d = new Date();
  const pad = (n)=>String(n).padStart(2,'0');
  return `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

async function backupIfExists(projectPath, backupsRoot) {
  if (fs.existsSync(projectPath)) {
    const stamp = nowStamp();
    const dest = path.join(backupsRoot, path.basename(projectPath) + '-' + stamp);
    await ensureDir(dest);
    // Node 16+: fs.cp available; fallback to manual copy if needed
    if (fs.cp) {
      await fsp.cp(projectPath, dest, { recursive: true });
    } else {
      // simple recursive copy
      const copyRecursive = async (src, dst) => {
        const stat = await fsp.stat(src);
        if (stat.isDirectory()) {
          await ensureDir(dst);
          const entries = await fsp.readdir(src);
          for (const e of entries) {
            await copyRecursive(path.join(src, e), path.join(dst, e));
          }
        } else {
          await fsp.copyFile(src, dst);
        }
      };
      await copyRecursive(projectPath, dest);
    }
    return dest;
  }
  return null;
}

async function writeCandidate(projectPath, port) {
  await ensureDir(projectPath);
  const indexHtml = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Enterprise Candidate</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 0; padding: 2rem; }
      header, footer { padding: 1rem 0; }
      .container { max-width: 960px; margin: 0 auto; }
      .hero { padding: 3rem 0; background: #f5f5f5; margin: 1rem 0; }
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <h1>Enterprise Candidate</h1>
      </header>
      <section class="hero">
        <h2>Placeholder Hero</h2>
        <p>This is a bootstrap candidate page served locally on port ${port}.</p>
      </section>
      <footer>
        <small>Enterprise System Â· Candidate</small>
      </footer>
    </div>
  </body>
  </html>`;
  await fsp.writeFile(path.join(projectPath, 'index.html'), indexHtml, 'utf8');
  // Minimal package for traceability (no deps)
  const pkg = {
    name: path.basename(projectPath), version: '0.0.1', private: true,
    scripts: { start: 'node server.js' }
  };
  await fsp.writeFile(path.join(projectPath, 'package.json'), JSON.stringify(pkg, null, 2), 'utf8');
}

function createServer(projectPath, port) {
  const indexPath = path.join(projectPath, 'index.html');
  const server = http.createServer((req, res) => {
    try {
      const html = fs.readFileSync(indexPath, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(html);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Server error');
    }
  });
  return new Promise(resolve => {
    server.listen(port, () => resolve(server));
  });
}

async function runOrchestration(targetUrl, opts = {}) {
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
  if (backupPath) {
    console.log(`[backup] Existing project backed up to: ${backupPath}`);
  }

  // 1) Extract target (screenshots + structure)
  try {
    const ex = await extractTarget(targetUrl, projectPath);
    console.log(`[extract] Artifacts at ${ex.evidenceDir}`);
  } catch (e) {
    console.log(`[extract] Skipped or failed: ${e.message || String(e)}`);
  }

  // 2) Synthesize candidate from extraction (fallback to placeholder)
  let synthOk = false;
  let synthesizedHtml = null;
  try {
    const s = await synthesizeFromExtraction(projectPath);
    synthOk = s.ok;
    if (s.ok) { try { synthesizedHtml = await fsp.readFile(s.indexPath, 'utf8'); } catch {} }
    console.log(s.ok ? `[synthesis] index.html updated (${s.indexPath})` : `[synthesis] ${s.reason}`);
  } catch (e) {
    console.log(`[synthesis] Error: ${e.message || String(e)}`);
  }

  if (!synthOk) { await writeCandidate(projectPath, port); }\n  // Optional Next.js bootstrap (ENT_TEMPLATE=next or --template next) (ENT_TEMPLATE=next or --template next)
  let nextProc = null;
  const wantNext = (opts.template === 'next') || (process.env.ENT_TEMPLATE === 'next');
  let server = null;
  if (wantNext && synthesizedHtml) {
    try {
      const nx = await bootstrapNext(projectPath, synthesizedHtml, port);
      if (nx.ok && nx.proc) {
        nextProc = nx.proc;
        console.log(`[orchestrator] Next.js dev server starting on ${localUrl}`);
        await new Promise(r => setTimeout(r, 3000));
      } else {
        console.log(`[orchestrator] Next bootstrap skipped: ${nx.note || 'unknown'}`);
      }
    } catch (e) { console.log(`[orchestrator] Next bootstrap error: ${e.message || String(e)}`); }
  }

  if (!nextProc) {
    server = await createServer(projectPath, port);
    console.log(`[orchestrator] Local server started at ${localUrl}`);
  }

  // 3) Execute Protocol 3.0 with explicit localUrl and projectPath
  let result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity });

  // 4) Minimal iterative patching: if similarity below target, try re-synthesis (no-op if already synthesized)
  const targetSim = parseInt(opts.targetSimilarity || '90', 10);
  if (!result.success && (result.finalSimilarity || 0) < targetSim) {
    try {
      const s2 = await synthesizeFromExtraction(projectPath);
      if (s2.ok) {
        console.log('[iterate] Re-synthesized candidate; re-running validation once');
        result = await executeProtocol30(targetUrl, { projectName, projectPath, localUrl, targetSimilarity: opts.targetSimilarity });
      }
    } catch {}
  }

  // Stop server
  if (server) {
    await new Promise(resolve => server.close(() => resolve()));
    console.log('[orchestrator] Server stopped');
  }
  if (nextProc) { try { nextProc.kill(); } catch {}; console.log('[orchestrator] Next.js server stopped'); }

  // Persist a simple result log
  const log = {
    timestamp: new Date().toISOString(),
    targetUrl, localUrl, projectName, projectPath,
    result
  };
  const logPath = path.join(projectPath, 'orchestrator-log.json');
  await fsp.writeFile(logPath, JSON.stringify(log, null, 2), 'utf8');
  console.log(`[orchestrator] Result written: ${logPath}`);

  // 5) Optional multi-viewport validation summary (best-effort)
  try {
    const { summarizeMultiViewport } = require('./multi-viewport-validate');
    const mv = await summarizeMultiViewport(targetUrl, localUrl, path.join(projectPath, 'evidence', 'validation'));
    if (mv && mv.summaryPath) {
      console.log(`[validation] Multi-viewport summary: ${mv.summaryPath}`);
    }
  } catch {}

  // 6) Budgets & gating (a11y/perf/multi-viewport) if ENT_ENFORCE_BUDGETS=1
  try {
    const { enforceBudgets } = require('./budgets');
    const gated = await enforceBudgets({ targetUrl, localUrl, projectPath, result });
    if (gated && gated.updated) {
      result = gated.result;
      console.log(`[gating] Budgets applied: success=${result.success}`);
    }
  } catch {}

  return { projectPath, localUrl, result, logPath };
}

module.exports = { runOrchestration };
