#!/usr/bin/env node

/**
 * Multi-Viewport Validation (Milestone 5, minimal)
 * - If Playwright and pixelmatch/pngjs available, captures pairs of screenshots
 *   for local and target across common viewports and computes per-viewport score.
 * - Writes a simple JSON summary under evidence/validation.
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const { compareVisual } = require('./visual-compare');

function tryRequire(name) { try { return require(name); } catch { return null; } }
async function ensureDir(p) { await fsp.mkdir(p, { recursive: true }); }

async function withPage(playwright, viewport, fn) {
  const browser = await playwright.chromium.launch();
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  try { return await fn(page); } finally { await context.close(); await browser.close(); }
}

const crypto = require('crypto');

async function hashHtml(url, viewport){
  try {
    const text = await (await fetch(url, { redirect:'follow' })).text();
    const key = `${viewport.width}x${viewport.height}:${url}:${text.substring(0, 5000)}`;
    return crypto.createHash('sha256').update(key).digest('hex').substring(0,12);
  } catch { return null; }
}

async function capture(url, outPath, viewport) {
  const playwright = tryRequire('playwright');
  if (!playwright) return false;
  // Caching: if a hash file exists for this URL+viewport, reuse
  try {
    const h = await hashHtml(url, viewport);
    if (h) {
      const cached = outPath.replace(/\.png$/, `-${h}.png`);
      const fs = require('fs');
      if (fs.existsSync(cached)) {
        try { fs.copyFileSync(cached, outPath); } catch {}
        return true;
      }
      const ok = await withPage(playwright, viewport, async (page) => {
        await page.goto(url, { waitUntil: 'load' });
        await page.screenshot({ path: outPath, fullPage: true });
      });
      try { fs.copyFileSync(outPath, cached); } catch {}
      return ok;
    }
  } catch {}
  await withPage(playwright, viewport, async (page) => {
    await page.goto(url, { waitUntil: 'load' });
    await page.screenshot({ path: outPath, fullPage: true });
  });
  return true;
}

function diffImages(aPath, bPath) {
  const pixelmatch = tryRequire('pixelmatch');
  const PNG = tryRequire('pngjs')?.PNG;
  if (!pixelmatch || !PNG) return null;
  const a = PNG.sync.read(fs.readFileSync(aPath));
  const b = PNG.sync.read(fs.readFileSync(bPath));
  if (a.width !== b.width || a.height !== b.height) return { score: 0, reason: 'dimension-mismatch' };
  const diff = pixelmatch(a.data, b.data, null, a.width, a.height, { threshold: 0.1 });
  const total = a.width * a.height;
  const diffRatio = diff / total;
  const score = Math.max(0, 100 - diffRatio * 100);
  return { score: Math.round(score) };
}

async function summarizeMultiViewport(targetUrl, localUrl, outDir, options = {}) {
  await ensureDir(outDir);
  const viewports = [
    { id: 'desktop', width: 1440, height: 900 },
    { id: 'tablet', width: 768, height: 1024 },
    { id: 'mobile', width: 375, height: 812 }
  ];
  const results = []; const warnings = [];
  for (const v of viewports) {
    const base = path.join(outDir, v.id);
    const tgt = base + '-target.png';
    const loc = base + '-local.png';
    try {
      const ok1 = await capture(targetUrl, tgt, { width: v.width, height: v.height });
      const ok2 = await capture(localUrl, loc, { width: v.width, height: v.height });
      if (ok1 && ok2) {
        // Prefer Microsoft or MCP; fallback to pixelmatch
        const cmp = await compareVisual({
          visualEngine: options.visualEngine || 'auto',
          baselinePath: tgt,
          candidatePath: loc,
          localUrl,
          targetUrl,
          minScore: parseInt(process.env.ENT_TARGET_MV_MIN || '85', 10)
        });
        if (cmp.warnings?.length) warnings.push(...cmp.warnings);
        results.push({ viewport: v.id, score: cmp.score ?? null, engine: cmp.engine || null });
      } else {
        warnings.push('[warn] Playwright not installed: screenshot capture unavailable');
        results.push({ viewport: v.id, score: null, note: 'playwright-missing' });
      }
    } catch (e) {
      results.push({ viewport: v.id, score: null, error: e.message || String(e) });
    }
  }
  const summary = {
    targetUrl, localUrl, createdAt: new Date().toISOString(), results, warnings,
    minScore: Math.min(...results.map(r => (typeof r.score === 'number' ? r.score : 101)))
  };
  const summaryPath = path.join(outDir, 'multi-viewport-summary.json');
  await fsp.writeFile(summaryPath, JSON.stringify(summary, null, 2), 'utf8');
  return { summaryPath };
}

module.exports = { summarizeMultiViewport };
