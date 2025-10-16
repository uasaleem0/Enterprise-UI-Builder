# Forge IA Parser
# Parses and validates Information Architecture output from Custom GPT

function Import-IABlock {
    param([string]$ProjectPath)

    . "$PSScriptRoot\state-manager.ps1"
    . "$PSScriptRoot\mode-manager.ps1"

    $state = Get-ProjectState -ProjectPath $ProjectPath

    # Check if PRD exists
    $prdPath = Join-Path $ProjectPath "prd.md"
    if (-not (Test-Path $prdPath)) {
        Write-Host ""
        Write-Host "[ERROR] No prd.md found. Complete PRD phase first." -ForegroundColor Red
        Write-Host "[INFO] Run 'forge init' to start a new project" -ForegroundColor Gray
        Write-Host ""
        return
    }

    # Check PRD confidence
    if ($state.confidence -lt 90) {
        Write-Host ""
        Write-Host "[WARN] PRD confidence is $($state.confidence)%. Recommend 90%+ before IA phase." -ForegroundColor Yellow
        Write-Host "[INFO] Continue anyway? (y/N): " -NoNewline -ForegroundColor Cyan
        $response = Read-Host
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "[INFO] Cancelled. Complete PRD validation first." -ForegroundColor Gray
            return
        }
    }

    Write-Host ""
    Write-Host "=== Import Information Architecture ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Paste the [FORGE_IA_START]...[FORGE_IA_END] block from Custom GPT" -ForegroundColor Gray
    Write-Host "Press Enter, then Ctrl+Z and Enter when done:" -ForegroundColor Gray
    Write-Host ""

    # Read multi-line input
    $lines = @()
    while ($true) {
        try {
            $line = Read-Host
            if ($null -eq $line) { break }
            $lines += $line
        } catch {
            break
        }
    }

    $content = $lines -join "`n"

    # Validate format
    if ($content -notmatch '\[FORGE_IA_START\]') {
        Write-Host ""
        Write-Host "[ERROR] Invalid format. Missing [FORGE_IA_START] marker." -ForegroundColor Red
        Write-Host "[INFO] Copy the complete output from Custom GPT including markers." -ForegroundColor Gray
        return
    }

    if ($content -notmatch '\[FORGE_IA_END\]') {
        Write-Host ""
        Write-Host "[ERROR] Invalid format. Missing [FORGE_IA_END] marker." -ForegroundColor Red
        return
    }

    # Extract content between markers
    if ($content -match '(?s)\[FORGE_IA_START\](.*?)\[FORGE_IA_END\]') {
        $iaContent = $matches[1].Trim()
    } else {
        Write-Host "[ERROR] Could not extract IA content between markers." -ForegroundColor Red
        return
    }

    # Parse sections
    $sections = @{
        sitemap = ""
        flows = ""
        navigation = ""
        components = ""
        entities = ""
    }

    $metadata = @{}

    # Extract metadata (PROJECT, DATE, CONFIDENCE)
    if ($iaContent -match '(?m)^PROJECT:\s*(.+)$') {
        $metadata.project = $matches[1].Trim()
    }
    if ($iaContent -match '(?m)^DATE:\s*(.+)$') {
        $metadata.date = $matches[1].Trim()
    }
    if ($iaContent -match '(?m)^CONFIDENCE:\s*(\d+)%?') {
        $metadata.confidence = [int]$matches[1]
    }

    # Extract sections
    if ($iaContent -match '(?s)---SITEMAP---(.*?)(?=---|$)') {
        $sections.sitemap = $matches[1].Trim()
    }
    if ($iaContent -match '(?s)---USER_FLOWS---(.*?)(?=---|$)') {
        $sections.flows = $matches[1].Trim()
    }
    if ($iaContent -match '(?s)---NAVIGATION---(.*?)(?=---|$)') {
        $sections.navigation = $matches[1].Trim()
    }
    if ($iaContent -match '(?s)---COMPONENTS---(.*?)(?=---|$)') {
        $sections.components = $matches[1].Trim()
    }
    if ($iaContent -match '(?s)---DATA_ENTITIES---(.*?)(?=---|$)') {
        $sections.entities = $matches[1].Trim()
    }

    # Validate required sections
    $missing = @()
    if ([string]::IsNullOrWhiteSpace($sections.sitemap)) { $missing += "SITEMAP" }
    if ([string]::IsNullOrWhiteSpace($sections.flows)) { $missing += "USER_FLOWS" }
    if ([string]::IsNullOrWhiteSpace($sections.navigation)) { $missing += "NAVIGATION" }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "[ERROR] Missing required sections: $($missing -join ', ')" -ForegroundColor Red
        Write-Host "[INFO] Ensure Custom GPT output includes all sections" -ForegroundColor Gray
        return
    }

    # Display parsed content summary
    Write-Host ""
    Write-Host "=== Parsed IA Content ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Project: " -NoNewline -ForegroundColor Gray
    Write-Host $metadata.project -ForegroundColor White
    Write-Host "Date: " -NoNewline -ForegroundColor Gray
    Write-Host $metadata.date -ForegroundColor White
    Write-Host "Confidence: " -NoNewline -ForegroundColor Gray
    Write-Host "$($metadata.confidence)%" -ForegroundColor $(if ($metadata.confidence -ge 75) { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "Sections parsed:" -ForegroundColor Gray
    Write-Host "  [OK] Sitemap ($($sections.sitemap.Length) chars)" -ForegroundColor Green
    Write-Host "  [OK] User Flows ($($sections.flows.Length) chars)" -ForegroundColor Green
    Write-Host "  [OK] Navigation ($($sections.navigation.Length) chars)" -ForegroundColor Green
    if (-not [string]::IsNullOrWhiteSpace($sections.components)) {
        Write-Host "  [OK] Components ($($sections.components.Length) chars)" -ForegroundColor Green
    }
    if (-not [string]::IsNullOrWhiteSpace($sections.entities)) {
        Write-Host "  [OK] Data Entities ($($sections.entities.Length) chars)" -ForegroundColor Green
    }
    Write-Host ""

    # Validate against PRD features
    Write-Host "Validating against PRD..." -ForegroundColor Cyan
    $prdContent = Get-Content $prdPath -Raw

    # Extract features from PRD (look for ## Features or ### Features section)
    $features = @()
    if ($prdContent -match '(?s)##\s+Features(.*?)(?=##|$)') {
        $featureSection = $matches[1]
        # Extract bullet points or numbered items
        $featureMatches = [regex]::Matches($featureSection, '(?m)^[\s\-\*\d\.]+(.+)$')
        foreach ($match in $featureMatches) {
            $feature = $match.Groups[1].Value.Trim()
            if ($feature -and $feature.Length -gt 3) {
                $features += $feature
            }
        }
    }

    if ($features.Count -gt 0) {
        Write-Host "Found $($features.Count) features in PRD" -ForegroundColor Gray

        # Check if features are mentioned in sitemap or flows
        $unmappedFeatures = @()
        foreach ($feature in $features) {
            $featureKeywords = $feature -split '\s+' | Where-Object { $_.Length -gt 3 } | Select-Object -First 3
            $found = $false
            foreach ($keyword in $featureKeywords) {
                if ($sections.sitemap -match [regex]::Escape($keyword) -or
                    $sections.flows -match [regex]::Escape($keyword)) {
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                $unmappedFeatures += $feature
            }
        }

        if ($unmappedFeatures.Count -gt 0) {
            Write-Host ""
            Write-Host "[WARN] Some PRD features may not be mapped in IA:" -ForegroundColor Yellow
            foreach ($feature in $unmappedFeatures) {
                Write-Host "  - $feature" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "Continue with import? (y/N): " -NoNewline -ForegroundColor Cyan
            $response = Read-Host
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "[INFO] Import cancelled. Update IA in Custom GPT and try again." -ForegroundColor Gray
                return
            }
        } else {
            Write-Host "[OK] All PRD features appear to be mapped" -ForegroundColor Green
        }
    }

    # Save files
    Write-Host ""
    Write-Host "Saving IA files..." -ForegroundColor Cyan

    # Create IA directory if needed
    $iaDir = Join-Path $ProjectPath "ia"
    if (-not (Test-Path $iaDir)) {
        New-Item -ItemType Directory -Path $iaDir -Force | Out-Null
    }

    # Save each section
    $timestamp = Get-Date -Format "yyyy-MM-dd"

    $sitemapContent = @"
# Sitemap
Generated: $timestamp
Confidence: $($metadata.confidence)%

$($sections.sitemap)
"@
    Set-Content (Join-Path $iaDir "sitemap.md") $sitemapContent

    $flowsContent = @"
# User Flows
Generated: $timestamp
Confidence: $($metadata.confidence)%

$($sections.flows)
"@
    Set-Content (Join-Path $iaDir "flows.md") $flowsContent

    $navContent = @"
# Navigation Structure
Generated: $timestamp
Confidence: $($metadata.confidence)%

$($sections.navigation)
"@
    Set-Content (Join-Path $iaDir "navigation.md") $navContent

    if (-not [string]::IsNullOrWhiteSpace($sections.components)) {
        $componentsContent = @"
# Component Inventory
Generated: $timestamp
Confidence: $($metadata.confidence)%

$($sections.components)
"@
        Set-Content (Join-Path $iaDir "components.md") $componentsContent
    }

    if (-not [string]::IsNullOrWhiteSpace($sections.entities)) {
        $entitiesContent = @"
# Data Entities
Generated: $timestamp
Confidence: $($metadata.confidence)%

$($sections.entities)
"@
        Set-Content (Join-Path $iaDir "entities.md") $entitiesContent
    }

    # Update state
    if (-not $state.deliverables) {
        $state.deliverables = @{}
    }
    $state.deliverables.ia_sitemap = 1
    $state.deliverables.ia_flows = 1
    $state.deliverables.ia_navigation = 1
    if (-not [string]::IsNullOrWhiteSpace($sections.components)) {
        $state.deliverables.ia_components = 1
    }
    if (-not [string]::IsNullOrWhiteSpace($sections.entities)) {
        $state.deliverables.ia_entities = 1
    }

    # Update IA confidence in state (separate from PRD confidence)
    $state.ia_confidence = $metadata.confidence

    Set-ProjectState -ProjectPath $ProjectPath -State $state

    # Update .agent/ folder architecture docs
    . "$PSScriptRoot\agent-manager.ps1"
    $iaData = @{
        Sitemap = $sections.sitemap
        Pages = @("Parsed from sitemap")
        Components = if ($sections.components) { @($sections.components) } else { @() }
        Navigation = $sections.navigation
        Flows = @($sections.flows)
    }
    Update-AgentArchitecture -ProjectPath $ProjectPath -IAData $iaData
    Update-AgentReadme -ProjectPath $ProjectPath -State $state

    # Log in dev mode
    if ((Get-ForgeMode) -eq "dev") {
        Write-DevLog -Operation "import" -File "ia/*.md" -Description "Imported IA from Custom GPT (confidence: $($metadata.confidence)%)"
    }

    Write-Host ""
    Write-Host "=== Import Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files created:" -ForegroundColor Gray
    Write-Host "  ia/sitemap.md" -ForegroundColor White
    Write-Host "  ia/flows.md" -ForegroundColor White
    Write-Host "  ia/navigation.md" -ForegroundColor White
    if (-not [string]::IsNullOrWhiteSpace($sections.components)) {
        Write-Host "  ia/components.md" -ForegroundColor White
    }
    if (-not [string]::IsNullOrWhiteSpace($sections.entities)) {
        Write-Host "  ia/entities.md" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "IA Confidence: $($metadata.confidence)%" -ForegroundColor $(if ($metadata.confidence -ge 75) { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review ia/*.md files" -ForegroundColor Gray
    Write-Host "  2. (Optional) Paste IA block into Claude Project for Mermaid visualization" -ForegroundColor Gray
    Write-Host "  3. Begin implementation in Cursor with IA as reference" -ForegroundColor Gray
    Write-Host ""
}
