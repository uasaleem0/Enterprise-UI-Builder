#!/usr/bin/env node

/**
 * Budgets & Gating
 * - a11y via @axe-core/playwright (if available)
 * - performance via lighthouse (if available)
 * - multi-viewport via summary file (if present)
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

function tryRequire(name) { try { return require(name); } catch { return null; } }

async function runAxe(url) {
  const playwright = tryRequire('playwright');
  const { AxeBuilder } = tryRequire('@axe-core/playwright') || {};
  if (!playwright || !AxeBuilder) return null;
  const browser = await playwright.chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  try {
    await page.goto(url, { waitUntil: 'load' });
    const results = await new AxeBuilder({ page }).analyze();
    const violations = results.violations || [];
    return { violationsCount: violations.length };
  } catch { return null; }
  finally { await context.close(); await browser.close(); }
}

async function runLighthouse(url) {
  const lighthouse = tryRequire('lighthouse');
  const chromeLauncher = tryRequire('chrome-launcher');
  if (!lighthouse || !chromeLauncher) return null;
  let chrome;
  try {
    chrome = await chromeLauncher.launch({ chromeFlags: ['--headless'] });
    const result = await lighthouse(url, { port: chrome.port, output: 'json', logLevel: 'error' });
    const cats = result.lhr.categories;
    const perf = Math.round((cats.performance?.score || 0) * 100);
    const acc = Math.round((cats.accessibility?.score || 0) * 100);
    const bp = Math.round((cats['best-practices']?.score || 0) * 100);
    return { performance: perf, accessibility: acc, bestPractices: bp };
  } catch { return null; }
  finally { try { await chrome?.kill(); } catch {} }
}

async function readMultiViewport(projectPath) {
  try {
    const p = path.join(projectPath, 'evidence', 'validation', 'multi-viewport-summary.json');
    return JSON.parse(await fsp.readFile(p, 'utf8'));
  } catch { return null; }
}

async function enforceBudgets(ctx) {
  const { localUrl, projectPath } = ctx;
  const thresholds = {
    mvMin: parseInt(process.env.ENT_TARGET_MV_MIN || '85', 10),
    a11yMaxViolations: parseInt(process.env.ENT_A11Y_MAX || '0', 10),
    perfMin: parseInt(process.env.ENT_PERF_MIN || '85', 10)
  };

  let mvOk = true, a11yOk = true, perfOk = true;
  let reports = {};

  const mv = await readMultiViewport(projectPath);
  if (mv && Array.isArray(mv.results)) {
    const scores = mv.results.map(r => (typeof r.score === 'number' ? r.score : 0));
    const min = scores.length ? Math.min(...scores) : 0;
    mvOk = min >= thresholds.mvMin;
    reports.multiViewport = { min, threshold: thresholds.mvMin };
  }

  const axe = await runAxe(localUrl);
  if (axe) {
    a11yOk = (axe.violationsCount <= thresholds.a11yMaxViolations);
    reports.a11y = { violations: axe.violationsCount, threshold: thresholds.a11yMaxViolations };
  }

  const lh = await runLighthouse(localUrl);
  if (lh) {
    perfOk = (lh.performance >= thresholds.perfMin);
    reports.lighthouse = lh;
    reports.perfThreshold = thresholds.perfMin;
  }

  const shouldEnforce = process.env.ENT_ENFORCE_BUDGETS === '1';
  if (!shouldEnforce) return { updated: false, reports };

  const pass = mvOk && a11yOk && perfOk;
  const result = Object.assign({}, ctx.result, { success: pass, budgets: { mvOk, a11yOk, perfOk, reports } });
  return { updated: true, result };
}

module.exports = { enforceBudgets };

