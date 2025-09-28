// Minimal progress-only console filter
// Enables essential logs and heartbeats while suppressing noisy output.
// Activate by setting ENT_PROGRESS_ONLY=1 in the environment.

function installProgressFilter() {
  try {
    if (process.env.ENT_PROGRESS_ONLY !== '1') return;

    const allow = [
      /^\[preflight\]/i,
      /^\[preflight-warn\]/i,
      /^Playwright:/i,
      /^MCP:/i,
      /PHASE\s+\d+/i,
      /^Iter\s+\d+\s+\(phase/i,
      /^Phase\s+\d+\s+complete/i,
      /^Target similarity/i,
      /^\[validate\]/i,
      /^\[stage\]\s+validate:visual/i,
      /^Starting Protocol 3\.0/i,
      /^Protocol 3\.0 Complete/i,
      /^Clone Orchestration Complete/i,
      /^Resume Complete/i,
      /^\[orchestrator\]\s+Result written/i,
      /^\[tick\]/ // heartbeat from orchestrator
    ];

    const origLog = console.log.bind(console);
    const origInfo = console.info ? console.info.bind(console) : origLog;
    const origWarn = console.warn ? console.warn.bind(console) : origLog;
    const origError = console.error.bind(console);

    function shouldPrint(args) {
      if (!args || args.length === 0) return false;
      const first = args[0];
      const asText = typeof first === 'string' ? first : '';
      for (const re of allow) {
        try { if (re.test(asText)) return true; } catch {}
      }
      return false;
    }

    console.log = function (...args) {
      if (shouldPrint(args)) return origLog(...args);
    };
    console.info = function (...args) {
      if (shouldPrint(args)) return origInfo(...args);
    };
    console.warn = function (...args) {
      if (shouldPrint(args)) return origWarn(...args);
    };
    // Do not filter errors to avoid hiding failures
    console.error = function (...args) { return origError(...args); };
  } catch {
    // Fail open: if filter setup fails, leave logging as-is
  }
}

module.exports = { installProgressFilter };

