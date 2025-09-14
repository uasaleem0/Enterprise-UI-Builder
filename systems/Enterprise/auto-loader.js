/**
 * Auto-Loader for Meta-Analyst System
 * Ensures Meta-Analyst is always active in Enterprise context
 */

// Check if we're in Enterprise context
function isEnterpriseContext() {
  const cwd = process.cwd();
  const args = process.argv.join(' ');
  const env = process.env.PWD || '';

  return [cwd, args, env].some(str =>
    str.includes('Enterprise') ||
    str.includes('enterprise-consultant') ||
    str.includes('ui-architect')
  );
}

// Auto-load if in Enterprise context
if (isEnterpriseContext()) {
  try {
    require('./hooks/claude-integration.js');
    console.log('🔍 META-ANALYST: Auto-loaded successfully');
  } catch (error) {
    console.log('⚠️ META-ANALYST: Failed to load -', error.message);
  }
}

// Export for manual loading
module.exports = {
  loadMetaAnalyst: () => require('./hooks/claude-integration.js'),
  isEnterpriseContext
};