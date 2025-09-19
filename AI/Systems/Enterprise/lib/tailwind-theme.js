#!/usr/bin/env node

/**
 * Tailwind Theme Extension
 * - Reads tokens/tokens.json and generates a Tailwind theme.extend config
 */

const fsp = require('fs').promises;
const path = require('path');

function pxToRem(px) {
  if (!px || typeof px !== 'string') return null;
  const m = px.match(/([0-9.]+)px/);
  if (!m) return null;
  const n = parseFloat(m[1]);
  return (n/16).toFixed(4) + 'rem';
}

async function loadTokens(projectPath) {
  try {
    const p = path.join(projectPath, 'tokens', 'tokens.json');
    return JSON.parse(await fsp.readFile(p, 'utf8'));
  } catch { return null; }
}

function genTheme(tokens) {
  const fontSans = (tokens.font || 'system-ui, Segoe UI, Roboto, Arial, sans-serif');
  const accent = tokens.accent || '#1e40af';
  const fsH1 = pxToRem(tokens.h1?.fontSize) || '2rem';
  const fsH2 = pxToRem(tokens.h2?.fontSize) || '1.5rem';
  const fsH3 = pxToRem(tokens.h3?.fontSize) || '1.25rem';
  const spacingHero = pxToRem(tokens.heroPad || '48px') || '3rem';
  return `module.exports = {
  content: ['./pages/**/*.{js,jsx,ts,tsx}','./components/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: { accent: '${accent}' },
      fontFamily: { sans: [${fontSans.split(',').map(s=>`'${s.trim()}'`).join(', ')}] },
      fontSize: { h1: '${fsH1}', h2: '${fsH2}', h3: '${fsH3}' },
      spacing: { hero: '${spacingHero}' }
    }
  },
  plugins: []
};\n`;
}

async function writeTailwindConfig(projectPath) {
  const tokens = await loadTokens(projectPath);
  const cfg = genTheme(tokens || {});
  const out = path.join(projectPath, 'tailwind.config.js');
  await fsp.writeFile(out, cfg, 'utf8');
  return out;
}

module.exports = { writeTailwindConfig };

