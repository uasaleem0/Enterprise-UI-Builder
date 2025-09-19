const fs = require('fs');
const path = require('path');

class EnhancedVisualDashboard {
  constructor() {
    this.sessionData = {
      sessionId: this._id(),
      startTime: new Date(),
      projectName: null,
      targetUrl: null,
      phases: [],
      iterations: [],
      currentPhase: 0,
      totalPhases: 11,
      overallProgress: 0
    };
    if (!process.env.ENT_NO_CLEAR) { try { console.clear(); } catch {} }
    console.log('--- Enterprise Dashboard ---');
  }

  _id() { return `DASH-${Date.now()}-${Math.random().toString(36).slice(2,6)}`; }

  startSession(projectName, targetUrl) {
    this.sessionData.projectName = projectName;
    this.sessionData.targetUrl = targetUrl;
    this.sessionData.startTime = new Date();
    this.sessionData.phases = [];
    this.sessionData.iterations = [];
    this.sessionData.overallProgress = 0;
    console.log(`Session: ${projectName} -> ${targetUrl}`);
  }

  recordPhaseCompletion(number, data) {
    this.sessionData.currentPhase = number;
    this.sessionData.phases.push({ number, ...data });
    this.sessionData.overallProgress = Math.min(100, Math.round((number / this.sessionData.totalPhases) * 100));
    console.log(`Phase ${number} complete. Similarity: ${data.similarity ?? 'N/A'}%`);
  }

  recordIteration(phase, iterationData) {
    this.sessionData.iterations.push({ phase, ...iterationData });
    console.log(`Iter ${iterationData.iteration} (phase ${phase}) sim: ${iterationData.similarity ?? 'N/A'}%`);
  }

  autoSaveSession(projectPath) {
    try {
      const out = path.join(projectPath, 'evidence', 'dashboard-session.json');
      fs.mkdirSync(path.dirname(out), { recursive: true });
      fs.writeFileSync(out, JSON.stringify(this.sessionData, null, 2), 'utf8');
    } catch {}
  }

  generateFinalReport() {
    const last = this.sessionData.iterations[this.sessionData.iterations.length - 1] || {};
    const sim = typeof last.similarity === 'number' ? last.similarity : 0;
    const grade = sim >= 95 ? 'A' : sim >= 90 ? 'B' : sim >= 80 ? 'C' : 'D';
    return { overallGrade: grade, similarity: sim, progress: this.sessionData.overallProgress };
  }
}

module.exports = { EnhancedVisualDashboard };

