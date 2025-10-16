# Forge System - Complete Guide

Comprehensive documentation for the Forge AI-powered software development system.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Core Philosophy](#core-philosophy)
3. [Architecture](#architecture)
4. [Workflows](#workflows)
5. [Agent System](#agent-system)
6. [Confidence Calculation](#confidence-calculation)
7. [Validation System](#validation-system)
8. [GitHub Integration](#github-integration)
9. [Display Modes](#display-modes)
10. [Configuration](#configuration)

---

## System Overview

### What is Forge?

Forge transforms vague project ideas into production-ready applications through a structured,
 confidence-based approach:

**Phase 1: PRD Development** (Current)
- Multi-agent discovery and analysis
- Weighted confidence tracking (95% threshold)
- Industry-specific compliance integration
- Dual workflow: from scratch OR import existing PRD

**Phase 2: GitHub Foundation** (Current)
- Repository scaffolding with CI/CD
- Test framework setup
- Atomic issue generation
- Scratchpad planning system

**Phase 3: Architecture** (Future)
- System design and data models
- API specifications
- Component architecture

**Phase 4: Implementation** (Future)
- Iterative feature development
- Test-driven development
- PR review workflows

### Why Forge?

Traditional software development struggles:
- ❌ Vague requirements lead to rework
- ❌ Scope creep delays launches
- ❌ Missing test coverage breaks features
- ❌ Context pollution confuses AI assistants

Forge solves this with:
- ✅ Confidence-based progression (no advancement without 95%+ clarity)
- ✅ Atomic, specific issues (granular, self-contained tasks)
- ✅ Test-first foundation (CI/CD before features)
- ✅ Fresh context per issue (clear between work items)

---

## Core Philosophy

### 1. Confidence-Based Progression

No phase advances without **95%+ confidence**.

**Why 95%?**
- Allows minor gaps without blocking
- Enforces clarity on critical items
- Balances thoroughness with practicality

**What blocks progression:**
- Vague features (missing acceptance criteria)
- Incomplete tech stack
- Conflicting requirements
- Missing industry compliance

### 2. Atomic, Specific Issues

Break large features into **granular, self-contained tasks**.

**Bad (Vague):**
```
Issue: Add user dashboard
```

**Good (Atomic):**
```
Issue: User dashboard - Workout history view
- Display last 30 days of workouts
- Show exercise name, sets, reps, weight
- Filter by date range
- Sort by most recent first
- Mobile responsive table layout
```

### 3. Test-First Foundation

Setup testing **before** feature development.

**Required before first feature:**
- Test suite (RSpec, Jest, pytest, etc.)
- CI/CD pipeline (GitHub Actions)
- Puppeteer for UI testing
- Branch protection rules

**Why?**
- Catches regressions early
- Enables confident AI commits
- Prevents "works on my machine"

### 4. Fresh Context Per Issue

Clear context **after each PR merge**.

**In Claude Code:**
```bash
# After PR merged:
/clear  # Wipes entire context window
```

**Why?**
- Prevents context pollution
- Forces issues to be self-contained
- Better results, fewer tokens
- Issues work from cold start

### 5. Human Review Points

Balance AI automation with human oversight:

| Phase | Human Involvement |
|-------|-------------------|
| Planning | **High** - Detailed specs, granular issues |
| Creating | **Low** - AI writes code |
| Testing | **Low** - Automated tests |
| Reviewing | **Medium** - PR review, final approval |
| Merging | **High** - Human decision |

---

## Architecture

### Folder Structure

```
Forge/
├─ forge.md                       # Main system instructions
├─ COMMANDS.md                    # Command reference
├─ README.md                      # Quick start
│
├─ core/                          # System core
│  ├─ workflows/
│  │  ├─ from-scratch.md          # Start from idea workflow
│  │  └─ import-prd.md            # Import existing PRD workflow
│  ├─ templates/
│  │  ├─ base-prd.md              # PRD template (BMAD-inspired)
│  │  ├─ extraction-compact.md    # Concise logging
│  │  ├─ confidence-progress.md   # Confidence tracker
│  │  └─ question-session.md      # Question display
│  └─ validation/
│     ├─ hard-blocks.json         # Blocking conditions
│     └─ confidence-weights.json  # Formula definition
│
├─ agents/                        # Agent definitions
│  ├─ analyst.md                  # Problem space expert
│  ├─ pm.md                       # User stories & personas
│  ├─ architect.md                # Tech stack advisor
│  └─ validator.md                # Validation specialist
│
├─ lib/                           # Reusable components
│  ├─ questions/                  # Question banks
│  │  ├─ core-discovery.json      # Universal questions
│  │  ├─ saas.json                # SaaS-specific
│  │  ├─ ecommerce.json           # E-commerce
│  │  ├─ fintech.json             # Fintech
│  │  └─ healthcare.json          # Healthcare
│  ├─ deliverables/               # Industry specs
│  │  ├─ saas.json
│  │  ├─ ecommerce.json
│  │  ├─ fintech.json
│  │  └─ healthcare.json
│  └─ formatters/                 # Display templates
│     ├─ unicode-renderer.js      # Claude Code (box-drawing)
│     ├─ ascii-renderer.js        # Codex fallback
│     └─ auto-detect.js           # Environment detection
│
├─ foundation/                    # GitHub repo templates
│  ├─ .github/
│  │  ├─ workflows/ci.yml         # CI/CD workflow
│  │  ├─ ISSUE_TEMPLATE/          # Feature, bug, enhancement
│  │  └─ PULL_REQUEST_TEMPLATE.md
│  ├─ scratchpads/                # Claude planning directory
│  ├─ .gitignore-template
│  ├─ README-template.md
│  └─ VALIDATION-CHECKLIST.md
│
├─ scripts/                       # Executables
│  ├─ forge.ps1                   # PowerShell wrapper
│  └─ warp-completion.ts          # Autocomplete spec
│
└─ docs/                          # Documentation
   ├─ quick-start.md              # Getting started
   ├─ full-system-guide.md        # This file
   ├─ command-reference.md        # All commands
   ├─ agent-behaviors.md          # Agent details
   ├─ github-workflow.md          # Issue processing
   └─ troubleshooting.md          # Common issues
```

### Project Structure (After `forge setup-repo`)

```
project-name/
├─ .github/
│  ├─ workflows/
│  │  └─ ci.yml                   # Runs tests + linter on every commit
│  ├─ ISSUE_TEMPLATE/
│  │  ├─ feature.md
│  │  ├─ bug.md
│  │  └─ enhancement.md
│  └─ PULL_REQUEST_TEMPLATE.md
├─ scratchpads/                   # Claude planning (issue-N-plan.md)
├─ prd.md                         # Product Requirements Document
├─ README.md                      # Auto-generated from PRD
├─ .gitignore                     # Framework-specific
└─ [framework files]              # Rails, Next.js, Django, etc.
```

---

## Workflows

### From-Scratch Workflow

**Command**: `forge start <project-name>`

**Steps**:

1. **Initialization**
   - Create project directory: `/c/Users/User/AI/Projects/<project-name>/`
   - Initialize empty `prd.md` file

2. **Analyst Agent - Discovery**
   - Ask core discovery questions:
     - What problem does this solve?
     - Who are the target users?
     - What's the market opportunity?
     - What defines success?
   - Extract problem statement
   - Identify target personas
   - Define success criteria

3. **Feature Extraction**
   - **Explicit features**: User mentioned directly
   - **Implied features**: System inferred (e.g., user mentions "workouts" → implies auth, database)
   - Batch approval: Show all implied features at once
   - User approves/rejects/modifies

4. **PM Agent - User Stories**
   - Create user personas (minimum 2)
   - Write Agile user stories: "As a [persona], I want [goal], so that [benefit]"
   - Prioritize with MoSCoW: Must/Should/Could/Won't-Have

5. **Architect Agent - Tech Stack**
   - Recommend frontend framework (React, Vue, Angular, etc.)
   - Recommend backend language/framework (Rails, Django, Express, etc.)
   - Recommend database (PostgreSQL, MongoDB, etc.)
   - Recommend auth provider (Auth0, Clerk, Supabase, etc.)
   - Recommend hosting (Render, Vercel, Railway, etc.)
   - **Justify each choice** with reasoning

6. **Validator Agent - Quality Check**
   - Check for feature conflicts (e.g., real-time + static hosting)
   - Verify tech stack completeness (all 5 components)
   - Validate acceptance criteria exist for features
   - Check industry compliance (HIPAA, PCI-DSS, etc.)
   - Calculate confidence score

7. **Confidence Check**
   - Must reach **95%** to proceed
   - If below 95%: Show gaps, ask targeted questions
   - If blockers exist: Show resolution steps

8. **GitHub Setup Offer**
   - Once 95% reached, offer to run `forge setup-repo`

### Import-PRD Workflow

**Command**: `forge import <project-name> <prd-file>`

**Steps**:

1. **Initialization**
   - Create project directory: `/c/Users/User/AI/Projects/<project-name>/`
   - Copy existing PRD to `prd.md`

2. **Validator Agent - Parsing**
   - Parse existing PRD structure
   - Map to Forge deliverables:
     - Problem Statement
     - User Personas
     - User Stories
     - Feature List
     - Tech Stack
     - Success Metrics
     - MVP Scope
     - Non-Functional Requirements

3. **Gap Analysis**
   - Calculate confidence score for existing content
   - Identify missing deliverables
   - Identify incomplete sections

4. **Targeted Questioning**
   - Ask ONLY about missing items
   - Fill gaps to reach 95%

5. **Validator Agent - Quality Check**
   - Same as from-scratch workflow (conflicts, completeness, clarity)

6. **Confidence Check**
   - Must reach 95% to proceed

7. **GitHub Setup Offer**
   - Once 95% reached, offer to run `forge setup-repo`

---

## Agent System

### Analyst Agent

**Role**: Problem space expert (BMAD-inspired)

**Focus**:
- Problem statement
- Target users
- Market opportunity
- Success criteria
- Competitive analysis

**Outputs**:
- Clear problem statement (10% weight)
- Defined target personas
- Success metrics (15% weight)
- Market context

**Thinking Mode**: Extended reasoning for complex problems

**Question Style**:
- Open-ended: "What problem does this solve?"
- Specific: "Who are the target users? (demographics, goals, pain points)"
- Example-driven: Shows good vs bad answers

### PM Agent

**Role**: User stories & personas specialist (BMAD-inspired)

**Focus**:
- User personas (minimum 2)
- Agile user stories
- MVP scope definition
- Feature prioritization (MoSCoW)

**Outputs**:
- User personas (7% weight)
- User stories in Agile format (5% weight)
- MVP scope (15% weight)
- Priority levels: Must/Should/Could/Won't-Have

**Question Style**:
- Persona-focused: "What are their goals and pain points?"
- Story-driven: "What do users need to accomplish?"
- Prioritization: "What's essential for v1 launch?"

### Architect Agent

**Role**: Tech stack advisor

**Focus**:
- Frontend framework
- Backend language/framework
- Database type
- Authentication provider
- Hosting/deployment platform

**Outputs**:
- Complete tech stack (20% weight)
- Reasoning for each choice
- Third-party integrations
- Non-functional requirements (3% weight)

**Decision Factors**:
- Team expertise
- Project requirements (real-time, static, etc.)
- Scalability needs
- Budget constraints
- Time to market

**Question Style**:
- Constraint-focused: "Do you have team expertise in any frameworks?"
- Requirement-driven: "Do you need real-time features? Offline-first?"
- Trade-off discussions: "Fast launch vs long-term maintainability?"

### Validator Agent

**Role**: PRD validation specialist

**Focus**:
- Completeness check
- Conflict detection
- Clarity verification
- Industry compliance

**Checks**:
1. **Tech Stack Completeness**: All 5 components defined (frontend, backend, database, auth, hosting)
2. **Feature Conflicts**: E.g., real-time + static hosting, offline-first + SSR
3. **Feature Clarity**: Acceptance criteria exist, features specific
4. **Industry Compliance**: HIPAA (healthcare), PCI-DSS (fintech/e-commerce), GDPR
5. **Overall Confidence**: Weighted score ≥ 95%

**Outputs**:
- Validation report (Unicode/ASCII format)
- List of blockers with resolution steps
- List of warnings (non-blocking)
- Next steps to reach 95%

---

## Confidence Calculation

### Formula

```
Confidence = Σ (Deliverable_Completion × Weight)
```

### Weights

| Deliverable | Weight | Rationale |
|------------|--------|-----------|
| Feature List | 25% | Core product definition |
| Tech Stack | 20% | Blocks architecture phase |
| Success Metrics | 15% | Defines "done" |
| MVP Scope | 15% | v1 vs v2+ clarity |
| Problem Statement | 10% | Foundation for decisions |
| User Personas | 7% | Drives UX decisions |
| User Stories | 5% | Implementation guidance |
| Non-Functional Reqs | 3% | Important but often deferred |

### Completion Scoring

Each deliverable scored 0-100%:
- **0%**: Not started
- **25%**: Vague/placeholder text exists
- **50%**: Partially complete with gaps
- **75%**: Mostly complete, minor clarification needed
- **100%**: Fully specified and validated

### Example Calculation

```
Project: Fitness Tracking App

✅ Feature List (100%) × 0.25 = 25.00%
✅ Tech Stack (100%) × 0.20 = 20.00%
⚠️  Success Metrics (75%) × 0.15 = 11.25%
⚠️  MVP Scope (50%) × 0.15 = 7.50%
✅ Problem Statement (100%) × 0.10 = 10.00%
⚠️  User Personas (75%) × 0.07 = 5.25%
❌ User Stories (0%) × 0.05 = 0.00%
⚠️  Non-Functional (50%) × 0.03 = 1.50%
─────────────────────────────────────
Total Confidence: 80.50%

🚨 Cannot proceed (minimum 95% required)

To reach 95%:
1. Complete User Stories (+5.00%) → 85.50%
2. Complete MVP Scope (+7.50%) → 93.00%
3. Complete Success Metrics (+3.75%) → 96.75% ✅
```

### Industry-Specific Weights

For regulated industries, add:

**Healthcare**:
```
+ HIPAA Compliance Plan: 5%
+ EHR Integration Spec: 3%
+ Data Privacy Policy: 2%
(Reduces other weights proportionally)
```

**Fintech**:
```
+ PCI-DSS Compliance: 5%
+ Financial Regulations: 3%
+ Security Audit Plan: 2%
```

**E-commerce**:
```
+ PCI-DSS Compliance: 5%
+ GDPR/Privacy Policy: 3%
```

---

## Validation System

### Hard Blocks (Critical)

**Cannot proceed if any exist.**

#### 1. Missing Tech Stack
**Condition**: `tech_stack_completion < 100%`

**Why Blocks**:
- Architecture phase requires complete stack
- Cannot design without knowing:
  - Frontend framework
  - Backend language/framework
  - Database type
  - Auth provider
  - Hosting platform

**Resolution**: Complete all 5 tech stack components

#### 2. Conflicting Features
**Condition**: `feature_conflicts_detected > 0`

**Examples**:
- Real-time collaboration + Static site hosting
- Offline-first + Server-side rendering
- Complex data processing + Serverless architecture

**Resolution**: Choose one approach, document why alternative was rejected

#### 3. Low Confidence
**Condition**: `overall_confidence < 95%`

**Why Blocks**:
- PRD too vague for implementation
- High risk of rework and scope creep

**Resolution**: See `forge status` for specific gaps

#### 4. Vague Features
**Condition**: `feature_list_completion < 75%`

**Examples**:
- ❌ Vague: "User dashboard"
- ✅ Specific: "User dashboard showing: workout history (last 30 days), progress charts, upcoming workouts, personal records"

**Resolution**: Add acceptance criteria to each feature

#### 5. Missing Compliance
**Condition**: `industry_compliance_required && compliance_plan_missing`

**Industries**:
- Healthcare: HIPAA, PHI handling, encryption
- Fintech: PCI-DSS, financial regulations, security audit
- E-commerce: PCI-DSS, GDPR

**Resolution**: Add industry-specific compliance deliverables

### Warnings (Non-Blocking)

**System warns but does not block if overall confidence ≥ 95%.**

#### 1. Unclear MVP Scope
**Condition**: `mvp_scope_completion < 75%`

**Risk**: Scope creep, delayed launch

**Resolution**: Define what's in v1 vs v2+

#### 2. Missing Success Metrics
**Condition**: `success_metrics_completion < 75%`

**Risk**: No clear definition of "success"

**Resolution**: Define 3-5 KPIs with targets

---

## GitHub Integration

### Setup (forge setup-repo)

**Prerequisites**:
- PRD confidence ≥ 95%
- GitHub CLI (`gh`) installed and authenticated

**Creates**:
1. `.github/workflows/ci.yml` - CI/CD pipeline
2. `.github/ISSUE_TEMPLATE/` - Feature, bug, enhancement templates
3. `.github/PULL_REQUEST_TEMPLATE.md` - PR template
4. `scratchpads/` - Claude planning directory
5. `.gitignore` - Framework-specific
6. `README.md` - Auto-generated from PRD

### Issue Generation (forge generate-issues)

**Converts PRD features → GitHub issues:**

**Input** (from prd.md):
```markdown
### Must-Have (MVP)

1. **Workout Logging**
   - Users can log workouts with exercises, sets, reps, weight
   - Acceptance Criteria:
     - [ ] Form with exercise selection
     - [ ] Fields for sets, reps, weight
     - [ ] Save to database
     - [ ] Display in workout history
```

**Output** (GitHub issue):
```markdown
Title: Workout Logging Interface

Description:
Users need ability to log workouts with exercises, sets, reps, and weight.

Acceptance Criteria:
- [ ] Form with exercise selection dropdown
- [ ] Input fields for sets (number), reps (number), weight (number)
- [ ] Save button stores to database
- [ ] Confirmation message on successful save
- [ ] New workout appears in history view

Related Issues: #4 (Exercise Database)
Priority: Must-Have (MVP)
```

### Issue Processing Workflow (forge issue <N>)

Based on **GitHub Flow** + **Software Development Life Cycle**.

#### Phase 1: Plan

**Steps**:
1. Fetch issue from GitHub via `gh issue view <N>`
2. Search `scratchpads/` for related prior work
3. Search previous PRs for context: `gh pr list --search "in:title workout"`
4. Use extended reasoning ("think harder" mode)
5. Break issue into atomic tasks
6. Write plan to `scratchpads/issue-<N>-plan.md`:
   ```markdown
   # Plan for Issue #3: Workout Logging Interface

   ## Context
   - Related to Issue #4 (Exercise Database)
   - Previous work: PR #2 (User Auth)

   ## Atomic Tasks
   1. Create WorkoutForm component
   2. Add exercise dropdown (fetches from Exercise DB)
   3. Add input fields: sets (number), reps (number), weight (number)
   4. Create POST /api/workouts endpoint
   5. Add database migration for workouts table
   6. Create Workout model with validations
   7. Add success confirmation UI
   8. Update WorkoutHistory component to display new workouts
   9. Write tests for WorkoutForm component
   10. Write tests for POST /api/workouts endpoint

   ## Estimated Time: 2-3 hours
   ```

#### Phase 2: Create

**Steps**:
1. Create new branch: `git checkout -b feat/workout-logging`
2. Implement code changes from plan
3. Follow framework best practices
4. Keep changes focused on issue scope

#### Phase 3: Test

**Steps**:
1. Run test suite: `npm test` / `rails test` / `pytest`
2. Add tests for new functionality
3. Use Puppeteer for UI testing (if UI changes)
4. Verify all acceptance criteria met

#### Phase 4: Deploy

**Steps**:
1. Commit changes: `git add . && git commit -m "feat: add workout logging interface (#3)"`
2. Push branch: `git push -u origin feat/workout-logging`
3. Open PR: `gh pr create --title "Add workout logging interface" --body "Closes #3"`
4. CI/CD runs automatically (tests + linter)
5. Review PR (human or separate Claude session)
6. Merge if tests pass and review approves
7. Delete branch: `git branch -d feat/workout-logging`

#### Phase 5: Clean Context

**CRITICAL**:
```bash
# In Claude Code:
/clear  # Wipes entire context window
```

**Why?**
- Prevents context pollution
- Next issue works from cold start
- Better results, fewer tokens

### PR Review (forge review-pr <N>)

**IMPORTANT**: Run in **NEW shell** (separate from issue processing).

**Steps**:
1. Open fresh Claude Code session
2. Fetch PR: `gh pr view <N>`
3. Review code changes
4. Leave comments: `gh pr comment <N> --body "Suggestion: ..."`
5. Approve or request changes: `gh pr review <N> --approve`

**Review Style**: Can specify (e.g., "Sandy Mets style" - maintainability focus)

---

## Display Modes

### Unicode Mode (Claude Code)

**Uses**: Box-drawing characters, Unicode icons

**Example**:
```
╔═══════════════════════════════════════════════════════════╗
║         FORGE PRD CONFIDENCE TRACKER - Fitness App        ║
╚═══════════════════════════════════════════════════════════╝

Overall: 80.50% ▓▓▓▓▓▓▓▓░░ │ Target: 95% │ Gap: -14.50%

┌────────────────────────────┬──────┬────────┬──────────────┐
│ Deliverable                │Weight│ Status │ Contribution │
├────────────────────────────┼──────┼────────┼──────────────┤
│ ✅ Feature List            │ 25%  │ 100%   │ 25.00%       │
│ ⚠️  Success Metrics        │ 15%  │  75%   │ 11.25%       │
└────────────────────────────┴──────┴────────┴──────────────┘
```

**Icons**: ✅ ❌ ⚠️ 🚨 📊 🔍 💡
**Progress**: ▓▓▓▓▓▓▓░░░

### ASCII Mode (Codex)

**Uses**: Standard characters for compatibility

**Example**:
```
===============================================================
         FORGE PRD CONFIDENCE TRACKER - Fitness App
===============================================================

Overall: 80.50% [########--] | Target: 95% | Gap: -14.50%

--------------------------------------------------------------
 Deliverable            | Weight | Status | Contribution
--------------------------------------------------------------
 [OK] Feature List      |   25%  |  100%  |   25.00%
 [!!] Success Metrics   |   15%  |   75%  |   11.25%
--------------------------------------------------------------
```

**Markers**: [OK] [XX] [!!] [>>]
**Progress**: [#######---]

### Auto-Detection

```javascript
function detectEnvironment() {
  const isClaudeCode = process.env.CLAUDE_CODE === 'true';
  const isCodex = process.env.CODEX === 'true';
  const terminalSupportsUnicode = process.env.LANG?.includes('UTF-8');

  if (isClaudeCode || terminalSupportsUnicode) {
    return 'unicode';
  }
  return 'ascii';
}
```

---

## Configuration

### Default Settings

Located in `forge.md`:

```yaml
confidence_threshold: 95
project_storage: /c/Users/User/AI/Projects/
rendering_mode: auto  # unicode, ascii, or auto-detect
thinking_mode: think_harder  # think_hard, think_harder, think_hardest, ultrathink
```

### Industry Detection

System auto-detects project type based on keywords:

| Industry | Keywords | Additional Deliverables |
|----------|----------|------------------------|
| SaaS | subscription, user management, dashboard | None |
| E-commerce | products, cart, checkout, payment | PCI-DSS (5%), GDPR (3%) |
| Fintech | transactions, accounts, payments, compliance | PCI-DSS (5%), Financial Regs (3%), Security (2%) |
| Healthcare | patients, PHI, HIPAA, medical | HIPAA (5%), EHR (3%), Privacy (2%) |
| Marketplace | buyers, sellers, listings, escrow | PCI-DSS (5%), GDPR (3%) |

### Customization

To customize for your workflow:

1. **Edit weights**: `core/validation/confidence-weights.json`
2. **Add questions**: `lib/questions/<industry>.json`
3. **Add deliverables**: `lib/deliverables/<industry>.json`
4. **Modify agents**: `agents/<agent>.md`
5. **Customize templates**: `core/templates/<template>.md`

---

## Best Practices

### 1. Planning Phase

**Spend time upfront on detailed specs:**
- Break features into acceptance criteria
- Be specific about data, UI, behavior
- Define success metrics clearly
- Prioritize ruthlessly (MVP vs v2+)

**"Manager mindset":**
- Write detailed specs (not code)
- Review AI-generated code
- Leave comments like "Not quite right, try again"
- Approve/reject merges

### 2. Issue Quality

**Atomic issues:**
- ✅ Single, focused task
- ✅ 2-4 hours of work
- ✅ Can be completed independently
- ❌ Multiple unrelated changes

**Specific acceptance criteria:**
- ✅ "Display last 30 days of workouts in table format"
- ❌ "Show workout history"

### 3. Testing

**Setup before features:**
- Test framework (RSpec, Jest, pytest)
- CI/CD (GitHub Actions)
- Puppeteer for UI testing

**Not aiming for 100% coverage:**
- High confidence that changes don't break existing features
- Tests for critical paths
- UI tests for key user flows

### 4. Context Management

**Clear context after each PR:**
```bash
# In Claude Code:
/clear
```

**Why?**
- Prevents context pollution
- Forces issues to be self-contained
- Better results, fewer tokens

### 5. PR Review

**Human involvement:**
- **Always** review PRs before merging
- Reading code is YOUR responsibility
- Can delegate to separate Claude session (fresh shell)
- But final merge decision is human

**Review for:**
- Correctness (does it solve the issue?)
- Maintainability (is it readable?)
- Test coverage (are critical paths tested?)
- Performance (any obvious issues?)

---

## Next Steps

- **Quick Start**: See `quick-start.md`
- **Command Reference**: See `COMMANDS.md`
- **Agent Details**: See `agent-behaviors.md`
- **GitHub Workflow**: See `github-workflow.md`
- **Troubleshooting**: See `troubleshooting.md`

---

**Generated by Forge v1.0**
