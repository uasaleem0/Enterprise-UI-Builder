#!/usr/bin/env node

/**
 * Enhanced Enterprise UI Builder Boot Display
 * Professional startup experience with system status
 */

const fs = require('fs');
const path = require('path');

// ANSI Color codes for enhanced display
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  bgBlue: '\x1b[44m',
  bgGreen: '\x1b[42m'
};

function generateSessionId() {
  return 'ENT-' + Date.now() + Math.floor(Math.random() * 1000);
}

function getTimestamp() {
  return new Date().toLocaleString('en-US', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });
}

function checkSystemHealth() {
  const health = {
    nodejs: process.version,
    memory: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
    uptime: `${Math.round(process.uptime())}s`,
    platform: process.platform
  };
  return health;
}

function scanProjects() {
  const projectsDir = './projects';
  const projects = [];

  try {
    if (fs.existsSync(projectsDir)) {
      const entries = fs.readdirSync(projectsDir, { withFileTypes: true });
      entries.forEach(entry => {
        if (entry.isDirectory()) {
          const projectPath = path.join(projectsDir, entry.name);
          const status = checkProjectStatus(projectPath);
          projects.push({
            name: entry.name,
            status: status,
            path: projectPath
          });
        }
      });
    }
  } catch (error) {
    // Silent fail for projects scanning
  }

  return projects;
}

function checkProjectStatus(projectPath) {
  try {
    // Check for various indicators of project status
    const hasPackageJson = fs.existsSync(path.join(projectPath, 'package.json'));
    const hasNodeModules = fs.existsSync(path.join(projectPath, 'node_modules'));
    const hasSrc = fs.existsSync(path.join(projectPath, 'src'));
    const hasDist = fs.existsSync(path.join(projectPath, 'dist'));

    if (hasDist) return 'DEPLOYED';
    if (hasNodeModules && hasSrc) return 'DEVELOPMENT';
    if (hasPackageJson) return 'INITIALIZED';
    return 'PLANNING';
  } catch {
    return 'UNKNOWN';
  }
}

function getStatusColor(status) {
  switch (status) {
    case 'DEPLOYED': return colors.green;
    case 'DEVELOPMENT': return colors.yellow;
    case 'INITIALIZED': return colors.blue;
    case 'PLANNING': return colors.magenta;
    default: return colors.dim;
  }
}

function displayBanner() {
  console.log(colors.cyan + colors.bright);
  console.log('  ███████╗███╗   ██╗████████╗███████╗██████╗ ██████╗ ██████╗ ██╗███████╗');
  console.log('  ██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔════╝');
  console.log('  █████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝██████╔╝██████╔╝██║███████╗');
  console.log('  ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔═══╝ ██╔══██╗██║╚════██║');
  console.log('  ███████╗██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║██║███████║');
  console.log('  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝');
  console.log();
  console.log(colors.white + colors.bright + '            🏢 ENTERPRISE UI BUILDER - ZERO TO APPLICATION 🏢');
  console.log();
  console.log(colors.white + '       Professional-grade software development with UI-first');
  console.log(colors.white + '         methodology and enterprise intelligence systems');
  console.log(colors.reset);
}

function displaySystemInfo() {
  const sessionId = generateSessionId();
  const timestamp = getTimestamp();
  const health = checkSystemHealth();

  console.log(colors.green + colors.bright + '🔍 META-ANALYST ACTIVATION' + colors.reset);
  console.log(colors.white + '├─ Session ID: ' + colors.yellow + sessionId + colors.reset);
  console.log(colors.white + '├─ Timestamp: ' + colors.cyan + timestamp + colors.reset);
  console.log(colors.white + '├─ Status: ' + colors.green + 'ACTIVE & MONITORING ALL SYSTEMS' + colors.reset);
  console.log(colors.white + '└─ Intelligence: ' + colors.magenta + 'ENTERPRISE-GRADE ANALYSIS ENABLED' + colors.reset);
  console.log();

  console.log(colors.blue + colors.bright + '⚡ SYSTEM HEALTH' + colors.reset);
  console.log(colors.white + '├─ Node.js: ' + colors.green + health.nodejs + colors.reset);
  console.log(colors.white + '├─ Memory: ' + colors.yellow + health.memory + colors.reset);
  console.log(colors.white + '├─ Platform: ' + colors.cyan + health.platform + colors.reset);
  console.log(colors.white + '└─ Uptime: ' + colors.green + health.uptime + colors.reset);
  console.log();
}

function displayProjects() {
  const projects = scanProjects();

  console.log(colors.magenta + colors.bright + '📁 PROJECT STATUS' + colors.reset);

  if (projects.length === 0) {
    console.log(colors.dim + '├─ No active projects found' + colors.reset);
    console.log(colors.dim + '└─ Ready to start new enterprise development' + colors.reset);
  } else {
    projects.forEach((project, index) => {
      const isLast = index === projects.length - 1;
      const prefix = isLast ? '└─' : '├─';
      const statusColor = getStatusColor(project.status);

      console.log(colors.white + prefix + ' ' + colors.bright + project.name + colors.reset +
                  colors.dim + ' [' + statusColor + project.status + colors.dim + ']' + colors.reset);
    });
  }
  console.log();
}

function displayQuickCommands() {
  console.log(colors.yellow + colors.bright + '🚀 QUICK COMMANDS' + colors.reset);
  console.log(colors.white + '├─ ' + colors.green + '/status' + colors.white + ' - View detailed system status' + colors.reset);
  console.log(colors.white + '├─ ' + colors.green + '/new-project' + colors.white + ' - Start new enterprise project' + colors.reset);
  console.log(colors.white + '├─ ' + colors.green + '/clone-website' + colors.white + ' - OneRedOak 7-phase website cloning' + colors.reset);
  console.log(colors.white + '├─ ' + colors.green + '/agents' + colors.white + ' - List available enterprise agents' + colors.reset);
  console.log(colors.white + '└─ ' + colors.green + '/help' + colors.white + ' - Show full command reference' + colors.reset);
  console.log();
}

function displayFooter() {
  console.log(colors.cyan + colors.dim + '────────────────────────────────────────────────────────────────────────' + colors.reset);
  console.log(colors.white + '  Enterprise System: ' + colors.bright + 'Where enterprise-grade robustness meets consumer-grade ease' + colors.reset);
  console.log(colors.cyan + colors.dim + '────────────────────────────────────────────────────────────────────────' + colors.reset);
  console.log();
  console.log(colors.green + '✅ System Ready - Awaiting Instructions' + colors.reset);
  console.log();
}

// Main boot sequence
function boot() {
  console.clear();
  displayBanner();
  console.log();
  displaySystemInfo();
  displayProjects();
  displayQuickCommands();
  displayFooter();

  // Load the meta-analyst after display
  try {
    require('./auto-loader.js');
  } catch (error) {
    console.log(colors.red + '⚠️ Warning: Could not load meta-analyst core - ' + error.message + colors.reset);
  }
}

// Export for programmatic use
module.exports = { boot, displayBanner, displaySystemInfo, displayProjects };

// Run if called directly
if (require.main === module) {
  boot();
}