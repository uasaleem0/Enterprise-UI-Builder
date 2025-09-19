#!/usr/bin/env node

/**
 * Patcher (Hero)
 * - If tokens include hero padding or h1 font size, ensure Hero and pages reflect it
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function readJson(p){ try { return JSON.parse(await fsp.readFile(p,'utf8')); } catch { return null; } }

async function patchHeroComponent(projectPath) {
  const file = path.join(projectPath,'components','Hero.js');
  if (!fs.existsSync(file)) return { changed:false };
  let src = await fsp.readFile(file,'utf8');
  // Ensure hero uses CSS vars for padding and h1 uses token size
  let changed = false;
  if (!/var\(--pad-hero/.test(src)) {
    src = src.replace(/<section([^>]*)>/, `<section$1 style={{paddingTop:'var(--pad-hero,3rem)', paddingBottom:'var(--pad-hero,3rem)'}}>`);
    changed = true;
  }
  if (!/text-3xl/.test(src) && !/var\(--fs-h1/.test(src)) {
    src = src.replace(/<h1([^>]*)>/, `<h1$1 style={{fontSize:'var(--fs-h1,2rem)'}}>`);
    changed = true;
  }
  if (changed) await fsp.writeFile(file, src, 'utf8');
  return { changed, file };
}

module.exports = { patchHeroComponent };

