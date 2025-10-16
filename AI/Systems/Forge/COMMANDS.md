# Forge Command Reference

Complete list of all Forge commands with descriptions, usage, and examples.

---

## Core Commands

### `forge start <project-name>`
**Purpose**: Create a new project from scratch
**Workflow**: from-scratch.md
**Agents**: Analyst → PM → Architect → Validator

**What it does**:
1. Creates project directory at `/c/Users/User/AI/Projects/<project-name>/`
2. Initializes empty `prd.md` file
3. Launches Analyst Agent for discovery questions
4. Iteratively builds PRD through questioning
5. Tracks confidence score (target: 95%)
6. Validates completeness and blocks if issues found

**Usage**:
```bash
forge start fitness-tracker
forge start saas-dashboard
forge start ecommerce-platform
```

**Example Output**:
```
╔═══════════════════════════════════════════════════════════╗
║               FORGE v1.0 - AI Dev System                 ║
╚═══════════════════════════════════════════════════════════╝

ℹ️  Starting new project: fitness-tracker

ℹ️  Creating project directory: C:\Users\User\AI\Projects\fitness-tracker
✅ Project created at: C:\Users\User\AI\Projects\fitness-tracker

ℹ️  Next: Answer discovery questions to build your PRD

Analyst Agent will now ask questions to understand your project...
```

**Autocomplete**: Yes (project name is free text)

---

### `forge import <project-name> <prd-file>`
**Purpose**: Import existing PRD for validation
**Workflow**: import-prd.md
**Agents**: Validator → Analyst/PM/Architect (gap filling)

**What it does**:
1. Creates project directory at `/c/Users/User/AI/Projects/<project-name>/`
2. Copies existing PRD file to project
3. Validator Agent analyzes PRD structure
4. Calculates initial confidence score
5. Identifies missing deliverables
6. Asks targeted questions to fill gaps
7. Validates completeness and blocks if issues found

**Usage**:
```bash
forge import fitness-tracker ./my-prd.md
forge import saas-dashboard C:\Documents\requirements.md
forge import ecommerce "C:\Path With Spaces\prd.md"
```

**Example Output**:
```
ℹ️  Importing PRD for project: fitness-tracker

✅ Project created at: C:\Users\User\AI\Projects\fitness-tracker

ℹ️  Validator Agent will now analyze your PRD...

📊 Initial Confidence: 67%
⚠️  Missing: Tech Stack (0%), MVP Scope (50%)
```

**Autocomplete**: Yes (project name + file path)

---

### `forge status`
**Purpose**: Show confidence breakdown and progress
**Context**: Must run from project directory

**What it does**:
1. Finds `prd.md` in current or parent directory
2. Calculates weighted confidence score
3. Shows deliverable completion breakdown
4. Lists blockers and warnings
5. Provides next steps to reach 95%

**Usage**:
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge status
```

**Example Output**:
```
╔═══════════════════════════════════════════════════════════╗
║         FORGE PRD CONFIDENCE TRACKER - Fitness App        ║
╚═══════════════════════════════════════════════════════════╝

Overall: 80.50% ▓▓▓▓▓▓▓▓░░ │ Target: 95% │ Gap: -14.50%

┌────────────────────────────┬──────┬────────┬──────────────┐
│ Deliverable                │Weight│ Status │ Contribution │
├────────────────────────────┼──────┼────────┼──────────────┤
│ ✅ Feature List            │ 25%  │ 100%   │ 25.00%       │
│ ✅ Tech Stack              │ 20%  │ 100%   │ 20.00%       │
│ ⚠️  Success Metrics        │ 15%  │  75%   │ 11.25%       │
│ ⚠️  MVP Scope              │ 15%  │  50%   │  7.50%       │
│ ✅ Problem Statement       │ 10%  │ 100%   │ 10.00%       │
│ ⚠️  User Personas          │  7%  │  75%   │  5.25%       │
│ ❌ User Stories            │  5%  │   0%   │  0.00%       │
│ ⚠️  Non-Functional Reqs    │  3%  │  50%   │  1.50%       │
└────────────────────────────┴──────┴────────┴──────────────┘

