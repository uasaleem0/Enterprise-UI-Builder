# Forge Quick Start Guide

Get up and running with Forge in under 5 minutes.

---

## What is Forge?

Forge is an AI-powered system that transforms vague ideas into production-ready applications through:
1. **PRD Development** - Confidence-based requirements gathering (95% threshold)
2. **GitHub Foundation** - Automated repo setup with CI/CD and test infrastructure
3. **Issue Generation** - Convert PRD features into atomic, actionable GitHub issues
4. **Development Workflow** - Plan → Create → Test → Deploy cycle

---

## Prerequisites

### Required
- **PowerShell** (Windows) or **Bash** (Linux/Mac)
- **Git** - Version control
- **GitHub CLI** (`gh`) - For GitHub integration
  ```bash
  # Install gh CLI
  # Windows (Chocolatey):
  choco install gh

  # Mac (Homebrew):
  brew install gh

  # Then authenticate:
  gh auth login
  ```

### Optional
- **Warp Terminal** - For autocomplete support
- **Claude Code** - For issue processing workflows

---

## Installation

### 1. Clone/Download Forge

Forge is already installed at:
```
C:\Users\User\AI\Systems\Forge\
```

### 2. Add Forge to PATH

**Windows PowerShell:**
```powershell
# Temporary (current session only)
$env:Path += ";C:\Users\User\AI\Systems\Forge\scripts"

# Permanent (add to PowerShell profile)
notepad $PROFILE
# Add this line to the file:
Set-Alias forge "C:\Users\User\AI\Systems\Forge\scripts\forge.ps1"
# Save and reload:
. $PROFILE
```

**Linux/Mac Bash:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/c/Users/User/AI/Systems/Forge/scripts"
alias forge="pwsh /c/Users/User/AI/Systems/Forge/scripts/forge.ps1"
```

### 3. Verify Installation

```bash
forge version
```

Should output:
```
╔═══════════════════════════════════════════════════════════╗
║               FORGE v1.0 - AI Dev System                 ║
╚═══════════════════════════════════════════════════════════╝

Forge System v1.0
Location: C:\Users\User\AI\Systems\Forge
```

### 4. (Optional) Setup Warp Autocomplete

```bash
# Copy completion spec to Warp
cp C:\Users\User\AI\Systems\Forge\scripts\warp-completion.ts ~/.warp/completion_specs/forge.ts

# Restart Warp terminal
```

Now typing `forge ` and pressing TAB shows all commands with descriptions.

---

## Quick Start: 5-Minute Walkthrough

### Scenario: Building a Fitness Tracker App

#### Step 1: Start Project (1 minute)

```bash
forge start fitness-tracker
```

**What happens:**
- Creates `/c/Users/User/AI/Projects/fitness-tracker/`
- Initializes empty `prd.md` file
- Launches **Analyst Agent** for discovery

**Expected output:**
```
╔═══════════════════════════════════════════════════════════╗
║               FORGE v1.0 - AI Dev System                 ║
╚═══════════════════════════════════════════════════════════╝

ℹ️  Starting new project: fitness-tracker

✅ Project created at: C:\Users\User\AI\Projects\fitness-tracker

ℹ️  Next: Answer discovery questions to build your PRD

Analyst Agent will now ask questions to understand your project...
```

#### Step 2: Answer Discovery Questions (2-3 minutes)

Analyst Agent asks questions like:

```
╔═══════════════════════════════════════════════════════════╗
║              🤖 ANALYST AGENT - Discovery Phase           ║
╚═══════════════════════════════════════════════════════════╝

Progress: [█████░░░░░] Question 5/9 │ Confidence: 45% → 67%

┌─ Q5: Target Users ────────────────────────────────────────┐
│                                                            │
│ Who will use this fitness tracking app?                   │
│                                                            │
│ (Be specific: demographics, fitness level, goals)         │
│                                                            │
│ Examples:                                                  │
│ • "Gym-goers aged 25-40 training for strength"           │
│ • "Beginners looking for guided workout plans"            │
│ • "Personal trainers managing 10-50 clients"              │
│                                                            │
│ Your answer: ___________________________________________   │
│                                                            │
└────────────────────────────────────────────────────────────┘

💡 Impact: Affects User Personas (+7%), User Stories (+5%)
```

**You answer:**
```
"Gym-goers aged 25-40 training for strength, and personal trainers managing their clients"
```

**Continue answering questions until confidence reaches 95%.**

#### Step 3: Check Status (30 seconds)

```bash
cd C:\Users\User\AI\Projects\fitness-tracker
forge status
```

**Expected output:**
```
Overall: 96.75% ▓▓▓▓▓▓▓▓▓▓ │ Target: 95% │ ✅ READY

