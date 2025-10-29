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

# Fix UTF-8 encoding for proper character display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

. "$PSScriptRoot/../lib/state-manager.ps1"
. "$PSScriptRoot/../lib/ia-heuristic-parser.ps1"

# --- Helper Functions ---
function Write-Section {
    param([string]$Title)
    Write-Host ""
    $line = ([string][char]0x2501) * 78
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-FeatureHeader {
    param([string]$Name, [string]$Scope)
    $scopeColor = switch ($Scope) {
        'MUST' { 'Green' }
        'SHOULD' { 'Yellow' }
        'COULD' { 'Cyan' }
        'UNKNOWN' { 'Gray' }
        default { 'White' }
    }
    Write-Host ""
    $topLine = [char]0x250F + ([string][char]0x2501 * 76) + [char]0x2513
    $bottomLine = [char]0x2517 + ([string][char]0x2501 * 76) + [char]0x251B
    Write-Host $topLine -ForegroundColor DarkGray
    Write-Host ([char]0x2503 + "  ") -NoNewline -ForegroundColor DarkGray
    Write-Host $Name -NoNewline -ForegroundColor White
    Write-Host " " -NoNewline
    Write-Host "[$Scope]" -NoNewline -ForegroundColor $scopeColor
    $padding = 73 - $Name.Length - $Scope.Length
    if ($padding -gt 0) { Write-Host (' ' * $padding) -NoNewline }
    Write-Host ([char]0x2503) -ForegroundColor DarkGray
    Write-Host $bottomLine -ForegroundColor DarkGray
}

function Write-Field {
    param([string]$Label, [string]$Value, [string]$Color = 'White')
    Write-Host "  " -NoNewline
    Write-Host "$Label" -NoNewline -ForegroundColor Cyan
    Write-Host " $Value" -ForegroundColor $Color
}

function Write-ListItem {
    param([string]$Text, [string]$Prefix = "•", [string]$Color = 'Gray')
    Write-Host "    $Prefix " -NoNewline -ForegroundColor $Color
    Write-Host $Text -ForegroundColor White
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

# Extract problem statement and user personas from PRD
$prdPath = Join-Path $ProjectPath 'prd.md'
$projectPurpose = ''
$userPersonas = @()
if (Test-Path $prdPath) {
    $prdText = Get-Content $prdPath -Raw
    # Extract problem statement (full text, no truncation)
    if ($prdText -match '(?is)##\s*Problem\s*Statement\s*\n+(.+?)(?=\n##|\Z)') {
        $problemSection = $matches[1]
        # Get all meaningful paragraphs
        $lines = $problemSection -split '\n' | Where-Object { $_.Trim() -and $_ -notmatch '^\*\*|^-|^#|^---' }
        $projectPurpose = ($lines -join ' ') -replace '\s+', ' '
        $projectPurpose = $projectPurpose.Trim()
    }
    # Extract all user personas with their descriptions
    if ($prdText -match '(?is)##\s*User\s*Personas\s*\n+(.+?)(?=\n##|\Z)') {
        $personaSection = $matches[1]
        # Find all ### Persona lines using regex
        $personaMatches = [regex]::Matches($personaSection, '###\s*Persona\s+\d+:\s*(.+)', 'IgnoreCase')

        for ($i = 0; $i -lt $personaMatches.Count; $i++) {
            $name = "Persona " + ($i + 1) + ": " + $personaMatches[$i].Groups[1].Value.Trim()

            # Get the content between this persona and the next (or end)
            $startIndex = $personaMatches[$i].Index
            $endIndex = if ($i + 1 -lt $personaMatches.Count) {
                $personaMatches[$i + 1].Index
            } else {
                $personaSection.Length
            }

            $section = $personaSection.Substring($startIndex, $endIndex - $startIndex)

            # Extract key attributes
            $summary = ""
            if ($section -match '\*\*Age:\*\*\s*([^\n]+)') {
                $summary += "Age: " + $matches[1].Trim() + " | "
            }
            if ($section -match '\*\*Occupation:\*\*\s*([^\n]+)') {
                $summary += $matches[1].Trim()
            }

            # Add pain points
            if ($section -match '\*\*Pain Points:\*\*\s*([^\n]+)') {
                $painPoints = $matches[1].Trim()
                if ($summary) { $summary += " - " }
                $summary += "Challenges: " + $painPoints
            }

            # Truncate if too long
            if ($summary.Length -gt 250) {
                $summary = $summary.Substring(0, 247) + '...'
            }

            $userPersonas += [PSCustomObject]@{
                Name = $name
                Description = $summary
            }
        }
    }
}

$featureCount = if ($state.prd_model.features) { $state.prd_model.features.Count } else { 0 }
$flowCount = if ($state.ia_model -and $state.ia_model.flows) { $state.ia_model.flows.Count } else { 0 }
$routeCount = if ($state.ia_model -and $state.ia_model.routes) { $state.ia_model.routes.Count } else { 0 }
$entityCount = if ($state.ia_model -and $state.ia_model.entities_by_route) { $state.ia_model.entities_by_route.Keys.Count } else { 0 }

# --- Report Generation ---

# Header
Clear-Host
Write-Host ""
$topBorder = [char]0x2554 + ([string][char]0x2550 * 76) + [char]0x2557
$bottomBorder = [char]0x255A + ([string][char]0x2550 * 76) + [char]0x255D
Write-Host $topBorder -ForegroundColor Cyan
Write-Host ([char]0x2551) -NoNewline -ForegroundColor Cyan
Write-Host "                          PRD REPORT: $projectName" -NoNewline -ForegroundColor White
$headerPadding = 76 - 42 - $projectName.Length
if ($headerPadding -gt 0) { Write-Host (' ' * $headerPadding) -NoNewline }
Write-Host ([char]0x2551) -ForegroundColor Cyan
Write-Host $bottomBorder -ForegroundColor Cyan

Write-Host ""
# Display Purpose (multi-line if needed)
Write-Host "  " -NoNewline
Write-Host "Purpose:" -ForegroundColor Cyan
if ($projectPurpose) {
    # Word wrap for long purpose text
    $maxWidth = 72
    $words = $projectPurpose -split '\s+'
    $currentLine = ""
    foreach ($word in $words) {
        if (($currentLine + " " + $word).Length -gt $maxWidth) {
            Write-Host "    $currentLine" -ForegroundColor White
            $currentLine = $word
        } else {
            if ($currentLine) {
                $currentLine += " " + $word
            } else {
                $currentLine = $word
            }
        }
    }
    if ($currentLine) {
        Write-Host "    $currentLine" -ForegroundColor White
    }
}
Write-Host ""

# Display User Personas
if ($userPersonas.Count -gt 0) {
    Write-Host "  " -NoNewline
    Write-Host "Target Users:" -ForegroundColor Cyan
    foreach ($persona in $userPersonas) {
        Write-Host "    • " -NoNewline -ForegroundColor Gray
        Write-Host $persona.Name -ForegroundColor White
        if ($persona.Description) {
            # Word wrap persona description
            $maxWidth = 68
            $words = $persona.Description -split '\s+'
            $currentLine = ""
            foreach ($word in $words) {
                if (($currentLine + " " + $word).Length -gt $maxWidth) {
                    Write-Host "      $currentLine" -ForegroundColor Gray
                    $currentLine = $word
                } else {
                    if ($currentLine) {
                        $currentLine += " " + $word
                    } else {
                        $currentLine = $word
                    }
                }
            }
            if ($currentLine) {
                Write-Host "      $currentLine" -ForegroundColor Gray
            }
        }
    }
}
Write-Host ""

# Summary
$confidence = if ($state.confidence) { $state.confidence } else { 0 }
$quality = if ($state.quality) { $state.quality } else { 0 }
$confColor = if ($confidence -ge 95) { "Green" } elseif ($confidence -ge 75) { "Yellow" } else { "Red" }
$qualColor = if ($quality -ge 85) { "Green" } elseif ($quality -ge 70) { "Yellow" } else { "Red" }

$summaryTop = "  " + [char]0x250C + ([string][char]0x2500 * 73) + [char]0x2510
$summaryBottom = "  " + [char]0x2514 + ([string][char]0x2500 * 73) + [char]0x2518
Write-Host $summaryTop -ForegroundColor DarkGray

# Calculate padding for perfect alignment
# Static text lengths: "Features: " (10) + "Confidence: " (12) + "Quality: " (9) + "%" (2) = 33
# Separators: " │ " x 3 = 9 chars
# Box edges: "│ " + " │" = 4 chars
# Total static: 33 + 9 + 4 = 46 chars
# Dynamic: featureCount + confidence + quality lengths
$contentLength = 46 + $featureCount.ToString().Length + $confidence.ToString().Length + $quality.ToString().Length
$summaryPad = 75 - $contentLength

Write-Host ("  " + [char]0x2502 + " ") -NoNewline -ForegroundColor DarkGray
Write-Host "Features: $featureCount" -NoNewline -ForegroundColor White
Write-Host (" " + [char]0x2502 + " ") -NoNewline -ForegroundColor DarkGray
Write-Host "Confidence: " -NoNewline -ForegroundColor Gray
Write-Host "$confidence%" -NoNewline -ForegroundColor $confColor
Write-Host (" " + [char]0x2502 + " ") -NoNewline -ForegroundColor DarkGray
Write-Host "Quality: " -NoNewline -ForegroundColor Gray
Write-Host "$quality%" -NoNewline -ForegroundColor $qualColor
if ($summaryPad -gt 0) { Write-Host (' ' * $summaryPad) -NoNewline }
Write-Host (" " + [char]0x2502) -ForegroundColor DarkGray
Write-Host $summaryBottom -ForegroundColor DarkGray

# Feature Details
Write-Section "FEATURES"

foreach ($feature in $state.prd_model.features) {
    Write-FeatureHeader -Name $feature.name -Scope $feature.scope

    Write-Host ""
    # Strip markdown bold syntax from description
    $cleanDescription = $feature.description -replace '^\*\*\s*', '' -replace '\s*\*\*$', ''
    Write-Field "Description:" $cleanDescription
    Write-Host ""

    # Acceptance Criteria
    if ($feature.acceptance -and $feature.acceptance.Count -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "Acceptance Criteria:" -ForegroundColor Cyan
        foreach ($acc in $feature.acceptance) {
            $accText = if ($acc -is [string]) { $acc } elseif ($acc.text) { $acc.text } else { $acc.ToString() }
            Write-ListItem -Text $accText -Prefix "√" -Color Green
        }
        Write-Host ""
    }

    # User Stories
    if ($feature.stories -and $feature.stories.Count -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "User Stories:" -ForegroundColor Cyan
        foreach ($story in $feature.stories) {
            $storyText = if ($story -is [string]) { $story } else { $story.ToString() }
            Write-ListItem -Text $storyText -Prefix "→" -Color Cyan
        }
        Write-Host ""
    }

    # NFR Areas
    if ($feature.nfr) {
        $hasNfr = $false
        if ($feature.nfr -is [string] -and $feature.nfr.Trim()) {
            $hasNfr = $true
        } elseif ($feature.nfr -is [array] -and $feature.nfr.Count -gt 0) {
            $hasNfr = $true
        } elseif ($feature.nfr.Count -gt 0) {
            $hasNfr = $true
        }

        if ($hasNfr) {
            Write-Host "  " -NoNewline
            Write-Host "Non-Functional Requirements:" -ForegroundColor Cyan
            if ($feature.nfr -is [string]) {
                Write-ListItem -Text $feature.nfr -Prefix "!" -Color Yellow
            } else {
                foreach ($nfr in $feature.nfr) {
                    $nfrText = if ($nfr -is [string]) { $nfr } else { $nfr.ToString() }
                    Write-ListItem -Text $nfrText -Prefix "!" -Color Yellow
                }
            }
            Write-Host ""
        }
    }

    # KPIs
    if ($feature.kpis) {
        $hasKpis = $false
        if ($feature.kpis -is [string] -and $feature.kpis.Trim()) {
            $hasKpis = $true
        } elseif ($feature.kpis -is [array] -and $feature.kpis.Count -gt 0) {
            $hasKpis = $true
        } elseif ($feature.kpis.Count -gt 0) {
            $hasKpis = $true
        }

        if ($hasKpis) {
            Write-Host "  " -NoNewline
            Write-Host "Success Metrics (KPIs):" -ForegroundColor Cyan
            if ($feature.kpis -is [string]) {
                Write-ListItem -Text $feature.kpis -Prefix "▪" -Color Magenta
            } else {
                foreach ($kpi in $feature.kpis) {
                    $kpiText = if ($kpi -is [string]) { $kpi } else { $kpi.ToString() }
                    Write-ListItem -Text $kpiText -Prefix "▪" -Color Magenta
                }
            }
            Write-Host ""
        }
    }
}