#!/usr/bin/env node

/**
 * Phase 2 Bootstrap (not the orchestrator)
 * - Minimal steps needed by Protocol 30 Phase 2:
 *   extraction → tokens → synthesis → ensure local server
 * - No preflight, budgets, or iteration. No calls back to Protocol.
 */

const path = require('path');

async function phase2Bootstrap(targetUrl, opts = {}) {
  const fs = require('fs');
  const fsp = require('fs').promises;
  const { extractTarget } = require('./extractor');
  const { generateTokens } = require('./tokens');
  const { synthesizeFromExtraction } = require('./synthesis');
  let synthesizeSnapshot = null;
  try { synthesizeSnapshot = require('./synthesize-snapshot').synthesizeSnapshot; } catch {}
  const { probeServer, startProjectServer } = require('./server-manager');

  const baseDir = process.cwd();
  const projectsRoot = path.join(baseDir, 'projects');
  const projectName = opts.projectName || 'protocol30-clone';
  const port = parseInt(opts.port || (opts.localUrl ? new URL(opts.localUrl).port || '3000' : '3000'), 10);
  const localUrl = opts.localUrl || `http://localhost:${port}`;
  const projectPath = path.join(projectsRoot, projectName);

  try { await fsp.mkdir(projectPath, { recursive: true }); } catch {}

  let okExtract = false, okTokens = false, okSynthesis = false, okServe = false;
  let error = null;

  try { const ex = await extractTarget(targetUrl, projectPath); okExtract = !!ex; } catch (e) { error = e; }
  try { const tk = await generateTokens(projectPath); okTokens = !!tk; } catch (e) { error = error || e; }
  try {
    let s = null;
    if (synthesizeSnapshot) s = await synthesizeSnapshot(projectPath);
    if (!s || !s.ok) s = await synthesizeFromExtraction(projectPath);
    okSynthesis = !!(s && s.ok);
  } catch (e) { error = error || e; }

  try {
    const up = await probeServer(localUrl, { timeoutMs: 15000 });
    if (up) okServe = true;
    else {
      const srv = await startProjectServer(projectPath, port, { projectName });
      const again = await probeServer(localUrl, { timeoutMs: 30000 });
      okServe = !!again;
    }
  } catch (e) { error = error || e; }

  const success = okExtract && okTokens && okSynthesis && okServe;
  return { success, projectPath, localUrl, error: success ? null : (error ? (error.message || String(error)) : 'phase2-bootstrap-failed') };
}

module.exports = { runOrchestration: phase2Bootstrap };

