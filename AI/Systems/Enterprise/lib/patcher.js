#!/usr/bin/env node

/**
 * Minimal patcher
 * - If multi-viewport min score is low and extracted linkColor exists,
 *   align tokens accent to extracted linkColor and update tokens.css
 */

const fsp = require('fs').promises;
const path = require('path');

async function readJson(p){ try { return JSON.parse(await fsp.readFile(p,'utf8')); } catch { return null; } }

async function patchTokens(projectPath) {
  const mvPath = path.join(projectPath,'evidence','validation','multi-viewport-summary.json');
  const exPath = path.join(projectPath,'evidence','extraction','extraction.json');
  const tkJson = path.join(projectPath,'tokens','tokens.json');
  const tkCss = path.join(projectPath,'tokens','tokens.css');
  const mv = await readJson(mvPath);
  const ex = await readJson(exPath);
  let tokens = await readJson(tkJson);
  if (!tokens) return { changed:false, reason:'no-tokens' };
  const minScore = Array.isArray(mv?.results) ? Math.min(...mv.results.map(r => (typeof r.score==='number'? r.score: 101))) : 100;
  const linkColor = ex?.structure?.visual?.linkColor || null;
  if (typeof minScore==='number' && minScore < 80 && linkColor && tokens.accent !== linkColor) {
    tokens.accent = linkColor;
    await fsp.writeFile(tkJson, JSON.stringify(tokens,null,2), 'utf8');
    try {
      let css = await fsp.readFile(tkCss,'utf8');
      css = css.replace(/--accent:\s*[^;]+;/, `--accent: ${linkColor};`);
      await fsp.writeFile(tkCss, css, 'utf8');
    } catch {}
    return { changed:true };
  }
  return { changed:false };
}

module.exports = { patchTokens };

