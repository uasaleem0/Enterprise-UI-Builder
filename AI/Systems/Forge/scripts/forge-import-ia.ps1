# Forge Import IA - Import Information Architecture Document
# Requires PRD to be imported and semantic model to exist
# Uses existing Import-IABlock from ia-importer.ps1

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$InputArgs
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\ia-importer.ps1"
. "$ForgeRoot\lib\semantic-model-builder.ps1"
. "$ForgeRoot\lib\prd-completeness-validator.ps1"
. "$ForgeRoot\lib\ia-semantic-analyzer.ps1"

function Write-ForgeSuccess { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-ForgeError { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-ForgeWarning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-ForgeInfo { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

# Parse arguments
$IaFile = $null
foreach ($a in $InputArgs) {
    if (-not ($a.StartsWith('--'))) {
        $IaFile = $a
        break
    }
}

$CurrentPath = Get-Location

# Guardrail 1: Check if IA file provided
if (-not $IaFile) {
    Write-ForgeError "Usage: forge import-ia [ia-file]"
    Write-Host "Example: forge import-ia C:\path\to\my-ia.txt" -ForegroundColor Gray
    Write-Host ""
    Write-ForgeInfo "This command must be run from your project directory"
    Write-Host "  cd C:\Users\User\AI\Projects\your-project" -ForegroundColor Gray
    Write-Host "  forge import-ia C:\path\to\ia.txt" -ForegroundColor Gray
    Write-Host ""
    Write-ForgeInfo "IA file must be in Custom GPT format with [FORGE_IA_START]...[FORGE_IA_END] markers"
    exit 1
}

# Guardrail 2: Check if IA file exists
if (-not (Test-Path $IaFile)) {
    Write-ForgeError "IA file not found: $IaFile"
    exit 1
}

# Guardrail 3: Check if PRD exists
$prdPath = Join-Path $CurrentPath 'prd.md'
if (-not (Test-Path $prdPath)) {
    Write-ForgeError "PRD not found in current directory"
    Write-Host ""
    Write-ForgeInfo "You must import a PRD first:"
    Write-Host "  forge import-prd C:\path\to\prd.txt" -ForegroundColor Gray
    Write-Host ""
    Write-ForgeInfo "Or create a new project:"
    Write-Host "  forge start project-name" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "               FORGE - Import IA                            " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Mark timestamp before import to detect if new files were created
$timestampBefore = Get-Date

# Use existing Import-IABlock function which handles:
# - Parsing [FORGE_IA_START]...[FORGE_IA_END] format
# - Validating sections (sitemap, flows, navigation, components, entities)
# - Checking PRD confidence
# - Validating IA maps to PRD features
# - Saving to ia/ directory
# - Updating state
Write-ForgeInfo "Importing IA using Import-IABlock..."
Import-IABlock -ProjectPath $CurrentPath -InputFile $IaFile

# Check if import was successful by verifying IA files were created/updated recently
$iaDir = Join-Path $CurrentPath 'ia'
$iaFiles = @('sitemap.md', 'flows.md', 'navigation.md')
$importSucceeded = $false

if (Test-Path $iaDir) {
    $allFilesExist = $true
    $anyFileUpdated = $false

    foreach ($file in $iaFiles) {
        $filePath = Join-Path $iaDir $file
        if (-not (Test-Path $filePath)) {
            $allFilesExist = $false
            break
        }
        # Check if file was modified after we started the import
        $fileInfo = Get-Item $filePath
        if ($fileInfo.LastWriteTime -gt $timestampBefore) {
            $anyFileUpdated = $true
        }
    }

    $importSucceeded = $allFilesExist -and $anyFileUpdated
}

if (-not $importSucceeded) {
    Write-Host ""
    Write-ForgeError "IA import was cancelled or failed"
    Write-Host ""
    Write-ForgeInfo "To import IA, ensure:"
    Write-Host "  1. PRD confidence is at least 90% (run: forge prd-report)" -ForegroundColor Gray
    Write-Host "  2. IA file is in correct format with [FORGE_IA_START]...[FORGE_IA_END] markers" -ForegroundColor Gray
    Write-Host "  3. All required IA sections are present (sitemap, flows, navigation)" -ForegroundColor Gray
    exit 1
}

# Import succeeded - calculate confidence and quality
Write-Host ""
Write-ForgeInfo "Analyzing IA completeness and quality..."

# Calculate IA confidence (completeness)
try {
    $iaCompletion = Get-IACompletion -IAPath $iaDir

    # Calculate weighted confidence score
    $iaConfidence = [Math]::Round((
        ($iaCompletion.sitemap_completeness * 0.30) +
        ($iaCompletion.flows_completeness * 0.35) +
        ($iaCompletion.entities_completeness * 0.20) +
        ($iaCompletion.navigation_completeness * 0.15)
    ), 0)

    # Run semantic analysis for quality
    $iaSemanticAnalysis = Get-IASemanticAnalysis -IAPath $iaDir -IAModel $null
    $iaQuality = Get-IAQualityScore -SemanticAnalysis $iaSemanticAnalysis

    # Store in state
    $state = Get-ProjectState -ProjectPath $CurrentPath
    $state.ia_confidence = $iaConfidence
    $state.ia_quality = $iaQuality
    $state.ia_deliverables = $iaCompletion
    $state.ia_semantic_analysis = $iaSemanticAnalysis
    Set-ProjectState -ProjectPath $CurrentPath -State $state

    Write-ForgeSuccess "IA analysis complete"
} catch {
    Write-ForgeWarning "Failed to analyze IA: $($_.Exception.Message)"
}

# Rebuild semantic model
Write-Host ""
Write-ForgeInfo "Rebuilding project semantic model..."
try {
    Build-ProjectSemanticModel -ProjectPath $CurrentPath
    Write-ForgeSuccess "Semantic model rebuilt successfully"
} catch {
    Write-ForgeWarning "Failed to rebuild semantic model: $($_.Exception.Message)"
    Write-Host ""
    Write-ForgeInfo "You can rebuild it manually later with: forge prd-report"
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "IA CONFIDENCE: $iaConfidence% (Completeness)" -ForegroundColor $(if ($iaConfidence -ge 90) { "Green" } elseif ($iaConfidence -ge 75) { "Yellow" } else { "Red" })
Write-Host "IA QUALITY:    $iaQuality% (Semantic Issues)" -ForegroundColor $(if ($iaQuality -ge 85) { "Green" } elseif ($iaQuality -ge 70) { "Yellow" } else { "Red" })
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Show semantic issues summary
$totalIssues = $iaSemanticAnalysis.vague_flows.Count +
               $iaSemanticAnalysis.route_contradictions.Count +
               $iaSemanticAnalysis.impossibilities.Count +
               $iaSemanticAnalysis.implied_dependencies.Count +
               $iaSemanticAnalysis.completeness_issues.Count

if ($totalIssues -gt 0) {
    Write-Host "Semantic Issues Found: $totalIssues" -ForegroundColor Yellow
    if ($iaSemanticAnalysis.vague_flows.Count -gt 0) {
        Write-Host "  - Vague Flows: $($iaSemanticAnalysis.vague_flows.Count)" -ForegroundColor Yellow
    }
    if ($iaSemanticAnalysis.route_contradictions.Count -gt 0) {
        Write-Host "  - Route Contradictions: $($iaSemanticAnalysis.route_contradictions.Count)" -ForegroundColor Red
    }
    if ($iaSemanticAnalysis.impossibilities.Count -gt 0) {
        Write-Host "  - Impossibilities: $($iaSemanticAnalysis.impossibilities.Count)" -ForegroundColor Red
    }
    if ($iaSemanticAnalysis.implied_dependencies.Count -gt 0) {
        Write-Host "  - Implied Dependencies: $($iaSemanticAnalysis.implied_dependencies.Count)" -ForegroundColor Cyan
    }
    if ($iaSemanticAnalysis.completeness_issues.Count -gt 0) {
        Write-Host "  - Completeness Issues: $($iaSemanticAnalysis.completeness_issues.Count)" -ForegroundColor Yellow
    }
} else {
    Write-ForgeSuccess "No semantic issues detected!"
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  forge show-ia          # View detailed IA analysis" -ForegroundColor White
if ($iaQuality -lt 85) {
    Write-Host "  forge evolve-spec      # Fix semantic issues" -ForegroundColor White
}
Write-Host ""

# Show what was created
$state = Get-ProjectState -ProjectPath $CurrentPath
Write-Host "Project Model Status:" -ForegroundColor Cyan
if ($state -and $state.ContainsKey('ia_model') -and $state.ia_model) {
    Write-Host "  [OK] IA model created" -ForegroundColor Green
    if ($state.ia_model.routes) { Write-Host "    - Routes: $($state.ia_model.routes.Count)" -ForegroundColor White }
    if ($state.ia_model.flows) { Write-Host "    - User Flows: $($state.ia_model.flows.Count)" -ForegroundColor White }
    if ($state.ia_model.components) { Write-Host "    - Components: $(($state.ia_model.components.Keys).Count)" -ForegroundColor White }
    if ($state.ia_model.entities) { Write-Host "    - Data Entities: $($state.ia_model.entities.Count)" -ForegroundColor White }
}
if ($state -and $state.ContainsKey('project_model') -and $state.project_model) {
    Write-Host "  [OK] Unified project model created" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  forge ia-sitemap-report     # Generate sitemap analysis" -ForegroundColor White
Write-Host "  forge ia-userflows-report   # Generate user flows analysis" -ForegroundColor White
Write-Host "  forge status                # View updated project status" -ForegroundColor White
Write-Host ""
