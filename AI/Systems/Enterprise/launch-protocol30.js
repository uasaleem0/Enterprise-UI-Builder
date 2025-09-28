
/**
 * Protocol 3.0 Launcher (ASCII-first)
 * Starts the Enhanced Enterprise UI Builder System.
 */

const os = require('os');
// Install progress-only filter if requested
try { require('./lib/progress-filter').installProgressFilter(); } catch {}
const { executeProtocol30 } = require('./protocols/protocol-3.0/integrated-protocol-3.0.js');
const path = require('path');
const { probeServer, startProjectServer } = require('./lib/server-manager');
const { appendEvent } = require('./lib/logger');

// Default configuration
const DEFAULT_CONFIG = {
  targetSimilarity: 90,
  projectName: null, // Will auto-generate from URL
  maxIterations: 3,
  localUrl: process.env.ENT_LOCAL_URL || 'http://localhost:3000'
};

// Prefer plain output on Windows unless overridden
if (process.platform === 'win32' && !process.env.ENT_PLAIN) process.env.ENT_PLAIN = '1';
// Force verbose by default (allow user override if explicitly set)
if (typeof process.env.ENT_QUIET === 'undefined') process.env.ENT_QUIET = '0';
if (typeof process.env.DEBUG === 'undefined') process.env.DEBUG = '1';

function printUsage() {
  const lines = [
    '============================================',
    ' Protocol 30 Launcher',
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

async function main() {
  try {
    preflight();

    console.log('\nStarting Protocol 30...');

    // Determine project path - prioritize existing projects
    const localUrl = config.localUrl || 'http://localhost:3000';
    let projectName = config.projectName;
    let inferredProjectPath = null;
    
    // First priority: use specified project name if it exists
    if (projectName) {
      const projectsDir = path.join(process.cwd(), 'projects');
      const specifiedPath = path.join(projectsDir, projectName);
      if (fsExists(specifiedPath)) {
        inferredProjectPath = specifiedPath;
        console.log(`[project] Using existing project: ${projectName}`);
      }
    }
    
    // Second priority: check for TWP-website (common project)
    if (!inferredProjectPath) {
      const projectsDir = path.join(process.cwd(), 'projects');
      const twpPath = path.join(projectsDir, 'TWP-website');
      if (fsExists(twpPath)) {
        inferredProjectPath = twpPath;
        projectName = 'TWP-website';
        console.log(`[project] Using existing TWP-website project`);
      }
    }

    // Ensure local server is running (auto-start if needed)
    const ok = await probeServer(localUrl, { timeoutMs: 3000, log: s => console.log(s) });
    let server = null;
    if (!ok) {
      console.log(`[server] Not reachable at ${localUrl}. Attempting auto-start...`);
      const projectPath = inferredProjectPath || path.join(process.cwd(), 'projects', 'TWP-website');
      await safeAppend(projectPath, { level: 'info', stage: 'serve', msg: 'auto-start-begin', url: localUrl });
      server = await startProjectServer(projectPath, parseInt((new URL(localUrl)).port || '3000', 10), { projectName });
      const up = await probeServer(localUrl, { timeoutMs: 20000, log: s => console.log(s) });
      if (!up) {
        const msg = `[fatal] Local preview not reachable after auto-start: ${localUrl}`;
        console.error(msg);
        if (server && server.stop) try { await server.stop(); } catch {}
        await safeAppend(projectPath, { level: 'error', stage: 'serve', msg: 'auto-start-failed', url: localUrl });
        process.exit(1);
      }
      await safeAppend(projectPath, { level: 'info', stage: 'serve', msg: 'auto-start-success', url: localUrl });
    }

    // Pass project configuration to protocol
    const protocolConfig = {
      ...config,
      projectName: projectName,
      projectPath: inferredProjectPath
    };
    
    const result = await executeProtocol30(targetUrl, protocolConfig);

    console.log('\nProtocol 30 Complete');
    console.log(`  Success: ${result.success}`);
    console.log(`  Final Similarity: ${result.finalSimilarity}%`);
    console.log(`  Performance Grade: ${result.performanceGrade}`);
    console.log(`  Project Path: ${result.projectPath}`);

  } catch (error) {
    console.error('\nProtocol 30 Failed:');
    console.error(error && error.message ? error.message : String(error));
    // Clear failure summary
    console.error('----------------------------------------');
    console.error('Failure Summary:');
    console.error(`  Reason: ${error.message || String(error)}`);
    console.error('  Hints: ensure local preview is reachable or allow auto-start');
    console.error('----------------------------------------');
    process.exit(1);
  }
}

function fsExists(p) { try { return require('fs').existsSync(p); } catch { return false; } }
async function safeAppend(projectPath, event) { try { await appendEvent(projectPath, event); } catch {} }

main();
