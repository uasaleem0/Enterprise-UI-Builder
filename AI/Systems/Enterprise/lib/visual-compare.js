#!/usr/bin/env node

/**
 * Visual Comparator (engine selector)
 * Priority: microsoft -> mcp -> pixelmatch
 * Emits warnings when engines are unavailable.
 */

const fs = require('fs');

function tryRequire(name){ try { return require(name); } catch { return null; } }

async function compareMicrosoft(baselinePath, candidatePath, options={}){
  if (typeof global.msSimilarityCompare !== 'function') return { available:false };
  try {
    const r = await global.msSimilarityCompare(baselinePath, candidatePath, options);
    if (!r) return { available:true, ok:false };
    if (typeof r.passed === 'boolean') return { available:true, ok:r.passed, score: r.score ?? (r.passed ? 100 : 0), engine:'microsoft' };
    if (typeof r.score === 'number') return { available:true, ok: r.score >= (options.minScore||85), score: r.score, engine:'microsoft' };
    return { available:true, ok:false, engine:'microsoft' };
  } catch (e) { return { available:true, ok:false, error: e.message || String(e), engine:'microsoft' }; }
}

async function compareMCP(localUrl, targetUrl, options={}){
  if (typeof global.mcpVisualValidate !== 'function') return { available:false };
  try {
    const r = await global.mcpVisualValidate(localUrl, targetUrl, options);
    if (!r) return { available:true, ok:false };
    const score = typeof r.similarity === 'number' ? r.similarity : (r.passed ? 100 : 0);
    const ok = typeof r.passed === 'boolean' ? r.passed : (score >= (options.minScore||85));
    return { available:true, ok, score, engine:'mcp' };
  } catch (e) { return { available:true, ok:false, error: e.message || String(e), engine:'mcp' }; }
}

async function comparePixelmatch(baselinePath, candidatePath, options={}){
  const pixelmatch = tryRequire('pixelmatch');
  const PNG = tryRequire('pngjs')?.PNG;
  if (!pixelmatch || !PNG) return { available:false };
  try {
    const a = PNG.sync.read(fs.readFileSync(baselinePath));
    const b = PNG.sync.read(fs.readFileSync(candidatePath));
    if (a.width !== b.width || a.height !== b.height) return { available:true, ok:false, score:0, reason:'dimension-mismatch', engine:'pixelmatch' };
    const diff = pixelmatch(a.data, b.data, null, a.width, a.height, { threshold: 0.1 });
    const total = a.width * a.height;
    const diffRatio = diff / total;
    const score = Math.max(0, 100 - diffRatio * 100);
    return { available:true, ok: score >= (options.minScore||85), score: Math.round(score), engine:'pixelmatch' };
  } catch (e) { return { available:true, ok:false, error: e.message || String(e), engine:'pixelmatch' }; }
}

async function compareVisual(opts){
  const warnings=[];
  const enginePref = (opts.visualEngine||'auto').toLowerCase();
  let order;
  if (enginePref === 'microsoft') order = ['microsoft','mcp','pixelmatch'];
  else if (enginePref === 'pixelmatch') order = ['pixelmatch'];
  else order = ['microsoft','mcp','pixelmatch'];

  for (const eng of order) {
    if (eng === 'microsoft') {
      const r = await compareMicrosoft(opts.baselinePath, opts.candidatePath, { minScore: opts.minScore });
      if (r.available) return { ...r, warnings };
      warnings.push('[warn] Microsoft similarity adapter not available');
    }
    if (eng === 'mcp') {
      const r = await compareMCP(opts.localUrl, opts.targetUrl, { minScore: opts.minScore });
      if (r.available) return { ...r, warnings };
      warnings.push('[warn] Playwright MCP visual validator not available');
    }
    if (eng === 'pixelmatch') {
      const r = await comparePixelmatch(opts.baselinePath, opts.candidatePath, { minScore: opts.minScore });
      if (r.available) return { ...r, warnings };
      warnings.push('[warn] pixelmatch/pngjs not installed');
    }
  }
  warnings.push('[warn] No visual engine available; falling back to structural and budget checks');
  return { available:false, ok:false, warnings };
}

module.exports = { compareVisual };

