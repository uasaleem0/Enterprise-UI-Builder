<#
.SYNOPSIS
    Displays a holistic, formatted report of the PRD model.

.DESCRIPTION
    Reads the project state file and generates a comprehensive, human-readable
    ASCII report. The report includes a project summary, at-a-glance totals
    for all major architectural components, a feature summary, and a detailed
    breakdown of each feature with its purpose, scope, acceptance criteria,
    and inferred connections to user flows.

.PARAMETER ProjectPath
    Path to the project directory containing .forge-prd-state.json

.EXAMPLE
    forge show-prd
#>
param(
    [string]$ProjectPath = '.'
)

. "$PSScriptRoot/../lib/state-manager.ps1"

# --- Helper Functions ---
function Write-BoxedLine {
    param([string]$Text, [int]$Width = 68)
    $padding = $Width - $Text.Length
    Write-Host "| $Text" + (' ' * $padding) + " |"
}

function Write-Separator {
    param([string]$Char = '-', [int]$Width = 70)
    Write-Host ($Char * $Width)
}

# --- Load State ---
$ErrorActionPreference = 'Stop'
try {
    $ProjectPath = Resolve-Path $ProjectPath
    $state = Get-ProjectState -ProjectPath $ProjectPath
} catch {
    Write-Host "ERROR: Could not read project state. Ensure you are in a valid project directory or provide the path." -ForegroundColor Red
    exit 1
}

if (-not $state.prd_model) {
    Write-Host "No PRD model found. Run 'forge import-prd' first." -ForegroundColor Yellow
    exit 0
}

# --- Data Preparation ---
$projectName = (Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath)
$projectPurpose = $state.deliverables.problem_statement_text -replace '`n', ' '
$userArchetype = $state.deliverables.user_personas_text -replace '`n', ' '

$featureCount = if ($state.prd_model.features) { $state.prd_model.features.Count } else { 0 }
$flowCount = if ($state.ia_model -and $state.ia_model.flows) { $state.ia_model.flows.Count } else { 0 }
$routeCount = if ($state.ia_model -and $state.ia_model.routes) { $state.ia_model.routes.Count } else { 0 }
$entityCount = if ($state.ia_model -and $state.ia_model.entities_by_route) { $state.ia_model.entities_by_route.Keys.Count } else { 0 }

# --- Report Generation ---

# Header Box
Write-Host ""
Write-Separator '+'
Write-BoxedLine " PRD REPORT: $projectName"
Write-Separator '+'
Write-BoxedLine ""
Write-BoxedLine "  Purpose: $projectPurpose"
Write-BoxedLine ""
Write-BoxedLine "  For:     $userArchetype"
Write-BoxedLine ""
Write-Separator '+'

# Summary Counts Box
Write-BoxedLine " [ SUMMARY ]"
Write-Separator '|' 70
Write-BoxedLine "  Features: $featureCount | User Flows: $flowCount | Routes: $routeCount | Entities: $entityCount"
Write-Separator '|' 70

# Confidence & Quality
$confidence = if ($state.confidence) { $state.confidence } else { 0 }
$quality = if ($state.quality) { $state.quality } else { 0 }
$confColor = if ($confidence -ge 95) { "Green" } elseif ($confidence -ge 75) { "Yellow" } else { "Red" }
$qualColor = if ($quality -ge 85) { "Green" } elseif ($quality -ge 70) { "Yellow" } else { "Red" }

Write-Host "| " -NoNewline
Write-Host "Confidence: $confidence%" -NoNewline -ForegroundColor $confColor
Write-Host " (Completeness) | " -NoNewline
Write-Host "Quality: $quality%" -NoNewline -ForegroundColor $qualColor
Write-Host " (Semantic)                   |"
Write-Separator '+'

# Feature Summary Box
$inScopeFeatures = @($state.prd_model.features | Where-Object { $_.scope -ne 'WON'T' -and $_.scope -ne 'UNKNOWN' })
$outOfScopeFeatures = @($state.prd_model.features | Where-Object { $_.scope -eq 'WON'T' })

Write-BoxedLine " [ FEATURE SUMMARY ]"
Write-Separator '|' 70
if ($inScopeFeatures.Count -gt 0) {
    Write-BoxedLine "  [In Scope]"
    foreach ($f in $inScopeFeatures) {
        Write-BoxedLine "    - [F: $($f.name)] ($($f.scope))"
        $desc = if ($f.description) { $f.description.Split('`n')[0] } else { 'No description.' }
        if ($desc.Length -gt 50) { $desc = $desc.Substring(0, 47) + "..." }
        Write-BoxedLine "      $desc"
    }
}
if ($outOfScopeFeatures.Count -gt 0) {
    Write-BoxedLine ""
    Write-BoxedLine "  [Out of Scope]"
    foreach ($f in $outOfScopeFeatures) {
        Write-BoxedLine "    - [F: $($f.name)] ($($f.scope))"
        $desc = if ($f.description) { $f.description.Split('`n')[0] } else { 'No description.' }
        if ($desc.Length -gt 50) { $desc = $desc.Substring(0, 47) + "..." }
        Write-BoxedLine "      $desc"
    }
}
Write-BoxedLine ""
Write-Separator '+'

# Feature Details Header
Write-Host ""
Write-Host "======================================================================"
Write-Host "  FEATURE DETAILS"
Write-Host "======================================================================"
Write-Host ""

# Detailed Feature Boxes
foreach ($feature in $state.prd_model.features) {
    Write-Separator '+'
    $scopeText = "[Scope: $($feature.scope)]"
    $nameText = "[F: $($feature.name)]"
    $padding = 68 - $nameText.Length - $scopeText.Length
    Write-Host "| $nameText" + (' ' * $padding) + "$scopeText |"
    Write-Separator '|' 70
    Write-BoxedLine ""
    Write-BoxedLine "  Purpose: $($feature.description)"
    Write-BoxedLine ""

    # Definition of Done
    if ($feature.definition_of_done) {
        Write-BoxedLine "  [x] Definition of Done:"
        foreach($line in ($feature.definition_of_done -split '`n')){
            Write-BoxedLine "      - $line"
        }
        Write-BoxedLine ""
    }

    # Associated Flows
    $featureRoutes = if ($state.project_model -and $state.project_model.feature_to_routes[$feature.name]) { $state.project_model.feature_to_routes[$feature.name] } else { @() }
    $associatedFlows = @()
    if ($state.ia_model -and $state.ia_model.flows) {
        foreach ($flow in $state.ia_model.flows) {
            $flowRoutes = if ($flow.steps) { $flow.steps } else { @() }
            $isAssociated = $false
            foreach ($fr in $featureRoutes) {
                if ($flowRoutes -contains $fr) {
                    $isAssociated = $true
                    break
                }
            }
            if ($isAssociated) {
                $associatedFlows += $flow.name
            }
        }
    }
    if ($associatedFlows.Count -gt 0) {
        Write-BoxedLine "  [->] Associated Flows:"
        foreach ($flowName in $associatedFlows) {
            Write-BoxedLine "      - [Flow: $flowName]"
        }
        Write-BoxedLine ""
    }

    # Acceptance Criteria
    if ($feature.acceptance -and $feature.acceptance.Count -gt 0) {
        Write-BoxedLine "  [+] Acceptance Criteria:"
        foreach ($acc in $feature.acceptance) {
            if ($acc.is_vague) {
                Write-BoxedLine "      - [!] $acc.text (Vague: '$($acc.vague_word)')"
            } else {
                Write-BoxedLine "      - [x] $acc.text"
            }
        }
        Write-BoxedLine ""
    }
    Write-Separator '+'
    Write-Host ""
}