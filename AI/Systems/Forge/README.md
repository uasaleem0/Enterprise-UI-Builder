# Forge v1.0
**AI-Powered Software Development System: Idea → PRD → Production**

Transform vague ideas into production-ready applications through confidence-based PRD development, multi-agent analysis, and automated GitHub setup.

---

## What is Forge?

Forge is a structured, confidence-based system that guides you from a vague idea to a production-ready PRD (Product Requirements Document) in 2-4 hours, then scaffolds a complete GitHub repository with CI/CD, test infrastructure, and atomic issues ready for development.

**Core Philosophy**:
1. **95% Confidence Threshold** - No phase advances without clarity
2. **Atomic, Specific Issues** - Granular, self-contained tasks
3. **Test-First Foundation** - CI/CD before features
4. **Fresh Context Per Issue** - Clear between work items

---

## Quick Start

### Installation

Forge is already installed at:
```
C:\Users\User\AI\Systems\Forge\
```

### Add to PATH (Windows PowerShell)

```powershell
# Add to current session
$env:Path += ";C:\Users\User\AI\Systems\Forge\scripts"

# Add permanently to profile
notepad $PROFILE
# Add this line:
Set-Alias forge "C:\Users\User\AI\Systems\Forge\scripts\forge.ps1"
# Save and reload:
. $PROFILE
```

### Verify Installation

```bash
forge version
```

### Create Your First Project (5 minutes)

```bash
# Start new project from idea
forge start fitness-tracker

# Answer discovery questions...
# Continue until confidence reaches 95%

# Check status
forge status

# Setup GitHub repository
forge setup-repo fitness-tracker

# Generate issues from PRD
cd C:\Users\User\AI\Projects\fitness-tracker
git init
gh repo create fitness-tracker --private --source=. --remote=origin
git add .
git commit -m "Initial commit from Forge"
git push -u origin main
forge generate-issues

# Process first issue (in Claude Code)
forge issue 1
```

---

## System Architecture

### Phases

**Phase 1: PRD Development** ✅ (Current)
- Multi-agent discovery and analysis
- Weighted confidence tracking (95% threshold)
- Industry-specific compliance integration
- Dual workflow: from scratch OR import existing PRD

**Phase 2: GitHub Foundation** ✅ (Current)
- Repository scaffolding with CI/CD
- Test framework setup
- Atomic issue generation
- Scratchpad planning system

**Phase 3: Architecture** 🔜 (Future)
- System design and data models
- API specifications
- Component architecture

**Phase 4: Implementation** 🔜 (Future)
- Iterative feature development
- Test-driven development
- PR review workflows

---

## Confidence System

### Weighted Formula

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
```

### Hard Blocks (Critical)

System **CANNOT** proceed if:
1. **Tech Stack < 100%** - All 5 components required (frontend, backend, database, auth, hosting)
2. **Conflicting Features** - E.g., real-time + static hosting
3. **Overall Confidence < 95%** - PRD too vague
4. **Vague Features** - Missing acceptance criteria
5. **Missing Compliance** - Healthcare (HIPAA), Fintech (PCI-DSS), etc.

---

## Agent System

### Analyst Agent (BMAD-Inspired)
**Focus**: Problem space, target users, market opportunity

**Outputs**:
- Problem Statement (10% weight)
- Success Metrics (15% weight)
- Feature extraction (explicit + implied)

### PM Agent (BMAD-Inspired)
**Focus**: User personas, Agile stories, MVP scope

**Outputs**:
- User Personas (7% weight)
- User Stories in Agile format (5% weight)
- MVP Scope definition (15% weight)

### Architect Agent
**Focus**: Tech stack decisions (100% required)

**Outputs**:
- Complete tech stack with reasoning (20% weight)
- Third-party integrations
- Non-functional requirements (3% weight)

### Validator Agent
**Focus**: Completeness, conflicts, clarity, compliance

**Outputs**:
- Validation report with blockers
- Confidence calculation
- Next steps to reach 95%

---

## Commands

### Core Commands
```bash
forge start <name>              # Create new project from scratch
forge import <name> <file>      # Import existing PRD
forge status                    # Show confidence & progress
forge show <section>            # Expand section details
```

### GitHub Commands
```bash
forge setup-repo <name>         # Create GitHub repo with CI/CD
forge generate-issues           # Convert PRD to GitHub issues
forge issue <number>            # Process issue (Plan → Create → Test → PR)
forge review-pr <number>        # Review PR in fresh context
forge test                      # Run test suite
forge deploy                    # Check deployment status
```

### Utility Commands
```bash
forge fix <blocker>             # Get guidance for blocker
forge export                    # Export PRD as markdown
forge help                      # Show command reference
forge version                   # Show Forge version
```

---

## Workflows

### From-Scratch Workflow

```
1. forge start my-app
   ├─ Analyst asks discovery questions
   ├─ PM creates personas and stories
   ├─ Architect defines tech stack
   └─ Validator checks completeness

