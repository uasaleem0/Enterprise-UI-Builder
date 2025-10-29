# Forge Status Dashboard Test Script
# Tests the new dashboard display with IronSense project

param(
    [string]$ProjectPath = $PWD.Path
)

# Load dashboard module
. "$PSScriptRoot\..\lib\forge-status-dashboard.ps1"

# Load state from .forge-state.json
$stateFile = Join-Path $ProjectPath ".forge-state.json"
if (Test-Path $stateFile) {
    $stateObj = Get-Content $stateFile -Raw | ConvertFrom-Json
    # Convert PSCustomObject to hashtable manually
    $state = @{
        confidence = if ($stateObj.confidence) { [int]$stateObj.confidence } else { 0 }
        ia_confidence = if ($stateObj.ia_confidence) { [int]$stateObj.ia_confidence } else { 0 }
        ia_quality = if ($stateObj.ia_quality) { [int]$stateObj.ia_quality } else { 0 }
        quality = if ($stateObj.quality) { [int]$stateObj.quality } else { 0 }
        deliverables = @{}
        ia_model = $stateObj.ia_model
        project_model = $stateObj.project_model
        semantic_analysis = $stateObj.semantic_analysis
        created_at = $stateObj.created_at
    }
    # Copy deliverables if they exist
    if ($stateObj.deliverables) {
        foreach ($key in ($stateObj.deliverables | Get-Member -MemberType NoteProperty).Name) {
            $state.deliverables[$key] = $stateObj.deliverables.$key
        }
    }
} else {
    $state = @{
        confidence = 0
        ia_confidence = 0
        deliverables = @{}
    }
}

# Show dashboard
Show-DashboardStatus -ProjectPath $ProjectPath -State $state