┌─ Next Steps to 95% ───────────────────────────────────────┐
│ Priority 1: Complete User Stories (+5.00%) → 85.50%       │
│ Priority 2: Complete MVP Scope (+7.50%) → 93.00%          │
│ Priority 3: Complete Success Metrics (+3.75%) → 96.75% ✅ │
└────────────────────────────────────────────────────────────┘

🚨 Hard Blocks: None │ ✅ Ready to proceed once 95% reached
```

**Autocomplete**: Yes (no arguments)

---

### `forge show <section>`
**Purpose**: Expand section details (less scrolling, show on demand)
**Context**: Must run from project directory

**Arguments**:
- `explicit` - Show explicitly mentioned features
- `implied` - Show system-inferred features
- `blockers` - Show all blockers with resolution steps
- `deliverables` - Show all deliverable details
- `all` - Show everything

**Usage**:
```bash
forge show explicit
forge show blockers
forge show deliverables
```

**Example Output** (forge show blockers):
```
╔═══════════════════════════════════════════════════════════╗
║                     🚨 CRITICAL BLOCKERS                  ║
╚═══════════════════════════════════════════════════════════╝

┌─ BLOCKER #1: Features Too Vague ──────────────────────────┐
│                                                            │
│ Reason: Cannot build without clear feature definitions.   │
│         Acceptance criteria missing or incomplete.        │
│                                                            │
│ Examples of vague features:                                │
│ ❌ "User dashboard"                                        │
│ ✅ "User dashboard showing: workout history (last 30      │
│    days), progress charts, upcoming workouts, PRs"        │
│                                                            │
│ Resolution: Add acceptance criteria to each feature       │
│                                                            │
│ Agent: analyst                                             │
└────────────────────────────────────────────────────────────┘
```

**Autocomplete**: Yes (section argument with predefined options)

---

## GitHub Commands

### `forge setup-repo <project-name>`
**Purpose**: Create GitHub repository with complete foundation
**Prerequisites**: PRD must be at 95%+ confidence

**What it does**:
1. Checks PRD confidence (must be 95%+)
2. Copies `.github/workflows/ci.yml` (CI/CD)
3. Copies `.github/ISSUE_TEMPLATE/` (feature, bug, enhancement)
4. Copies `.github/PULL_REQUEST_TEMPLATE.md`
5. Creates `scratchpads/` directory for Claude planning
6. Copies `.gitignore` template (framework-specific)
7. Generates `README.md` from PRD
8. Shows git init commands to run

**Usage**:
```bash
forge setup-repo fitness-tracker
```

**Example Output**:
```
ℹ️  Setting up GitHub repository for: fitness-tracker

ℹ️  Checking PRD confidence...
✅ PRD confidence: 96.75% (meets 95% threshold)

ℹ️  Copying GitHub foundation templates...
✅ GitHub foundation templates copied

ℹ️  Next: Initialize git repository

  cd C:\Users\User\AI\Projects\fitness-tracker
  git init
  gh repo create fitness-tracker --private --source=. --remote=origin
  git add .
  git commit -m "Initial commit from Forge"
  git push -u origin main
```

**Files Created**:
```
project/
├─ .github/
│  ├─ workflows/ci.yml
│  ├─ ISSUE_TEMPLATE/
│  │  ├─ feature.md
│  │  ├─ bug.md
│  │  └─ enhancement.md
│  └─ PULL_REQUEST_TEMPLATE.md
├─ scratchpads/
├─ .gitignore
└─ README.md
```

**Autocomplete**: Yes (project name)

---

### `forge generate-issues`
**Purpose**: Convert PRD features into atomic GitHub issues
**Context**: Must run from project directory with GitHub repo

**What it does**:
1. Parses `prd.md` in current directory
2. Extracts all features from "Must-Have (MVP)" section
3. Breaks complex features into atomic issues
4. Creates GitHub issues via `gh` CLI
5. Labels issues by priority (Must/Should/Could)
6. Links related issues
7. Includes acceptance criteria from PRD

**Usage**:
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge generate-issues
```