2. Reach 95% confidence
   └─ Iterate until all deliverables complete

3. forge setup-repo my-app
   ├─ Copy GitHub templates (CI/CD, issues, PRs)
   └─ Create scratchpads directory

4. git init + gh repo create
   └─ Initialize repository

5. forge generate-issues
   └─ Convert PRD features into atomic GitHub issues

6. FOR EACH ISSUE:
   ├─ forge issue <N>
   │  ├─ Plan → Create → Test → Deploy
   │  └─ Opens PR
   ├─ Review PR
   ├─ Merge PR
   └─ /clear (in Claude Code)
```

### Import-PRD Workflow

```
1. forge import my-app ./prd.md
   ├─ Validator parses existing PRD
   ├─ Calculates initial confidence (40-80%)
   └─ Identifies gaps

2. Fill gaps with targeted questions
   └─ Ask ONLY about missing items

3. Reach 95% confidence
   └─ Iterate until validated

4. forge setup-repo my-app
   └─ [Same as from-scratch workflow]
```

---

## GitHub Flow Integration

Based on the GitHub workflow best practices:

**Issue Processing** (Plan → Create → Test → Deploy):

1. **Plan Phase**:
   - Fetch issue from GitHub via `gh` CLI
   - Search `scratchpads/` for related work
   - Break into atomic tasks
   - Write plan to `scratchpads/issue-<N>-plan.md`

2. **Create Phase**:
   - Implement code changes
   - Follow framework best practices

3. **Test Phase**:
   - Run test suite (npm test, rails test, pytest)
   - Add tests for new functionality
   - Use Puppeteer for UI testing

4. **Deploy Phase**:
   - Commit changes
   - Open pull request
   - CI/CD runs automatically
   - Review PR (human or separate Claude session)
   - Merge to main
   - Main auto-deploys (optional)

5. **Clean Context**:
   - **CRITICAL**: Run `/clear` in Claude Code after merge
   - Prevents context pollution
   - Next issue works from cold start

---

## File Structure

```
Forge/
├─ forge.md                       # Main system instructions
├─ COMMANDS.md                    # Full command reference
├─ README.md                      # This file
│
├─ core/
│  ├─ workflows/                  # from-scratch.md, import-prd.md
│  ├─ templates/                  # base-prd.md, logging templates
│  └─ validation/                 # hard-blocks.json, confidence-weights.json
│
├─ agents/                        # Agent definitions
│  ├─ analyst.md
│  ├─ pm.md
│  ├─ architect.md
│  └─ validator.md
│
├─ lib/
│  ├─ questions/                  # Question banks (core, saas, healthcare, etc.)
│  ├─ deliverables/               # Industry specs (healthcare, fintech, etc.)
│  └─ formatters/                 # unicode-renderer.js, ascii-renderer.js
│
├─ foundation/                    # GitHub repo templates
│  ├─ .github/
│  │  ├─ workflows/ci.yml
│  │  ├─ ISSUE_TEMPLATE/
│  │  └─ PULL_REQUEST_TEMPLATE.md
│  ├─ .gitignore
│  └─ README-template.md
│
├─ scripts/
│  ├─ forge.ps1                   # PowerShell wrapper
│  └─ warp-completion.ts          # Warp autocomplete
│
└─ docs/
   ├─ quick-start.md
   ├─ full-system-guide.md
   ├─ command-reference.md
   └─ [more docs]
