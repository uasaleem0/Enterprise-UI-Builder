<#
 Readiness utilities to ensure required artifacts exist before reports run.
 - Ensures .forge-state.json exists on disk
 - Ensures PRD/IA semantic models are present (builds project_model)
 - Ensures quality and semantic_analysis are computed and persisted
#>

. "$PSScriptRoot/state-manager.ps1"
. "$PSScriptRoot/prd-semantic-analyzer.ps1"
. "$PSScriptRoot/semantic-model-builder.ps1"

function Ensure-ProjectArtifacts {
    param([string]$ProjectPath, [switch]$Quiet)

    $proj = (Resolve-Path $ProjectPath)
    $stateFile = Join-Path $proj '.forge-state.json'
    $prdPath = Join-Path $proj 'prd.md'

    # Ensure state exists on disk
    $state = Get-ProjectState -ProjectPath $proj
    if (-not (Test-Path $stateFile)) {
        if (-not $Quiet) { Write-Host "[INFO] Initializing project state..." -ForegroundColor Cyan }
        Set-ProjectState -ProjectPath $proj -State $state
    }

    # Guard: PRD must exist
    if (-not (Test-Path $prdPath)) {
        throw "PRD not found at $prdPath. Run 'forge import-prd <file>' first."
    }

    # Delegate to the unified refresh pipeline
    return (Refresh-ProjectState -ProjectPath $proj -Quiet:$Quiet)
}


function Refresh-ProjectState {
    param(
        [string]$ProjectPath,
        [switch]$Quiet
    )

    $proj = (Resolve-Path $ProjectPath)
    $state = Get-ProjectState -ProjectPath $proj
    $prdPath = Join-Path $proj 'prd.md'
    if (-not (Test-Path $prdPath)) {
        throw "PRD not found at $prdPath. Run 'forge import-prd <file>' first."
    }

    if (-not $Quiet) { Write-Host "[INFO] Refresh: checking PRD and state..." -ForegroundColor Cyan }

    # Compute current hashes to detect changes
    $hash = $null
    try { $hash = Get-ProjectSourcesHash -ProjectPath $proj } catch { $hash = @{ prd_hash=''; ia_hash='' } }
    $prevPrdHash = ''
    if ($state -and $state.project_model -and $state.project_model.meta -and $state.project_model.meta.prd_hash) {
        $prevPrdHash = $state.project_model.meta.prd_hash
    }

    # Detect missing or incomplete PRD model (e.g., missing acceptance array)
    $needsPrdRebuild = $false
    if (-not $state.prd_model -or -not $state.prd_model.features -or $state.prd_model.features.Count -eq 0) {
        $needsPrdRebuild = $true
    } else {
        try {
            foreach ($f in $state.prd_model.features) { if (-not ($f.PSObject.Properties.Name -contains 'acceptance')) { $needsPrdRebuild = $true; break } }
        } catch { $needsPrdRebuild = $true }
    }

    # Rebuild PRD/IA/project model if the PRD changed or model is missing/incomplete
    if ($needsPrdRebuild -or ($hash -and $hash.prd_hash -ne $prevPrdHash)) {
        if (-not $Quiet) { Write-Host "[INFO] Refresh: rebuilding semantic models (PRD changed or incomplete)" -ForegroundColor Cyan }
        Build-ProjectSemanticModel -ProjectPath $proj | Out-Null
        $state = Get-ProjectState -ProjectPath $proj
    } else {
        if (-not $Quiet) { Write-Host "[INFO] Refresh: semantic models up to date" -ForegroundColor DarkGray }
    }

    # Compute deliverables, confidence, semantic analysis, and quality; persist to state
    try {
        if (-not $Quiet) { Write-Host "[INFO] Refresh: analyzing PRD deliverables" -ForegroundColor Cyan }
        $completion = Get-SemanticPrdCompletion -PrdPath $prdPath
        $confidence = Update-ProjectConfidence -ProjectPath $proj -Deliverables $completion
        $state.deliverables = $completion
        $state.confidence = $confidence
    } catch {
        if (-not $Quiet) { Write-Host "[WARN] Refresh: deliverable analysis failed: $_" -ForegroundColor Yellow }
    }

    try {
        if (-not $Quiet) { Write-Host "[INFO] Refresh: running semantic analysis" -ForegroundColor Cyan }
        $sa = Get-SemanticAnalysis -PrdPath $prdPath -AiModelPath $null
        $quality = Get-PRDQualityScore -SemanticAnalysis $sa
        $state.semantic_analysis = $sa
        $state.quality = $quality
    } catch {
        if (-not $Quiet) { Write-Host "[WARN] Refresh: semantic analysis failed: $_" -ForegroundColor Yellow }
    }

    Set-ProjectState -ProjectPath $proj -State $state

    if (-not $Quiet) { Write-Host "[OK] Refresh: state updated (confidence=$($state.confidence)%, quality=$($state.quality)%)" -ForegroundColor Green }
    return $state
}

