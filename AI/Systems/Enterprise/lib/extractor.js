#!/usr/bin/env node

/**
 * Target Site Extractor (Milestone 2)
 * - Captures multi-viewport screenshots (if Playwright available)
 * - Extracts basic structure (headings, nav links, CTAs)
 * - Extracts visual hints (body background, primary link color, font-family)
 * - Writes artifacts under projectPath/evidence/extraction
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

function tryRequire(name) { try { return require(name); } catch { return null; } }

async function ensureDir(p) { await fsp.mkdir(p, { recursive: true }); }

async function withPage(playwright, viewport, fn) {
  const browser = await playwright.chromium.launch();
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  try {
    return await fn(page);
  } finally {
    await context.close();
    await browser.close();
  }
}

async function captureScreenshots(targetUrl, outDir) {
  const playwright = tryRequire('playwright');
  if (!playwright) return { captured: false, files: [] };
  const viewports = [
    { id: 'desktop', width: 1440, height: 900 },
    { id: 'tablet', width: 768, height: 1024 },
    { id: 'mobile', width: 375, height: 812 }
  ];
  const files = [];
  for (const v of viewports) {
    const file = path.join(outDir, `target-${v.id}.png`);
    await withPage(playwright, { width: v.width, height: v.height }, async (page) => {
      await page.goto(targetUrl, { waitUntil: 'load' });
      await page.screenshot({ path: file, fullPage: true });
    });
    files.push({ id: v.id, path: file });
  }
  return { captured: true, files };
}

async function extractStructure(targetUrl) {
  const playwright = tryRequire('playwright');
  if (!playwright) return { ok: false, reason: 'playwright-not-installed' };
  return await withPage(playwright, { width: 1440, height: 900 }, async (page) => {
    await page.goto(targetUrl, { waitUntil: 'load' });
    const data = await page.evaluate(() => {
      const getTextList = (sel, max = 12) => Array.from(document.querySelectorAll(sel)).map(e => (e.innerText||'').trim()).filter(Boolean).slice(0, max);
      const style = window.getComputedStyle(document.body);
      const bg = style.getPropertyValue('background-color') || null;
      const ff = style.getPropertyValue('font-family') || null;
      const a = document.querySelector('a');
      const aStyle = a ? window.getComputedStyle(a) : null;
      const linkColor = aStyle ? aStyle.getPropertyValue('color') : null;
      return {
        headings: getTextList('h1, h2, h3', 12),
        nav: getTextList('nav a, header a', 16),
        ctas: getTextList('a[role="button"], button, .btn, [class*="button"]', 12),
        visual: { bodyBackground: bg, bodyFont: ff, linkColor }
      };
    });
    return { ok: true, data };
  });
}

async function extractTarget(targetUrl, projectPath) {
  const evidenceDir = path.join(projectPath, 'evidence', 'extraction');
  await ensureDir(evidenceDir);

  // Screenshots
  const shots = await captureScreenshots(targetUrl, evidenceDir);

  // Structure + visual hints
  const struct = await extractStructure(targetUrl);

  const artifact = {
    meta: {
      targetUrl,
      createdAt: new Date().toISOString(),
      tool: 'enterprise-extractor/1.0'
    },
    screenshots: shots,
    structure: struct.ok ? struct.data : null,
    notes: !struct.ok ? [struct.reason] : []
  };

  const outPath = path.join(evidenceDir, 'extraction.json');
  await fsp.writeFile(outPath, JSON.stringify(artifact, null, 2), 'utf8');
  return { artifact, outPath, evidenceDir };
}

module.exports = { extractTarget };

