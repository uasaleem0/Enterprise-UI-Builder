#!/usr/bin/env node

/**
 * Synthesis MVP (Milestone 3)
 * - Generates a simple index.html from extraction artifacts
 * - Applies primary colors, font-family, nav, hero heading, CTAs
 */

const fsp = require('fs').promises;
const path = require('path');

function sanitizeColor(value, fallback) {
  if (!value || typeof value !== 'string') return fallback;
  return value.trim();
}

function choosePrimary(struct) {
  const bg = sanitizeColor(struct?.visual?.bodyBackground, '#ffffff');
  const link = sanitizeColor(struct?.visual?.linkColor, '#1e40af');
  // Prefer link color as accent, bg as page background
  return { pageBg: bg, accent: link };
}

function pickHeroHeading(struct) {
  const h = (struct?.headings || []).find(Boolean);
  return h || 'Welcome';
}

function buildIndexHtml(struct, theme) {
  const font = (struct?.visual?.bodyFont || 'system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif');
  const nav = (struct?.nav || []).slice(0, 6);
  const ctas = (struct?.ctas || []).slice(0, 2);
  const hero = pickHeroHeading(struct);

  const navHtml = nav.map(t => `<a href="#" class="nav-link">${t}</a>`).join(' ');
  const ctaHtml = ctas.map(t => `<a href="#" class="cta">${t}</a>`).join(' ');

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Enterprise Candidate</title>
    <style>
      :root { --accent: ${theme.accent}; }
      html, body { height: 100%; }
      body { font-family: ${font}; margin: 0; background: ${theme.pageBg}; color: #111; }
      .container { max-width: 1080px; margin: 0 auto; padding: 1.5rem; }
      header { display: flex; align-items: center; justify-content: space-between; padding: 1rem 0; }
      .brand { font-weight: 700; }
      .nav-link { margin-right: 1rem; color: var(--accent); text-decoration: none; }
      .nav-link:hover { text-decoration: underline; }
      .hero { padding: 3rem 0; background: rgba(0,0,0,0.02); border-radius: 8px; }
      .hero h1 { font-size: 2.25rem; margin: 0 0 0.5rem 0; }
      .cta { display: inline-block; margin-right: 0.75rem; margin-top: 0.75rem; background: var(--accent); color: white; padding: 0.6rem 1rem; border-radius: 6px; text-decoration: none; }
      footer { padding: 2rem 0; color: #555; }
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <div class="brand">Enterprise Candidate</div>
        <nav>${navHtml}</nav>
      </header>
      <section class="hero">
        <h1>${hero}</h1>
        <p>Generated from extraction artifacts. Accent color and font applied.</p>
        ${ctaHtml}
      </section>
      <footer>
        <small>Enterprise System · Candidate</small>
      </footer>
    </div>
  </body>
</html>`;
}

async function synthesizeFromExtraction(projectPath) {
  const extractionPath = path.join(projectPath, 'evidence', 'extraction', 'extraction.json');
  let artifact;
  try {
    artifact = JSON.parse(await fsp.readFile(extractionPath, 'utf8'));
  } catch {
    return { ok: false, reason: 'extraction-not-found' };
  }
  const struct = artifact.structure || null;
  if (!struct) return { ok: false, reason: 'no-structure' };
  const theme = choosePrimary(struct);
  const html = buildIndexHtml(struct, theme);
  const indexPath = path.join(projectPath, 'index.html');
  await fsp.writeFile(indexPath, html, 'utf8');
  return { ok: true, indexPath, theme };
}

module.exports = { synthesizeFromExtraction };

