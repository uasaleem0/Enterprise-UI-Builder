#!/usr/bin/env node

/**
 * Structure Validation (basic)
 * - Compares extracted counts (headings/nav/ctas) with local HTML counts
 */

async function fetchText(url){ try{ const r = await fetch(url); if(!r.ok) return null; return await r.text(); } catch { return null; } }

function countMatches(html, sel) {
  try {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    return doc.querySelectorAll(sel).length;
  } catch {
    // Fallback regex heuristics
    if (sel === 'h1, h2, h3') return (html.match(/<h[123][^>]*>/gi)||[]).length;
    if (sel === 'nav a, header a') return (html.match(/<a[^>]+>/gi)||[]).length;
    if (sel === 'a[role="button"], button, .btn, [class*="button"]') return (html.match(/<button[^>]*>|role="button"/gi)||[]).length;
    return 0;
  }
}

async function validateStructure(extracted, localUrl) {
  const html = await fetchText(localUrl);
  if (!html) return { ok:false, reason:'local-fetch-failed' };
  const wantHeadings = (extracted?.structure?.headings||[]).length;
  const wantNav = (extracted?.structure?.nav||[]).length;
  const wantCtas = (extracted?.structure?.ctas||[]).length;
  const gotHeadings = countMatches(html, 'h1, h2, h3');
  const gotNav = countMatches(html, 'nav a, header a');
  const gotCtas = countMatches(html, 'a[role="button"], button, .btn, [class*="button"]');
  const issues=[];
  if (gotHeadings === 0 && wantHeadings > 0) issues.push('missing-headings');
  if (gotNav === 0 && wantNav > 0) issues.push('missing-nav-links');
  if (gotCtas === 0 && wantCtas > 0) issues.push('missing-ctas');
  return { ok: issues.length===0, counts: { wantHeadings, gotHeadings, wantNav, gotNav, wantCtas, gotCtas }, issues };
}

module.exports = { validateStructure };

