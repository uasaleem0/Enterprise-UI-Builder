#!/usr/bin/env node

/**
 * Enterprise UI Builder Command Handler
 * Handles all quick commands from boot display
 */

const fs = require('fs');
const path = require('path');

// ANSI Color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

function displayStatus() {
  console.log(colors.cyan + colors.bright + '📊 ENTERPRISE SYSTEM STATUS' + colors.reset);
  console.log();

  // System info
  const health = {
    nodejs: process.version,
    memory: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
    uptime: `${Math.round(process.uptime())}s`,
    platform: process.platform,
    cwd: process.cwd()
  };

  console.log(colors.blue + '⚡ System Health:' + colors.reset);
  Object.entries(health).forEach(([key, value]) => {
    console.log(colors.white + `  ${key}: ${colors.green}${value}${colors.reset}`);
  });
  console.log();

  // Projects status
  displayProjectsDetailed();

  // Available agents
  console.log(colors.magenta + '🤖 Available Agents:' + colors.reset);
  const agents = [
    '@enterprise-consultant - Requirements discovery & PRD creation',
    '@ui-architect - Design direction & branching decisions',
    '@website-cloner - OneRedOak 7-phase automated cloning',
    '@style-guide-builder - Live style guide creation',
    '@ui-builder - Iterative component development',
    '@implementation-manager - Enterprise deployment'
  ];

  agents.forEach(agent => {
    console.log(colors.white + '  ' + agent + colors.reset);
  });
  console.log();
}

function displayProjectsDetailed() {
  console.log(colors.yellow + '📁 Projects Status:' + colors.reset);

  const projectsDir = './projects';
  try {
    if (fs.existsSync(projectsDir)) {
      const entries = fs.readdirSync(projectsDir, { withFileTypes: true });

      if (entries.length === 0) {
        console.log(colors.white + '  No projects found - Ready to create new ones!' + colors.reset);
      } else {
        entries.forEach(entry => {
          if (entry.isDirectory()) {
            const projectPath = path.join(projectsDir, entry.name);
            const status = checkProjectStatus(projectPath);
            const lastModified = getLastModified(projectPath);

            console.log(colors.white + `  📁 ${entry.name}` + colors.reset);
            console.log(colors.white + `     Status: ${getStatusColor(status)}${status}${colors.reset}`);
            console.log(colors.white + `     Modified: ${colors.cyan}${lastModified}${colors.reset}`);
            console.log();
          }
        });
      }
    } else {
      console.log(colors.white + '  Projects directory not found - will be created on first project' + colors.reset);
    }
  } catch (error) {
    console.log(colors.white + '  Error reading projects: ' + error.message + colors.reset);
  }
  console.log();
}

function checkProjectStatus(projectPath) {
  try {
    const hasPackageJson = fs.existsSync(path.join(projectPath, 'package.json'));
    const hasNodeModules = fs.existsSync(path.join(projectPath, 'node_modules'));
    const hasSrc = fs.existsSync(path.join(projectPath, 'src'));
    const hasDist = fs.existsSync(path.join(projectPath, 'dist'));
    const hasNext = fs.existsSync(path.join(projectPath, '.next'));

    if (hasDist || hasNext) return 'DEPLOYED';
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
    default: return colors.white;
  }
}

function getLastModified(projectPath) {
  try {
    const stats = fs.statSync(projectPath);
    return stats.mtime.toLocaleDateString();
  } catch {
    return 'Unknown';
  }
}

function startNewProject() {
  console.log(colors.green + colors.bright + '🚀 STARTING NEW ENTERPRISE PROJECT' + colors.reset);
  console.log();
  console.log(colors.white + 'Choose your development path:' + colors.reset);
  console.log();
  console.log(colors.yellow + '1. 🌳 Website Cloning' + colors.white + ' - Clone existing site (95%+ accuracy)' + colors.reset);
  console.log(colors.yellow + '2. 🎨 Original Design' + colors.white + ' - Create from scratch (evidence-based)' + colors.reset);
  console.log(colors.yellow + '3. 📱 Mobile App' + colors.white + ' - React Native enterprise app' + colors.reset);
  console.log(colors.yellow + '4. 🔧 API Service' + colors.white + ' - Backend service development' + colors.reset);
  console.log();
  console.log(colors.cyan + 'Next: Describe your project idea and choose a path!' + colors.reset);
  console.log();
}

