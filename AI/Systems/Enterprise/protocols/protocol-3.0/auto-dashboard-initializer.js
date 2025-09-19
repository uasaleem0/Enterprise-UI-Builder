const { EnhancedVisualDashboard } = require('./dashboard/enhanced-visual-dashboard.js');

class AutoDashboardInitializer {
  constructor() {
    this.dashboard = null;
    this.isInitialized = false;
    this.activeSession = null;\n    this._autosaveTimer = null;

    // Auto-initialize when this class is instantiated
    this.initialize();
  }

  // Initialize dashboard system
  initialize() {
    if (!this.isInitialized) {
      this.dashboard = new EnhancedVisualDashboard();
      this.isInitialized = true;
      console.log('ðŸŽ¯ Auto-Dashboard Initializer: READY');
    }
  }

  // Automatically start dashboard for any website cloning session
  startAutoDashboard(projectName, targetUrl, projectPath) {
    if (!this.isInitialized) {
      this.initialize();
    }

    // Start the enhanced dashboard session
    this.dashboard.startSession(projectName, targetUrl);

    this.activeSession = {
      projectName,
      targetUrl,
      projectPath,
      startTime: new Date()
    };

    // Setup auto-save interval
    this.setupAutoSave();

    console.log(`ðŸš€ Auto-Dashboard ACTIVATED for: ${projectName}`);
    return this.dashboard;
  }

  // Get the active dashboard instance
  getDashboard() {
    if (!this.isInitialized) {
      this.initialize();
    }
    return this.dashboard;
  }

  // Setup automatic session saving
  setupAutoSave() {
    if (this.activeSession && this.activeSession.projectPath) {
      const intervalMs = parseInt(process.env.ENT_AUTOSAVE_MS || '180000', 10); // default 3 min
      setInterval(() => {
        if (this.dashboard && this.activeSession) {
          this.dashboard.autoSaveSession(this.activeSession.projectPath);
        }
      }, intervalMs);
    }
  }

  // Auto-detect and initialize dashboard for any Protocol 3.0 execution
  autoDetectAndInitialize(targetUrl) {
    // Extract project name from URL
    const projectName = this.extractProjectName(targetUrl);
    const projectPath = this.generateProjectPath(projectName);

    console.log('ðŸ” Auto-detecting website cloning session...');
    return this.startAutoDashboard(projectName, targetUrl, projectPath);
  }

  // Extract project name from URL
  extractProjectName(url) {
    try {
      const urlObj = new URL(url);
      const domain = urlObj.hostname.replace('www.', '');
      return domain.split('.')[0] + '-clone';
    } catch (error) {
      return 'website-clone-' + Date.now();
    }
  }

  // Generate project path
  generateProjectPath(projectName) {
    const path = require('path');
    return path.join(process.cwd(), 'projects', projectName);
  }

  // Integration hooks for Protocol 3.0
  getIntegrationHooks() {
    return {
      onPhaseStart: (phaseNumber, phaseName) => {
        if (this.dashboard) {
          console.log(`ðŸ”„ Phase ${phaseNumber} Starting: ${phaseName}`);
        }
      },

      onPhaseComplete: (phaseNumber, phaseData) => {
        if (this.dashboard) {
          this.dashboard.recordPhaseCompletion(phaseNumber, phaseData);
          // Save immediately on phase completion to reduce risk of data loss
          if (this.activeSession && this.activeSession.projectPath) {
            this.dashboard.autoSaveSession(this.activeSession.projectPath);
          }
        }
      },

      onIteration: (phaseNumber, iterationData) => {
        if (this.dashboard) {
          this.dashboard.recordIteration(phaseNumber, iterationData);
        }
      },

      onSessionComplete: () => {
        if (this.dashboard) {
          const report = this.dashboard.generateFinalReport();
          console.log('ðŸŽ‰ Session completed with dashboard tracking!');
          return report;
        }
      }
    };
  }

  // Check if dashboard is active
  isActive() {
    return this.isInitialized && this.activeSession !== null;
  }

  // Get session info
  getSessionInfo() {
    return this.activeSession;
  }
}

// Global instance for auto-initialization
let globalDashboardInitializer = null;

// Factory function to ensure single instance
function getGlobalDashboard() {
  if (!globalDashboardInitializer) {
    globalDashboardInitializer = new AutoDashboardInitializer();
  }
  return globalDashboardInitializer;
}

// Auto-detect and initialize for any website cloning operation
function autoInitializeDashboard(targetUrl) {
  const initializer = getGlobalDashboard();
  return initializer.autoDetectAndInitialize(targetUrl);
}

module.exports = {
  AutoDashboardInitializer,
  getGlobalDashboard,
  autoInitializeDashboard
};
