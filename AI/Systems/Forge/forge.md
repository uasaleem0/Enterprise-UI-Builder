# Forge System v1.0
**AI-Powered Software Development System**

## Overview

Forge is a confidence-based system that transforms vague ideas into production-ready PRDs (Product Requirements Documents) through iterative questioning, multi-agent analysis, and weighted validation. Once the PRD reaches 95%+ confidence, Forge scaffolds a complete GitHub repository with CI/CD, test infrastructure, and atomic issues ready for development.

## Core Philosophy

1. **Confidence-Based Progression**: No phase advances without 95%+ confidence
2. **Atomic, Specific Issues**: Break work into granular, self-contained tasks
3. **Test-First Foundation**: Setup testing infrastructure before feature development
4. **Fresh Context Per Issue**: Clear context between work items to prevent pollution
5. **Human Review Points**: Planning (high involvement), PRs (medium), merge decisions (approval)

## System Architecture

### Phases

**Phase 1: PRD Development** (Current Implementation)
- Idea extraction and feature discovery
- Multi-agent analysis (Analyst, PM, Architect, Validator)
- Weighted confidence tracking (95% threshold)
- Industry-specific compliance integration
- Dual workflow: from scratch OR import existing PRD

**Phase 2: GitHub Foundation** (Implemented)
- Repository scaffolding with CI/CD
- Test framework setup
- Issue generation from PRD features
- Scratchpad planning system
- Branch protection and workflows

**Phase 3: Architecture** (Future)
- System design and data models
- API specifications
- Component architecture

**Phase 4: Implementation** (Future)
- Iterative feature development
- Test-driven development
- PR review workflows

## Weighted Confidence Formula

```
Confidence = Σ (Deliverable_Completion × Weight)

Weights:
- Feature List: 25%
- Tech Stack: 20%
- Success Metrics: 15%
- MVP Scope: 15%
- Problem Statement: 10%
- User Personas: 7%
- User Stories: 5%
- Non-Functional Requirements: 3%

Industry-Specific (if applicable):
- Healthcare: +10% (HIPAA, EHR, Privacy)
- Fintech: +10% (PCI-DSS, Regulations, Security)
- E-commerce: +5% (PCI-DSS, GDPR)
```

## Hard Validation Blocks

System will NOT proceed if:
1. **Tech Stack < 100%** - Cannot design architecture without complete stack
2. **Feature Conflicts Detected** - Contradictory requirements must be resolved
3. **Overall Confidence < 95%** - PRD too vague for implementation
4. **Feature List < 75%** - Acceptance criteria missing or incomplete
5. **Industry Compliance Missing** - Required for healthcare/fintech/regulated industries

## Workflows

### From Scratch Workflow

1. **Start Project**: `/forge-start <project-name>`
2. **Analyst Agent**: Extracts problem statement, target users, market opportunity
3. **Discovery Questions**: Iterative questioning with confidence impact shown
4. **Feature Extraction**: Explicit (user mentioned) vs Implied (system inferred)
5. **Batch Approval**: Review all implied features at once
6. **PM Agent**: Develops user personas and stories
7. **Architect Agent**: Defines tech stack with reasoning
8. **Validator Agent**: Checks for conflicts, completeness, clarity
9. **Confidence Check**: Must reach 95% to proceed
10. **GitHub Setup**: Generate repo foundation with CI/CD
11. **Issue Generation**: Convert PRD features into atomic GitHub issues

### Import PRD Workflow

1. **Import PRD**: `/forge-import <project-name> <prd-file>`
2. **Validator Agent**: Parses existing PRD and maps to Forge structure
3. **Gap Analysis**: Identifies missing deliverables
4. **Confidence Calculation**: Scores existing content
5. **Fill Gaps**: Asks targeted questions for missing items
6. **Validation**: Checks for conflicts and completeness
7. **Confidence Check**: Must reach 95% to proceed
8. **GitHub Setup**: Generate repo foundation with CI/CD
9. **Issue Generation**: Convert PRD features into atomic GitHub issues

## Agent Roles

### Analyst Agent (BMAD-Inspired)
- **Focus**: Problem space, market opportunity, user insights
- **Outputs**: Problem statement, target users, competitive analysis
- **Thinking Mode**: Extended reasoning for complex problems
- **Weight Contribution**: Problem Statement (10%), Success Metrics (15%)

