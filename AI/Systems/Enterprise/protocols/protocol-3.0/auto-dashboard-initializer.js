const { EnhancedVisualDashboard } = require('./dashboard/enhanced-visual-dashboard.js');

class AutoDashboardInitializer {
  constructor() {
    this.dashboard = null;
    this.isInitialized = false;
    this.activeSession = null;
    this._autosaveTimer = null;
    this.initialize();
  }

  initialize() {
    if (!this.isInitialized) {
      this.dashboard = new EnhancedVisualDashboard();
      this.isInitialized = true;
      console.log('[dashboard] Ready');
    }
  }

  startAutoDashboard(projectName, targetUrl, projectPath) {
    if (!this.isInitialized) this.initialize();
    this.dashboard.startSession(projectName, targetUrl);
    this.activeSession = { projectName, targetUrl, projectPath, startTime: new Date() };
    this.setupAutoSave();
    console.log(`[dashboard] Active for: ${projectName}`);
    return this.dashboard;
  }

  getDashboard() { if (!this.isInitialized) this.initialize(); return this.dashboard; }

  setupAutoSave() {
    if (this._autosaveTimer) { try { clearInterval(this._autosaveTimer); } catch {} this._autosaveTimer = null; }
    if (this.activeSession && this.activeSession.projectPath) {
      const ms = parseInt(process.env.ENT_AUTOSAVE_MS || '180000', 10);
      this._autosaveTimer = setInterval(() => {
        try { this.dashboard.autoSaveSession(this.activeSession.projectPath); } catch {}
      }, ms);
    }
  }

  autoDetectAndInitialize(targetUrl) {
    const projectName = this.extractProjectName(targetUrl);
    const projectPath = this.generateProjectPath(projectName);
    console.log('[dashboard] Auto-detecting session...');
    return this.startAutoDashboard(projectName, targetUrl, projectPath);
  }

  extractProjectName(url) {
    try { const u = new URL(url); const domain = u.hostname.replace('www.',''); return domain.split('.')[0] + '-clone'; } catch { return 'website-clone-' + Date.now(); }
  }

  generateProjectPath(projectName) {
    const p = require('path');
    return p.join(process.cwd(), 'projects', projectName);
  }

  getIntegrationHooks() {
    return {
      onPhaseStart: (n, name) => { /* noop */ },
      onPhaseComplete: (n, data) => {
        if (this.dashboard) {
          this.dashboard.recordPhaseCompletion(n, data);
          if (this.activeSession?.projectPath) this.dashboard.autoSaveSession(this.activeSession.projectPath);
        }
      },
      onIteration: (n, iter) => { if (this.dashboard) this.dashboard.recordIteration(n, iter); },
      onSessionComplete: () => { if (this.dashboard) return this.dashboard.generateFinalReport(); }
    };
  }

  isActive() { return this.isInitialized && this.activeSession !== null; }
  getSessionInfo() { return this.activeSession; }
}

let globalDashboardInitializer = null;
function getGlobalDashboard() { if (!globalDashboardInitializer) globalDashboardInitializer = new AutoDashboardInitializer(); return globalDashboardInitializer; }
function autoInitializeDashboard(targetUrl) { const init = getGlobalDashboard(); return init.autoDetectAndInitialize(targetUrl); }

module.exports = { AutoDashboardInitializer, getGlobalDashboard, autoInitializeDashboard };