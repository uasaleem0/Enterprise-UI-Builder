#!/usr/bin/env node

/**
 * Same-origin crawler (multi-page)
 * - Discovers up to N pages within the target origin
 * - Saves a simple site map with titles and paths
 */

const fsp = require('fs').promises;
const path = require('path');

function normalizeUrl(u) { try { return new URL(u).toString().replace(/#.*$/,''); } catch { return null; } }
function sameOrigin(a, b) { try { const A = new URL(a), B = new URL(b); return A.origin === B.origin; } catch { return false; } }

async function fetchHtml(url) {
  try { const res = await fetch(url, { redirect: 'follow' }); if (!res.ok) return null; return await res.text(); } catch { return null; }
}

function extractLinks(baseUrl, html) {
  const urls = new Set();
  const re = /href\s*=\s*"([^"]+)"|href\s*=\s*'([^']+)'/gi;
  let m; while ((m = re.exec(html))) { const href = m[1] || m[2]; const abs = normalizeUrl(new URL(href, baseUrl).toString()); if (abs && sameOrigin(baseUrl, abs)) urls.add(abs); }
  return Array.from(urls);
}

function extractTitle(html) {
  const m = html.match(/<title>([^<]+)<\/title>/i); return m ? m[1].trim() : null;
}

async function crawl(targetUrl, limit = 5) {
  const start = normalizeUrl(targetUrl);
  if (!start) return { pages: [] };
  const q = [start];
  const seen = new Set([start]);
  const pages = [];
  while (q.length && pages.length < limit) {
    const url = q.shift();
    const html = await fetchHtml(url);
    if (!html) continue;
    const title = extractTitle(html);
    pages.push({ url, title });
    const links = extractLinks(url, html);
    for (const l of links) { if (!seen.has(l) && pages.length + q.length < limit) { seen.add(l); q.push(l); } }
  }
  return { pages };
}

async function saveSiteMap(projectPath, site) {
  const dir = path.join(projectPath, 'evidence', 'extraction');
  await fsp.mkdir(dir, { recursive: true });
  const p = path.join(dir, 'site-map.json');
  await fsp.writeFile(p, JSON.stringify(site, null, 2), 'utf8');
  return p;
}

module.exports = { crawl, saveSiteMap };

