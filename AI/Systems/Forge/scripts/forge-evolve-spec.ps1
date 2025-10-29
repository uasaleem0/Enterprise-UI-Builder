# Forge Evolve-Spec - AI-Guided PRD and IA Evolution
# Interactive workflow for evolving PRD and IA based on user requests

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

# Load required libraries
. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\change-analyzer.ps1"
. "$ForgeRoot\lib\ai-extractor.ps1"
. "$ForgeRoot\lib\change-applicator.ps1"
. "$ForgeRoot\lib\evolve-reporter.ps1"
. "$ForgeRoot\lib\semantic-model-builder.ps1"
. "$ForgeRoot\lib\prd-completeness-validator.ps1"

function Write-ForgeSuccess { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-ForgeError { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-ForgeWarning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-ForgeInfo { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

function Start-ForgeEvolveSpec {
    [CmdletBinding()]
    param ([string[]]$Arguments)

    # Parse flags
    $useAI = $true
    $skipConfirmation = $false
    foreach ($arg in $Arguments) {
        if ($arg -eq '--no-ai') { $useAI = $false }
        if ($arg -eq '-y' -or $arg -eq '--yes') { $skipConfirmation = $true }
    }

    # Verify project directory
    $CurrentPath = Get-Location
    $prdPath = Join-Path $CurrentPath 'prd.md'
    if (-not (Test-Path $prdPath)) {
        Write-ForgeError "No project found. Run this from a project directory with prd.md"
        Write-Host "Usage: forge evolve-spec [--no-ai] [-y|--yes]" -ForegroundColor Gray
        exit 1
    }

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "          FORGE EVOLVE-SPEC - PRD/IA Evolution              " -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Get user request
    Write-Host "What change would you like to make to your PRD/IA?" -ForegroundColor Cyan
    Write-Host "(Describe in plain English)" -ForegroundColor Gray
    Write-Host ""
    $userRequest = Read-Host "Change Request"
    if ([string]::IsNullOrWhiteSpace($userRequest)) {
        Write-ForgeWarning "No request provided. Cancelled."
        exit 0
    }

    # Load state
    Write-Host ""
    Write-ForgeInfo "Loading project state..."
    $state = Get-ProjectState -ProjectPath $CurrentPath

    # Analyze
    Write-Host ""
    Write-ForgeInfo "Analyzing impact..."
    $analysis = $null
    if ($useAI) {
        try {
            $analysis = Invoke-ForgeEvolveAnalysis -ProjectPath $CurrentPath -UserRequest $userRequest
            Write-ForgeSuccess "AI analysis complete"
        } catch {
            Write-ForgeWarning "AI analysis failed: $($_.Exception.Message)"
            $useAI = $false
        }
    }
    if (-not $useAI -or -not $analysis) {
        try {
            $analysis = Get-ChangeImpact -ProjectPath $CurrentPath -UserRequest $userRequest -CurrentState $state
            Write-ForgeSuccess "Heuristic analysis complete"
        } catch {
            Write-ForgeError "Analysis failed: $($_.Exception.Message)"
            exit 1
        }
    }

    # Display report
    Write-Host ""
    Show-EvolveAnalysisReport -Analysis $analysis

    # Confirmation
    if (-not $skipConfirmation) {
        Write-Host ""
        $confirm = Read-Host "Apply these changes? (y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-ForgeWarning "Cancelled by user."
            exit 0
        }
    }

    # Apply changes
    Write-Host ""
    Write-ForgeInfo "Applying changes..."
    try {
        $results = Apply-EvolveChanges -ProjectPath $CurrentPath -Analysis $analysis -CreateBackup $true
        Write-ForgeSuccess "Changes applied"
    } catch {
        Write-ForgeError "Failed to apply changes: $($_.Exception.Message)"
        exit 1
    }

    # Rebuild model
    Write-Host ""
    Write-ForgeInfo "Rebuilding project model..."
    try {
        Build-ProjectSemanticModel -ProjectPath $CurrentPath
        Write-ForgeSuccess "Project model rebuilt"
    } catch {
        Write-ForgeWarning "Failed to rebuild: $($_.Exception.Message)"
    }

    # Recalculate confidence
    Write-Host ""
    Write-ForgeInfo "Recalculating confidence..."
    try {
        $completion = Get-SemanticPrdCompletion -PrdPath $prdPath
        $newConfidence = Update-ProjectConfidence -ProjectPath $CurrentPath -Deliverables $completion
        $updatedState = Get-ProjectState -ProjectPath $CurrentPath
        $updatedState.confidence = $newConfidence
        Set-ProjectState -ProjectPath $CurrentPath -State $updatedState
        Write-ForgeSuccess "Confidence recalculated"
    } catch {
        $newConfidence = $null
    }

    # Display results
    Write-Host ""
    Show-EvolveResultsReport -Results $results -NewConfidence $newConfidence

    # Next steps
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "  forge status      # View updated status" -ForegroundColor White
    Write-Host "  forge prd-report  # Review PRD" -ForegroundColor White
    Write-Host ""
    Write-ForgeSuccess "Evolution complete!"
}

Start-ForgeEvolveSpec -Arguments $Arguments
