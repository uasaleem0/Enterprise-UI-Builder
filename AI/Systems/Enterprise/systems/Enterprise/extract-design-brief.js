/**
 * Design Brief Extractor
 * Collects high-level and per-element details using Playwright for Phase 1.
 * Produces a machine JSON and a human MD from the same data.
 */

const fs = require('fs');
const path = require('path');

async function tryPlaywright() {
  try { return require('playwright'); } catch { return null; }
}

async function extractComputedStyle(page, selector, props) {
  try {
    return await page.$eval(selector, (el, props) => {
      const cs = window.getComputedStyle(el);
      const out = {};
      props.forEach(p => { out[p] = cs.getPropertyValue(p); });
      return out;
    }, props);
  } catch {
    return null;
  }
}

async function getTextList(page, selector, max = 10) {
  try {
    const arr = await page.$$eval(selector, els => els.map(e => (e.innerText || '').trim()).filter(Boolean));
    return arr.slice(0, max);
  } catch { return []; }
}

async function extractBasic(page) {
  const headings = await getTextList(page, 'h1, h2, h3', 12);
  const nav = await getTextList(page, 'nav a, header a', 12);
  const ctas = await getTextList(page, 'a[role="button"], button, .btn, [class*="button"]', 12);
  return { headings, nav, ctas };
}

function parseBoxShadow(value) {
  if (!value) return null;
  // Very simple parser: split by commas into layers
  return value.split(',').map(layer => layer.trim());
}

function colorOrGradient(background) {
  if (!background) return null;
  if (background.includes('gradient')) return { type: 'gradient', value: background };
  return { type: 'solid', value: background };
}

async function extractElementSpec(page, id, selector) {
  const vis = await extractComputedStyle(page, selector, [
    'color','background-image','background-color','box-shadow','border-top-width','border-right-width','border-bottom-width','border-left-width','border-top-color','border-right-color','border-bottom-color','border-left-color','border-top-style','border-right-style','border-bottom-style','border-left-style','border-top-left-radius','border-top-right-radius','border-bottom-left-radius','border-bottom-right-radius','filter','opacity','font-family','font-weight','font-size','line-height','letter-spacing'
  ]);
  if (!vis) return null;
  return {
    id,
    selectors: [selector],
    visual: {
      color: vis['color'] || null,
      background: colorOrGradient(vis['background-image']) || (vis['background-color'] ? { type: 'solid', value: vis['background-color'] } : null),
      boxShadow: parseBoxShadow(vis['box-shadow']) || null,
      border: {
        width: {
          top: vis['border-top-width'], right: vis['border-right-width'], bottom: vis['border-bottom-width'], left: vis['border-left-width']
        },
        style: {
          top: vis['border-top-style'], right: vis['border-right-style'], bottom: vis['border-bottom-style'], left: vis['border-left-style']
        },
        color: {
          top: vis['border-top-color'], right: vis['border-right-color'], bottom: vis['border-bottom-color'], left: vis['border-left-color']
        }
      },
      radius: {
        topLeft: vis['border-top-left-radius'], topRight: vis['border-top-right-radius'], bottomLeft: vis['border-bottom-left-radius'], bottomRight: vis['border-bottom-right-radius']
      },
      filter: vis['filter'] || null,
      opacity: vis['opacity'] || null,
      typography: {
        fontFamily: vis['font-family'] || null,
        fontWeight: vis['font-weight'] || null,
        fontSize: vis['font-size'] || null,
        lineHeight: vis['line-height'] || null,
        letterSpacing: vis['letter-spacing'] || null
      }
    }
  };
}

