# AGENTS.md — Output Formatting Policy

Scope: Applies to the entire repository and all agent messages produced while working within this repo using Codex CLI.

Objective: Improve readability with clearer structure, modest whitespace, and light ASCII separators while remaining compatible with the CLI renderer.

## Default Structure
- Summary
  - 1–2 bullets on the outcome.
- Details or Changes (choose the most relevant heading)
  - Focused bullets (4–6 max) grouped by topic.
- Commands (only when useful)
  - Use monospace for commands, file paths, and code identifiers.
- Next Steps
  - Verification, decisions, or follow-ups.

## Formatting Rules
- Use short section headers in Title Case, wrapped with `**` (e.g., `**Summary**`).
- Insert a single blank line between major sections for breathing room. Avoid multiple consecutive blank lines.
- Use `-` plus a space for bullets. Keep bullets to one line when possible.
- Prefer 4–6 bullets per section; consolidate related points.
- Wrap commands, file paths, env vars, and code identifiers in backticks.
- Use light ASCII separators sparingly when helpful: a single 40–60 char line like `────────────────────────────────────────` between major blocks. Do not use large banners or heavy box art.
- Keep tone concise, direct, and collaborative. Prefer present tense and active voice.

## Modes
- Expanded mode (default in this repo):
  - Include a brief Summary, then Details, then Commands (if relevant), then Next Steps.
  - Add a single blank line between sections.
  - Allow a light ASCII rule once between major blocks if it improves scanability.
- Compact mode (on request):
  - Fewer sections, condensed bullets, minimal separators.
- Numbered steps: Use when the user asks for step-by-step instructions or when sequencing matters.

## Do/Don’t
- Do: Keep messages scannable, with clear headers and grouped bullets.
- Do: Keep code and commands in monospace for easy copy/paste.
- Do: Prefer subtle visual aids (short horizontal rules) over decorative ASCII.
- Don’t: Use heavy ASCII art, big banners, or tables that may break parsers.
- Don’t: Add excessive whitespace beyond one blank line between sections.

## Examples

**Summary**
- Implemented default “Expanded mode” formatting policy for this repo.

**Details**
- Added this `AGENTS.md` to define structure and style.
- Set light ASCII rules as optional and sparing.
- Emphasized monospace for commands and paths.
- Limited bullets per section for readability.

**Commands**
- `git add AGENTS.md`
- `git commit -m "Add AGENTS.md formatting policy"`

**Next Steps**
- If you prefer numbered steps by default, state “Use numbered steps by default”.
- If you want fewer separators, state “No separators unless asked”.

