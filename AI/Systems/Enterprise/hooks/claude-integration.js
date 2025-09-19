/**
 * Claude Code Integration Hooks
 * Minimal overhead monitoring for all Enterprise activities
 */

const MetaAnalyst = require('../meta-analyst-core');

if (process.env.ENT_HOOKS === '1') {
  // Hook into Claude Code tool execution
  const originalConsoleLog = console.log;
  console.log = function(...args) {
    const text = args.join(' ');
    if (global.metaAnalyst) { global.metaAnalyst.detect(text, { tool: 'console' }); }
    originalConsoleLog.apply(console, args);
  };
}

if (process.env.ENT_HOOKS === '1') {
  // Hook into process.cwd() calls to detect context switches
  const originalCwd = process.cwd;
  process.cwd = function() {
    const cwd = originalCwd.call(this);
    if (cwd.includes('Enterprise') && (!global.metaAnalyst || !global.metaAnalyst.active)) {
      global.metaAnalyst = new MetaAnalyst();
    }
    return cwd;
  };
}

if (process.env.ENT_HOOKS === '1') {
  // Hook into file operations
  const fs = require('fs');
  const originalReadFileSync = fs.readFileSync;
  const originalWriteFileSync = fs.writeFileSync;
  fs.readFileSync = function(filePath, ...args) {
    if (global.metaAnalyst && String(filePath).includes('Enterprise')) {
      global.metaAnalyst.detect('Reading file: ' + filePath, { tool: 'file_read' });
    }
    return originalReadFileSync.call(this, filePath, ...args);
  };
  fs.writeFileSync = function(filePath, data, ...args) {
    if (global.metaAnalyst && String(filePath).includes('Enterprise')) {
      global.metaAnalyst.detect('Writing file: ' + filePath, { tool: 'file_write' });
      if (typeof data === 'string') { global.metaAnalyst.detect(data, { tool: 'file_content' }); }
    }
    return originalWriteFileSync.call(this, filePath, data, ...args);
  };
}

// Hook into error handling
process.on('uncaughtException', (error) => {
  if (global.metaAnalyst) {
    global.metaAnalyst.detect(error.message, { tool: 'error', severity: 'critical' });
  }
});

// Auto-load on require
if (process.cwd().includes('Enterprise')) {
  global.metaAnalyst = new MetaAnalyst();
}

module.exports = { MetaAnalyst };