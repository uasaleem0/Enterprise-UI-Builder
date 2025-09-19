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
  return { accent, pageBg, font };
}

function cssVariables(tokens){
  return `:root{\n  --accent: ${tokens.accent};\n  --page-bg: ${tokens.pageBg};\n  --font: ${tokens.font};\n}\nbody{ background: var(--page-bg); font-family: var(--font); }\n`;
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

