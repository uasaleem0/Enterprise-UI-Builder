# Operational Agent Guidelines (Output & UX)

Purpose
- Make logs and messages easy to scan, consistent, and low‑noise.
- Use clear structure, whitespace, and simple graphical elements where helpful.

Core Principles
- Clarity first: short, structured, and predictable.
- Minimal noise: no excessive ANSI, no random emojis, no repeating banners.
- Evidence‑oriented: always reference file paths and artifacts succinctly.
- Progressive disclosure: top‑level summary first, details on demand.

Default Formatting Rules
- Section headers: UPPER or Title Case, separated by a thin rule if needed.
- Whitespace: one blank line between sections; avoid dense walls of text.
- Bullets: single‑line bullets; break only if truly necessary.
- Inline literals: wrap commands/paths in backticks.
- Code fences: prefer for trees, logs, JSON/JSONL samples, or multi‑line commands.
- Tables: only for short matrices; otherwise prefer bullets.
- Graphical elements: use light ASCII boxes/lines, not heavy art.

Folder/Tree Presentation
- Use a code fence with a simple tree:
```
projects/athlead-org-clone
├─ design-brief.md
├─ evidence/
│  ├─ phase-2/
│  │  └─ iter-1/
│  │     ├─ local-candidate.png
│  │     └─ target-baseline.png
└─ simple-log.txt
```

Run/Log Presentation
- Always start with a compact summary block:
```
=== Clone Run ===
Target: https://example.com
Project: projects/example-clone
Stage→Phase: 3→[1–8], 6→[9–11]
Final Target: ≥95%
MCP: ACTIVE | Playwright: AVAILABLE
```
- Then stream concise status lines (Simple Log Mode):
```
[2025-09-18T11:43:10Z] phase_start stage=3 phase=2 name="Structural Foundation"
[2025-09-18T11:43:34Z] iteration phase=2 iter=1 sim=32% delta=+6.5% evidence="…/evidence/phase-2/iter-1/"
[2025-09-18T11:44:02Z] phase_complete phase=2 sim=35% iterations=2 status=COMPLETED
```
- If a phase fails: 
```
[ts] phase_error phase=4 error="network timeout"
```
- If early completion or critical fail triggers:
```
[ts] early_completion phase=8 sim=91%
[ts] critical_fail phase=5 reason="no_improvement_10"
```

Evidence & Artifacts
- Refer to artifacts with relative paths under `projects/<name>/…`.
- When listing multiple files, show first 2–3 then indicate count:
  - `… (2 more)`

Environment & Warnings
- Condensed one‑liners only:
  - `Playwright: AVAILABLE | MCP: ACTIVE`
  - `Axe: SKIPPED (ENT_SKIP_AXE=1)`
  - `Lighthouse: UNAVAILABLE (no preview @ http://localhost:3000)`

Do/Don’t
- Do: ask crisp yes/no when a decision gates progress.
- Do: keep live output ≤ 30 lines per phase unless explicitly asked for more.
- Don’t: print large ASCII banners repeatedly.
- Don’t: dump entire files; link to paths instead.

Simple Log Mode (default)
- Prefer ENT_SIMPLE_LOG=1 as default behavior.
- Write to both console and files:
  - `projects/<name>/simple-log.txt`
  - `projects/<name>/simple-log.jsonl`

Phase Output Checklist
- Phase start: `phase_start` with stage, phase number, name.
- Iteration: similarity, delta, evidence path, duration (optional short form).
- Phase complete: similarity, iterations, status, issues>0 indicator.
- P10/P11 rollups: one‑line PASS/CHECK.
- Final: overall similarity, acceptance (pass/fail), artifact index path.

User Interaction Pattern
- Summarize status in ≤ 6 bullets.
- Offer exactly 2–3 next actions (e.g., “tail log”, “open evidence”, “resume at phase N”).
- Use a short code fence for commands, not inline paragraphs.

Examples: Command Blocks
```
# Tail the simple log
Get-Content -Path projects/example-clone/simple-log.txt -Wait

# Open evidence folder
explorer projects\example-clone\evidence
```

Rationale
- These rules improve scanability and reduce cognitive overhead.
- They create a stable UX across terminals/editors and facilitate quick audits.

