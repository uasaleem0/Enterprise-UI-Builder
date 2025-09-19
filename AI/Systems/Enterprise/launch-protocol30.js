#!/usr/bin/env node

/**
 * Protocol 3.0 Launcher (ASCII-first)
 * Starts the Enhanced Enterprise UI Builder System.
 */

const os = require('os');
const { executeProtocol30 } = require('./protocols/protocol-3.0/integrated-protocol-3.0.js');

// Default configuration
const DEFAULT_CONFIG = {
  targetSimilarity: 90,
  projectName: null, // Will auto-generate from URL
  maxIterations: 3,
  localUrl: process.env.ENT_LOCAL_URL || 'http://localhost:3000'
};

// Prefer plain output on Windows unless overridden
if (process.platform === 'win32' && !process.env.ENT_PLAIN) {
  process.env.ENT_PLAIN = '1';
}

function printUsage() {
  const lines = [
    '============================================',
    ' Protocol 3.0 Launcher',
    '============================================',
    'Usage: node launch-protocol30.js <website-url> [options]',
    '',
    'Options:',
    '  --similarity <number>    Target similarity (default: 90)',
    '  --name <string>          Custom project name',
    '  --local <url>            Local preview URL (default: http://localhost:3000)',
    '  --help                   Show this help',
    '',
    'Examples:',
    '  node launch-protocol30.js https://forward.digital',
    '  node launch-protocol30.js https://stripe.com --similarity 92',
    '  node launch-protocol30.js https://apple.com --local http://localhost:3004',
    '============================================'
  ];
  console.log(lines.join(os.EOL));
}

function preflight() {
  const missing = [];
  function tryResolve(name) { try { require.resolve(name); return true; } catch { return false; } }
  if (!tryResolve('playwright')) missing.push('playwright');
  const hasPixel = tryResolve('pixelmatch') && tryResolve('pngjs');

  console.log('Preflight:');
  console.log(`  Node: ${process.version}`);
  console.log(`  Platform: ${process.platform}`);
  console.log(`  Playwright: ${missing.includes('playwright') ? 'MISSING' : 'AVAILABLE'}`);
  console.log(`  Pixelmatch/pngjs: ${hasPixel ? 'AVAILABLE' : 'OPTIONAL (missing)'}`);
  if (missing.length > 0) {
    console.log('\nNote: Install missing dependencies in Enterprise folder:');
    console.log('  npm i');
  }
}

// Parse arguments
const args = process.argv.slice(2);
if (args.includes('--help') || args.length === 0) {
  printUsage();
  process.exit(args.length === 0 ? 1 : 0);
}

const targetUrl = args[0];
const config = { ...DEFAULT_CONFIG };
for (let i = 1; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--similarity') { config.targetSimilarity = parseInt(args[++i], 10); }
  else if (arg === '--name') { config.projectName = args[++i]; }
  else if (arg === '--local') { config.localUrl = args[++i]; }
}

preflight();
console.log('\nStarting Protocol 3.0...');

executeProtocol30(targetUrl, config)
  .then(result => {
    console.log('\nProtocol 3.0 Complete');
    console.log(`  Success: ${result.success}`);
    console.log(`  Final Similarity: ${result.finalSimilarity}%`);
    console.log(`  Performance Grade: ${result.performanceGrade}`);
    console.log(`  Project Path: ${result.projectPath}`);
  })
  .catch(error => {
    console.error('\nProtocol 3.0 Failed:');
    console.error(error && error.message ? error.message : String(error));
    process.exit(1);
  });