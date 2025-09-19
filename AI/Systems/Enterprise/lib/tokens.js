#!/usr/bin/env node

/**
 * Token generator
 * - Aggregates extracted visuals to produce simple theme tokens
 * - Writes tokens.json and tokens.css (CSS variables)
 */

const fsp = require('fs').promises;
const path = require('path');

function pick(first, fallback){ return first && typeof first==='string' ? first.trim() : fallback; }

async function loadExtraction(projectPath){
  try {
    const p = path.join(projectPath,'evidence','extraction','extraction.json');
    return JSON.parse(await fsp.readFile(p,'utf8'));
  } catch { return null; }
}

function aggregate(struct){
  const accent = pick(struct?.visual?.linkColor, '#1e40af');
  const pageBg = pick(struct?.visual?.bodyBackground, '#ffffff');
  const font = pick(struct?.visual?.bodyFont, 'system-ui, Segoe UI, Roboto, Arial, sans-serif');
  const bodySize = pick(struct?.visual?.bodyFontSize, '16px');
  const h1 = struct?.typography?.h1 || null;
  const h2 = struct?.typography?.h2 || null;
  const h3 = struct?.typography?.h3 || null;
  return { accent, pageBg, font, bodySize, h1, h2, h3 };
}

function cssVariables(tokens){
  const lines = [];
  lines.push(':root{');
  lines.push(`  --accent: ${tokens.accent};`);
  lines.push(`  --page-bg: ${tokens.pageBg};`);
  lines.push(`  --font: ${tokens.font};`);
  if (tokens.bodySize) lines.push(`  --fs-body: ${tokens.bodySize};`);
  if (tokens.h1?.fontSize) lines.push(`  --fs-h1: ${tokens.h1.fontSize};`);
  if (tokens.h2?.fontSize) lines.push(`  --fs-h2: ${tokens.h2.fontSize};`);
  if (tokens.h3?.fontSize) lines.push(`  --fs-h3: ${tokens.h3.fontSize};`);
  lines.push('}');
  lines.push('body{ background: var(--page-bg); font-family: var(--font); font-size: var(--fs-body,16px); }');
  lines.push('h1{ font-size: var(--fs-h1,2rem); }');
  lines.push('h2{ font-size: var(--fs-h2,1.5rem); }');
  lines.push('h3{ font-size: var(--fs-h3,1.25rem); }');
  lines.push('');
  return lines.join('\n');
}

async function generateTokens(projectPath) {
  const extraction = await loadExtraction(projectPath);
  const struct = extraction?.structure || null;
  const tokens = aggregate(struct||{});
  const dir = path.join(projectPath,'tokens');
  await fsp.mkdir(dir,{recursive:true});
  const jsonPath = path.join(dir,'tokens.json');
  const cssPath = path.join(dir,'tokens.css');
  await fsp.writeFile(jsonPath, JSON.stringify(tokens, null, 2), 'utf8');
  await fsp.writeFile(cssPath, cssVariables(tokens), 'utf8');
  return { tokens, jsonPath, cssPath };
}

module.exports = { generateTokens };