### PM Agent (BMAD-Inspired)
- **Focus**: User personas, stories, MVP scope, metrics
- **Outputs**: User personas (min 2), user stories (Agile format), MVP definition
- **Priority Framework**: MoSCoW (Must/Should/Could/Won't)
- **Weight Contribution**: User Personas (7%), User Stories (5%), MVP Scope (15%)

### Architect Agent
- **Focus**: Tech stack decisions, integrations, non-functional requirements
- **Outputs**: Complete tech stack (frontend, backend, database, auth, hosting)
- **Reasoning**: Must justify each technology choice
- **Weight Contribution**: Tech Stack (20%), Non-Functional (3%)

### Validator Agent
- **Focus**: Completeness, conflicts, clarity, compliance
- **Outputs**: Validation report, blockers, warnings, next steps
- **Checks**: Feature conflicts, tech stack completeness, industry compliance
- **Weight Contribution**: Triggers hard blocks when issues found

## Display Modes

### Unicode Mode (Claude Code)
- Box-drawing characters for tables
- Progress bars: ▓▓▓▓▓▓▓░░░
- Icons: ✅ ❌ ⚠️ 🚨 📊 🔍 💡
- Compact, scannable layout

### ASCII Mode (Codex)
- Standard characters for compatibility
- Progress bars: [#######---]
- Text markers: [OK] [XX] [!!]
- Prevents Mojibake errors

Auto-detected via environment variables.

## Commands

### Core Commands
- `/forge-start <name>` - Create new project from scratch
- `/forge-import <name> <file>` - Import existing PRD for validation
- `/forge-status` - Show confidence breakdown and progress
- `/forge-show <section>` - Expand section (explicit/implied/blockers/deliverables)

### GitHub Commands (After PRD Complete)
- `/forge-setup-repo <name>` - Create GitHub repo with foundation
- `/forge-generate-issues` - Convert PRD features into GitHub issues
- `/forge-issue <number>` - Process GitHub issue (plan → create → test → PR)
- `/forge-review-pr <number>` - Review PR in fresh context
- `/forge-test` - Run test suite
- `/forge-deploy` - Check deployment status

### Utility Commands
- `/forge-help` - Show command reference
- `/forge-fix <blocker>` - Get detailed guidance for specific blocker
- `/forge-export` - Export PRD as markdown

## Project Storage

Projects are stored separately from the Forge system:
- **System Location**: `/c/Users/User/AI/Systems/Forge/`
- **Project Location**: `/c/Users/User/AI/Projects/<project-name>/`

This keeps Forge portable and clean. Installing Forge on a new machine starts fresh with no projects.

## GitHub Foundation

After PRD reaches 95%, Forge offers to:

1. **Create Repository Structure**
   ```
   project-name/
   ├─ .github/
   │  ├─ workflows/ci.yml        # Run tests + linter on every commit
   │  └─ ISSUE_TEMPLATE/         # Feature, bug, enhancement templates
   ├─ scratchpads/               # Claude planning directory
   ├─ README.md                  # Auto-generated from PRD
   ├─ .gitignore                 # Framework-specific
   └─ [framework files]          # Rails, Next.js, Django, etc.
   ```

2. **Setup CI/CD**
   - GitHub Actions workflow
   - Runs tests on every commit to any branch
   - Runs linter (framework-specific)
   - Blocks merge if tests fail
   - Auto-deploys main branch (optional: Render, Vercel, etc.)

3. **Generate Atomic Issues**
   - Convert each PRD feature into 1-3 GitHub issues
   - Issues are granular, specific, atomic
   - Include acceptance criteria from PRD
   - Link related issues
   - Label by priority (Must/Should/Could)

4. **Create Scratchpad System**
   - Directory for Claude to plan work
   - Format: `scratchpads/issue-{number}-plan.md`
   - Contains: issue breakdown, atomic tasks, links to PRD

## Issue Processing Workflow (After Setup)

Based on GitHub Flow + Software Development Life Cycle:

### Plan Phase
1. Fetch issue from GitHub via `gh` CLI
2. Search scratchpads for related prior work
3. Search previous PRs for context
4. Use extended reasoning ("think harder" mode)
5. Break issue into atomic tasks
6. Write plan to scratchpad with link to issue

### Create Phase
7. Implement code changes
8. Follow framework best practices
9. Keep changes focused on issue scope
10. Write clear, maintainable code

### Test Phase
11. Run test suite to verify no breakage
12. Add tests for new functionality
13. Use Puppeteer for UI testing (if applicable)
14. Verify acceptance criteria met

### Deploy Phase
15. Commit changes with descriptive message
16. Open pull request with PR template
17. CI/CD runs tests + linter
18. Review PR (human or separate Claude session)
19. Merge to main if tests pass and review approves
20. Main branch auto-deploys to production

### Clean Context
21. Run `/clear` to wipe context completely
22. Next issue works from cold start
23. Uses scratchpads and PRs for context
24. Prevents context pollution

## Configuration

### Default Settings
```yaml
confidence_threshold: 95
project_storage: /c/Users/User/AI/Projects/
rendering_mode: auto  # unicode, ascii, or auto-detect
thinking_mode: think_harder  # think_hard, think_harder, think_hardest, ultrathink
```

### Industry Detection
System auto-detects project type based on keywords:
- **SaaS**: subscription, user management, dashboard
- **E-commerce**: products, cart, checkout, payment
- **Fintech**: transactions, accounts, payments, compliance
- **Healthcare**: patients, PHI, HIPAA, medical
- **Marketplace**: buyers, sellers, listings, escrow

Applies industry-specific deliverables and compliance requirements automatically.

## File Structure

```
Forge/
├─ forge.md                       # This file (main system instructions)
├─ COMMANDS.md                    # Full command reference
├─ README.md                      # Quick start guide
│
├─ core/
│  ├─ workflows/
│  │  ├─ from-scratch.md          # Start from idea workflow
│  │  └─ import-prd.md            # Import existing PRD workflow
│  ├─ templates/
│  │  ├─ base-prd.md              # PRD template with BMAD integration
│  │  ├─ extraction-compact.md    # Concise logging template
│  │  ├─ confidence-progress.md   # Confidence tracker display
│  │  └─ question-session.md      # Question display template
│  └─ validation/
│     ├─ hard-blocks.json         # Critical blocking conditions
│     └─ confidence-weights.json  # Weighted formula definition
│
├─ agents/
│  ├─ analyst.md                  # Problem space expert (BMAD inspired)
│  ├─ pm.md                       # User stories & personas specialist
│  ├─ architect.md                # Tech stack advisor
│  └─ validator.md                # PRD validation specialist
│
├─ lib/
│  ├─ questions/
│  │  ├─ core-discovery.json      # Universal questions (all projects)
│  │  ├─ saas.json                # SaaS-specific questions
│  │  ├─ ecommerce.json           # E-commerce questions
│  │  ├─ fintech.json             # Fintech questions
│  │  └─ healthcare.json          # Healthcare questions
│  ├─ deliverables/
│  │  ├─ saas.json                # SaaS deliverables
│  │  ├─ ecommerce.json           # E-commerce deliverables
│  │  ├─ fintech.json             # Fintech (PCI-DSS, regulations)
│  │  └─ healthcare.json          # Healthcare (HIPAA, EHR, privacy)
│  └─ formatters/
│     ├─ unicode-renderer.js      # Claude Code display (box-drawing)
│     ├─ ascii-renderer.js        # Codex fallback display
│     └─ auto-detect.js           # Environment detection
│
├─ foundation/                    # GitHub repo scaffolding templates
│  ├─ .github/
│  │  ├─ workflows/
│  │  │  └─ ci.yml                # CI/CD workflow template
│  │  ├─ ISSUE_TEMPLATE/
│  │  │  ├─ feature.md            # Feature request template
│  │  │  ├─ bug.md                # Bug report template
│  │  │  └─ enhancement.md        # Enhancement template
│  │  └─ PULL_REQUEST_TEMPLATE.md # PR template
│  ├─ scratchpads/
│  │  └─ .gitkeep                 # Ensure directory exists
│  ├─ .gitignore-template         # Framework-specific ignores
│  ├─ README-template.md          # Auto-generated README
│  └─ VALIDATION-CHECKLIST.md     # Pre-merge validation
│
├─ scripts/
│  ├─ forge.ps1                   # PowerShell wrapper (all commands)
│  └─ warp-completion.ts          # Warp terminal autocomplete spec
│
└─ docs/
   ├─ quick-start.md              # Getting started guide
   ├─ full-system-guide.md        # Complete system explanation
   ├─ command-reference.md        # All commands with examples
   ├─ agent-behaviors.md          # How each agent works
   ├─ github-workflow.md          # Issue processing workflow
   └─ troubleshooting.md          # Common issues and solutions
```

## Usage Examples

### Example 1: Start from Scratch
```bash
/forge-start fitness-tracker
# Analyst asks discovery questions
# PM creates personas and stories
# Architect defines tech stack
# Validator checks completeness
# System reaches 95% confidence
# Offer to setup GitHub repo
```

### Example 2: Import Existing PRD
```bash
/forge-import fitness-tracker /path/to/existing-prd.md
# Validator parses PRD
# Shows confidence: 67%
# Identifies gaps: MVP Scope, Tech Stack
# Asks targeted questions
# Fills gaps to reach 95%
# Offer to setup GitHub repo
```

### Example 3: Process GitHub Issue
```bash
/forge-issue 42
# Fetch issue #42 from GitHub
# Search scratchpads for related work
# Plan work in scratchpad
# Implement code changes
# Run tests
# Commit and open PR
# Clear context with /clear
```

## Success Metrics

A successful Forge project has:
- ✅ PRD with 95%+ confidence
- ✅ Zero critical blockers
- ✅ Complete tech stack with reasoning
- ✅ Granular, atomic features with acceptance criteria
- ✅ Industry compliance addressed (if applicable)
- ✅ GitHub repo with CI/CD setup
- ✅ Atomic issues ready for development
- ✅ Test framework scaffolding in place

## Version History

**v1.0** (Current)
- PRD development with weighted confidence
- Multi-agent analysis (Analyst, PM, Architect, Validator)
- Dual workflow (from scratch + import)
- GitHub foundation scaffolding
- Issue generation from PRD
- CI/CD templates
- Scratchpad planning system
- Dual rendering (Unicode/ASCII)

**Future Versions**
- v1.1: Architecture phase with system design
- v1.2: Implementation phase with iterative development
- v1.3: Deployment automation
- v2.0: Multi-agent parallel processing

---

**Generated by Forge v1.0**
**System Location**: `/c/Users/User/AI/Systems/Forge/`
**Documentation**: See `docs/` folder for detailed guides
