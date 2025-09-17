/**
 * Enhanced Meta-Analyst Core
 * Extends base functionality with system error detection
 */

const fs = require('fs');
const path = require('path');
const MetaAnalyst = require('./meta-analyst-core');

class EnhancedMetaAnalyst extends MetaAnalyst {
  constructor() {
    super();
    this.systemErrors = [];
    this.bashMonitors = new Map();
    this.errorPatterns = {
      // System errors
      'ENOENT': /ENOENT.*no such file or directory/i,
      'EACCES': /EACCES.*permission denied/i,
      'PORT_CONFLICT': /Port \d+ is in use/i,
      'MODULE_ERROR': /MODULE_NOT_FOUND|Cannot resolve module/i,

      // Development errors
      'COMPILATION_ERROR': /Compilation error|Failed to compile/i,
      'RUNTIME_ERROR': /unhandledRejection|uncaughtException/i,
      'NETWORK_ERROR': /ECONNREFUSED|ENOTFOUND|network error/i,

      // Platform-specific
      'WINDOWS_COMPAT': /sleep.*command not found|'sleep' is not recognized/i,
      'PATH_SEPARATOR': /Cannot find.*\\.*\/|\/.*\\/i
    };

    this.initializeSystemMonitoring();
  }

  initializeSystemMonitoring() {
    // Fix the log path to use current directory structure
    this.logPath = path.join(__dirname, '.meta-analyst', 'sessions', `${this.sessionId}.json`);

    // Ensure directories exist
    const sessionsDir = path.dirname(this.logPath);
    if (!fs.existsSync(sessionsDir)) {
      fs.mkdirSync(sessionsDir, { recursive: true });
    }

    if (this.active) {
      console.log('🔍 META-ANALYST: Enhanced system monitoring active');
    }
  }

  // System error detection
  detectSystemError(output, source = 'unknown') {
    if (!this.active) return;

    const errors = [];

    for (const [errorType, pattern] of Object.entries(this.errorPatterns)) {
      if (pattern.test(output)) {
        const error = {
          timestamp: Date.now(),
          type: errorType,
          source: source,
          message: this.extractErrorMessage(output, pattern),
          severity: this.calculateErrorSeverity(errorType)
        };

        errors.push(error);
        this.systemErrors.push(error);

        if (error.severity === 'CRITICAL') {
          this.alertCriticalError(error);
        }
      }
    }

    return errors;
  }

  extractErrorMessage(output, pattern) {
    const match = output.match(pattern);
    if (match) {
      // Extract surrounding context (50 chars before and after)
      const index = output.indexOf(match[0]);
      const start = Math.max(0, index - 50);
      const end = Math.min(output.length, index + match[0].length + 50);
      return output.substring(start, end).trim();
    }
    return match ? match[0] : 'Unknown error';
  }

  calculateErrorSeverity(errorType) {
    const criticalErrors = ['ENOENT', 'COMPILATION_ERROR', 'RUNTIME_ERROR'];
    const warningErrors = ['PORT_CONFLICT', 'WINDOWS_COMPAT'];

    if (criticalErrors.includes(errorType)) return 'CRITICAL';
    if (warningErrors.includes(errorType)) return 'WARNING';
    return 'INFO';
  }

  alertCriticalError(error) {
    const alert = `🚨 META-ANALYST SYSTEM ALERT: ${error.type} detected in ${error.source}`;
    console.log('\x1b[31m' + alert + '\x1b[0m'); // Red text

    // Log to session file immediately
    this.logSystemError(error);
  }

  logSystemError(error) {
    const logPath = path.join(__dirname, '.meta-analyst', 'system-errors.json');
    const logDir = path.dirname(logPath);

    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }

    let existingErrors = [];
    if (fs.existsSync(logPath)) {
      try {
        existingErrors = JSON.parse(fs.readFileSync(logPath, 'utf8'));
      } catch (e) {
        existingErrors = [];
      }
    }

    existingErrors.push(error);
    fs.writeFileSync(logPath, JSON.stringify(existingErrors, null, 2));
  }

  // Monitor bash processes
  monitorBashProcess(processId, command) {
    this.bashMonitors.set(processId, {
      command: command,
      startTime: Date.now(),
      errorCount: 0,
      lastCheck: Date.now()
    });

    if (this.active) {
      console.log(`🔍 META-ANALYST: Monitoring bash process ${processId}`);
    }
  }

  // Analyze bash output for errors
  analyzeBashOutput(processId, stdout, stderr) {
    if (!this.active) return;

    const monitor = this.bashMonitors.get(processId);
    if (!monitor) return;

    // Check stderr for errors
    if (stderr) {
      const errors = this.detectSystemError(stderr, `bash-${processId}`);
      monitor.errorCount += errors.length;
    }

    // Check stdout for warning patterns
    if (stdout) {
      const warnings = this.detectSystemError(stdout, `bash-${processId}`);
      monitor.errorCount += warnings.filter(w => w.severity === 'WARNING').length;
    }

    monitor.lastCheck = Date.now();
  }

  // Generate system error report
  generateSystemErrorReport() {
    const report = {
      timestamp: new Date().toISOString(),
      totalErrors: this.systemErrors.length,
      criticalErrors: this.systemErrors.filter(e => e.severity === 'CRITICAL').length,
      warningErrors: this.systemErrors.filter(e => e.severity === 'WARNING').length,
      monitoredProcesses: this.bashMonitors.size,
      recentErrors: this.systemErrors.slice(-10) // Last 10 errors
    };

    return report;
  }

  // Enhanced session summary including system errors
  generateEnhancedSummary() {
    const baseSummary = this.generateSummary();
    const systemReport = this.generateSystemErrorReport();

    const enhancedSummary = {
      ...JSON.parse(fs.readFileSync(this.logPath, 'utf8')),
      systemErrors: systemReport,
      recommendations: this.generateRecommendations()
    };

    // Write enhanced summary
    const enhancedPath = this.logPath.replace('.json', '-enhanced.json');
    fs.writeFileSync(enhancedPath, JSON.stringify(enhancedSummary, null, 2));

    return `🔍 MA: Enhanced session logged to ${path.basename(enhancedPath)}`;
  }

  generateRecommendations() {
    const recommendations = [];

    // Analyze error patterns for recommendations
    const errorTypes = this.systemErrors.reduce((acc, error) => {
      acc[error.type] = (acc[error.type] || 0) + 1;
      return acc;
    }, {});

    if (errorTypes.ENOENT > 2) {
      recommendations.push("Consider checking file paths and directory structure");
    }

    if (errorTypes.PORT_CONFLICT > 1) {
      recommendations.push("Implement dynamic port selection for development servers");
    }

    if (errorTypes.WINDOWS_COMPAT > 0) {
      recommendations.push("Replace Unix commands with cross-platform alternatives");
    }

    return recommendations;
  }
}

module.exports = EnhancedMetaAnalyst;