function renderMd(json) {
  const lines = [];
  lines.push('# Design Brief');
  lines.push('');
  lines.push(`Target: ${json.meta.targetUrl}`);
  lines.push(`Date: ${json.meta.createdAt}`);
  lines.push(`Version: ${json.meta.version}`);
  lines.push('');
  lines.push('## 1) Overview & Goals');
  lines.push('- Auto-generated overview stub');
  lines.push('');
  lines.push('## 2) Page Inventory (P0/P1)');
  json.pages.forEach(p => lines.push(`- ${p.id} (${p.priority}) — ${p.path}`));
  lines.push('');
  lines.push('## 3) Structure');
  lines.push(`Headings: ${json.structure.headings.join(' | ')}`);
  lines.push(`Navigation: ${json.structure.nav.join(' | ')}`);
  lines.push(`Primary CTAs: ${json.structure.ctas.join(' | ')}`);
  lines.push('');
  lines.push('## 4) Visual Language (summary)');
  lines.push('- Colors/typography summarized in per-element specs below');
  lines.push('');
  lines.push('## 5) Components (selected)');
  json.components.slice(0, 8).forEach(c => {
    lines.push(`### Component: ${c.id}`);
    lines.push(`Selectors: ${c.selectors.join(', ')}`);
    if (c.visual) {
      lines.push(`- Color: ${c.visual.color}`);
      lines.push(`- Background: ${c.visual.background ? `${c.visual.background.type} ${c.visual.background.value}` : 'n/a'}`);
      lines.push(`- Box-shadow: ${c.visual.boxShadow ? c.visual.boxShadow.join(' , ') : 'n/a'}`);
      lines.push(`- Radius: TL ${c.visual.radius.topLeft}, TR ${c.visual.radius.topRight}, BL ${c.visual.radius.bottomLeft}, BR ${c.visual.radius.bottomRight}`);
      lines.push(`- Typography: ${c.visual.typography.fontFamily}, ${c.visual.typography.fontWeight}, ${c.visual.typography.fontSize}/${c.visual.typography.lineHeight}`);
    }
    lines.push('');
  });
  lines.push('## 6) Acceptance Gates');
  lines.push(`- Final: ≥ ${json.acceptance.finalTarget}% and Phase 10/11 gates`);
  lines.push('');
  lines.push('## 7) Evidence Index');
  json.pages.forEach(p => {
    lines.push(`- ${p.id} screenshots: ${Object.values(p.evidence.screenshots || {}).join(', ')}`);
  });
  lines.push('');
  return lines.join('\n');
}

async function extractDesignBrief(targetUrl, projectPath) {
  const json = {
    meta: {
      targetUrl,
      createdAt: new Date().toISOString(),
      version: '1.0.0',
      extractor: { name: 'playwright-extractor', version: '1' }
    },
    pages: [
      { id: 'home', path: '/', priority: 'P0', viewports: ['desktop','tablet','mobile'], evidence: { screenshots: {} } }
    ],
    structure: { headings: [], nav: [], ctas: [] },
    components: [],
    interactions: [],
    acceptance: {
      phaseTargets: { P2:30,P3:45,P4:60,P5:70,P6:75,P7:80,P8:85,P9:90,P10:94 },
      finalTarget: 95,
      a11y: { axeNoCritical: true },
      lighthouse: { performance: 90, accessibility: 90, bestPractices: 90 }
    },
    artifacts: { designBriefMd: './design-brief.md', simpleLogTxt: './simple-log.txt', simpleLogJsonl: './simple-log.jsonl' }
  };

  const pw = await tryPlaywright();
  if (!pw) return { json, md: renderMd(json) };

  const browser = await pw.chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  await page.goto(targetUrl, { waitUntil: 'load' });

  // Basic texts
  const basic = await extractBasic(page);
  json.structure = basic;

  // Attempt element specs: header, hero h1, primary CTA
  const header = await extractElementSpec(page, 'header', 'header');
  if (header) json.components.push(header);
  // hero h1 (heuristic)
  const heroH1 = await extractElementSpec(page, 'hero-heading', 'h1');
  if (heroH1) json.components.push(heroH1);
  // primary CTA heuristic
  const cta = await extractElementSpec(page, 'hero-cta-primary', 'a[role="button"], button');
  if (cta) json.components.push(cta);

  await browser.close();

  const md = renderMd(json);
  return { json, md };
}

async function writeDesignBrief(targetUrl, projectPath) {
  try {
    const { json, md } = await extractDesignBrief(targetUrl, projectPath);
    const jsonPath = path.join(projectPath, 'design-brief.json');
    const mdPath = path.join(projectPath, 'design-brief.md');
    fs.mkdirSync(projectPath, { recursive: true });
    fs.writeFileSync(jsonPath, JSON.stringify(json, null, 2), { encoding: 'utf8' });
    fs.writeFileSync(mdPath, md, { encoding: 'utf8' });
    return { jsonPath, mdPath };
  } catch (e) {
    return null;
  }
}

module.exports = { writeDesignBrief };