**Example Output**:
```
ℹ️  Generating GitHub issues from PRD...

ℹ️  Parsing PRD: C:\Users\User\AI\Projects\fitness-tracker\prd.md
ℹ️  Converting features to atomic issues...

Found 12 features in PRD:
  • 8 Must-Have (MVP)
  • 3 Should-Have (Post-MVP)
  • 1 Could-Have (Future)

Creating GitHub issues for 8 MVP features...

✅ Issue #1: Setup test suite and CI/CD
✅ Issue #2: User authentication with OAuth
✅ Issue #3: Workout logging interface
✅ Issue #4: Exercise database with search
✅ Issue #5: Progress tracking charts
✅ Issue #6: Trainer oversight dashboard
✅ Issue #7: User profile management
✅ Issue #8: Mobile responsive design

✅ Created 8 issues successfully

ℹ️  Next: Process issues with forge issue <number>
```

**Autocomplete**: Yes (no arguments)

---

### `forge issue <number>`
**Purpose**: Process GitHub issue (Plan → Create → Test → Deploy)
**Context**: Must run from project directory with GitHub repo
**Workflow**: GitHub Flow (branch → commit → PR → review → merge)

**What it does**:
1. **Plan Phase**:
   - Fetches issue from GitHub via `gh` CLI
   - Searches `scratchpads/` for related prior work
   - Searches previous PRs for context
   - Uses extended reasoning ("think harder" mode)
   - Breaks issue into atomic tasks
   - Writes plan to `scratchpads/issue-<number>-plan.md`

2. **Create Phase**:
   - Implements code changes
   - Follows framework best practices
   - Keeps changes focused on issue scope

3. **Test Phase**:
   - Runs test suite to verify no breakage
   - Adds tests for new functionality
   - Uses Puppeteer for UI testing (if applicable)
   - Verifies acceptance criteria met

4. **Deploy Phase**:
   - Commits changes with descriptive message
   - Opens pull request with PR template
   - CI/CD runs tests + linter
   - Waits for review

**Usage**:
```bash
forge issue 42
forge issue 1
```

**Example Output**:
```
ℹ️  Processing GitHub issue #42

Phase 1: PLAN
  • Fetching issue from GitHub via gh CLI...
  • Searching scratchpads for related work...
  • Searching previous PRs for context...
  • Using extended reasoning (think harder mode)...
  • Breaking issue into atomic tasks...
  • Writing plan to scratchpad...

Phase 2: CREATE
  • Implementing code changes...

Phase 3: TEST
  • Running test suite...
  • Adding tests for new functionality...

Phase 4: DEPLOY
  • Committing changes...
  • Opening pull request...

⚠️  Remember to run /clear after merge to prevent context pollution
```

**Important**: Run `/clear` in Claude Code after merging PR to prevent context pollution.

**Autocomplete**: Yes (issue number)

---

### `forge review-pr <number>`
**Purpose**: Review pull request in fresh context
**Context**: Run in NEW shell (separate from issue processing)

**What it does**:
1. Opens fresh Claude Code session (no context pollution)
2. Fetches PR from GitHub via `gh` CLI
3. Reviews code changes
4. Leaves comments on PR
5. Suggests improvements
6. Checks for maintainability issues

**Usage**:
```bash
# In a NEW shell/terminal
forge review-pr 42
```

**Example Output**:
```
ℹ️  Reviewing pull request #42

⚠️  Run this in a FRESH shell to avoid context pollution

Fetching PR from GitHub via gh CLI...
```

