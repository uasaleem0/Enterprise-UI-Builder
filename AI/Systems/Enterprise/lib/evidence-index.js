#!/usr/bin/env node

/**
 * Evidence Index
 * - Generates a simple HTML index of key evidence files (screens, reports)
 */

const fsp = require('fs').promises;
const path = require('path');

async function writeEvidenceIndex(projectPath) {
  const evDir = path.join(projectPath,'evidence');
  const valDir = path.join(evDir,'validation');
  const extDir = path.join(evDir,'extraction');
  const items = [
    { label: 'Extraction', file: path.join(extDir,'extraction.json') },
    { label: 'Site Map', file: path.join(extDir,'site-map.json') },
    { label: 'Multi-Viewport Summary', file: path.join(valDir,'multi-viewport-summary.json') },
    { label: 'DOM Parity', file: path.join(valDir,'dom-parity.json') },
    { label: 'Integrity', file: path.join(valDir,'integrity.json') }
  ];
  let html = ['<!doctype html>','<meta charset="utf-8"><title>Evidence Index</title>','<h1>Evidence Index</h1>'];
  for (const it of items) {
    const rel = path.relative(evDir, it.file).replace(/\\/g,'/');
    html.push(`<div><strong>${it.label}:</strong> <code>${rel}</code></div>`);
  }
  await fsp.mkdir(evDir,{recursive:true});
  const out = path.join(evDir,'index.html');
  await fsp.writeFile(out, html.join('\n'),'utf8');
  return out;
}

module.exports = { writeEvidenceIndex };

