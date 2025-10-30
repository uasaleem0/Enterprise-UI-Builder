# Forge System - PowerShell Wrapper
# (removed stray lines)
# Forge System - PowerShell Wrapper
# Version: 1.0
# All Forge commands with autocomplete support

param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet(
        'start', 'import-prd', 'import-ia', 'status', 'show', 'show-prd', 'show-ia', 'help',
        'setup-repo', 'generate-issues', 'issue', 'review-pr',
        'test', 'deploy', 'fix', 'export', 'export-prd', 'version',
        'start-workflow', 'status-workflow', 'generate-issues-workflow',
        'note', 'session-close', 'mode', 'dev-test', 'dev-backup', 'dev-edit',
        'dev-note', 'dev-status', 'ia-sitemap-report', 'ia-userflows-report', 'ia-erd-report', 'prd-report', 'prd-feedback', 'evolve-spec',
        'delete-project', 'remove-project', 'design-brief', 'design-ref'
    )]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Normalize arguments: remove empty/null entries so downstream defaults apply
$Arguments = @($Arguments | Where-Object { $_ -ne '' -and $_ -ne $null })

# Forge system paths
$ForgeRoot = "C:\Users\User\AI\Systems\Forge"
$ProjectRoot = "C:\Users\User\AI\Projects"
$CorePath = "$ForgeRoot\core"
$AgentsPath = "$ForgeRoot\agents"
$LibPath = "$ForgeRoot\lib"
$FoundationPath = "$ForgeRoot\foundation"

# Load all modules once at startup
. "$LibPath\mode-manager.ps1"
. "$LibPath\state-manager.ps1"
. "$LibPath\prd-completeness-validator.ps1"
. "$LibPath\forge-status-renderer.ps1"
. "$LibPath\forge-status-dashboard.ps1"
. "$LibPath\session-tracker.ps1"
. "$LibPath\session-formatter.ps1"
. "$LibPath\issue-generator.ps1"
. "$ForgeRoot\scripts\New-ForgePRDReport.ps1"
. "$LibPath\ia-importer.ps1"
. "$ForgeRoot\lib\ia-heuristic-parser.ps1"
. "$ForgeRoot\scripts\Format-SitemapReport.ps1"
. "$ForgeRoot\scripts\Format-UserFlowsReport.ps1"
. "$LibPath\readiness.ps1"
. "$LibPath\project-manager.ps1"