**Important**: Must run in completely fresh shell to avoid context pollution from issue processing.

**Autocomplete**: Yes (PR number)

---

### `forge test`
**Purpose**: Run test suite
**Context**: Must run from project directory
**Auto-detects**: Rails, Node.js, Python

**What it does**:
1. Detects project framework (Rails, Node, Python, etc.)
2. Runs appropriate test command
3. Shows test results

**Framework Detection**:
- **Rails**: Detects `Gemfile` → runs `rails test`
- **Node.js**: Detects `package.json` → runs `npm test`
- **Python**: Detects `requirements.txt` or `pyproject.toml` → runs `pytest`

**Usage**:
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge test
```

**Example Output** (Rails):
```
ℹ️  Running test suite...

Detected Rails project. Running: rails test

Run options: --seed 12345

# Running:

....................

Finished in 2.345678s, 8.5254 runs/s, 12.7881 assertions/s.
20 runs, 30 assertions, 0 failures, 0 errors, 0 skips
```

**Autocomplete**: Yes (no arguments)

---

### `forge deploy`
**Purpose**: Check deployment status
**Context**: Must run from project directory with GitHub repo

**What it does**:
1. Checks CI/CD status via `gh` CLI
2. Shows last 5 workflow runs
3. Shows deployment status

**Usage**:
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge deploy
```

**Example Output**:
```
ℹ️  Checking deployment status...

Checking CI/CD status via gh CLI...

STATUS  NAME        WORKFLOW   BRANCH  EVENT  ID
✓       CI          CI/CD      main    push   123456789
✓       CI          CI/CD      feat-42 push   123456788
✗       CI          CI/CD      fix-10  push   123456787
✓       CI          CI/CD      main    push   123456786
✓       CI          CI/CD      main    push   123456785
```

**Autocomplete**: Yes (no arguments)

---

## Utility Commands

### `forge fix <blocker>`
**Purpose**: Get detailed guidance for specific blocker

**Arguments**:
- `missing_tech_stack` - Tech stack incomplete
- `conflicting_features` - Contradictory requirements
- `low_confidence` - Confidence below 95%
- `vague_features` - Acceptance criteria missing
- `missing_compliance` - Industry compliance not addressed

**Usage**:
```bash
forge fix missing_tech_stack
forge fix vague_features
forge fix conflicting_features
```

**Example Output** (forge fix vague_features):
```
ℹ️  Getting guidance for: vague_features

🚨 CRITICAL: Features Too Vague

Reason: Cannot build without clear feature definitions.
        Acceptance criteria missing or incomplete.

Examples:
❌ Vague: "User dashboard"
✅ Specific: "User dashboard showing: workout history (last 30 days),
              progress charts (weight/reps over time), upcoming
              scheduled workouts, personal records"

❌ Vague: "Payment system"
✅ Specific: "Stripe integration for: monthly subscriptions ($9.99/mo),
              annual plans ($99/year with 2 months free), payment
              method management, invoice history"

Resolution:
1. Add acceptance criteria to each feature
2. Define what "done" looks like
3. Be specific about data, UI, and behavior

Agent: analyst
```

**Autocomplete**: Yes (blocker argument with predefined options)

---

### `forge export`
**Purpose**: Export PRD as markdown
**Context**: Must run from project directory

**What it does**:
1. Finds `prd.md` in current directory
2. Creates timestamped export file
3. Saves to current directory

**Usage**:
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge export
```

**Example Output**:
```
ℹ️  Exporting PRD as markdown...

✅ PRD exported to: C:\Users\User\AI\Projects\fitness-tracker\prd-export-20250110-143022.md
```

**Autocomplete**: Yes (no arguments)

---

### `forge help`
**Purpose**: Show command reference
**Output**: Lists all commands with brief descriptions

**Usage**:
```bash
forge help
```

**Autocomplete**: Yes (no arguments)

---

### `forge version`
**Purpose**: Show Forge version and location

**Usage**:
```bash
forge version
```

**Example Output**:
```
╔═══════════════════════════════════════════════════════════╗
║               FORGE v1.0 - AI Dev System                 ║
╚═══════════════════════════════════════════════════════════╝

