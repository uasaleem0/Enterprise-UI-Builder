# Forge Generate Issues Workflow
# Validates project and generates GitHub issues

$ForgeRoot = "C:\Users\User\AI\Systems\Forge"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "         FORGE GENERATE ISSUES WORKFLOW                     " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Validate project
Write-Host "[1/5] Validating project..." -ForegroundColor Yellow

$CurrentPath = Get-Location
if (-not (Test-Path "$CurrentPath\prd.md")) {
    Write-Host "[ERROR] No project found. Run this from a project directory." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Project found" -ForegroundColor Green
Write-Host ""

# Step 2: Check confidence
Write-Host "[2/5] Checking PRD confidence..." -ForegroundColor Yellow

. "$ForgeRoot\lib\semantic-validator.ps1"
. "$ForgeRoot\lib\state-manager.ps1"

$deliverables = Get-SemanticPrdCompletion -PrdPath "$CurrentPath\prd.md"
$confidence = Update-ProjectConfidence -ProjectPath $CurrentPath -Deliverables $deliverables

Write-Host "Current confidence: $confidence%" -ForegroundColor $(if ($confidence -ge 95) { "Green" } else { "Yellow" })

if ($confidence -lt 95) {
    Write-Host "[WARNING] PRD below 95% confidence" -ForegroundColor Yellow
    Write-Host "Recommended: Run 'forge status' to identify gaps" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "Continue anyway? [y/N]"
    if ($continue -ne "y") {
        Write-Host "[CANCELLED] Run 'forge status' to improve PRD" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "[OK] PRD validated" -ForegroundColor Green
Write-Host ""

# Step 3: Check git repository
Write-Host "[3/5] Checking git repository..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    Write-Host "[ERROR] Not a git repository" -ForegroundColor Red
    Write-Host "Run: git init" -ForegroundColor Gray
    exit 1
}

Write-Host "[OK] Git repository found" -ForegroundColor Green
Write-Host ""

# Step 4: Check GitHub remote
Write-Host "[4/5] Checking GitHub remote..." -ForegroundColor Yellow

try {
    $remote = git remote get-url origin 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "No remote found"
    }
    Write-Host "[OK] Remote: $remote" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] No GitHub remote configured" -ForegroundColor Red
    Write-Host "Run: gh repo create <name> --private --source=. --remote=origin" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Step 5: Generate issues
Write-Host "[5/5] Generating GitHub issues..." -ForegroundColor Yellow
Write-Host ""

& "$ForgeRoot\scripts\forge.ps1" generate-issues

Write-Host ""
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "              WORKFLOW COMPLETE                             " -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

Write-Host "View issues:" -ForegroundColor Cyan
Write-Host "  gh issue list" -ForegroundColor White
Write-Host ""
Write-Host "Start working on an issue:" -ForegroundColor Cyan
Write-Host "  forge issue [number]" -ForegroundColor White
Write-Host ""
