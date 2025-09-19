#!/usr/bin/env node

/**
 * PRD Capture (conversational)
 * - Accepts a freeform description and produces a lightweight structured PRD
 * - Persists JSON + Markdown summary under projectPath/prd
 */

const fsp = require('fs').promises;
const path = require('path');

function toArray(text) {
  if (!text) return [];
  return text.split(/[,\n]+/).map(s => s.trim()).filter(Boolean);
}

function inferFeatures(desc) {
  const lower = (desc||'').toLowerCase();
  const out = [];
  if (/(auth|login|signup)/.test(lower)) out.push('Authentication');
  if (/(dashboard|admin)/.test(lower)) out.push('Dashboard');
  if (/(blog|posts|articles)/.test(lower)) out.push('Blog/Posts');
  if (/(payments|stripe|checkout)/.test(lower)) out.push('Payments');
  if (/(api|backend)/.test(lower)) out.push('API');
  return out;
}

function buildPrd(description, options = {}) {
  const prd = {
    meta: {
      createdAt: new Date().toISOString(),
      source: 'conversation',
    },
    description,
    goals: toArray(options.goals || ''),
    style: toArray(options.style || ''),
    pages: toArray(options.pages || ''),
    features: Array.from(new Set([...(options.features || []), ...inferFeatures(description)])),
    acceptance: {
      cloneSimilarity: options.cloneSimilarity || 95,
      a11y: 'zero critical',
      perf: 85
    }
  };
  return prd;
}

function prdMarkdown(prd) {
  const lines = [];
  lines.push('# Project Requirements (PRD)');
  lines.push('');
  lines.push(`Created: ${prd.meta.createdAt}`);
  lines.push('');
  lines.push('## Description');
  lines.push(prd.description || 'N/A');
  lines.push('');
  if (prd.goals.length) { lines.push('## Goals'); prd.goals.forEach(g => lines.push(`- ${g}`)); lines.push(''); }
  if (prd.style.length) { lines.push('## Style Preferences'); prd.style.forEach(s => lines.push(`- ${s}`)); lines.push(''); }
  if (prd.pages.length) { lines.push('## Target Pages'); prd.pages.forEach(p => lines.push(`- ${p}`)); lines.push(''); }
  if (prd.features.length) { lines.push('## Features'); prd.features.forEach(f => lines.push(`- ${f}`)); lines.push(''); }
  lines.push('## Acceptance Criteria');
  lines.push(`- Clone Similarity: ${prd.acceptance.cloneSimilarity}%`);
  lines.push(`- Accessibility: ${prd.acceptance.a11y}`);
  lines.push(`- Performance: ${prd.acceptance.perf}+`);
  lines.push('');
  return lines.join('\n');
}

async function savePrd(projectPath, prd) {
  const dir = path.join(projectPath, 'prd');
  await fsp.mkdir(dir, { recursive: true });
  const jsonPath = path.join(dir, 'prd.json');
  const mdPath = path.join(dir, 'prd.md');
  await fsp.writeFile(jsonPath, JSON.stringify(prd, null, 2), 'utf8');
  await fsp.writeFile(mdPath, prdMarkdown(prd), 'utf8');
  return { jsonPath, mdPath };
}

module.exports = { buildPrd, savePrd };

