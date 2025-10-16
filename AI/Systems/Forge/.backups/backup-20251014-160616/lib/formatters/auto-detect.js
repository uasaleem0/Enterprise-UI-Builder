// Forge System - Auto-detect rendering mode
// Detects Claude Code vs Codex and chooses Unicode vs ASCII

function detectEnvironment() {
  // Check environment variables
  const isClaudeCode = process.env.CLAUDE_CODE === 'true';
  const isCodex = process.env.CODEX === 'true';

  // Check terminal Unicode support
  const terminalSupportsUnicode =
    process.env.LANG?.includes('UTF-8') ||
    process.env.LC_ALL?.includes('UTF-8') ||
    process.env.TERM_PROGRAM === 'vscode' ||
    process.env.TERM_PROGRAM === 'warp';

  // Check platform
  const isWindows = process.platform === 'win32';
  const windowsSupportsUnicode =
    process.env.WT_SESSION || // Windows Terminal
    process.env.TERM_PROGRAM === 'vscode';

  // Decision logic
  if (isClaudeCode || terminalSupportsUnicode) {
    return 'unicode';
  }

  if (isCodex) {
    return 'ascii';
  }

  if (isWindows && !windowsSupportsUnicode) {
    return 'ascii';
  }

  // Default to Unicode for modern terminals
  return 'unicode';
}

function getRenderer() {
  const mode = detectEnvironment();

  if (mode === 'unicode') {
    return require('./unicode-renderer');
  } else {
    return require('./ascii-renderer');
  }
}

module.exports = {
  detectEnvironment,
  getRenderer
};
