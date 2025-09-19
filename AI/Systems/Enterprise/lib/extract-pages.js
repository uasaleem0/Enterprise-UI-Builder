#!/usr/bin/env node

/**
 * Per-page extraction
 * - For each crawled page, capture basic structure and visual hints
 * - Writes JSON files under evidence/extraction/pages
 */

const fsp = require('fs').promises;
const path = require('path');

function tryRequire(n){ try { return require(n); } catch { return null; } }
async function ensureDir(p){ await fsp.mkdir(p,{recursive:true}); }

async function withPage(playwright, viewport, fn){
  const browser = await playwright.chromium.launch();
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  try { return await fn(page); } finally { await context.close(); await browser.close(); }
}

async function extractOne(url) {
  const playwright = tryRequire('playwright');
  if (!playwright) return { ok:false, reason:'playwright-not-installed' };
  return await withPage(playwright,{width:1440,height:900}, async(page)=>{
    await page.goto(url, { waitUntil:'load' });
    const data = await page.evaluate(()=>{
      const textList=(sel,max=12)=>Array.from(document.querySelectorAll(sel)).map(e=>(e.innerText||'').trim()).filter(Boolean).slice(0,max);
      const style=window.getComputedStyle(document.body);
      const a=document.querySelector('a'); const aStyle=a?window.getComputedStyle(a):null;
      return {
        title: document.title || null,
        headings: textList('h1, h2, h3', 12),
        nav: textList('nav a, header a', 16),
        ctas: textList('a[role="button"], button, .btn, [class*="button"]', 12),
        visual: {
          bodyBackground: style.getPropertyValue('background-color')||null,
          bodyFont: style.getPropertyValue('font-family')||null,
          linkColor: aStyle? aStyle.getPropertyValue('color') : null
        }
      };
    });
    return { ok:true, data };
  });
}

async function extractPages(site, projectPath) {
  const outDir = path.join(projectPath,'evidence','extraction','pages');
  await ensureDir(outDir);
  const pages = Array.isArray(site.pages) && site.pages.length ? site.pages : [];
  const results=[];
  for (const p of pages) {
    try {
      const r = await extractOne(p.url);
      const file = path.join(outDir, encodeURIComponent(new URL(p.url).pathname||'/') + '.json');
      await fsp.writeFile(file, JSON.stringify({ url:p.url, ok:r.ok, data:r.data||null }, null, 2), 'utf8');
      results.push({ url:p.url, file, ok:r.ok });
    } catch (e) {
      results.push({ url:p.url, error:e.message||String(e), ok:false });
    }
  }
  return { outDir, results };
}

module.exports = { extractPages };

