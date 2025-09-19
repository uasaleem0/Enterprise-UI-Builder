#!/usr/bin/env node

/**
 * Preflight Checks
 * - Verifies presence of key tools/libraries and prints a concise PASS/FAIL table
 */

const os = require('os');

function tryRequire(name) { try { require.resolve(name); return true; } catch { return false; } }

function checkRequire(name) { return tryRequire(name); }

function checkNode() { return process.versions && process.versions.node; }

function result(label, ok, note='') { return { label, ok, note }; }

async function runPreflight() {
  const rows = [];
  rows.push(result('Node', !!checkNode(), process.versions.node || 'unknown'));
  rows.push(result('Playwright', checkRequire('playwright')));
  rows.push(result('pixelmatch', checkRequire('pixelmatch')));
  rows.push(result('pngjs', checkRequire('pngjs')));
  rows.push(result('@axe-core/playwright', checkRequire('@axe-core/playwright')));
  rows.push(result('lighthouse', checkRequire('lighthouse')));
  rows.push(result('tailwindcss', checkRequire('tailwindcss')));

  // Attempt to wire Microsoft adapter and report
  try { require('../hooks/microsoft-sim-adapter.js'); } catch {}
  const msPresent = typeof global.msSimilarityCompare === 'function';
  rows.push(result('ms-similarity-adapter', msPresent));

  const warnings = [];
  const failures = rows.filter(r => !r.ok);
  if (failures.length) warnings.push('Some tools are missing. Visual compare may degrade and budgets may skip.');
  // Critical visual requirements (as per owner preference)
  const critical = [];
  if (!rows.find(r=>r.label==='Playwright').ok) critical.push('Playwright');
  if (!rows.find(r=>r.label==='ms-similarity-adapter').ok) critical.push('ms-similarity-adapter');

  const criticalBlock = critical.length ? `Critical missing: ${critical.join(', ')}` : '';

  const summary = {
    host: os.hostname(),
    platform: process.platform,
    node: process.versions.node,
    rows,
    warnings,
    criticalMissing: critical
  };
  return summary;
}

module.exports = { runPreflight };
