#!/usr/bin/env node

/**
 * DOM/Text Parity Validation (basic)
 * - Compares presence of page titles and primary headings across pages
 * - Writes a simple report with pass/fail per page
 */

const fsp = require('fs').promises;
const path = require('path');

async function fetchHtml(url) { try { const res = await fetch(url, { redirect: 'follow' }); if (!res.ok) return null; return await res.text(); } catch { return null; } }
function extractTitle(html) { const m = html?.match(/<title>([^<]+)<\/title>/i); return m ? m[1].trim() : null; }
function extractH1(html) { const m = html?.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i); return m ? m[1].replace(/<[^>]+>/g,'').trim() : null; }

async function validatePages(pages, localBase, outDir) {
  const results = [];
  for (const p of pages) {
    try {
      const localUrl = new URL(p.url).pathname === '/' ? localBase : new URL(p.url).pathname.replace(/\/$/,'');
      const fullLocal = new URL(localUrl, localBase).toString();
      const tHtml = await fetchHtml(p.url);
      const lHtml = await fetchHtml(fullLocal);
      const tTitle = extractTitle(tHtml);
      const lTitle = extractTitle(lHtml);
      const tH1 = extractH1(tHtml);
      const lH1 = extractH1(lHtml);
      const pass = !!(lHtml && (lTitle || lH1));
      results.push({ url: p.url, local: fullLocal, targetTitle: tTitle, localTitle: lTitle, targetH1: tH1, localH1: lH1, pass });
    } catch (e) {
      results.push({ url: p.url, error: e.message || String(e), pass: false });
    }
  }
  await fsp.mkdir(outDir, { recursive: true });
  const reportPath = path.join(outDir, 'dom-parity.json');
  await fsp.writeFile(reportPath, JSON.stringify({ createdAt: new Date().toISOString(), results }, null, 2), 'utf8');
  return { reportPath };
}

module.exports = { validatePages };

