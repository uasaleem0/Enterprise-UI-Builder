# Forge Status Workflow
# Shows comprehensive project status with recommendations

$ForgeRoot = "C:\Users\User\AI\Systems\Forge"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "              FORGE STATUS WORKFLOW                         " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Find current project
$CurrentPath = Get-Location
if (-not (Test-Path "$CurrentPath\prd.md")) {
    Write-Host "[ERROR] No project found. Run this from a project directory." -ForegroundColor Red
    exit 1
}

# Run status
& "$ForgeRoot\scripts\forge.ps1" status

Write-Host ""
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "              DETAILED ANALYSIS                             " -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Show blockers
Write-Host "Blockers:" -ForegroundColor Yellow
& "$ForgeRoot\scripts\forge.ps1" show blockers

Write-Host ""
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Show deliverables detail
Write-Host "Deliverables Breakdown:" -ForegroundColor Yellow
& "$ForgeRoot\scripts\forge.ps1" show deliverables

Write-Host ""
Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Recommendations
Write-Host "Recommendations:" -ForegroundColor Green
Write-Host ""

. "$ForgeRoot\lib\state-manager.ps1"
$state = Get-ProjectState -ProjectPath $CurrentPath

if ($state.confidence -lt 95) {
    Write-Host "To reach 95% confidence:" -ForegroundColor Yellow
    Write-Host ""

    $nextSteps = Get-NextSteps -State $state
    $i = 1
    foreach ($step in $nextSteps | Select-Object -First 3) {
        $deliverable = $step.deliverable -replace '_', ' '
        $deliverable = (Get-Culture).TextInfo.ToTitleCase($deliverable)
        Write-Host "  $i. Complete $deliverable (+$($step.impact)%)" -ForegroundColor Cyan
        $i++
    }
} else {
    Write-Host "[READY] PRD is ready for GitHub setup!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. forge setup-repo <project-name>" -ForegroundColor White
    Write-Host "  2. git init && gh repo create" -ForegroundColor White
    Write-Host "  3. forge generate-issues" -ForegroundColor White
}

Write-Host ""
