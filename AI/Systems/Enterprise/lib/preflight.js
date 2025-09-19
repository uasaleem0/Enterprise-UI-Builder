#!/usr/bin/env node

/**
 * Preflight Checks
 * - Verifies presence of key tools/libraries and prints a concise PASS/FAIL table
 */

const os = require('os');

function checkRequire(name) { try { require.resolve(name); return true; } catch { return false; } }

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

  const warnings = [];
  const failures = rows.filter(r => !r.ok);
  if (failures.length) {
    warnings.push('Some tools are missing. Visual compare may degrade and budgets may skip.');
  }

  const summary = {
    host: os.hostname(),
    platform: process.platform,
    node: process.versions.node,
    rows,
    warnings
  };
  return summary;
}

module.exports = { runPreflight };

