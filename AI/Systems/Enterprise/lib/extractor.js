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

  // Asset harvesting: stylesheets, images, and fonts referenced by stylesheets
  const assets = await harvestAssets(targetUrl, evidenceDir);

  const artifact = {
    meta: {
      targetUrl,
      createdAt: new Date().toISOString(),
      tool: 'enterprise-extractor/1.0'
    },
    screenshots: shots,
    structure: struct.ok ? struct.data : null,
    notes: !struct.ok ? [struct.reason] : [],
    assets
  };

  const outPath = path.join(evidenceDir, 'extraction.json');
  await fsp.writeFile(outPath, JSON.stringify(artifact, null, 2), 'utf8');
  return { artifact, outPath, evidenceDir };
}

module.exports = { extractTarget };

// -------------------- internals: asset harvesting --------------------

function toAbsolute(baseUrl, href) {
  try { return new URL(href, baseUrl).toString(); } catch { return null; }
}

async function download(url, destPath) {
  try {
    const res = await fetch(url, { redirect: 'follow' });
    if (!res.ok) return false;
    const ab = await res.arrayBuffer();
    await ensureDir(path.dirname(destPath));
    await fsp.writeFile(destPath, Buffer.from(ab));
    return true;
  } catch { return false; }
}

async function harvestAssets(targetUrl, outDir) {
  const playwright = tryRequire('playwright');
  const result = { css: [], images: [], fonts: [], notes: [] };
  if (!playwright) { result.notes.push('playwright-not-installed'); return result; }

  const cssDir = path.join(outDir, 'assets', 'css');
  const imgDir = path.join(outDir, 'assets', 'img');
  const fontDir = path.join(outDir, 'assets', 'fonts');

  const links = await withPage(playwright, { width: 1440, height: 900 }, async (page) => {
    await page.goto(targetUrl, { waitUntil: 'load' });
    return await page.evaluate(() => {
      const abs = (href) => { try { return new URL(href, location.href).toString(); } catch { return null; } };
      const css = Array.from(document.querySelectorAll('link[rel="stylesheet"][href]')).map(l => abs(l.href)).filter(Boolean);
      const images = Array.from(document.images || []).map(img => abs(img.src)).filter(Boolean);
      return { css, images };
    });
  });

  // Download CSS and parse for font URLs
  const fontUrls = new Set();
  for (const cssUrl of (links.css || [])) {
    const fileName = cssUrl.split('?')[0].split('/').pop() || 'style.css';
    const dest = path.join(cssDir, fileName);
    const ok = await download(cssUrl, dest);
    result.css.push({ url: cssUrl, path: ok ? dest : null });
    if (ok) {
      try {
        const content = await fsp.readFile(dest, 'utf8');
        const regex = /url\(([^)]+)\)/g; let m;
        while ((m = regex.exec(content))) {
          const raw = m[1].replace(/['"]/g, '').trim();
          if (/\.(woff2?|ttf|otf)(\?|#|$)/i.test(raw)) {
            const abs = toAbsolute(cssUrl, raw);
            if (abs) fontUrls.add(abs);
          }
        }
      } catch {}
    }
  }

  // Download images
  for (const imgUrl of (links.images || [])) {
    const fileName = (imgUrl.split('?')[0].split('/').pop() || 'image').slice(-128);
    const dest = path.join(imgDir, fileName);
    const ok = await download(imgUrl, dest);
    result.images.push({ url: imgUrl, path: ok ? dest : null });
  }

  // Download fonts
  for (const fUrl of fontUrls) {
    const fileName = fUrl.split('?')[0].split('/').pop() || 'font';
    const dest = path.join(fontDir, fileName);
    const ok = await download(fUrl, dest);
    result.fonts.push({ url: fUrl, path: ok ? dest : null });
  }

  return result;
}
