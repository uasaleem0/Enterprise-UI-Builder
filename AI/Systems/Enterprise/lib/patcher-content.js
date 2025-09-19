#!/usr/bin/env node

/**
 * Patcher (Content)
 * - Syncs page headings/CTAs from extracted per-page data into generated Next.js pages
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function readJson(p){ try { return JSON.parse(await fsp.readFile(p,'utf8')); } catch { return null; } }

function pathToFile(routePath) {
  const clean = routePath.replace(/^\//,'').replace(/\/$/,'');
  return clean.length ? clean + '.js' : 'index.js';
}

async function patchPage(projectPath, pageUrl, data) {
  const file = path.join(projectPath, 'pages', pathToFile(new URL(pageUrl).pathname));
  if (!fs.existsSync(file)) return { changed:false };
  let src = await fsp.readFile(file, 'utf8');
  // Replace heading literal in page component if present
  const heading = (data?.data?.title || (data?.data?.headings||[])[0] || null);
  if (heading) {
    src = src.replace(/<h1[^>]*>[^<]*<\/h1>/, `<h1 className='text-3xl mb-2'>${heading}</h1>`);
  }
  // Replace CTA labels (up to 2)
  if (Array.isArray(data?.data?.ctas) && data.data.ctas.length) {
    const ctas = data.data.ctas.slice(0,2);
    // A simple heuristic: replace first two button labels
    let count = 0;
    src = src.replace(/>([^<]{2,40})<\/a>/g, (m, label) => {
      if (count < ctas.length) { const repl = `>${ctas[count]}<\/a>`; count++; return m.replace(/>[^<]*<\/a>/, repl); }
      return m;
    });
  }
  await fsp.writeFile(file, src, 'utf8');
  return { changed:true, file };
}

async function patchContentFromExtraction(projectPath) {
  const pagesDir = path.join(projectPath,'evidence','extraction','pages');
  if (!fs.existsSync(pagesDir)) return { changed:false };
  const entries = fs.readdirSync(pagesDir).filter(f=>f.endsWith('.json'));
  let changed = false; const touched=[];
  for (const j of entries) {
    const p = path.join(pagesDir, j);
    const data = await readJson(p);
    if (data?.url) {
      const res = await patchPage(projectPath, data.url, data);
      if (res.changed) { changed=true; touched.push(res.file); }
    }
  }
  return { changed, files: touched };
}

module.exports = { patchContentFromExtraction };

