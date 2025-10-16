// Forge System - Unicode Renderer (Claude Code)
// Uses box-drawing characters and Unicode icons

const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  gray: '\x1b[90m'
};

function renderBanner(title) {
  const width = 59;
  const padding = Math.floor((width - title.length) / 2);
  const line = '═'.repeat(width);

  return `
${colors.cyan}╔${line}╗${colors.reset}
${colors.cyan}║${' '.repeat(padding)}${colors.bold}${title}${colors.reset}${colors.cyan}${' '.repeat(width - padding - title.length)}║${colors.reset}
${colors.cyan}╚${line}╝${colors.reset}
`;
}

function renderProgressBar(percentage) {
  const filled = Math.floor(percentage / 10);
  const empty = 10 - filled;
  return '▓'.repeat(filled) + '░'.repeat(empty);
}

function renderConfidenceTracker(projectName, confidence, deliverables) {
  const progressBar = renderProgressBar(confidence);
  const gap = 95 - confidence;
  const status = confidence >= 95 ? '✅ READY' : '⚠️  BLOCKED';

  let output = renderBanner(`FORGE PRD CONFIDENCE TRACKER - ${projectName}`);

  output += `
Overall: ${confidence}% ${progressBar} │ Target: 95% │ Gap: ${gap > 0 ? '-' : '+'}${Math.abs(gap).toFixed(2)}%

┌────────────────────────────┬──────┬────────┬──────────────┐
│ Deliverable                │Weight│ Status │ Contribution │
├────────────────────────────┼──────┼────────┼──────────────┤
`;

  deliverables.forEach(d => {
    const icon = d.status === 100 ? '✅' : d.status >= 75 ? '⚠️ ' : '❌';
    const statusPct = `${d.status}%`.padStart(4);
    const contrib = `${d.contribution.toFixed(2)}%`.padStart(6);
    const name = d.name.padEnd(26);
    const weight = `${d.weight}%`.padStart(4);

    output += `│ ${icon} ${name} │ ${weight} │ ${statusPct} │ ${contrib}       │\n`;
  });

  output += `└────────────────────────────┴──────┴────────┴──────────────┘

${status} │ ${confidence >= 95 ? 'Ready for GitHub setup' : `Need ${gap.toFixed(2)}% more`}
`;

  return output;
}

function renderValidationReport(projectName, results) {
  let output = renderBanner(`🔍 PRD VALIDATION REPORT - ${projectName}`);

  output += '\nRunning validation sequence...\n\n';

  results.checks.forEach((check, i) => {
    const icon = check.passed ? '✅' : check.warning ? '⚠️ ' : '❌';
    output += `[${i + 1}/7] ${icon} ${check.message}\n`;
  });

  if (results.blockers.length > 0) {
    output += `\n${colors.cyan}╔═══════════════════════════════════════════════════════════╗${colors.reset}\n`;
    output += `${colors.cyan}║${colors.reset}                     ${colors.red}🚨 CRITICAL BLOCKERS (${results.blockers.length})${colors.reset}              ${colors.cyan}║${colors.reset}\n`;
    output += `${colors.cyan}╚═══════════════════════════════════════════════════════════╝${colors.reset}\n\n`;

    results.blockers.forEach((blocker, i) => {
      output += `┌─ BLOCKER #${i + 1}: ${blocker.title} ${'─'.repeat(Math.max(0, 30 - blocker.title.length))}┐\n`;
      output += `│${' '.repeat(60)}│\n`;
      output += `│ Reason: ${blocker.reason.substring(0, 52).padEnd(52)} │\n`;
      output += `│${' '.repeat(60)}│\n`;
      output += `│ Resolution: ${blocker.resolution.substring(0, 47).padEnd(47)} │\n`;
      output += `│${' '.repeat(60)}│\n`;
      output += `│ Agent: ${blocker.agent.padEnd(51)} │\n`;
      output += `└${'─'.repeat(60)}┘\n\n`;
    });
  }

  if (results.warnings.length > 0) {
    output += `${colors.cyan}╔═══════════════════════════════════════════════════════════╗${colors.reset}\n`;
    output += `${colors.cyan}║${colors.reset}                        ${colors.yellow}⚠️  WARNINGS (${results.warnings.length})${colors.reset}                    ${colors.cyan}║${colors.reset}\n`;
    output += `${colors.cyan}╚═══════════════════════════════════════════════════════════╝${colors.reset}\n\n`;

    results.warnings.forEach((warning, i) => {
      output += `${i + 1}. ${warning.title}\n`;
      output += `   └─ Risk: ${warning.risk}\n`;
      output += `   └─ Fix: ${warning.fix}\n\n`;
    });
  }

  return output;
}

function renderFeatureList(features) {
  let output = '\n';

  const categories = {
    explicit: features.filter(f => f.type === 'explicit'),
    implied: features.filter(f => f.type === 'implied'),
    low_conf: features.filter(f => f.confidence < 75)
  };

  output += `✅ EXPLICIT (${categories.explicit.length})         🔍 IMPLIED (${categories.implied.length})        ⚠️  LOW CONF (${categories.low_conf.length})\n`;

  const maxRows = Math.max(categories.explicit.length, categories.implied.length, categories.low_conf.length);

  for (let i = 0; i < maxRows; i++) {
    const exp = categories.explicit[i];
    const imp = categories.implied[i];
    const low = categories.low_conf[i];

    const expText = exp ? `${exp.name} ${exp.confidence}%` : '';
    const impText = imp ? `${imp.name} ${imp.confidence}%` : '';
    const lowText = low ? low.name : '';

    output += `${expText.padEnd(20)} ${impText.padEnd(20)} ${lowText}\n`;
  }

  return output;
}

function renderQuestionPrompt(question, questionNum, totalQuestions, currentConfidence, targetConfidence) {
  const progress = Math.floor((questionNum / totalQuestions) * 10);
  const progressBar = '█'.repeat(progress) + '░'.repeat(10 - progress);

  let output = renderBanner('🤖 ANALYST AGENT - Discovery Phase');

  output += `
Progress: [${progressBar}] Question ${questionNum}/${totalQuestions} │ Confidence: ${currentConfidence}% → ${targetConfidence}%

┌─ Q${questionNum}: ${question.title} ${'─'.repeat(Math.max(0, 45 - question.title.length))}┐
│${' '.repeat(60)}│
│ ${question.text.padEnd(58)} │
│${' '.repeat(60)}│
│ ${question.subtext.padEnd(58)} │
│${' '.repeat(60)}│
│ Examples:${' '.repeat(50)}│
`;

  question.examples.forEach(ex => {
    output += `│ • ${ex.substring(0, 56).padEnd(56)} │\n`;
  });

  output += `│${' '.repeat(60)}│
│ Your answer: ${'_'.repeat(45)}   │
│${' '.repeat(60)}│
└${'─'.repeat(60)}┘

💡 Impact: ${question.impact}

⏭️  Skip question (keeps confidence at ${currentConfidence}%)
💾 Save & continue later (/forge-status to resume)
`;

  return output;
}

module.exports = {
  renderBanner,
  renderProgressBar,
  renderConfidenceTracker,
  renderValidationReport,
  renderFeatureList,
  renderQuestionPrompt
};
