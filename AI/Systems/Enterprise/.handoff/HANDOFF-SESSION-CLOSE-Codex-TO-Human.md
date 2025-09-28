# AI Handoff: Codex → Human (Session Close)

**Project**: Enterprise Website Clone
**Date**: 2025-09-26
**Objective**: Finalize architecture, provide exact run instructions, and document verification for high‑fidelity cloning (target ≥ 95%).

## Current Status
- Orchestrator is top‑level owner: runs preflight + setup, delegates once to Protocol 30, applies budgets, writes summary.
- Protocol 30 performs extraction, tokens, synthesis, server lifecycle, phases/iterations, validation, and evidence.
- No cycles: Phase 2 uses a minimal bootstrap helper (not the orchestrator) to avoid recursion.
- Preflight, Playwright sanity, validator tests, and CLIs all pass locally.

## Exact Run Commands
1) Preflight (sanity)
- `node scripts/run-preflight.js`

2) Enable progress‑only logging (recommended)
- `$env:ENT_PROGRESS_ONLY='1'; $env:ENT_NO_CLEAR='1'`

3) Run the clone at 95% with budgets
- `node enterprise-clone.js "https://your-target.com" --similarity 95 --enforce-budgets`
- Optional: `--name my-clone --port 3004`

4) Inspect outputs
- Log: `projects/<name>/orchestrator-log.json`
- Iterations: `projects/<name>/evidence/dashboard-session.json`
- Validation: `projects/<name>/evidence/validation/`

## Logging Expectations
- Preflight rows: `[preflight] [...]` and `[preflight-warn]` if any.
- Delegation: `[delegate] protocol-30`.
- Phases: `PHASE <n>: <NAME>` before work starts.
- Iterations: `Iter <k> (phase <n>) sim: <S>% (+<Δ>%)` per iteration.
- Heartbeats: `[tick] ...` every 10s on long steps (validation/evidence) to show liveness.
- Full mode (without ENT_PROGRESS_ONLY) adds step‑level logs: extraction, tokens, synthesis, evidence capture, validation complete.

## Technical Context
- Orchestrator: `lib/clone-orchestrator.js` delegates to `executeProtocol30(...)` after `runPreflight()` and optional PRD.
- Protocol 30: `protocols/protocol-3.0/integrated-protocol-3.0.js` (engine for phases/iterations). Phase 2 uses `lib/phase2-bootstrap.js` (extraction → tokens → synthesis → ensure server).
- Budgets: a11y/perf/multi‑viewport enforced post‑protocol by orchestrator when `--enforce-budgets`.
- Progress‑only filter: `ENT_PROGRESS_ONLY=1` prints only essential progress + heartbeats.

## Files Modified (key)
- Updated: `lib/clone-orchestrator.js` (delegate to Protocol 30, budgets post‑protocol, cleaned imports)
- Updated: `launch-protocol30.js` (naming/log tweaks)
- Updated: `enterprise-clone.js` (progress filter wiring previously)
- Added: `lib/phase2-bootstrap.js`
- Added: `scripts/run-preflight.js`
- Deleted: `lib/clone-orchestrator-proxy.js`, `lib/validation.js`, `lib/project.js`

## Notes / Risks
- Highly dynamic/personalized targets may not reach 95% without custom handling (overlays, auth, animations, fonts). Static targets likely achieve ≥ 95%.
- Some Protocol 30 console lines still contain cosmetic mojibake; functionally harmless.
- Optional improvement: unify per‑iteration validation with multi‑viewport scoring to strictly gate on the same metric.

## Next Steps
- Provide the target URL and run the clone command above.
- Review evidence and scores; if needed, request iteration tuning or validator unification for stricter gating.

