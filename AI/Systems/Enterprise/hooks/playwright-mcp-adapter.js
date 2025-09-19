/**
 * Playwright MCP Adapter (Local)
 * Exposes global.mcpVisualValidate and global.mcpGenerateDesignBrief
 * using Playwright + pixelmatch fallback so protocol can treat this as MCP.
 */

const path = require('path');

async function ensurePlaywright() {
  try { return require('playwright'); } catch { return null; }
}

async function ensurePixelmatch() {
  try {
    return { pixelmatch: require('pixelmatch'), PNG: require('pngjs').PNG };
  } catch {
    return null;
  }
}

global.mcpVisualValidate = async function(localUrl, targetUrl, options = {}) {
  const pw = await ensurePlaywright();
  const pm = await ensurePixelmatch();
  if (!pw || !pm) {
    return { passed: false, similarity: 0, issues: ['Playwright/pixelmatch not available'] };
  }
  const { pixelmatch, PNG } = pm;
  const fs = require('fs');
  const os = require('os');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mcp-validate-'));
  const candPath = path.join(dir, 'local.png');
  const basePath = path.join(dir, 'target.png');
  try {
    const browser = await pw.chromium.launch();
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const p1 = await context.newPage();
    await p1.goto(localUrl, { waitUntil: 'load' });
    await p1.screenshot({ path: candPath, fullPage: false });
    const p2 = await context.newPage();
    await p2.goto(targetUrl, { waitUntil: 'load' });
    await p2.screenshot({ path: basePath, fullPage: false });
    await browser.close();

    const a = PNG.sync.read(fs.readFileSync(basePath));
    const b = PNG.sync.read(fs.readFileSync(candPath));
    if (a.width !== b.width || a.height !== b.height) {
      return { passed: false, similarity: 0, issues: ['dimension mismatch'] };
    }
    const diff = pixelmatch(a.data, b.data, null, a.width, a.height, { threshold: 0.1 });
    const total = a.width * a.height;
    const diffRatio = diff / total;
    const similarity = Math.max(0, 100 - diffRatio * 100);
    const threshold = parseInt(process.env.MS_SIM_THRESHOLD || '90', 10);
    const passed = similarity >= threshold;
    return { passed, similarity: Math.round(similarity), issues: [] };
  } catch (e) {
    return { passed: false, similarity: 0, issues: [e.message || String(e)] };
  }
};

global.mcpGenerateDesignBrief = async function(targetUrl) {
  const pw = await ensurePlaywright();
  if (!pw) return 'Design brief: (Playwright unavailable)';
  try {
    const browser = await pw.chromium.launch();
    const page = await browser.newPage();
    await page.goto(targetUrl, { waitUntil: 'load' });
    const brief = await page.evaluate(() => {
      const getText = sel => Array.from(document.querySelectorAll(sel)).map(e => e.innerText.trim()).filter(Boolean);
      const headings = getText('h1, h2, h3');
      const nav = getText('nav a');
      const buttons = getText('button, a[role="button"]');
      return [
        '## Structure',
        `Headings: ${headings.slice(0, 10).join(' | ')}`,
        `Navigation: ${nav.slice(0, 10).join(' | ')}`,
        `Primary CTAs: ${buttons.slice(0, 10).join(' | ')}`
      ].join('\n');
    });
    await browser.close();
    return brief || 'Design brief: (No content extracted)';
  } catch (e) {
    return `Design brief: (Error) ${e.message || String(e)}`;
  }
};

module.exports = {};

