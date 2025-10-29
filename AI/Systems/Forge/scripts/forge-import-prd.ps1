# Forge Import PRD - Enhanced with Semantic Analysis
# Auto-analyzes PRD on import and shows initial confidence

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$InputArgs
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\prd-completeness-validator.ps1"
. "$ForgeRoot\lib\prd-semantic-analyzer.ps1"
. "$ForgeRoot\lib\ai-extractor.ps1"
. "$ForgeRoot\lib\semantic-model-builder.ps1"

function Write-ForgeSuccess { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-ForgeError { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-ForgeWarning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-ForgeInfo { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

# Parse arguments
$PrdFile = $null
foreach ($a in $InputArgs) {
    if (-not ($a.StartsWith('--'))) {
        $PrdFile = (Resolve-Path $a).Path
        break
    }
}

$CurrentPath = Get-Location

# Guardrail: Check if we're in a valid project directory
# A valid project directory should either:
# 1. Not have a prd.md yet (new project), OR
# 2. Have a prd.md that we'll overwrite with confirmation
$prdPath = Join-Path $CurrentPath 'prd.md'
$existingPrd = Test-Path -LiteralPath $prdPath
$stateFile = Test-Path (Join-Path $CurrentPath '.forge-state.json')

if (-not $PrdFile) {
    Write-ForgeError "Usage: forge import-prd [prd-file]"
    Write-Host "Example: forge import-prd C:\path\to\my-prd.txt" -ForegroundColor Gray
    Write-Host ""
    Write-ForgeInfo "Run this command from your project directory"
    Write-Host "  cd C:\Users\User\AI\Projects\your-project" -ForegroundColor Gray
    Write-Host "  forge import-prd C:\path\to\prd.txt" -ForegroundColor Gray
    exit 1
}

if ($existingPrd) {
    # Treat an empty or whitespace-only placeholder as not existing for UX
    try {
        $len = (Get-Item -LiteralPath $prdPath -ErrorAction Stop).Length
        $isEmpty = ($null -eq $len) -or ($len -eq 0)
    } catch { $isEmpty = $false }
    if (-not $isEmpty) {
        try {
            $content = Get-Content -LiteralPath $prdPath -Raw -ErrorAction SilentlyContinue
            $tlen = if ($null -eq $content) { 0 } else { ($content.Trim()).Length }
            if ($tlen -eq 0) { $isEmpty = $true }
        } catch { }
    }

    if ($env:FORGE_DEBUG) {
        Write-Host "[DEBUG] existingPrd=$existingPrd len=$len tlen=$tlen isEmpty=$isEmpty path=$prdPath" -ForegroundColor DarkGray
    }

    if (-not $isEmpty) {
        Write-ForgeWarning "prd.md already exists in this directory"
        $confirm = Read-Host "Overwrite existing PRD? (y/n)"
        if ($confirm -ne 'y') {
            Write-ForgeInfo "Import cancelled"
            exit 0
        }
    }
}

if (-not (Test-Path $PrdFile)) {
    Write-ForgeError "PRD file not found: $PrdFile"
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "               FORGE - Import PRD                           " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy PRD to project
Write-ForgeInfo "Importing PRD..."
try {
    $prdDestination = $prdPath
    Copy-Item -Path $PrdFile -Destination $prdDestination -Force
    Write-ForgeSuccess "PRD copied to: prd.md"
} catch {
    Write-ForgeError "Failed to copy PRD: $($_.Exception.Message)"
    exit 1
}

# Step 2: Validate PRD content and calculate initial confidence
Write-Host ""
Write-ForgeInfo "Analyzing PRD structure..."
try {
    # Guardrail: PRD must not be empty/whitespace
    $rawPrd = Get-Content -LiteralPath $prdDestination -Raw -Encoding UTF8
    if (-not $rawPrd -or ($rawPrd.Trim()).Length -eq 0) {
        throw "PRD content is empty after import"
    }
    $completion = Get-SemanticPrdCompletion -PrdPath $prdDestination
    $confidence = Update-ProjectConfidence -ProjectPath $CurrentPath -Deliverables $completion

    # Step 3: Run semantic analysis (pattern-based, no AI required)
    Write-ForgeInfo "Running semantic analysis..."
    $semanticAnalysis = Get-SemanticAnalysis -PrdPath $prdDestination -AiModelPath $null

    # Calculate quality score
    $quality = Get-PRDQualityScore -SemanticAnalysis $semanticAnalysis

    # Step 4: Update state
    $state = Get-ProjectState -ProjectPath $CurrentPath
    $state.confidence = $confidence
    $state.quality = $quality
    $state.deliverables = $completion

    # Add semantic analysis to state
    if (-not $state.ContainsKey('semantic_analysis')) {
        $state['semantic_analysis'] = @{}
    }
    $state.semantic_analysis = $semanticAnalysis

    Set-ProjectState -ProjectPath $CurrentPath -State $state

    # Build semantic model (heuristic + optional AI enrichment)
    Write-ForgeInfo "Building semantic model..."
    Build-ProjectSemanticModel -ProjectPath $CurrentPath | Out-Null

    Write-ForgeSuccess "Initial analysis complete!"
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "PRD CONFIDENCE: $confidence% (Completeness)" -ForegroundColor $(if ($confidence -ge 95) { "Green" } elseif ($confidence -ge 75) { "Yellow" } else { "Red" })
    Write-Host "PRD QUALITY:    $quality% (Semantic Issues)" -ForegroundColor $(if ($quality -ge 85) { "Green" } elseif ($quality -ge 70) { "Yellow" } else { "Red" })
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Show quick summary
    $issueCount = 0
    $issueCount += $semanticAnalysis.implied_dependencies.Count
    $issueCount += $semanticAnalysis.contradictions.Count
    $issueCount += $semanticAnalysis.impossibilities.Count
    $issueCount += $semanticAnalysis.vague_features.Count

    if ($issueCount -gt 0) {
        Write-Host "Semantic Issues Found: $issueCount" -ForegroundColor Yellow
        if ($semanticAnalysis.implied_dependencies.Count -gt 0) {
            Write-Host "  - Implied Dependencies: $($semanticAnalysis.implied_dependencies.Count)" -ForegroundColor Yellow
        }
        if ($semanticAnalysis.contradictions.Count -gt 0) {
            Write-Host "  - Contradictions: $($semanticAnalysis.contradictions.Count)" -ForegroundColor Red
        }
        if ($semanticAnalysis.impossibilities.Count -gt 0) {
            Write-Host "  - Impossibilities: $($semanticAnalysis.impossibilities.Count)" -ForegroundColor Red
        }
        if ($semanticAnalysis.vague_features.Count -gt 0) {
            Write-Host "  - Vague Features: $($semanticAnalysis.vague_features.Count)" -ForegroundColor Yellow
        }
    } else {
        Write-ForgeSuccess "No semantic issues detected!"
    }

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  forge prd-report       # View detailed analysis" -ForegroundColor White
    if ($confidence -lt 95) {
        Write-Host "  forge prd-feedback     # Get improvement suggestions" -ForegroundColor White
    }
    Write-Host ""

} catch {
    Write-ForgeError "Analysis failed: $($_.Exception.Message)"
    Write-ForgeWarning "PRD imported but analysis incomplete - run 'forge status' to retry"
    exit 1
}
