#!/usr/bin/env node

/**
 * Enterprise Clone CLI
 * Usage:
 *   node enterprise-clone.js <target-url> [--name <projectName>] [--local <url>] [--similarity <n>] [--port <n>] [--template next] [--enforce-budgets]
 */

const os = require('os');
const { runOrchestration } = require('./lib/clone-orchestrator');

function printHelp() {
  const lines = [
    '============================================',
    ' Enterprise Clone CLI',
    '============================================',
    'Usage: node enterprise-clone.js <website-url> [options]',
    '',
    'Options:',
    '  --name <string>          Custom project name',
    '  --local <url>            Local preview URL (default: http://localhost:3000)',
    '  --port <number>          Local server port (default: 3000)',
    '  --similarity <number>    Target similarity (default: 90)',
    '  --template next          Bootstrap Next.js candidate (falls back if install fails)',
    '  --enforce-budgets        Enforce a11y/perf/multi-viewport budgets (ENT_ENFORCE_BUDGETS=1)',
    '  --help                   Show this help',
    '',
    'Example:',
    '  node enterprise-clone.js https://stripe.com --port 3004',
    '============================================'
  ];
  console.log(lines.join(os.EOL));
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes('--help')) {
    printHelp();
    process.exit(args.length === 0 ? 1 : 0);
  }

  const targetUrl = args[0];
  const opts = {};
  for (let i = 1; i < args.length; i++) {
    const a = args[i];
    if (a === '--name') opts.projectName = args[++i];
    else if (a === '--local') opts.localUrl = args[++i];
    else if (a === '--port') opts.port = args[++i];
    else if (a === '--similarity') opts.targetSimilarity = parseInt(args[++i], 10);
    else if (a === '--template') opts.template = args[++i];
    else if (a === '--enforce-budgets') process.env.ENT_ENFORCE_BUDGETS = '1';
  }

  // Prefer plain output on Windows
  if (process.platform === 'win32' && !process.env.ENT_PLAIN) {
    process.env.ENT_PLAIN = '1';
  }

  try {
    const res = await runOrchestration(targetUrl, opts);
    console.log('');
    console.log('Clone Orchestration Complete');
    console.log(`  Success: ${res.result.success}`);
    console.log(`  Final Similarity: ${res.result.finalSimilarity}%`);
    console.log(`  Project Path: ${res.projectPath}`);
    console.log(`  Log: ${res.logPath}`);
  } catch (e) {
    console.error('Clone Orchestration Failed');
    console.error(e && e.message ? e.message : String(e));
    process.exit(1);
  }
}

main();
