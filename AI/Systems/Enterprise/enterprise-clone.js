#!/usr/bin/env node

/**
 * Enterprise Clone CLI
 * Usage:
 *   node enterprise-clone.js <target-url> [--name <projectName>] [--local <url>] [--similarity <n>] [--port <n>] [--template next] [--enforce-budgets]
 *   node enterprise-clone.js resume [--project <name>] [--template next] [--visual-engine auto|microsoft|pixelmatch] [--auto]
 */

const os = require('os');
const { runOrchestration } = require('./lib/clone-orchestrator');

function printHelp() {
  const lines = [
    '============================================',
    ' Enterprise Clone CLI',
    '============================================',
    'Usage: node enterprise-clone.js <website-url> [options] (supports multi-page crawl)',
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
    '  node enterprise-clone.js resume --project my-clone --template next',
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

  const fs = require('fs');
  const path = require('path');

  // Resume subcommand
  if (args[0] === 'resume') {
    const opts = {};
    for (let i = 1; i < args.length; i++) {
      const a = args[i];
      if (a === '--project') opts.projectName = args[++i];
      else if (a === '--template') opts.template = args[++i];
      else if (a === '--visual-engine') opts.visualEngine = args[++i];
      else if (a === '--auto') opts.auto = true;
      else if (a === '--enforce-budgets') process.env.ENT_ENFORCE_BUDGETS = '1';
    }
    if (process.platform === 'win32' && !process.env.ENT_PLAIN) process.env.ENT_PLAIN = '1';
    // Find project path
    const projectsRoot = path.join(process.cwd(), 'projects');
    let projectPath = null;
    if (opts.projectName) {
      projectPath = path.join(projectsRoot, opts.projectName);
    } else {
      // Pick most recently modified project with orchestrator-log.json
      try {
        const entries = fs.readdirSync(projectsRoot, { withFileTypes: true });
        let latest = { m: 0, p: null };
        for (const e of entries) {
          if (!e.isDirectory()) continue;
          const p = path.join(projectsRoot, e.name, 'orchestrator-log.json');
          if (fs.existsSync(p)) {
            const m = fs.statSync(p).mtimeMs;
            if (m > latest.m) latest = { m, p: path.join(projectsRoot, e.name) };
          }
        }
        projectPath = latest.p;
      } catch {}
    }
    if (!projectPath || !fs.existsSync(path.join(projectPath, 'orchestrator-log.json'))) {
      console.error('Resume failed: could not locate a project with orchestrator-log.json');
      process.exit(1);
    }
    const log = JSON.parse(fs.readFileSync(path.join(projectPath, 'orchestrator-log.json'), 'utf8'));
    const targetUrl = log.targetUrl;
    if (!targetUrl) {
      console.error('Resume failed: targetUrl missing from orchestrator-log.json');
      process.exit(1);
    }
    // Carry forward project name and options
    const { runOrchestration } = require('./lib/clone-orchestrator');
    try {
      if (opts.visualEngine) process.env.ENT_VISUAL_ENGINE = opts.visualEngine;
      if (!process.env.ENT_ENFORCE_BUDGETS) process.env.ENT_ENFORCE_BUDGETS = '1';
      const res = await runOrchestration(targetUrl, { ...opts, projectName: path.basename(projectPath) });
      console.log('');
      console.log('Resume Complete');
      console.log(`  Success: ${res.result.success}`);
      console.log(`  Final Similarity: ${res.result.finalSimilarity}%`);
      console.log(`  Project Path: ${res.projectPath}`);
      console.log(`  Log: ${res.logPath}`);
    } catch (e) {
      console.error('Resume Failed');
      console.error(e && e.message ? e.message : String(e));
      process.exit(1);
    }
    return;
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
    else if (a === '--crawl-limit') opts.crawlLimit = args[++i];
    else if (a === '--describe') opts.describe = args[++i];
    else if (a === '--auth') opts.auth = true;
    else if (a === '--no-auth') opts.auth = false;
    else if (a === '--deploy') opts.deploy = true;
    else if (a === '--rollback') opts.rollback = true;
    else if (a === '--visual-engine') opts.visualEngine = args[++i];
    else if (a === '--pause-after-threshold') opts.pauseAfterThreshold = true;
    else if (a === '--auto') opts.auto = true;
    else if (a === '--verbose') opts.verbose = true;
    else if (a === '--quiet') opts.quiet = true;
  }

  // Defaults per your preferences
  if (!process.env.ENT_ENFORCE_BUDGETS) process.env.ENT_ENFORCE_BUDGETS = '1';
  if (!opts.crawlLimit) opts.crawlLimit = 8;
  if (opts.auth === undefined && !!opts.describe) opts.auth = true;

  // Prefer plain output on Windows
  if (process.platform === 'win32' && !process.env.ENT_PLAIN) {
    process.env.ENT_PLAIN = '1';
  }
  if (opts.visualEngine) process.env.ENT_VISUAL_ENGINE = opts.visualEngine;
  if (opts.verbose) process.env.ENT_VERBOSE = '1';
  if (opts.quiet) process.env.ENT_QUIET = '1';

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
