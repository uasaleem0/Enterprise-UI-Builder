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
**Purpose**: Run test suite for the project or for the Forge system itself.
**Context**: Must run from project directory
**Auto-detects**: Rails, Node.js, Python, PowerShell (Pester)

**What it does**:
1. Detects project framework (Rails, Node, Python, etc.) or Forge system tests.
2. Runs appropriate test command.
3. Shows test results.

**Framework Detection**:
- **Rails**: Detects `Gemfile` → runs `rails test`
- **Node.js**: Detects `package.json` → runs `npm test`
- **Python**: Detects `requirements.txt` or `pyproject.toml` → runs `pytest`
- **Forge System**: Detects `*.Tests.ps1` files in `tests/` → runs `Invoke-Pester`

**Usage**:
```bash
# Run tests for a user project
cd C:\Users\User\AI\Projects\fitness-tracker
forge test

# Run tests for the Forge system itself
cd C:\Users\User\AI\Systems\Forge
forge test
```

**Example Output** (Pester):
```
ℹ️  Running test suite...

Detected Forge System tests. Running: Invoke-Pester

Tests completed in 78ms
Passed: 1, Failed: 0, Skipped: 0, Pending: 0, Inconclusive: 0
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

### `forge evolve-spec`
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

## Project Management Commands

### `forge delete-project` / `forge remove-project`
**Purpose**: Safely delete a Forge project with comprehensive validation
**Context**: Must run from within the project directory to delete
**Status**: ✅ FULLY IMPLEMENTED

**What it does**:
1. Verifies execution is within a valid project directory (contains `.forge-prd-state.json`)
2. Protects core Forge system from accidental deletion
3. Scans for system dependencies (symbolic links, config references)
4. Displays project information and deletion impact
5. Requires explicit confirmation (project name + "DELETE" keyword)
6. Creates automatic backup before deletion (unless `--NoBackup` specified)
7. Removes project directory and all files
8. Reports any system dependencies that need manual cleanup

**Safety Guardrails**:
- ✅ Must be run from within a project directory
- ✅ Cannot delete Forge system directory or its subdirectories
- ✅ Warns if project path doesn't match expected pattern (`\AI\Projects\`)
- ✅ Scans for symbolic links pointing to project
- ✅ Scans for config files referencing project
- ✅ Checks global state file for references
- ✅ Creates backup before deletion (stored in `Forge\.backups`)
- ✅ Requires two-step confirmation (project name + "DELETE")
- ✅ Can skip confirmation with `-Force` flag (still performs safety checks)

**Usage**:
```bash
# Basic usage (from within project directory)
cd C:\Users\User\AI\Projects\old-project
forge delete-project

# Delete with explicit path
forge delete-project -ProjectPath "C:\Users\User\AI\Projects\old-project"

# Skip confirmation (still performs safety checks)
forge delete-project -Force

# Skip backup creation (not recommended)
forge delete-project -NoBackup

# Combined flags
forge delete-project -Force -NoBackup
```

**Example Output**:
```
🔍 Scanning for system dependencies...
   ✅ No system dependencies found

╔════════════════════════════════════════════════════════════╗
║           PROJECT DELETION CONFIRMATION                   ║
╚════════════════════════════════════════════════════════════╝

Project Details:
  Name:       fitness-tracker-old
  Path:       C:\Users\User\AI\Projects\fitness-tracker-old
  Created:    2025-01-15 10:30:00
  Confidence: 45%

Deletion Impact:
  Files:      127 files
  Size:       15.3 MB
  Backup:     Will be created before deletion

⚠️  WARNING: This action cannot be undone!

To confirm deletion, type the project name exactly: fitness-tracker-old
> fitness-tracker-old

Are you absolutely sure? Type 'DELETE' to confirm:
> DELETE

📦 Creating backup...
   ✅ Backup created: C:\Users\User\AI\Systems\Forge\.backups\deleted-project-fitness-tracker-old-20251025-143022

🗑️  Deleting project...

✅ Project deleted successfully
   Path: C:\Users\User\AI\Projects\fitness-tracker-old

💾 Backup location: C:\Users\User\AI\Systems\Forge\.backups\deleted-project-fitness-tracker-old-20251025-143022
```

**Example with Dependencies**:
```
🔍 Scanning for system dependencies...

⚠️  WARNING: Found system dependencies

   Config files referencing this project:
     • C:\Users\User\AI\Systems\Forge\.forge-dev-log.json
     • C:\Users\User\.forge-state.json

   These dependencies will need manual cleanup after deletion.

[... rest of confirmation flow ...]

✅ Project deleted successfully

