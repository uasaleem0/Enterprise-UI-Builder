# Forge Design Importer
# Handles the import of a pre-written design brief.

function Invoke-ImportDesignBrief {
    param(
        [string]$ProjectPath,
        [string]$ImportFilePath
    )

    . "$PSScriptRoot\design-state-manager.ps1"

    # --- Guardrail 1: Ensure we are in a valid Forge Project ---
    $projectsRoot = Join-Path $env:USERPROFILE "AI\Projects"
    if (-not $ProjectPath.StartsWith($projectsRoot)) {
        Write-Host '[ERROR] This command must be run from within a valid project directory inside your AI\Projects folder.' -ForegroundColor Red
        return
    }

    # --- Guardrail 2: Ensure PRD and IA are present ---
    $prdPath = Join-Path $ProjectPath 'prd.md'
    $iaPath = Join-Path $ProjectPath 'ia.md'
    if (-not (Test-Path $prdPath)) {
        Write-Host '[ERROR] A prd.md file was not found in the project root. Please complete the PRD phase first.' -ForegroundColor Red
        return
    }
    if (-not (Test-Path $iaPath)) {
        Write-Host '[WARN] An ia.md file was not found. It is recommended to complete the IA phase first.' -ForegroundColor Yellow
    }

    # --- File Parsing Logic ---
    if (-not (Test-Path $ImportFilePath)) {
        Write-Host "[ERROR] The specified import file was not found: $ImportFilePath" -ForegroundColor Red
        return
    }

    $content = Get-Content -Raw $ImportFilePath
    $state = Get-DesignState -ProjectPath $ProjectPath
    if (-not $state) {
        Initialize-DesignState -ProjectPath $ProjectPath -Type 'website' # Default type
        $state = Get-DesignState -ProjectPath $ProjectPath
    }

    # Helper to parse sections
    function Get-SectionContent($content, $heading) {
        $pattern = "(?is)### $heading\s*\n(.*?)(?=\n###|\z)"
        if ($content -match $pattern) {
            return $matches[1].Trim()
        }
        return ""
    }

    $aestheticGoals = Get-SectionContent -content $content -heading "Aesthetic Goals"
    $antiPatterns = Get-SectionContent -content $content -heading "Anti-Patterns"
    $keyFeatures = (Get-SectionContent -content $content -heading "Key Features to Emphasize") -split '\n' | ForEach-Object { $_.Trim() -replace '^- ', '' }
    $inspirationSitesRaw = (Get-SectionContent -content $content -heading "Inspiration Sites") -split '\n' | ForEach-Object { $_.Trim() -replace '^- ', '' }

    # Parse Color Range
    $colorContent = Get-SectionContent -content $content -heading "Color Range"
    $warmCool = if ($colorContent -match '- Preference: (.*)') { $matches[1].Trim() } else { '' }
    $lightDark = if ($colorContent -match '- Theme: (.*)') { $matches[1].Trim() } else { '' }
    $accentsInclude = if ($colorContent -match '- Accents to Include: (.*)') { @($matches[1].Trim() -split ',' | ForEach-Object { $_.Trim() }) } else { @() }
    $accentsExclude = if ($colorContent -match '- Accents to Exclude: (.*)') { @($matches[1].Trim() -split ',' | ForEach-Object { $_.Trim() }) } else { @() }

    # --- Validation ---
    if ([string]::IsNullOrWhiteSpace($aestheticGoals) -or [string]::IsNullOrWhiteSpace($antiPatterns)) {
        Write-Host '[ERROR] Import failed. The import file must contain `''### Aesthetic Goals`'' and `''### Anti-Patterns`'' sections.' -ForegroundColor Red
        return
    }

    # --- Update State and Create Files ---
    $state.interview.aesthetic_goals = $aestheticGoals
    $state.interview.anti_patterns = $antiPatterns
    $state.interview.features = $keyFeatures
    $state.interview.inspiration_sites = $inspirationSitesRaw
    $state.interview.color_range.warm_cool = $warmCool
    $state.interview.color_range.light_dark = $lightDark
    $state.interview.color_range.accents_include = $accentsInclude
    $state.interview.color_range.accents_exclude = $accentsExclude
    $state.interview_complete = $true
    $state.confidence = 20

    Set-DesignState -ProjectPath $ProjectPath -State $state

    # Persist a copy of the brief to the design folder
    $designDir = Join-Path $ProjectPath 'design'
    if (-not (Test-Path $designDir)) { New-Item -ItemType Directory -Path $designDir -Force | Out-Null }
    $briefPath = Join-Path $designDir 'aesthetic-brief.md'
    Copy-Item -Path $ImportFilePath -Destination $briefPath -Force

    Write-Host "[OK] Successfully imported design brief from $ImportFilePath." -ForegroundColor Green
    Write-Host '[i] A copy has been saved to design/aesthetic-brief.md' -ForegroundColor Gray
    Write-Host '[i] Confidence set to 20%.' -ForegroundColor Yellow
    Write-Host ""
    Write-Host 'System is now ready to proceed to Protocol 1: Guided Discovery & Approval.' -ForegroundColor Cyan
    Write-Host "Move on to Competitor Analysis now? (Y/n): " -NoNewline -ForegroundColor Cyan
    $proceed = Read-Host
    if ($proceed -ne 'n' -and $proceed -ne 'N') {
        Update-DesignPhase -ProjectPath $ProjectPath -NewPhase 'competitive'
        . "$PSScriptRoot\design-competitor.ps1"
        Start-CompetitorAnalysis -ProjectPath $ProjectPath
    }
}