# Color output helpers
function Write-ForgeSuccess { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-ForgeError { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-ForgeWarning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-ForgeInfo { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

# Session Tracking Hook - Called at start of every command
function Initialize-SessionTracking {
    $CurrentPath = Get-Location

    # Check if we're in a project directory
    if ((Test-Path "$CurrentPath\prd.md") -or (Test-Path "$CurrentPath\.forge-state.json")) {
        # Show previous session notes if exists (except for commands that manually display it)
        $skipAutoDisplay = @('session-close', 'help', 'version')
        if ($Command -eq 'show' -and $Arguments -contains 'last-session') {
            $skipAutoDisplay += 'show'
        }

        if ($Command -notin $skipAutoDisplay) {
            Show-PreviousSessionNotes -ProjectPath $CurrentPath
        }

        # Track this command
        Track-Command -ProjectPath $CurrentPath -Command $Command -Arguments $Arguments
    }
}

# Banner
function Show-Banner {
    $modeIndicator = Get-ModeIndicator
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    if ($modeIndicator) {
        Write-Host "          FORGE v1.0 - AI Dev System $modeIndicator     " -ForegroundColor Yellow
    } else {
        Write-Host "               FORGE v1.0 - AI Dev System                 " -ForegroundColor Cyan
    }
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Command: forge start <project-name>
function Invoke-ForgeStart {
    param([string]$ProjectName)

    if (-not $ProjectName) {
        Write-ForgeError "Project name required: forge start [project-name]"
        return
    }

    Show-Banner
    Write-ForgeInfo "Starting new project: $ProjectName"
    Write-Host ""

    $ProjectPath = "$ProjectRoot\$ProjectName"

    if (Test-Path $ProjectPath) {
        Write-ForgeError "Project already exists: $ProjectPath"
        return
    }

    Write-ForgeInfo "Creating project directory: $ProjectPath"
    New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    # Do not create prd.md placeholder; require explicit import or authoring

    Write-ForgeSuccess "Project created at: $ProjectPath"
    Write-Host ""
    Write-ForgeInfo "Next: cd into the project and start the guided workflow"
    Write-Host ""
    Write-Host "  cd $ProjectPath" -ForegroundColor Yellow
    Write-Host ""
    Write-ForgeInfo "AI: Reference C:\Users\User\AI\Systems\Forge\core\workflows\from-scratch.md"
    Write-ForgeInfo "Next: create PRD (forge import-prd <file> or author prd.md)"
}

# Legacy command removed - use 'forge import-prd' instead

# Command: forge status
function Invoke-ForgeStatus {
    Show-Banner
    Write-ForgeInfo "Analyzing project PRD..."
    Write-Host ""

    # Find current project (look for prd.md in current directory or parent)
    $CurrentPath = Get-Location
    $PrdPath = $null
    $ProjectPath = $null

    if (Test-Path "$CurrentPath\prd.md") {
        $PrdPath = "$CurrentPath\prd.md"
        $ProjectPath = $CurrentPath
    } elseif (Test-Path "..\prd.md") {
        $PrdPath = "..\prd.md"
        $ProjectPath = Split-Path $CurrentPath -Parent
    }

    if (-not $PrdPath) {
        Write-ForgeError "No project found. Run this command from a project directory."
        Write-ForgeInfo "Or use: forge start [name] to create a new project"
        return
    }

    # Parse PRD and calculate deliverables using semantic validation
    try {
        $deliverables = Get-SemanticPrdCompletion -PrdPath $PrdPath

        # Calculate confidence
        $confidence = Update-ProjectConfidence -ProjectPath $ProjectPath -Deliverables $deliverables

        # Get project name
        $projectName = Split-Path $ProjectPath -Leaf

        # Get full state and render new dashboard
        $fullState = Get-ProjectState -ProjectPath $ProjectPath
        Show-DashboardStatus -ProjectPath $ProjectPath -State $fullState

        Write-Host ""
        Write-Host ""

    } catch {
        Write-ForgeError "Failed to parse PRD: $($_.Exception.Message)"
        Write-ForgeInfo "Make sure prd.md exists and has valid content"
    }
}

# Command: forge show <section>
function Invoke-ForgeShow {
    param([string]$Section)

    $ValidSections = @('deliverables', 'blockers', 'state', 'prd', 'last-session', 'history')

    if (-not $Section -or $Section -notin $ValidSections) {
        Write-ForgeError "Usage: forge show [section]"
        Write-Host "Valid sections: deliverables, blockers, state, prd, last-session, history" -ForegroundColor Gray
        return
    }

    Show-Banner
    Write-ForgeInfo "Showing section: $Section"
    Write-Host ""

    # Find current project
    $CurrentPath = Get-Location
    if (-not (Test-Path "$CurrentPath\prd.md")) {
        Write-ForgeError "No project found. Run this from a project directory."
        return
    }

    $state = Get-ProjectState -ProjectPath $CurrentPath

    switch ($Section) {
        'deliverables' {
            Write-Host "Deliverables Status:" -ForegroundColor Cyan
            Write-Host ""
            foreach ($key in $state.deliverables.Keys | Sort-Object) {
                $value = $state.deliverables.$key
                $icon = if ($value -eq 100) { "[OK]" } elseif ($value -ge 75) { "[!!]" } else { "[XX]" }
                $color = if ($value -eq 100) { "Green" } elseif ($value -ge 75) { "Yellow" } else { "Red" }
                Write-Host "  " -NoNewline
                Write-Host $icon -ForegroundColor $color -NoNewline
                Write-Host " $($key): $value%"
            }
        }
        'blockers' {
            $blockers = Test-ValidationBlocks -State $state
            if ($blockers.Count -eq 0) {
                Write-ForgeSuccess "No blockers found!"
            } else {
                Write-Host "Blockers ($($blockers.Count)):" -ForegroundColor Red
                Write-Host ""
                foreach ($blocker in $blockers) {
                    Write-Host "  [BLOCKED] $($blocker.message)" -ForegroundColor Red
                    Write-Host "    Resolution: $($blocker.resolution)" -ForegroundColor Yellow
                }
            }
        }
        'state' {
            Write-Host "Project State:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Project: $($state.project_name)"
            Write-Host "  Created: $($state.created_at)"
            Write-Host "  Confidence: $($state.confidence)%"
            Write-Host "  Industry: $($state.industry)"
            Write-Host "  Validated: $($state.validated)"
        }
        'prd' {
            Get-Content "$CurrentPath\prd.md"
        }
        'last-session' {
            Format-LastSession -ProjectPath $CurrentPath
        }
        'history' {
            Format-SessionHistory -ProjectPath $CurrentPath -State $state
        }
    }
}

# Command: forge setup-repo <project-name>
function Invoke-ForgeSetupRepo {
    param([string]$ProjectName)

    if (-not $ProjectName) {
        Write-ForgeError "Project name required: forge setup-repo [project-name]"
        return
    }

    Show-Banner
    Write-ForgeInfo "Setting up GitHub repository for: $ProjectName"
    Write-Host ""

    $ProjectPath = "$ProjectRoot\$ProjectName"

    if (-not (Test-Path $ProjectPath)) {
        Write-ForgeError "Project not found: $ProjectPath"
        Write-ForgeInfo "Run: forge start $ProjectName first"
        return
    }

    Write-ForgeInfo "Checking PRD confidence..."
    # This would check if PRD is at 95%+

    Write-ForgeInfo "Copying GitHub foundation templates..."

    # Copy foundation templates
    $GithubPath = "$ProjectPath\.github"
    New-Item -ItemType Directory -Path "$GithubPath\workflows" -Force | Out-Null
    New-Item -ItemType Directory -Path "$GithubPath\ISSUE_TEMPLATE" -Force | Out-Null

    Copy-Item "$FoundationPath\.github\workflows\*" "$GithubPath\workflows\" -Force
    Copy-Item "$FoundationPath\.github\ISSUE_TEMPLATE\*" "$GithubPath\ISSUE_TEMPLATE\" -Force
    Copy-Item "$FoundationPath\.github\PULL_REQUEST_TEMPLATE.md" "$GithubPath\" -Force

    # Create scratchpads directory
    New-Item -ItemType Directory -Path "$ProjectPath\scratchpads" -Force | Out-Null

    Write-ForgeSuccess "GitHub foundation templates copied"
    Write-Host ""
    Write-ForgeInfo "Next: Initialize git repository"
    Write-Host ""
    Write-Host "  cd $ProjectPath" -ForegroundColor Yellow
    Write-Host "  git init" -ForegroundColor Yellow
    Write-Host "  gh repo create $ProjectName --private --source=. --remote=origin" -ForegroundColor Yellow
    Write-Host "  git add ." -ForegroundColor Yellow
    Write-Host "  git commit -m `"Initial commit from Forge`"" -ForegroundColor Yellow
    Write-Host "  git push -u origin main" -ForegroundColor Yellow
}

# Command: forge generate-issues
function Invoke-ForgeGenerateIssues {
    Show-Banner
    Write-ForgeInfo "Generating GitHub issues from PRD..."
    Write-Host ""

    # Find current project
    $CurrentPath = Get-Location
    $PrdPath = $null

    if (Test-Path "$CurrentPath\prd.md") {
        $PrdPath = "$CurrentPath\prd.md"
    }

    if (-not $PrdPath) {
        Write-ForgeError "No project found. Run this command from a project directory."
        return
    }

    # Check if gh CLI is available
    try {
        $null = Get-Command gh -ErrorAction Stop
    } catch {
        Write-ForgeError "GitHub CLI (gh) not found. Please install it first:"
        Write-Host "  choco install gh" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Yellow
        return
    }

    # Check if in a git repository
    if (-not (Test-Path ".git")) {
        Write-ForgeError "Not in a git repository. Run 'forge setup-repo' first."
        return
    }

    Write-ForgeInfo "Parsing PRD: $PrdPath"
    Write-Host ""

    try {
        $issues = Invoke-IssueGeneration -PrdPath $PrdPath

        Write-Host ""
        Write-Host "=============================================================" -ForegroundColor Green
        Write-Host "Successfully created $($issues.Count) GitHub issues!" -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor Green
        Write-Host ""

        Write-Host "View issues:" -ForegroundColor Yellow
        Write-Host "  gh issue list" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Work on an issue:" -ForegroundColor Yellow
        Write-Host "  forge issue [number]" -ForegroundColor Cyan

    } catch {
        Write-ForgeError "Failed to generate issues: $($_.Exception.Message)"
    }
}

# Command: forge issue <number>
function Invoke-ForgeIssue {
    param([string]$IssueNumber)

    if (-not $IssueNumber) {
        Write-ForgeError "Issue number required: forge issue [number]"
        return
    }

    # Check if gh CLI is available
    try {
        $null = Get-Command gh -ErrorAction Stop
    } catch {
        Write-ForgeError "GitHub CLI (gh) not found. Please install it first:"
        Write-Host "  choco install gh" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Yellow
        return
    }

    Show-Banner
    Write-ForgeInfo "Fetching GitHub issue #$IssueNumber"
    Write-Host ""

    try {
        # Fetch issue details
        $issueJson = gh issue view $IssueNumber --json title,body,labels,state | ConvertFrom-Json

        Write-Host "Issue #$IssueNumber" -ForegroundColor Cyan
        Write-Host "Title: $($issueJson.title)" -ForegroundColor White
        Write-Host "State: $($issueJson.state)" -ForegroundColor $(if ($issueJson.state -eq "OPEN") { "Green" } else { "Red" })
        Write-Host ""
        Write-Host "Body:" -ForegroundColor Yellow
        Write-Host $issueJson.body -ForegroundColor White
        Write-Host ""
        Write-Host "Labels: $($issueJson.labels.name -join ', ')" -ForegroundColor Gray
        Write-Host ""
        Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Use this issue in Claude Code to:" -ForegroundColor Yellow
        Write-Host "  1. Plan implementation in scratchpads/" -ForegroundColor White
        Write-Host "  2. Implement the feature" -ForegroundColor White
        Write-Host "  3. Run tests (forge test)" -ForegroundColor White
        Write-Host "  4. Create PR (git commit + gh pr create)" -ForegroundColor White
        Write-Host ""
        Write-ForgeWarning "Remember to run /clear after merge to prevent context pollution"

    } catch {
        Write-ForgeError "Failed to fetch issue: $($_.Exception.Message)"
        Write-Host "Make sure you're in a git repository with remote set up" -ForegroundColor Gray
    }
}

# Command: forge review-pr <number>
function Invoke-ForgeReviewPR {
    param([string]$PRNumber)

    if (-not $PRNumber) {
        Write-ForgeError "PR number required: forge review-pr [number]"
        return
    }

    # Check if gh CLI is available
    try {
        $null = Get-Command gh -ErrorAction Stop
    } catch {
        Write-ForgeError "GitHub CLI (gh) not found. Please install it first:"
        Write-Host "  choco install gh" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Yellow
        return
    }

    Show-Banner
    Write-ForgeWarning "Run this in a FRESH shell to avoid context pollution"
    Write-Host ""
    Write-ForgeInfo "Fetching pull request #$PRNumber"
    Write-Host ""

    try {
        # Fetch PR details
        $prJson = gh pr view $PRNumber --json title,body,state,author,mergeable,commits | ConvertFrom-Json

        Write-Host "PR #$PRNumber" -ForegroundColor Cyan
        Write-Host "Title: $($prJson.title)" -ForegroundColor White
        Write-Host "Author: $($prJson.author.login)" -ForegroundColor White
        Write-Host "State: $($prJson.state)" -ForegroundColor $(if ($prJson.state -eq "OPEN") { "Green" } else { "Gray" })
        Write-Host "Mergeable: $($prJson.mergeable)" -ForegroundColor $(if ($prJson.mergeable -eq "MERGEABLE") { "Green" } else { "Red" })
        Write-Host ""
        Write-Host "Body:" -ForegroundColor Yellow
        Write-Host $prJson.body -ForegroundColor White
        Write-Host ""
        Write-Host "Commits: $($prJson.commits.Count)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "View diff:" -ForegroundColor Yellow
        Write-Host "  gh pr diff $PRNumber" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "View checks:" -ForegroundColor Yellow
        Write-Host "  gh pr checks $PRNumber" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Checkout locally:" -ForegroundColor Yellow
        Write-Host "  gh pr checkout $PRNumber" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Add review comment:" -ForegroundColor Yellow
        Write-Host "  gh pr review $PRNumber --comment -b 'Your review comment'" -ForegroundColor Cyan

    } catch {
        Write-ForgeError "Failed to fetch PR: $($_.Exception.Message)"
        Write-Host "Make sure you're in a git repository with remote set up" -ForegroundColor Gray
    }
}

# Command: forge test
function Invoke-ForgeTest {
    Show-Banner
    Write-ForgeInfo "Running test suite..."
    Write-Host ""

    # Detect framework and run appropriate tests
    if (Test-Path "Gemfile") {
        Write-Host "Detected Rails project. Running: rails test" -ForegroundColor Gray
        rails test
    } elseif (Test-Path "package.json") {
        Write-Host "Detected Node project. Running: npm test" -ForegroundColor Gray
        npm test
    } elseif ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        Write-Host "Detected Python project. Running: pytest" -ForegroundColor Gray
        pytest
    } else {
        Write-ForgeError "Could not detect project type. Run tests manually."
    }
}

# Command: forge deploy
function Invoke-ForgeDeploy {
    Show-Banner
    Write-ForgeInfo "Checking deployment status..."
    Write-Host ""

    Write-Host "Checking CI/CD status via gh CLI..." -ForegroundColor Gray
    gh run list --limit 5
}

# Command: forge fix <blocker>
function Invoke-ForgeFix {
    param([string]$Blocker)

    $ValidBlockers = @('missing_tech_stack', 'conflicting_features', 'low_confidence', 'vague_features', 'missing_compliance')

    if (-not $Blocker -or $Blocker -notin $ValidBlockers) {
        Write-ForgeError "Usage: forge fix [blocker]"
        Write-Host "Valid blockers:" -ForegroundColor Gray
        Write-Host "  - missing_tech_stack" -ForegroundColor Gray
        Write-Host "  - conflicting_features" -ForegroundColor Gray
        Write-Host "  - low_confidence" -ForegroundColor Gray
        Write-Host "  - vague_features" -ForegroundColor Gray
        Write-Host "  - missing_compliance" -ForegroundColor Gray
        return
    }

    Show-Banner
    Write-ForgeInfo "Getting guidance for: $Blocker"
    Write-Host ""

    # Load hard-blocks.json and show specific guidance
    $BlocksPath = "$CorePath\validation\hard-blocks.json"
    if (-not (Test-Path $BlocksPath)) {
        Write-ForgeError "Validation rules not found"
        return
    }

    $blocks = Get-Content $BlocksPath | ConvertFrom-Json
    $blockerInfo = $blocks.blocks | Where-Object { $_.id -eq $Blocker }

    if (-not $blockerInfo) {
        Write-ForgeError "Blocker not found: $Blocker"
        return
    }

    Write-Host "$($blockerInfo.message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Reason:" -ForegroundColor Yellow
    Write-Host "  $($blockerInfo.reason)" -ForegroundColor White
    Write-Host ""
    Write-Host "Impact:" -ForegroundColor Yellow
    Write-Host "  $($blockerInfo.impact)" -ForegroundColor White
    Write-Host ""
    Write-Host "Resolution:" -ForegroundColor Green
    Write-Host "  $($blockerInfo.resolution)" -ForegroundColor White
    Write-Host ""

    if ($blockerInfo.examples) {
        Write-Host "Examples:" -ForegroundColor Cyan
        foreach ($example in $blockerInfo.examples) {
            Write-Host ""
            if ($example.vague) {
                Write-Host "  Vague: $($example.vague)" -ForegroundColor Red
                Write-Host "  Better: $($example.specific)" -ForegroundColor Green
            } elseif ($example.conflict) {
                Write-Host "  Conflict: $($example.conflict)" -ForegroundColor Red
                Write-Host "  Reason: $($example.reason)" -ForegroundColor Yellow
                Write-Host "  Fix: $($example.resolution)" -ForegroundColor Green
            }
        }
    }
}

# Command: forge export
function Invoke-ForgeExport {
    Show-Banner
    Write-ForgeInfo "Exporting PRD as markdown..."
    Write-Host ""

    $CurrentPath = Get-Location
    if (Test-Path "$CurrentPath\prd.md") {
        $ExportPath = "$CurrentPath\prd-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        Copy-Item "$CurrentPath\prd.md" $ExportPath
        Write-ForgeSuccess "PRD exported to: $ExportPath"
    } else {
        Write-ForgeError "No prd.md found in current directory"
    }
}

# Command: forge help
function Invoke-ForgeHelp {
    Show-Banner

    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "                    FORGE COMMANDS                         " -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

    # STEP 0 - Core Setup
    Write-Host "STEP 0 - CORE SETUP:" -ForegroundColor Yellow
    Write-Host "  forge start [name]              Create new project from scratch"
    Write-Host "  forge status                    Show confidence and progress (legacy)"
    Write-Host "  forge show [section]            Show deliverables/blockers/state/prd/history"
    Write-Host "  forge show-prd                  Display parsed PRD with confidence & quality"
    Write-Host "  forge fix [blocker]             Get guidance for specific blocker"
    Write-Host ""

    # STEP 1 - PRD Development
    Write-Host "STEP 1 - PRD DEVELOPMENT:" -ForegroundColor Yellow
    Write-Host "  forge import-prd [file]         Import PRD using AI extraction"
    Write-Host "  forge show-prd                  Display parsed PRD model (features, screens, etc)"
    Write-Host "  forge prd-report                Generate PRD analysis report with confidence"
    Write-Host "  forge prd-feedback              Get AI feedback on PRD quality & issues"
    Write-Host "  forge evolve-spec [request]     AI-guided PRD/IA evolution from user request"
    Write-Host "  forge export-prd                Export PRD as markdown"
    Write-Host "  forge start-workflow [name]     Interactive project creation workflow"
    Write-Host "  forge status-workflow           Comprehensive status report (legacy)"
    Write-Host ""

    # STEP 2 - GitHub Foundation
    Write-Host "STEP 2 - GITHUB FOUNDATION:" -ForegroundColor Yellow
    Write-Host "  forge setup-repo [name]         Create GitHub repo with CI/CD"
    Write-Host "  forge generate-issues           Convert PRD to GitHub issues"
    Write-Host "  forge generate-issues-workflow  Validated issue generation"
    Write-Host ""

    # STEP 3 - Information Architecture
    Write-Host "STEP 3 - IA (INFORMATION ARCHITECTURE):" -ForegroundColor Yellow
    Write-Host "  forge import-ia [file]          Import IA from sitemap/flows/ERD"
    Write-Host "  forge ia-sitemap-report         Generate sitemap analysis report"
    Write-Host "  forge ia-userflows-report       Generate user flows report"
    Write-Host "  forge ia-erd-report             Generate entity relationship diagram"
    Write-Host ""

    # STEP 4 — Implementation
    Write-Host "STEP 4 — IMPLEMENTATION:" -ForegroundColor Yellow
    Write-Host "  forge issue [number]            Process GitHub issue"
    Write-Host "  forge review-pr [number]        Review pull request"
    Write-Host "  forge test                      Run test suite"
    Write-Host "  forge deploy                    Check deployment status"
    Write-Host ""

    # Session & Notes
    Write-Host "SESSION COMMANDS:" -ForegroundColor Yellow
    Write-Host "  forge note ""message""            Capture important context/feedback"
    Write-Host "  forge session-close             End session and generate summary"
    Write-Host "  forge show last-session         View previous session summary"
    Write-Host "  forge show history              View all project sessions"
    Write-Host ""

    # Dev Mode
    Write-Host "DEV COMMANDS (Development Mode Only):" -ForegroundColor Yellow
    Write-Host "  forge mode [prod|dev]           Switch between modes or show current"
    Write-Host "  forge dev-test                  Run Forge test suite"
    Write-Host "  forge dev-backup                Backup Forge system files"
    Write-Host "  forge dev-edit [file]           Edit system file"
    Write-Host "  forge dev-note ""message""        Log system development note"
    Write-Host "  forge dev-status                Show system development status"
    Write-Host ""

    # Project Management
    Write-Host "PROJECT MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "  forge delete-project            Safely delete current project with backups"
    Write-Host "  forge remove-project            (alias for delete-project)"
    Write-Host ""

    # Utilities
    Write-Host "UTILITY COMMANDS:" -ForegroundColor Yellow
    Write-Host "  forge help                      Show this help"
    Write-Host "  forge version                   Show Forge version"
    Write-Host ""

    # Examples
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Start new project"
    Write-Host "  forge start fitness-tracker"
    Write-Host ""
    Write-Host "  # Import and analyze PRD"
    Write-Host "  forge import-prd ./prd.md"
    Write-Host "  forge show-prd"
    Write-Host "  forge prd-report"
    Write-Host "  forge prd-feedback"
    Write-Host "  forge evolve-spec ""Add user authentication with OAuth"""
    Write-Host ""
    Write-Host "  # Import and analyze IA"
    Write-Host "  forge import-ia"
    Write-Host "  forge ia-sitemap-report"
    Write-Host "  forge ia-userflows-report"
    Write-Host "  forge ia-erd-report"
    Write-Host ""
    Write-Host "  # Generate GitHub issues"
    Write-Host "  forge setup-repo fitness-tracker"
    Write-Host "  forge generate-issues"
    Write-Host "  forge issue 42"
    Write-Host ""

    Write-Host "Documentation: $ForgeRoot\docs" -ForegroundColor Cyan
    Write-Host ""
}

# Command: forge version
function Invoke-ForgeVersion {
    Show-Banner
    Write-Host "Forge System v1.0" -ForegroundColor Cyan
    Write-Host "Location: $ForgeRoot" -ForegroundColor Gray
    Write-Host ""
}

# Command: forge note <message>
function Invoke-ForgeNote {
    param([string]$Note)

    if (-not $Note) {
        Write-ForgeError "Note message required: forge note ""your message"""
        return
    }

    $CurrentPath = Get-Location
    if (-not (Test-Path "$CurrentPath\prd.md")) {
        Write-ForgeError "No project found. Run this from a project directory."
        return
    }

    Add-SessionNote -ProjectPath $CurrentPath -Note $Note
}

# Command: forge session-close
function Invoke-ForgeSessionClose {
    $CurrentPath = Get-Location
    if (-not (Test-Path "$CurrentPath\prd.md")) {
        Write-ForgeError "No project found. Run this from a project directory."
        return
    }

    Close-ForgeSession -ProjectPath $CurrentPath
}

# Command: forge mode [prod|dev]
function Invoke-ForgeMode {
    param([string]$TargetMode)

    if (-not $TargetMode) {
        Show-ModeInfo
        return
    }

    Set-ForgeMode -TargetMode $TargetMode
}

# Command: forge dev-test
function Invoke-ForgeDevTest {
    Assert-DevMode -Operation "dev-test"

    Show-Banner
    Write-ForgeInfo "Running Forge test suite..."
    Write-Host ""

    # Run testing script if exists
    $TestScript = "$ForgeRoot\FORGE-TESTING-PLAN.md"
    if (Test-Path $TestScript) {
        Write-ForgeInfo "Test plan: $TestScript"
        Write-Host ""
        Write-ForgeInfo "Run manual tests from testing plan"
    } else {
        Write-ForgeError "Testing plan not found"
    }

    Write-DevLog -Operation "test" -File "system" -Description "Ran dev test suite"
}

# Command: forge dev-backup
function Invoke-ForgeDevBackup {
    Assert-DevMode -Operation "dev-backup"

    Show-Banner
    Write-ForgeInfo "Backing up Forge system files..."
    Write-Host ""

    # Clean old backups (keep last 5)
    $BackupDir = "$ForgeRoot\.backups"
    if (Test-Path $BackupDir) {
        $existingBackups = Get-ChildItem $BackupDir -Directory | Sort-Object Name -Descending
        if ($existingBackups.Count -ge 5) {
            $toDelete = $existingBackups | Select-Object -Skip 4
            foreach ($backup in $toDelete) {
                Remove-Item $backup.FullName -Recurse -Force
                Write-Host "[INFO] Removed old backup: $($backup.Name)" -ForegroundColor Gray
            }
        }
    }

    $BackupPath = "$BackupDir\backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

    # Create subdirectories
    New-Item -ItemType Directory -Path "$BackupPath\scripts" -Force | Out-Null
    New-Item -ItemType Directory -Path "$BackupPath\lib" -Force | Out-Null
    New-Item -ItemType Directory -Path "$BackupPath\core" -Force | Out-Null

    # Backup critical system files
    Copy-Item "$ForgeRoot\scripts\*" "$BackupPath\scripts\" -Recurse -Force
    Copy-Item "$ForgeRoot\lib\*" "$BackupPath\lib\" -Recurse -Force
    Copy-Item "$ForgeRoot\core\*" "$BackupPath\core\" -Recurse -Force

    Write-ForgeSuccess "Backup created: $BackupPath"
    Write-DevLog -Operation "backup" -File $BackupPath -Description "System backup created"
}

# Command: forge dev-edit [file]
function Invoke-ForgeDevEdit {
    param([string]$FilePath)

    Assert-DevMode -Operation "dev-edit"

    if (-not $FilePath) {
        Write-ForgeError "File path required: forge dev-edit [file]"
        return
    }

    $FullPath = Join-Path $ForgeRoot $FilePath

    if (-not (Test-Path $FullPath)) {
        Write-ForgeError "File not found: $FullPath"
        return
    }

    Write-ForgeInfo "Opening in default editor: $FullPath"
    Write-DevLog -Operation "edit" -File $FilePath -Description "Opened system file for editing"

    notepad $FullPath
}

# Command: forge dev-note <message>
function Invoke-ForgeDevNote {
    param([string]$Message)

    if (-not $Message) {
        Write-ForgeError "Message required: forge dev-note ""your note"""
        return
    }

    # Force dev mode temporarily for logging (notes allowed in any mode)
    $originalMode = $env:FORGE_MODE
    $env:FORGE_MODE = "dev"

    Write-DevLog -Operation "note" -File "system" -Description $Message

    # Restore original mode
    $env:FORGE_MODE = $originalMode

    Write-ForgeSuccess "System note logged"
}

# Command: forge dev-status
function Invoke-ForgeDevStatus {
    Assert-DevMode -Operation "dev-status"

    Show-Banner
    Write-Host "=== FORGE SYSTEM STATUS ===" -ForegroundColor Cyan
    Write-Host ""

    $logPath = "$ForgeRoot\.forge-dev-log.json"

    if (-not (Test-Path $logPath)) {
        Write-ForgeWarning "No dev log found. No system activity recorded yet."
        return
    }

    $log = Get-Content $logPath -Raw | ConvertFrom-Json
    if (-not $log -or $log.Count -eq 0) {
        Write-ForgeWarning "Dev log is empty"
        return
    }

    # Separate entries
    $openIssues = @($log | Where-Object { $_.operation -eq "note" -and (-not $_.status -or $_.status -eq "open") })
    $operations = @($log | Where-Object { $_.operation -ne "note" })
    $resolved = @($log | Where-Object { $_.operation -eq "note" -and $_.status -eq "fixed" })

    # Display open issues
    if ($openIssues.Count -gt 0) {
        Write-Host "[OPEN ISSUES - $($openIssues.Count)]" -ForegroundColor Red
        for ($i = 0; $i -lt $openIssues.Count; $i++) {
            $entry = $openIssues[$i]
            Write-Host "  $($i + 1). " -NoNewline -ForegroundColor Yellow
            Write-Host "[$($entry.timestamp)] " -NoNewline -ForegroundColor Gray
            Write-Host $entry.description -ForegroundColor White
        }
        Write-Host ""
    }

    # Display recent operations
    if ($operations.Count -gt 0) {
        Write-Host "[RECENT OPERATIONS - $($operations.Count)]" -ForegroundColor Cyan
        $recentOps = $operations | Select-Object -Last 5
        foreach ($entry in $recentOps) {
            Write-Host "  * " -NoNewline -ForegroundColor Cyan
            Write-Host "[$($entry.timestamp)] " -NoNewline -ForegroundColor Gray
            Write-Host "$($entry.operation): " -NoNewline -ForegroundColor Yellow
            Write-Host $entry.description -ForegroundColor White
        }
        Write-Host ""
    }

    # Display resolved issues
    if ($resolved.Count -gt 0) {
        Write-Host "[RESOLVED - $($resolved.Count)]" -ForegroundColor Green
        foreach ($entry in $resolved) {
            Write-Host "  " -NoNewline
            Write-Host "[FIXED] " -NoNewline -ForegroundColor Green
            Write-Host "[$($entry.timestamp)] " -NoNewline -ForegroundColor Gray
            Write-Host $entry.description -ForegroundColor White
        }
        Write-Host ""
    }

    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Initialize session tracking for project commands
Initialize-SessionTracking

# Main command router
switch ($Command) {
    'start'                     { if ($Arguments) { Invoke-ForgeStart $Arguments[0] } else { Invoke-ForgeStart } }
    'import-prd'                { & "$ForgeRoot\scripts\forge-import-prd.ps1" @Arguments }
    'import-ia'                 { & "$ForgeRoot\scripts\forge-import-ia.ps1" @Arguments }
    'status'                    { Invoke-ForgeStatus }
    'show'                      { if ($Arguments) { Invoke-ForgeShow $Arguments[0] } else { Invoke-ForgeShow } }
    'show-prd'                  {
        # Map '--plain' flag and ensure artifacts before rendering
        $argsFiltered = @()
        foreach($a in $Arguments){ if ($a -in @('--plain','-plain','-Plain','/plain')) { $env:FORGE_PLAIN='1' } else { $argsFiltered += $a } }
        $projPath = (Get-Location)
        try { [void](Ensure-ProjectArtifacts -ProjectPath $projPath -Quiet) } catch { Write-ForgeError $_; return }
        & "$ForgeRoot\scripts\forge-show-prd.ps1" -ProjectPath $projPath @argsFiltered
    }
    'setup-repo'                { if ($Arguments) { Invoke-ForgeSetupRepo $Arguments[0] } else { Invoke-ForgeSetupRepo } }
    'generate-issues'           { Invoke-ForgeGenerateIssues }
    'issue'                     { if ($Arguments) { Invoke-ForgeIssue $Arguments[0] } else { Invoke-ForgeIssue } }
    'ia-sitemap-report'         { & "$ForgeRoot\scripts\forge-ia-sitemap-report.ps1" @Arguments }
    'ia-userflows-report'       { & "$ForgeRoot\scripts\forge-ia-userflows-report.ps1" @Arguments }
    'ia-erd-report'             { & "$ForgeRoot\scripts\forge-ia-erd-report.ps1" @Arguments }
    'review-pr'                 { if ($Arguments) { Invoke-ForgeReviewPR $Arguments[0] } else { Invoke-ForgeReviewPR } }
    'test'                      { Invoke-ForgeTest }
    'deploy'                    { Invoke-ForgeDeploy }
    'fix'                       { if ($Arguments) { Invoke-ForgeFix $Arguments[0] } else { Invoke-ForgeFix } }
    'export'                    { Invoke-ForgeExport }
    'export-prd'                { Invoke-ForgeExport }
    'help'                      { Invoke-ForgeHelp }
    'version'                   { Invoke-ForgeVersion }
    'note'                      { if ($Arguments) { Invoke-ForgeNote ($Arguments -join ' ') } else { Invoke-ForgeNote } }
    'session-close'             { Invoke-ForgeSessionClose }
    'mode'                      { if ($Arguments) { Invoke-ForgeMode $Arguments[0] } else { Invoke-ForgeMode } }
    'dev-test'                  { Invoke-ForgeDevTest }
    'dev-backup'                { Invoke-ForgeDevBackup }
    'dev-edit'                  { if ($Arguments) { Invoke-ForgeDevEdit $Arguments[0] } else { Invoke-ForgeDevEdit } }
    'dev-note'                  { if ($Arguments) { Invoke-ForgeDevNote ($Arguments -join ' ') } else { Invoke-ForgeDevNote } }
    'dev-status'                { Invoke-ForgeDevStatus }
    'start-workflow'            { & "$ForgeRoot\scripts\forge-start-workflow.ps1" @Arguments }
    'status-workflow'           { & "$ForgeRoot\scripts\forge-status-workflow.ps1" }
    'generate-issues-workflow'  { & "$ForgeRoot\scripts\forge-generate-issues-workflow.ps1" }
    'evolve-spec'               { & "$ForgeRoot\scripts\forge-evolve-spec.ps1" @Arguments }

    'prd-report'                {
        try { [void](Ensure-ProjectArtifacts -ProjectPath (Get-Location) -Quiet) } catch { Write-ForgeError $_; return }
        & "$ForgeRoot\scripts\forge-prd-report.ps1" @Arguments
    }
    'prd-feedback'              { & "$ForgeRoot\scripts\forge-prd-feedback.ps1" @Arguments }
    'delete-project'            {
        # Parse arguments for Remove-ForgeProject (array-splat doesn't bind named params)
        $projPath = (Get-Location).Path
        $force = $false
        $noBackup = $false
        for ($i = 0; $i -lt $Arguments.Count; $i++) {
            $arg = $Arguments[$i]
            switch -Regex ($arg) {
                '^(?:-ProjectPath|-Path|--path)$' { if ($i+1 -lt $Arguments.Count) { $projPath = $Arguments[$i+1]; $i++ }; continue }
                '^(?:-Force|--force|-y|--yes)$'   { $force = $true; continue }
                '^(?:-NoBackup|--no-backup)$'     { $noBackup = $true; continue }
                default { }
            }
        }
        Remove-ForgeProject -ProjectPath $projPath -Force:$force -NoBackup:$noBackup
    }
    'remove-project'            {
        $projPath = (Get-Location).Path
        $force = $false
        $noBackup = $false
        for ($i = 0; $i -lt $Arguments.Count; $i++) {
            $arg = $Arguments[$i]
            switch -Regex ($arg) {
                '^(?:-ProjectPath|-Path|--path)$' { if ($i+1 -lt $Arguments.Count) { $projPath = $Arguments[$i+1]; $i++ }; continue }
                '^(?:-Force|--force|-y|--yes)$'   { $force = $true; continue }
                '^(?:-NoBackup|--no-backup)$'     { $noBackup = $true; continue }
                default { }
            }
        }
        Remove-ForgeProject -ProjectPath $projPath -Force:$force -NoBackup:$noBackup
    }
    'design-brief'              { & "$LibPath\design-interview.ps1" @Arguments }
    'design-ref'                { & "$LibPath\design-references.ps1" @Arguments }
    default                     { Invoke-ForgeHelp }
}



