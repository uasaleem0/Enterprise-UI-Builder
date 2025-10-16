// Forge System - ASCII Renderer (Codex/Basic Terminal)
// Uses standard ASCII characters only

function renderBanner(title) {
  const width = 59;
  const padding = Math.floor((width - title.length) / 2);
  const line = '='.repeat(width);

  return `
${line}
${' '.repeat(padding)}${title}
${line}
`;
}

function renderProgressBar(percentage) {
  const filled = Math.floor(percentage / 10);
  const empty = 10 - filled;
  return '[' + '#'.repeat(filled) + '-'.repeat(empty) + ']';
}

function renderConfidenceTracker(projectName, confidence, deliverables) {
  const progressBar = renderProgressBar(confidence);
  const gap = 95 - confidence;
  const status = confidence >= 95 ? '[READY]' : '[BLOCKED]';

  let output = renderBanner(`FORGE PRD CONFIDENCE TRACKER - ${projectName}`);

  output += `
Overall: ${confidence}% ${progressBar} | Target: 95% | Gap: ${gap > 0 ? '-' : '+'}${Math.abs(gap).toFixed(2)}%

--------------------------------------------------------------
 Deliverable            | Weight | Status | Contribution
--------------------------------------------------------------
`;

  deliverables.forEach(d => {
    const icon = d.status === 100 ? '[OK]' : d.status >= 75 ? '[!!]' : '[XX]';
    const statusPct = `${d.status}%`.padStart(4);
    const contrib = `${d.contribution.toFixed(2)}%`.padStart(6);
    const name = d.name.padEnd(22);
    const weight = `${d.weight}%`.padStart(4);

    output += ` ${icon} ${name} | ${weight} | ${statusPct} | ${contrib}\n`;
  });

  output += `--------------------------------------------------------------

${status} | ${confidence >= 95 ? 'Ready for GitHub setup' : `Need ${gap.toFixed(2)}% more`}
`;

  return output;
}

function renderValidationReport(projectName, results) {
  let output = renderBanner(`[PRD VALIDATION REPORT - ${projectName}]`);

  output += '\nRunning validation sequence...\n\n';

  results.checks.forEach((check, i) => {
    const icon = check.passed ? '[OK]' : check.warning ? '[!!]' : '[XX]';
    output += `[${i + 1}/7] ${icon} ${check.message}\n`;
  });

  if (results.blockers.length > 0) {
    output += `\n${'='.repeat(59)}\n`;
    output += `                  [CRITICAL BLOCKERS (${results.blockers.length})]\n`;
    output += `${'='.repeat(59)}\n\n`;

    results.blockers.forEach((blocker, i) => {
      output += `---------------------------------------------------------------\n`;
      output += ` BLOCKER #${i + 1}: ${blocker.title}\n`;
      output += `---------------------------------------------------------------\n\n`;
      output += ` Reason: ${blocker.reason}\n\n`;
      output += ` Resolution: ${blocker.resolution}\n\n`;
      output += ` Agent: ${blocker.agent}\n`;
      output += `---------------------------------------------------------------\n\n`;
    });
  }

  if (results.warnings.length > 0) {
    output += `${'='.repeat(59)}\n`;
    output += `                       [WARNINGS (${results.warnings.length})]\n`;
    output += `${'='.repeat(59)}\n\n`;

    results.warnings.forEach((warning, i) => {
      output += `${i + 1}. ${warning.title}\n`;
      output += `   -> Risk: ${warning.risk}\n`;
      output += `   -> Fix: ${warning.fix}\n\n`;
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

  output += `  EXPLICIT (${categories.explicit.length})   |   IMPLIED (${categories.implied.length})    |   LOW CONF (${categories.low_conf.length})\n`;
  output += `-----------------+------------------+-----------------------\n`;

  const maxRows = Math.max(categories.explicit.length, categories.implied.length, categories.low_conf.length);

  for (let i = 0; i < maxRows; i++) {
    const exp = categories.explicit[i];
    const imp = categories.implied[i];
    const low = categories.low_conf[i];

    const expText = exp ? `${exp.name} ${exp.confidence}%` : '';
    const impText = imp ? `${imp.name} ${imp.confidence}%` : '';
    const lowText = low ? low.name : '';

    output += ` ${expText.padEnd(15)} | ${impText.padEnd(16)} | ${lowText}\n`;
  }

  return output;
}

function renderQuestionPrompt(question, questionNum, totalQuestions, currentConfidence, targetConfidence) {
  const progress = Math.floor((questionNum / totalQuestions) * 10);
  const progressBar = '[' + '#'.repeat(progress) + '-'.repeat(10 - progress) + ']';

  let output = renderBanner('[ANALYST AGENT - Discovery Phase]');

  output += `
Progress: ${progressBar} Question ${questionNum}/${totalQuestions} | Confidence: ${currentConfidence}% -> ${targetConfidence}%

---------------------------------------------------------------
 Q${questionNum}: ${question.title}
---------------------------------------------------------------

 ${question.text}

 ${question.subtext}

 Examples:
`;

  question.examples.forEach(ex => {
    output += ` * ${ex}\n`;
  });

  output += `
 Your answer: _______________________________________________

---------------------------------------------------------------

 Impact: ${question.impact}

 >> Skip question (keeps confidence at ${currentConfidence}%)
 >> Save & continue later (/forge-status to resume)
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