function showHelp() {
  console.log(colors.cyan + colors.bright + '📚 ENTERPRISE COMMAND REFERENCE' + colors.reset);
  console.log();

  const commands = [
    ['/status', 'View detailed system and project status'],
    ['/new-project', 'Start a new enterprise project'],
    ['/clone-website', 'OneRedOak 7-phase website cloning'],
    ['/agents', 'List all available enterprise agents'],
    ['/help', 'Show this command reference'],
    ['node auto-loader.js', 'Restart Enterprise system'],
    ['node enterprise-boot.js', 'Full boot sequence with display']
  ];

  commands.forEach(([cmd, desc]) => {
    console.log(colors.green + cmd.padEnd(20) + colors.white + ' - ' + desc + colors.reset);
  });
  console.log();

  console.log(colors.yellow + 'Enterprise Agents:' + colors.reset);
  console.log(colors.white + '@enterprise-consultant' + colors.cyan + ' - Requirements & strategy' + colors.reset);
  console.log(colors.white + '@ui-architect' + colors.cyan + '        - Design & architecture' + colors.reset);
  console.log(colors.white + '@website-cloner' + colors.cyan + '      - Automated site cloning' + colors.reset);
  console.log();
}

function listAgents() {
  console.log(colors.magenta + colors.bright + '🤖 ENTERPRISE AGENTS' + colors.reset);
  console.log();

  const agents = [
    {
      name: '@enterprise-consultant',
      description: 'Requirements discovery & PRD creation',
      capabilities: ['Business analysis', 'Requirements gathering', 'PRD creation', 'Stakeholder management']
    },
    {
      name: '@ui-architect',
      description: 'Design direction & branching decisions',
      capabilities: ['UI/UX design', 'Component architecture', 'Design systems', 'User research']
    },
    {
      name: '@website-cloner',
      description: 'OneRedOak 7-phase automated cloning',
      capabilities: ['Automated cloning', 'Visual similarity', 'Responsive design', 'Cross-browser testing']
    },
    {
      name: '@style-guide-builder',
      description: 'Live style guide creation',
      capabilities: ['Style guides', 'Component libraries', 'Design tokens', 'Documentation']
    },
    {
      name: '@ui-builder',
      description: 'Iterative component development',
      capabilities: ['Component development', 'Interactive prototypes', 'A/B testing', 'Performance optimization']
    },
    {
      name: '@implementation-manager',
      description: 'Enterprise deployment',
      capabilities: ['CI/CD setup', 'Cloud deployment', 'Monitoring', 'Security compliance']
    }
  ];

  agents.forEach(agent => {
    console.log(colors.cyan + agent.name + colors.reset);
    console.log(colors.white + '  ' + agent.description + colors.reset);
    console.log(colors.yellow + '  Capabilities: ' + agent.capabilities.join(', ') + colors.reset);
    console.log();
  });
}

// Command router
function handleCommand(command) {
  switch (command) {
    case '/status':
      displayStatus();
      break;
    case '/new-project':
      startNewProject();
      break;
    case '/clone-website':
      console.log(colors.green + '🌳 OneRedOak Website Cloning System' + colors.reset);
      console.log(colors.white + 'Provide the URL you want to clone and we\'ll create a 95%+ accurate replica!' + colors.reset);
      break;
    case '/agents':
      listAgents();
      break;
    case '/help':
      showHelp();
      break;
    default:
      console.log(colors.yellow + 'Unknown command. Type /help for available commands.' + colors.reset);
  }
}

// Export for programmatic use
module.exports = {
  handleCommand,
  displayStatus,
  startNewProject,
  showHelp,
  listAgents
};

// Run if called directly with command
if (require.main === module) {
  const command = process.argv[2];
  if (command) {
    // Ensure command starts with /
    const formattedCommand = command.startsWith('/') ? command : '/' + command;
    handleCommand(formattedCommand);
  } else {
    showHelp();
  }
}