```

---

## Project Structure (After Setup)

```
my-app/
├─ .github/
│  ├─ workflows/ci.yml            # CI/CD (tests + linter on every commit)
│  ├─ ISSUE_TEMPLATE/
│  └─ PULL_REQUEST_TEMPLATE.md
├─ scratchpads/                   # Claude planning (issue-N-plan.md)
├─ prd.md                         # Product Requirements Document
├─ README.md                      # Auto-generated from PRD
└─ [framework files]              # Rails, Next.js, Django, etc.
```

---

## Documentation

- **Quick Start**: `docs/quick-start.md` - Get up and running in 5 minutes
- **Full Guide**: `docs/full-system-guide.md` - Complete system explanation
- **Command Reference**: `COMMANDS.md` - All commands with examples
- **Main System**: `forge.md` - System instructions and configuration

---

## Example: Fitness Tracker App

```bash
# Start project
forge start fitness-tracker

# Analyst asks:
Q: "What problem does this solve?"
A: "Personal trainers struggle to track client progress..."

Q: "Who will use this?"
A: "Trainers managing 10-50 clients, gym-goers tracking workouts"

Q: "How will you know it's successful?"
A: "50 active trainers within 3 months, 80% retention rate"

# Continue until 95% confidence...

# Setup GitHub
forge setup-repo fitness-tracker
cd C:\Users\User\AI\Projects\fitness-tracker
git init
gh repo create fitness-tracker --private --source=. --remote=origin
git add .
git commit -m "Initial commit from Forge"
git push -u origin main

# Generate issues
forge generate-issues
# Creates 8 atomic issues from PRD features

# Process first issue (in Claude Code)
forge issue 1
# Plan → Create → Test → PR
# After PR merged: /clear

# Repeat for remaining issues...
```

---

## Requirements

### Required
- **PowerShell** (Windows) or **Bash** (Linux/Mac)
- **Git** - Version control
- **GitHub CLI** (`gh`) - For GitHub integration
  ```bash
  choco install gh  # Windows
  brew install gh   # Mac
  gh auth login
  ```

### Optional
- **Warp Terminal** - For autocomplete support
- **Claude Code** - For issue processing workflows
- **Node.js/Ruby/Python** - Depending on project type

---

## Version History

**v1.0** (Current)
- PRD development with weighted confidence (95% threshold)
- Multi-agent analysis (Analyst, PM, Architect, Validator)
- Dual workflow (from scratch + import)
- GitHub foundation scaffolding with CI/CD
- Issue generation from PRD
- Scratchpad planning system
- Dual rendering (Unicode/ASCII)
- Industry-specific compliance (Healthcare, Fintech, E-commerce)

**Future Versions**
- v1.1: Architecture phase with system design
- v1.2: Implementation phase with iterative development
- v1.3: Deployment automation
- v2.0: Multi-agent parallel processing

---

## Contributing

This is a personal system. If you want to use or extend it:
1. Clone/copy the Forge folder
2. Customize agents, templates, validation rules
3. Adjust confidence weights for your workflow

---

## License

MIT License - Use freely for personal or commercial projects

---

## Contact

For questions or issues:
- Check documentation: `docs/` folder
- Run: `forge help`
- Check troubleshooting: `docs/troubleshooting.md` (if exists)

---

**Built by**: Enterprise UI Builder System
**Version**: 1.0
**Location**: `/c/Users/User/AI/Systems/Forge/`

---

**Ready to build?**
```bash
forge start my-awesome-app
```
