/**
 * Meta-Analyst Core Engine
 * Auto-activating monitoring system for Enterprise
 */

class MetaAnalyst {
  constructor() {
    this.sessionId = `ENT-${Date.now()}`;
    this.violations = [];
    this.active = false;
    this.init();
  }

  // Auto-activation on Enterprise context
  init() {
    if (this.isEnterpriseContext()) {
      this.activate();
    }
  }

  isEnterpriseContext() {
    const cwd = process.cwd();
    const indicators = [
      'Enterprise',
      'enterprise-consultant',
      'ui-architect',
      'implementation-manager'
    ];
    return indicators.some(i => cwd.includes(i) || process.env.PWD?.includes(i));
  }

  activate() {
    this.active = true;
    console.log(`🔍 META-ANALYST: ACTIVE | Session: ${this.sessionId} | Monitoring: ALL`);
    this.startSession();
  }

  // Detection patterns (token-efficient)
  detect(text, context = {}) {
    if (!this.active) return;

    const violations = [
      // Visual hallucinations
      {
        pattern: /I can see|looking at|visual analysis|the image shows/i,
        type: 'VISUAL_HALLUCINATION',
        alert: '🚨 MA: Visual claim detected'
      },

      // False confidence
      {
        pattern: /(\d{2,3})% confidence|excellent|perfect|ready for production/i,
        type: 'FALSE_CONFIDENCE',
        alert: '🚨 MA: Unsubstantiated confidence'
      },

      // Over-engineering
      {
        pattern: /complex architecture|enterprise pattern|scalable solution/i,
        type: 'OVER_ENGINEERING',
        alert: '⚠️ MA: Over-engineering risk'
      },

      // Missing evidence
      {
        pattern: /users want|industry standard|best practice|typically/i,
        type: 'ASSUMPTION',
        alert: '⚠️ MA: Assumption without evidence'
      }
    ];

    violations.forEach(v => {
      if (v.pattern.test(text)) {
        this.logViolation(v.type, text.match(v.pattern)[0], context);
        if (v.alert.includes('🚨')) {
          console.log(v.alert);
        }
      }
    });
  }

  // Silent logging (minimal overhead)
  logViolation(type, match, context) {
    this.violations.push({
      timestamp: Date.now(),
      type,
      match: match.substring(0, 50),
      context: context.tool || 'conversation'
    });
  }

  // Session management
  startSession() {
    this.sessionStart = Date.now();
    this.logPath = `C:/Users/User/systems/Enterprise/.meta-analyst/sessions/${this.sessionId}.json`;
  }

  // Periodic update (non-intrusive)
  getStatus() {
    if (this.violations.length > 0) {
      return `🔍 MA: ${this.violations.length} issues logged`;
    }
    return null;
  }

  // Session summary
  generateSummary() {
    const summary = {
      sessionId: this.sessionId,
      duration: Date.now() - this.sessionStart,
      violations: this.violations,
      patterns: this.analyzePatterns()
    };

    require('fs').writeFileSync(this.logPath, JSON.stringify(summary, null, 2));
    return `🔍 MA: Session logged to ${this.sessionId}.json`;
  }

  analyzePatterns() {
    const types = {};
    this.violations.forEach(v => {
      types[v.type] = (types[v.type] || 0) + 1;
    });
    return types;
  }
}

// Auto-instantiate when loaded
if (typeof global !== 'undefined') {
  global.metaAnalyst = new MetaAnalyst();
}

module.exports = MetaAnalyst;