┌────────────────────────────┬──────┬────────┬──────────────┐
│ Deliverable                │Weight│ Status │ Contribution │
├────────────────────────────┼──────┼────────┼──────────────┤
│ ✅ Feature List            │ 25%  │ 100%   │ 25.00%       │
│ ✅ Tech Stack              │ 20%  │ 100%   │ 20.00%       │
│ ✅ Success Metrics         │ 15%  │ 100%   │ 15.00%       │
│ ✅ MVP Scope               │ 15%  │ 100%   │ 15.00%       │
│ ✅ Problem Statement       │ 10%  │ 100%   │ 10.00%       │
│ ✅ User Personas           │  7%  │ 100%   │  7.00%       │
│ ✅ User Stories            │  5%  │  80%   │  4.00%       │
│ ✅ Non-Functional Reqs     │  3%  │  75%   │  2.25%       │
└────────────────────────────┴──────┴────────┴──────────────┘

🚨 Hard Blocks: None │ ✅ Ready for GitHub setup
```

#### Step 4: Setup GitHub Repository (1 minute)

```bash
forge setup-repo fitness-tracker
```

**What happens:**
- Checks PRD confidence (must be 95%+)
- Copies GitHub foundation templates (CI/CD, issue templates, PR template)
- Creates `scratchpads/` directory
- Generates `README.md` from PRD

**Expected output:**
```
ℹ️  Setting up GitHub repository for: fitness-tracker

✅ PRD confidence: 96.75% (meets 95% threshold)
✅ GitHub foundation templates copied

ℹ️  Next: Initialize git repository

  cd C:\Users\User\AI\Projects\fitness-tracker
  git init
  gh repo create fitness-tracker --private --source=. --remote=origin
  git add .
  git commit -m "Initial commit from Forge"
  git push -u origin main
```

**Run the commands shown:**
```bash
cd C:\Users\User\AI\Projects\fitness-tracker
git init
gh repo create fitness-tracker --private --source=. --remote=origin
git add .
git commit -m "Initial commit from Forge"
git push -u origin main
```

#### Step 5: Generate GitHub Issues (30 seconds)

```bash
forge generate-issues
```

**What happens:**
- Parses `prd.md`
- Extracts MVP features
- Creates atomic GitHub issues via `gh` CLI

**Expected output:**
```
ℹ️  Generating GitHub issues from PRD...

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
```

#### Step 6: Process First Issue (in Claude Code)

```bash
forge issue 1
```

**What happens (in Claude Code):**
1. **Plan Phase**: Fetches issue, searches prior work, breaks down into tasks
2. **Create Phase**: Implements code
3. **Test Phase**: Runs tests, adds new tests
4. **Deploy Phase**: Commits code, opens PR

**After PR is merged, run:**
```bash
/clear  # In Claude Code - wipes context
```

**Then process next issue:**
```bash
forge issue 2
```

---

## Common Commands

```bash
# Start new project from scratch
forge start <project-name>

# Import existing PRD
forge import <project-name> <prd-file>

# Check confidence and progress
forge status

# Show specific section
forge show blockers
forge show explicit
forge show deliverables

# Setup GitHub repository
forge setup-repo <project-name>

# Generate issues from PRD
forge generate-issues

# Process GitHub issue (Plan → Create → Test → Deploy)
forge issue <number>

# Review PR in fresh context (NEW shell)
forge review-pr <number>

# Run tests
forge test

# Check deployment
forge deploy

# Get blocker guidance
forge fix vague_features
forge fix missing_tech_stack

# Export PRD
forge export

# Show help
forge help
```

---

## Typical Workflow

```
1. forge start my-app
   ├─ Answer discovery questions
   └─ Reach 95% confidence

2. forge setup-repo my-app
   ├─ Copy GitHub templates
   └─ git init + gh repo create

3. forge generate-issues
   └─ Create 8-12 atomic issues

4. FOR EACH ISSUE:
   ├─ forge issue <N>
   │  ├─ Plan → Create → Test → Deploy
   │  └─ Opens PR
   ├─ Review PR (you or Claude)
   ├─ Merge PR
   └─ /clear (in Claude Code)

5. forge deploy
   └─ Verify all green

6. Ship to production 🚀
```

---

## Troubleshooting

### "Project not found"
- Ensure you're in the project directory: `cd C:\Users\User\AI\Projects\<project-name>`
- Or specify project name: `forge setup-repo <project-name>`

### "Confidence below 95%"
- Run: `forge status` to see missing deliverables
- Run: `forge fix <blocker>` for specific guidance
- Answer remaining questions to fill gaps

### "GitHub CLI not found"
```bash
# Install gh CLI
choco install gh  # Windows
brew install gh   # Mac

# Authenticate
gh auth login
```

### "Command not found: forge"
- Verify Forge is in PATH: `$env:Path` (Windows) or `echo $PATH` (Linux/Mac)
- Reload profile: `. $PROFILE` (PowerShell) or `source ~/.bashrc` (Bash)

---

## Next Steps

- **Full Documentation**: See `docs/full-system-guide.md`
- **Command Reference**: See `COMMANDS.md`
- **Agent Behaviors**: See `docs/agent-behaviors.md`
- **GitHub Workflow**: See `docs/github-workflow.md`
- **Troubleshooting**: See `docs/troubleshooting.md`

---

## Getting Help

```bash
# Show all commands
forge help

# Get guidance for blocker
forge fix <blocker>

# Check documentation
cd C:\Users\User\AI\Systems\Forge\docs
```

---

**Ready to build?**
```bash
forge start my-awesome-app
```

---

**Generated by Forge v1.0**
