# Website Cloner (Full Playbook)

This is the canonical SOP for Protocol 3.0 website cloning.

## Inputs
- `url`: Target site to clone
- `viewports`: desktop/tablet/mobile defaults unless overridden
- `targetSimilarity`: default 90% (final acceptance); per‑phase thresholds per Protocol 3.0
- `projectName`: optional; auto‑derived from URL otherwise

## Environments
- Primary: Playwright MCP for navigation/screenshots and interactions
- Fallback: Standard Playwright with Microsoft similarity (pass/fail) or pixel (% via pixelmatch)

## Evidence
- Full‑page screenshots at each viewport
- Component‑level screenshots (header, nav, hero, sections, footer)
- Interaction states: hover/focus/click, forms, menus
- Artifacts stored under `projects/<name>/`

## Acceptance Gates
- Per‑phase targets (see Protocol 3.0): enforce pass/fail at phase end
  - Microsoft similarity: PASS if ≥ threshold (default 90% final; lower thresholds earlier phases)
  - Pixelmatch fallback: score ≥ threshold (%)
- Final acceptance: ≥ 90% before completion or handoff

## CLI Usage
```bash
node commands.js /clone-website <url> [--similarity 90] [--name project]
```

## Artifacts
- `projects/<name>/protocol-3.0-session-<id>.json`: session state (phases, iterations, scores)
- Screenshots and diffs as produced by MCP/validation suite

## Troubleshooting
- Fonts/assets missing: configure local preview to load matching assets
- Selectors unstable: add robust selectors for components of interest
- Tolerance tuning: adjust phase thresholds or pixel tolerance for specific pages

## Notes
- Protocol 3.0 is ACTIVE (11‑phase); see PROTOCOL-HIERARCHY.md
- Stage ↔ Phase mapping: Stage 3 → Phases 1–8; Stage 6 → Phases 9–11