Forge System v1.0
Location: C:\Users\User\AI\Systems\Forge
```

**Autocomplete**: Yes (no arguments)

---

## Command Summary Table

| Command | Arguments | Context | Autocomplete |
|---------|-----------|---------|--------------|
| `forge start` | `<name>` | Any | Yes |
| `forge import` | `<name> <file>` | Any | Yes |
| `forge status` | None | Project dir | Yes |
| `forge show` | `<section>` | Project dir | Yes |
| `forge setup-repo` | `<name>` | Any | Yes |
| `forge generate-issues` | None | Project dir + GitHub | Yes |
| `forge issue` | `<number>` | Project dir + GitHub | Yes |
| `forge review-pr` | `<number>` | Project dir + GitHub | Yes |
| `forge test` | None | Project dir | Yes |
| `forge deploy` | None | Project dir + GitHub | Yes |
| `forge fix` | `<blocker>` | Any | Yes |
| `forge export` | None | Project dir | Yes |
| `forge help` | None | Any | Yes |
| `forge version` | None | Any | Yes |

---

## Setup Instructions

### Windows PowerShell

1. Add Forge to PATH:
   ```powershell
   $env:Path += ";C:\Users\User\AI\Systems\Forge\scripts"
   ```

2. Make permanent (add to PowerShell profile):
   ```powershell
   notepad $PROFILE
   # Add this line:
   Set-Alias forge "C:\Users\User\AI\Systems\Forge\scripts\forge.ps1"
   ```

3. Reload profile:
   ```powershell
   . $PROFILE
   ```

### Warp Terminal (Autocomplete)

1. Copy completion spec:
   ```bash
   cp C:\Users\User\AI\Systems\Forge\scripts\warp-completion.ts ~/.warp/completion_specs/
   ```

2. Restart Warp terminal

3. Type `forge ` and press TAB to see autocomplete

---

## Common Workflows

### Workflow 1: Start from Scratch → GitHub → Development

```bash
# Step 1: Start project
forge start fitness-tracker

# Answer discovery questions...
# Continue until confidence reaches 95%

# Step 2: Setup GitHub repository
forge setup-repo fitness-tracker
cd C:\Users\User\AI\Projects\fitness-tracker
git init
gh repo create fitness-tracker --private --source=. --remote=origin
git add .
git commit -m "Initial commit from Forge"
git push -u origin main

# Step 3: Generate issues from PRD
forge generate-issues

# Step 4: Process first issue
forge issue 1
# In Claude Code: /clear after PR merged

# Step 5: Process next issue
forge issue 2
# Repeat...
```

### Workflow 2: Import Existing PRD → Validate → GitHub

```bash
# Step 1: Import PRD
forge import my-app C:\Documents\my-prd.md

# Answer gap-filling questions...
# Continue until confidence reaches 95%

# Step 2: Setup GitHub repository
forge setup-repo my-app
cd C:\Users\User\AI\Projects\my-app
git init
gh repo create my-app --private --source=. --remote=origin
git add .
git commit -m "Initial commit from Forge"
git push -u origin main

# Step 3: Generate issues from PRD
forge generate-issues

# Step 4: Process issues
forge issue 1
```

### Workflow 3: Check Status → Fix Blockers → Continue

```bash
# Check status
cd C:\Users\User\AI\Projects\fitness-tracker
forge status

# Shows: 80% confidence, blocker: vague_features

# Get guidance
forge fix vague_features

# Fix issues in PRD, then check again
forge status

# Now at 96% confidence, ready to proceed
forge setup-repo fitness-tracker
```

---

**Generated by Forge v1.0**