⚠️  Remember to clean up system dependencies manually
```

**Backup Contents**:
Each backup includes:
- Complete copy of project directory
- `.deletion-metadata.json` with:
  - Project name and original path
  - Deletion timestamp and user
  - Project state snapshot
  - List of detected dependencies

**Restoring from Backup**:
```bash
# Copy backup to new location
cp -r "C:\Users\User\AI\Systems\Forge\.backups\deleted-project-name-timestamp" "C:\Users\User\AI\Projects\restored-project"
```

**Important Notes**:
- You cannot delete the Forge system itself using this command
- Deletion is irreversible unless backup was created
- Use `-NoBackup` only if you're absolutely certain
- Dependencies in config files must be cleaned up manually
- Backups are stored indefinitely and should be cleaned periodically

**Related Commands**:
- `forge status` - Check project before deletion
- `forge show-prd` - Review project contents
- `forge export` - Export PRD before deletion

---

**Generated by Forge v1.0**
### `forge design-brief <type>`
Purpose: Start the design brief interview for the current project. Type can be any label (e.g., `website`, `app`, `dashboard`).

What it does:
1. Optionally previews IA context (if found)
2. Asks brief questions (who it’s for, feel, anti-patterns, color range, key features, inspiration)
3. Saves `design/aesthetic-brief.md`
4. Offers to proceed to Competitor Analysis

Usage:
```powershell
cd C:\Users\User\AI\Projects\my-app
forge design-brief website
```

---

### `forge design-ref <type> <url-or-path>`
Purpose: Add a single design reference directly to the living brief.

What it does:
1. Ensures `design/aesthetic-brief.md` exists
2. Appends under “Inspiration References”: `- [type] value`

Usage:
```powershell
forge design-ref website https://linear.app
forge design-ref image C:\shots\nike-hero.png
```

---

### `forge evolve-spec`
**Status**: ✅ FULLY IMPLEMENTED
**Purpose**: AI-guided PRD and IA evolution
**Context**: Must run from project directory

**What it does**:
1. Prompts for plain English change request
2. Analyzes impact using AI (OpenAI/Anthropic) or heuristics
3. Identifies PRD changes (features, scope, NFRs, KPIs)
4. Identifies IA changes (routes, flows, components, entities)
5. Shows detailed impact report
6. Requests user confirmation
7. Applies changes to PRD and IA files
8. Creates automatic backup
9. Rebuilds project semantic model
10. Recalculates confidence score

**Supports**:
- ✅ PRD modifications (features, scope, NFRs, KPIs, user stories)
- ✅ IA modifications (routes, flows, components, entities)
- ✅ Cross-document consistency validation
- ✅ Automatic project-model rebuild
- ✅ Semantic issue detection
- ✅ Heuristic fallback if AI unavailable
- ✅ Automatic backups

**Usage**:
```bash
cd /c/Users/User/AI/Projects/fitness-tracker
forge evolve-spec
# Interactive prompt appears

# With flags:
forge evolve-spec --no-ai    # Use heuristic analysis only
forge evolve-spec -y         # Skip confirmation prompt
forge evolve-spec --yes      # Skip confirmation prompt
```

**Example Session**:
```
=============================================================
          FORGE EVOLVE-SPEC - PRD/IA Evolution
=============================================================

What change would you like to make to your PRD/IA?
(Describe in plain English)

Change Request: Add a Programs feature that groups multiple workouts together

[INFO] Loading project state...
[INFO] Analyzing impact...
[OK] AI analysis complete

=============================================================
CHANGE IMPACT ANALYSIS
=============================================================

REQUEST:
  Add a Programs feature that groups multiple workouts together

DETECTED INTENT:
  Operation: add
  Target: feature
  Entity: Programs
  Scope: SHOULD

PRD MODIFICATIONS:

  Features to Add:
    + Programs [SHOULD]
      Programs enables grouping multiple workouts into training programs

  Non-Functional Requirements to Add:
    + [Performance] Programs should have optimal performance with <200ms response time

IA MODIFICATIONS:

  Routes to Add:
    + /programs
      Programs

  User Flows to Add:
    + Access Programs
      Steps: /dashboard -> /programs

  Components to Add:
    Route: /programs
      + ProgramsHeader
      + ProgramsContent
      + ProgramsActions

  Data Entities to Add:
    + Programs
      Fields: id, name, createdAt, updatedAt

CONFIDENCE IMPACT: +2.0%

=============================================================

Apply these changes? (y/n): y

[INFO] Applying changes...
[OK] Changes applied
[INFO] Rebuilding project model...
[OK] Project model rebuilt
[INFO] Recalculating confidence...
[OK] Confidence recalculated

=============================================================
CHANGES APPLIED
=============================================================

FILES MODIFIED:
  * prd.md
  * ia/sitemap.md
  * ia/flows.md
  * ia/components.md
  * ia/entities.md

BACKUP CREATED:
  .forge-backups/backup-evolve-20251023-162745

NEW CONFIDENCE SCORE: 87.5%

=============================================================

NEXT STEPS:
  forge status      # View updated status
  forge prd-report  # Review PRD

[OK] Evolution complete!
```

**Rollback**:
If changes need to be reverted, restore from backup:
```bash
cp .forge-backups/backup-evolve-20251023-162745/prd.md ./prd.md
cp -r .forge-backups/backup-evolve-20251023-162745/ia ./ia
forge status  # Verify restoration
```

**AI Configuration**:
Set environment variables or create `.forge-ai.json`:
```json
{
  "provider": "openai",
  "openai_api_key": "sk-...",
  "openai_model": "gpt-4o"
}
```

Or use Anthropic:
```json
{
  "provider": "anthropic",
  "anthropic_api_key": "sk-ant-...",
  "anthropic_model": "claude-3-5-sonnet-20241022"
}
```

**Notes**:
- Always creates backup before applying changes
- Falls back to heuristic analysis if AI fails
- Validates consistency between PRD and IA
- Automatically rebuilds semantic model
- Works with both PRD and IA simultaneously

---
