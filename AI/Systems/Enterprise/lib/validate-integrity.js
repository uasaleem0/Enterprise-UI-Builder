#!/usr/bin/env node

/**
 * Link/Asset Integrity Validation
 * - For the local site, checks that common links and local images resolve.
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function fetchText(url){ try{ const r = await fetch(url); if(!r.ok) return null; return await r.text(); } catch { return null; } }

function extractAssets(html){
  const imgs=[]; const links=[];
  const imgRe=/<img[^>]+src=["']([^"']+)["']/gi; let m;
  while((m=imgRe.exec(html))) imgs.push(m[1]);
  const aRe=/<a[^>]+href=["']([^"']+)["']/gi; let n;
  while((n=aRe.exec(html))) links.push(n[1]);
  return { imgs, links };
}

function isLocal(href){ return href && !/^https?:\/\//i.test(href) && !/^\/\//.test(href); }

async function validateLocalAssets(projectPath, localUrl){
  const html = await fetchText(localUrl);
  if (!html) return { ok:false, reason:'local-fetch-failed' };
  const { imgs, links } = extractAssets(html);
  const missing=[];
  for(const src of imgs){ if(isLocal(src)){ const p = path.join(projectPath, src.replace(/^\//,'')); if(!fs.existsSync(p)) missing.push({ type:'img', src }); } }
  // basic link presence (skip mailto/tel)
  const brokenLinks = links.filter(h => h && !/^https?:|^mailto:|^tel:/i.test(h) && h.trim()==='#');
  return { ok: missing.length===0 && brokenLinks.length===0, missing, brokenLinks };
}

async function validateIntegrity(projectPath, localUrl, outDir){
  const res = await validateLocalAssets(projectPath, localUrl);
  await fsp.mkdir(outDir,{recursive:true});
  const p = path.join(outDir,'integrity.json');
  await fsp.writeFile(p, JSON.stringify({ createdAt: new Date().toISOString(), ...res }, null, 2), 'utf8');
  return { reportPath: p };
}

module.exports = { validateIntegrity };

