# Forge Design Interview
# Captures aesthetic input for Phase 2.5 (Visual Design)

function Start-DesignInterview {
    param(
        [string]$ProjectPath,
        [string]$Type
    )

    . "$PSScriptRoot\design-state-manager.ps1"
    . "$PSScriptRoot\design-competitor.ps1"

    # Check if design state already exists
    $existingState = Get-DesignState -ProjectPath $ProjectPath

    # Determine and optionally change the design type (accept any string)
    $resolvedType = if (-not [string]::IsNullOrWhiteSpace($Type)) { $Type } elseif ($existingState -and $existingState.type) { $existingState.type } else { 'website' }

    if ($existingState -and $existingState.interview_complete) {
        Write-Host ""
        Write-Host "[WARN] Design interview already complete ($($existingState.confidence)% confidence)" -ForegroundColor Yellow
        Write-Host "[INFO] Current aesthetic goals: $($existingState.interview.aesthetic_goals)" -ForegroundColor Gray
        Write-Host "[INFO] Current design type: $($existingState.type)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Change design type? (y/N): " -NoNewline -ForegroundColor Cyan
        $typeChange = Read-Host
        if ($typeChange -eq 'y' -or $typeChange -eq 'Y') {
            Write-Host "Enter new type (e.g., website, app, dashboard, mobile, ecommerce): " -NoNewline -ForegroundColor Yellow
            $newType = Read-Host
            if (-not [string]::IsNullOrWhiteSpace($newType)) {
                $resolvedType = $newType
            }
        }

        Write-Host "Edit existing values? (y/N): " -NoNewline -ForegroundColor Cyan
        $response = Read-Host

        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "[INFO] Keeping existing interview data" -ForegroundColor Gray
            return
        }

        Write-Host "[INFO] Entering edit mode..." -ForegroundColor Cyan
        $editMode = $true
    } else {
        $editMode = $false
    }

    # Initialize state if new
    if (-not $existingState) {
        Initialize-DesignState -ProjectPath $ProjectPath -Type $resolvedType
        $state = Get-DesignState -ProjectPath $ProjectPath
    } else {
        $state = $existingState
        # Ensure state type reflects any change
        if ($state.type -ne $resolvedType) { $state.type = $resolvedType }
    }

    # Display banner
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "          FORGE DESIGN INTERVIEW - $($resolvedType.ToUpper()) MODE        " -ForegroundColor Yellow
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PowerShell Function: " -NoNewline -ForegroundColor Gray
    Write-Host "Start-DesignInterview" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Let's capture your aesthetic vision. Answer in 1-2 sentences per question." -ForegroundColor Gray
    Write-Host ""

    # Brief IA context (flow from previous phase)
    try {
        $prdPath = Join-Path $ProjectPath 'prd.md'
        $iaSummary = @()
        if (Test-Path (Join-Path $ProjectPath 'ia.md')) {
            $iaText = Get-Content -Raw (Join-Path $ProjectPath 'ia.md')
        } elseif (Test-Path $prdPath) {
            $iaText = Get-Content -Raw $prdPath
        }
        if ($iaText) {
            if ($iaText -match '(?is)---SITEMAP---(.*?)(?=---|$)') { $iaSummary += "Sitemap: " + (($matches[1].Trim() -split "`n")[0]) }
            if ($iaText -match '(?is)---USER_FLOWS---(.*?)(?=---|$)') { $iaSummary += "User Flows: " + (($matches[1].Trim() -split "`n")[0]) }
            if ($iaText -match '(?m)^##\s+Sitemap\s*(?:\r?\n)+(.+)$') { $iaSummary += "Sitemap: " + $matches[1] }
            if ($iaText -match '(?m)^##\s+User\s*Flows\s*(?:\r?\n)+(.+)$') { $iaSummary += "User Flows: " + $matches[1] }
        }
        if ($iaSummary.Count -gt 0) {
            Write-Host "IA Context (from previous phase):" -ForegroundColor Cyan
            $iaSummary | Select-Object -First 3 | ForEach-Object { Write-Host ("  - " + $_) -ForegroundColor Gray }
            Write-Host "Use this IA context as reference while answering? (Y/n): " -NoNewline -ForegroundColor Cyan
            $useIA = Read-Host
            Write-Host ""  # spacing only; choice is informational for now
        } else {
            Write-Host "No IA summary detected. You can run 'forge import-ia' to add one." -ForegroundColor DarkGray
            Write-Host ""
        }
    } catch { }
    Write-Host ""

    # Optional: Who is it for
    Write-Host "1. Who is this for? (personas, context, accessibility)" -ForegroundColor Cyan
    if ($editMode -and $state.interview.who_for) { Write-Host "   Current: $($state.interview.who_for)" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $whoFor = Read-Host
    if ($editMode -and [string]::IsNullOrWhiteSpace($whoFor)) { $whoFor = $state.interview.who_for }

    # Aesthetic Goals (Feel)
    Write-Host ""
    Write-Host "2. What should the UI feel like?" -ForegroundColor Cyan
    Write-Host "   Examples: ""Modern SaaS, trustworthy, clean"", ""Playful startup, energetic""" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.aesthetic_goals) { Write-Host "   Current: $($state.interview.aesthetic_goals)" -ForegroundColor Gray }
    Write-Host ""
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $aestheticGoals = Read-Host

    # Keep existing if empty in edit mode
    if ($editMode -and [string]::IsNullOrWhiteSpace($aestheticGoals)) {
        $aestheticGoals = $state.interview.aesthetic_goals
    }

    # Anti-patterns
    Write-Host ""
    Write-Host "3. What should it NOT feel like? (Anti-patterns)" -ForegroundColor Cyan
    Write-Host "   Examples: ""Not corporate, not busy"", ""Not playful, not minimalist""" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.anti_patterns) { Write-Host "   Current: $($state.interview.anti_patterns)" -ForegroundColor Gray }
    Write-Host ""
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $antiPatterns = Read-Host

    if ($editMode -and [string]::IsNullOrWhiteSpace($antiPatterns)) {
        $antiPatterns = $state.interview.anti_patterns
    }

    # Color Range (broad constraints)
    Write-Host ""
    Write-Host "4. Color range: warm/cool/neutral preference?" -ForegroundColor Cyan
    if ($editMode -and $state.interview.color_range.warm_cool) { Write-Host "   Current: $($state.interview.color_range.warm_cool)" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $warmCool = Read-Host
    if ($editMode -and [string]::IsNullOrWhiteSpace($warmCool)) { $warmCool = $state.interview.color_range.warm_cool }

    Write-Host "   Light/Dark preference (light/dark/both)?" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.color_range.light_dark) { Write-Host "   Current: $($state.interview.color_range.light_dark)" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $lightDark = Read-Host
    if ($editMode -and [string]::IsNullOrWhiteSpace($lightDark)) { $lightDark = $state.interview.color_range.light_dark }

    Write-Host "   Accents to include (comma-separated, optional):" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.color_range.accents_include.Count -gt 0) { Write-Host "   Current: $($state.interview.color_range.accents_include -join ', ')" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $accentsIncludeInput = Read-Host
    $accentsInclude = @()
    if (-not [string]::IsNullOrWhiteSpace($accentsIncludeInput)) { $accentsInclude = @($accentsIncludeInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } elseif ($editMode) { $accentsInclude = $state.interview.color_range.accents_include }

    Write-Host "   Accents to exclude (comma-separated, optional):" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.color_range.accents_exclude.Count -gt 0) { Write-Host "   Current: $($state.interview.color_range.accents_exclude -join ', ')" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $accentsExcludeInput = Read-Host
    $accentsExclude = @()
    if (-not [string]::IsNullOrWhiteSpace($accentsExcludeInput)) { $accentsExclude = @($accentsExcludeInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } elseif ($editMode) { $accentsExclude = $state.interview.color_range.accents_exclude }

    # Key features
    Write-Host ""
    Write-Host "5. Key features to emphasize (3-5, comma-separated)" -ForegroundColor Cyan
    if ($editMode -and $state.interview.features.Count -gt 0) { Write-Host "   Current: $($state.interview.features -join ', ')" -ForegroundColor Gray }
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $featuresInput = Read-Host
    $features = @()
    if (-not [string]::IsNullOrWhiteSpace($featuresInput)) { $features = @($featuresInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } elseif ($editMode) { $features = $state.interview.features }

    # Inspiration Sites (optional)
    Write-Host ""
    Write-Host "6. Any sites you like the look of? (optional, for next phase)" -ForegroundColor Cyan
    Write-Host "   Paste URLs separated by commas, or type ""none""" -ForegroundColor DarkGray
    if ($editMode -and $state.interview.inspiration_sites.Count -gt 0) {
        Write-Host "   Current: $($state.interview.inspiration_sites -join ', ')" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "   > " -NoNewline -ForegroundColor Yellow
    $sitesInput = Read-Host

    $inspirationSites = @()
    if (-not [string]::IsNullOrWhiteSpace($sitesInput) -and $sitesInput -ne "none") {
        $inspirationSites = @($sitesInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    } elseif ($editMode -and [string]::IsNullOrWhiteSpace($sitesInput)) {
        $inspirationSites = $state.interview.inspiration_sites
    }

    # Validate required fields
    if ([string]::IsNullOrWhiteSpace($aestheticGoals)) {
        Write-Host ""
        Write-Host "[ERROR] Aesthetic goals are required" -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($antiPatterns)) {
        Write-Host ""
        Write-Host "[ERROR] Anti-patterns are required" -ForegroundColor Red
        return
    }
    if ($features.Count -eq 0) {
        Write-Host ""
        Write-Host "[ERROR] Key features are required (3-5, comma-separated)" -ForegroundColor Red
        return
    }

    # Update state
    $state.interview.who_for = if ($whoFor) { $whoFor } else { $state.interview.who_for }
    $state.interview.aesthetic_goals = $aestheticGoals
    $state.interview.anti_patterns = $antiPatterns
    $state.interview.brand_line = $state.interview.brand_line  # reserved for later prompt
    $state.interview.color_range.warm_cool = if ($warmCool) { $warmCool } else { $state.interview.color_range.warm_cool }
    $state.interview.color_range.light_dark = if ($lightDark) { $lightDark } else { $state.interview.color_range.light_dark }
    $state.interview.color_range.accents_include = $accentsInclude
    $state.interview.color_range.accents_exclude = $accentsExclude
    $state.interview.features = $features
    $state.interview.inspiration_sites = $inspirationSites
    $state.interview_complete = $true
    $state.confidence = 20
    $state.type = $resolvedType

    Set-DesignState -ProjectPath $ProjectPath -State $state

    # Persist brief to design.md
    try {
        $briefPath = Join-Path $ProjectPath 'design.md'
        $dateStr = Get-Date -Format 'yyyy-MM-dd'
        $brief = @()
        $brief += "# Design Specification"
        $brief += ""
        $brief += "## 1. Aesthetic Brief"
        $brief += ""
        $brief += "Date: $dateStr"
        $brief += "Type: $resolvedType"
        $brief += "Confidence: 20%"
        $brief += ""
        if ($whoFor) {
            $brief += "### 1.1. Who It’s For"
            $brief += $whoFor
            $brief += ""
        }

        $brief += "### 1.2. Aesthetic Goals"
        $brief += $aestheticGoals
        $brief += ""
        $brief += "### 1.3. Anti-Patterns"
        $brief += $antiPatterns
        $brief += ""
        $brief += "### 1.4. Color Range"
        if ($warmCool) { $brief += "- Warm/Cool/Neutral: $warmCool" }
        if ($lightDark) { $brief += "- Light/Dark: $lightDark" }
        if ($accentsInclude.Count -gt 0) { $brief += ("- Accents (include): " + ($accentsInclude -join ", ")) }
        if ($accentsExclude.Count -gt 0) { $brief += ("- Accents (exclude): " + ($accentsExclude -join ", ")) }
        $brief += ""
        $brief += "### 1.5. Key Features to Emphasize"
        if ($features.Count -gt 0) {
            foreach ($f in $features) { $brief += "- $f" }
        }
        $brief += ""
        $brief += "## 2. Inspiration & Competitive Analysis"
        $brief += ""
        $brief += "### 2.1. Inspiration"
        if ($inspirationSites.Count -gt 0) {
            foreach ($s in $inspirationSites) { $brief += "- [website] $s" }
        }
        $brief += ""
        $brief += "### 2.2. Competitive Analysis Summary"
        $brief += "*(This section will be populated by the `design-competitor.ps1` script)*"
        $brief += ""
        $brief += "## 3. Design System"
        $brief += "*(This section will be populated by the `design-competitor.ps1` script)*"


        $brief -join "`r`n" | Set-Content -Path $briefPath -Encoding UTF8
        Write-Host "[OK] Saved brief to: design.md" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Failed to write design.md: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Display summary
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Green
    Write-Host "                 AESTHETIC INPUT CAPTURED                    " -ForegroundColor Green
    Write-Host "=============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Type: " -NoNewline -ForegroundColor Gray
    Write-Host $resolvedType -ForegroundColor White
    Write-Host "Confidence: " -NoNewline -ForegroundColor Gray
    Write-Host "20%" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Aesthetic Goals:" -ForegroundColor Cyan
    Write-Host "  $aestheticGoals" -ForegroundColor White
    Write-Host ""
    Write-Host "Anti-Patterns:" -ForegroundColor Cyan
    Write-Host "  $antiPatterns" -ForegroundColor White

    if ($colorPrefs) {
        Write-Host ""
        Write-Host "Color Preferences:" -ForegroundColor Cyan
        Write-Host "  $colorPrefs" -ForegroundColor White
    }

    if ($inspirationSites.Count -gt 0) {
        Write-Host ""
        Write-Host "Inspiration Sites:" -ForegroundColor Cyan
        foreach ($site in $inspirationSites) {
            Write-Host "  - $site" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. (Optional) Review IA and brief alignment" -ForegroundColor Gray
    Write-Host "  2. (Next) Competitive analysis to raise confidence" -ForegroundColor Gray
    Write-Host ""

    # Gate to proceed to competitor analysis
    Write-Host "Section complete: Move on to Competitor Analysis now? (Y/n): " -NoNewline -ForegroundColor Cyan
    $proceed = Read-Host
    if ($proceed -ne 'n' -and $proceed -ne 'N') {
        Update-DesignPhase -ProjectPath $ProjectPath -NewPhase 'competitive'
        Start-CompetitorAnalysis -ProjectPath $ProjectPath
    }
}

# Entry point when called directly
if ($MyInvocation.InvocationName -ne '.') {
    $projectPath = Get-Location
    $type = if ($args.Count -gt 0) { $args[0] } else { 'website' }
    Start-DesignInterview -ProjectPath $projectPath -Type $type
}
