param([string]$ProjectPath = '.')

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\ia-data-helpers.ps1"

$CurrentPath = if ($ProjectPath -eq '.') { Get-Location } else { $ProjectPath }

if (-not (Test-Path "$CurrentPath\prd.md")) {
    Write-Host "[ERROR] No project found. Run this from a project directory." -ForegroundColor Red
    exit 1
}

# Parse comprehensive flow data with all sections
function Parse-IAForUserFlowsReport {
    param([string]$ProjectPath)

    $state = Get-ProjectState -ProjectPath $ProjectPath
    $projectName = if ($state.project_name) { $state.project_name } else { Split-Path -Leaf $ProjectPath }

    # Build flows with full data
    $flows = @()
    if ($state.ia_model -and $state.ia_model.flows) {
        foreach ($flow in $state.ia_model.flows) {
            $flowObj = [PSCustomObject]@{
                Name = $flow.name
                Purpose = $flow.purpose
                Goal = if ($flow.goal) { $flow.goal } else { $flow.purpose }
                EntryPoint = if ($flow.entry) { $flow.entry } else { 'N/A' }
                PreCondition = $null
                Steps = @()
                SuccessScenario = if ($flow.success) { $flow.success } else { '' }
                ErrorStates = @()
                EmptyStates = $null
                DataRead = @()
                DataCreated = @()
                DataUpdated = @()
            }

            # Extract steps using helper
            $flowObj.Steps = Get-StepsFromValue -Value $flow.steps

            # Extract error scenarios using helper
            $flowObj.ErrorStates = Get-ErrorStatesFromValue -Value $flow.errors

            # Extract data entities from steps/routes
            $routesInFlow = $flowObj.Steps | Where-Object { $_ -match '^/' }

            # Map entities from entities_by_route using helper
            if ($state.ia_model.entities_by_route) {
                foreach ($route in $routesInFlow) {
                    $entities = Get-RouteEntities -EntitiesByRoute $state.ia_model.entities_by_route -Route $route
                    foreach ($ent in $entities) {
                        if (-not ($flowObj.DataRead -contains $ent)) {
                            $flowObj.DataRead += $ent
                        }
                    }
                }
            }

            $flows += $flowObj
        }
    }

    # Build Feature-to-Flow mapping
    $featuresMapping = @()
    if ($state.prd_model -and $state.prd_model.features) {
        foreach ($feature in $state.prd_model.features) {
            # Find flows that match this feature
            $matchingFlows = @()
            foreach ($flow in $flows) {
                # Simple name matching
                if ($flow.Name -match $feature.name -or $feature.name -match ($flow.Name -replace ' Flow$', '')) {
                    $matchingFlows += $flow.Name
                }
            }

            if ($matchingFlows.Count -gt 0) {
                $featuresMapping += [PSCustomObject]@{
                    Feature = $feature.name
                    Description = $feature.description
                    Flow = ($matchingFlows -join ', ')
                }
            }
        }
    }

    # Extract future features from out_of_scope
    $futureFeatures = @()
    if ($state.ia_model -and $state.ia_model.out_of_scope) {
        foreach ($item in $state.ia_model.out_of_scope) {
            if ($item -and $item -is [string] -and $item -notmatch '^Totals:') {
                $futureFeatures += $item
            }
        }
    }

    # Build PRD Feature Coverage
    $prdFeatureCoverage = @()
    if ($state.prd_model -and $state.prd_model.features) {
        foreach ($feature in $state.prd_model.features) {
            # Find flows that implement this feature
            $coveringFlows = @()
            foreach ($flow in $flows) {
                if ($flow.Name -match $feature.name -or $feature.name -match ($flow.Name -replace ' Flow$', '')) {
                    $coveringFlows += $flow.Name
                }
            }

            $prdFeatureCoverage += [PSCustomObject]@{
                Feature = $feature.name
                Scope = if ($feature.scope) { $feature.scope } else { 'UNKNOWN' }
                Flows = $coveringFlows
                Notes = ''
            }
        }
    }

    return [PSCustomObject]@{
        ProjectName = $projectName
        Flows = $flows
        FeaturesMapping = $featuresMapping
        FutureFeatures = $futureFeatures
        PrdFeatureCoverage = $prdFeatureCoverage
    }
}

$reportData = Parse-IAForUserFlowsReport -ProjectPath $CurrentPath

# Load formatter function
. "$ForgeRoot\scripts\Format-UserFlowsReport.ps1"

$outPath = Join-Path $CurrentPath 'userflows_report.md'

New-ForgeUserFlowsReport -ReportData $reportData -OutputPath $outPath

# Display report
$content = Get-Content -Path $outPath -Raw -Encoding UTF8

Write-Host ""
Write-Host "[FORGE_IA_USERFLOWS_REPORT_START]" -ForegroundColor Cyan
Write-Host $content -ForegroundColor White
Write-Host "[FORGE_IA_USERFLOWS_REPORT_END]" -ForegroundColor Cyan
Write-Host ""
