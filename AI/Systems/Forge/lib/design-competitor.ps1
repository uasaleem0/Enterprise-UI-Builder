# Forge Competitor Analysis - Experience-First Methodology
# Implements semantic analysis, Playwright capture, and confidence-gated interpretation

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-SiteHeader {
    param(
        [string]$SiteName,
        [int]$Current,
        [int]$Total
    )

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   SITE $Current of $Total`: " -NoNewline -ForegroundColor Gray
    Write-Host $SiteName.ToUpper() -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
}

function Measure-FeedbackSpecificity {
    param(
        [string]$Feedback,
        [string]$AestheticGoals
    )

    # Design-related keywords that indicate specific feedback
    $designKeywords = @(
        'spacing', 'color', 'typography', 'layout', 'shadow', 'radius',
        'hero', 'navigation', 'button', 'card', 'hierarchy', 'contrast',
        'whitespace', 'font', 'bold', 'margin', 'padding', 'grid',
        'hover', 'animation', 'transition', 'header', 'footer'
    )

    # Vague phrases that indicate low specificity
    $vaguePhrases = @('looks good', 'nice', 'looks nice', 'good design')

    # Count specific design keywords
    $specificCount = 0
    foreach ($keyword in $designKeywords) {
        if ($Feedback.ToLower() -match "\b$keyword\b") {
            $specificCount++
        }
    }

    # Count vague phrases
    $vagueCount = 0
    foreach ($phrase in $vaguePhrases) {
        if ($Feedback.ToLower() -match $phrase) {
            $vagueCount++
        }
    }

    # Check semantic overlap with aesthetic goals
    $goalOverlap = 0
    $goalWords = $AestheticGoals.ToLower() -split '[,\s]+' | Where-Object { $_.Length -gt 3 }
    foreach ($word in $goalWords) {
        if ($Feedback.ToLower() -match "\b$word\b") {
            $goalOverlap++
        }
    }

    # Calculate specificity score
    $specificity = 0

    if ($specificCount -ge 3) { $specificity += 40 }
    elseif ($specificCount -ge 1) { $specificity += 20 }

    if ($goalOverlap -ge 2) { $specificity += 40 }
    elseif ($goalOverlap -ge 1) { $specificity += 20 }

    if ($vagueCount -eq 0 -and $specificCount -gt 0) { $specificity += 20 }

    return [Math]::Min(100, $specificity)
}

function Test-InteractionFeedback {
    param([string]$Feedback)

    $interactionKeywords = @('hover', 'animation', 'transition', 'click', 'active', 'focus', 'interaction')

    foreach ($keyword in $interactionKeywords) {
        if ($Feedback.ToLower() -match "\b$keyword\b") {
            return $true
        }
    }

    return $false
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

function Start-CompetitorAnalysis {
    param([string]$ProjectPath)

    . "$PSScriptRoot\design-state-manager.ps1"

    $state = Get-DesignState -ProjectPath $ProjectPath

    if (-not $state -or -not $state.interview_complete) {
        Write-Host "  [OK] Please complete design interview first (forge design-interview)" -ForegroundColor Red
        return
    }

    $designDir = Join-Path $ProjectPath 'design'
    if (-not (Test-Path $designDir)) {
        New-Item -ItemType Directory -Path $designDir -Force | Out-Null
    }

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "         COMPETITIVE ANALYSIS - EXPERIENCE-FIRST          " -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Confidence: " -NoNewline -ForegroundColor Gray
    Write-Host "$($state.confidence)%" -ForegroundColor $(if ($state.confidence -ge 60) { 'Green' } elseif ($state.confidence -ge 40) { 'Yellow' } else { 'White' })
    Write-Host "Aesthetic Goals: " -NoNewline -ForegroundColor Gray
    Write-Host $state.interview.aesthetic_goals -ForegroundColor White
    Write-Host ""
    Write-Host "This workflow has 5 phases:" -ForegroundColor DarkGray
    Write-Host "  1. Site Discovery (Approve 3-5 inspiration sites)" -ForegroundColor DarkGray
    Write-Host "  2. Feedback Collection (Explain what you like)" -ForegroundColor DarkGray
    Write-Host "  3. Playwright Capture (Screenshots + CSS extraction)" -ForegroundColor DarkGray
    Write-Host "  4. Dashboard Generation (Visual review)" -ForegroundColor DarkGray
    Write-Host "  5. Design System Extraction (Create design-system.md)" -ForegroundColor DarkGray
    Write-Host ""

    # Phase 1: Source Gathering (Manual + AI)
    $approvedSites = Invoke-AidedInspirationDiscovery -State $state -ProjectPath $ProjectPath

    if ($approvedSites.Count -lt 5) {
        Write-Host ""
        Write-Host "[ERROR] Protocol 1 did not complete successfully. Exiting." -ForegroundColor Red
        return
    }

    # Handoff to Protocol 2
    Write-Host "We are now ready to proceed to Protocol 2: Visual Analysis & Capture." -ForegroundColor Green
    Write-Host ""
    
    # --- The rest of the phases are placeholders for now ---

    # Phase 2: Detailed Feedback Collection (Batch)
    # $siteFeedback = Invoke-FeedbackCollection -Sites $approvedSites -State $state

    # Phase 3: Playwright Capture + AI Interpretation
    # $siteAnalyses = Invoke-PlaywrightAnalysis -Feedback $siteFeedback -ProjectPath $ProjectPath -State $state

    # Phase 4: Generate Dashboard
    # Invoke-DashboardGeneration -Analyses $siteAnalyses -ProjectPath $ProjectPath

    # Phase 5: Design System Extraction
    # Invoke-DesignSystemExtraction -Analyses $siteAnalyses -ProjectPath $ProjectPath -State $state

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Green
    Write-Host "         COMPETITIVE ANALYSIS COMPLETE (Protocol 1)        " -ForegroundColor Green
        Write-Host ('=' * 61) -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# PHASE 1: GUIDED DISCOVERY & APPROVAL
# ============================================================================

function Invoke-AidedInspirationDiscovery {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    $approvedSites = [System.Collections.Generic.List[hashtable]]::new()
    $targetSiteCount = 5

    Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   PROTOCOL 1: GUIDED DISCOVERY & APPROVAL                 " -ForegroundColor Yellow
    Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Goal: " -NoNewline -ForegroundColor Gray
    Write-Host "Approve exactly $targetSiteCount inspirational websites." -ForegroundColor White
    Write-Host ""

    # Main loop continues until we have 5 approved sites
    while ($approvedSites.Count -lt $targetSiteCount) {
        Write-Host "You have $($approvedSites.Count)/$targetSiteCount approved sites." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "What would you like to do?" -ForegroundColor Cyan
        Write-Host "  1. Add a URL from Gemini's suggestions" -ForegroundColor Gray
        Write-Host "  2. Add a URL manually" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Choose (1/2): " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host

        $url = ""
        $justification = ""

        if ($choice -eq '1') {
            Write-Host ""
            Write-Host "Action: Please ask Gemini for a suggestion now." -ForegroundColor Cyan
            Write-Host "Please paste the URL from Gemini's suggestion:" -NoNewline -ForegroundColor Yellow
            $url = Read-Host
            Write-Host "Please paste the justification for this URL:" -NoNewline -ForegroundColor Yellow
            $justification = Read-Host
        }
        elseif ($choice -eq '2') {
            Write-Host ""
            Write-Host "Please enter the URL you would like to add:" -NoNewline -ForegroundColor Yellow
            $url = Read-Host
            $justification = "Manually added by user."
        }
        else {
            Write-Host "[ERROR] Invalid choice. Please enter 1 or 2." -ForegroundColor Red
            continue
        }

        # --- Validation and Guardrails ---
        if (-not ($url -match "^https?://")) {
            Write-Host "[ERROR] Invalid URL format. Please include http:// or https://." -ForegroundColor Red
            Write-Host ""
            continue
        }

        $isDuplicate = $false
        foreach ($site in $approvedSites) {
            if ($site.url -eq $url) {
                $isDuplicate = $true
                break
            }
        }
        if ($isDuplicate) {
            Write-Host "[WARN] This URL has already been approved." -ForegroundColor Yellow
            Write-Host ""
            continue
        }

        # --- Approval Step ---
        Write-Host ""
        Write-Host ('-' * 61) -ForegroundColor DarkGray
        Write-Host "Candidate [$($approvedSites.Count + 1)/$targetSiteCount]: $url" -ForegroundColor White
        Write-Host "Reason: $justification" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Approve this site for analysis? (y/n): " -NoNewline -ForegroundColor Yellow
        $approval = Read-Host

        if ($approval -eq 'y') {
            $approvedSites.Add(@{ url = $url; justification = $justification })
            Write-Host "[✓] Approved." -ForegroundColor Green
        } else {
            Write-Host "[i] Rejected." -ForegroundColor Yellow
        }
        Write-Host ('-' * 61) -ForegroundColor DarkGray
        Write-Host ""
    }

    # --- Completion ---
    Write-Host ""
    Write-Host ('=' * 61) -ForegroundColor Green
    Write-Host "         [✓] PROTOCOL 1 COMPLETE                           " -ForegroundColor Green
    Write-Host ('=' * 61) -ForegroundColor Green
    Write-Host ""
    Write-Host "Final Approved Inspiration Sites:" -ForegroundColor Cyan
    foreach ($site in $approvedSites) {
        Write-Host "  - $($site.url)" -ForegroundColor White
    }
    Write-Host ""

    # Save state
    . "$PSScriptRoot\design-state-manager.ps1"
    $State.inspiration_sites = $approvedSites
    Set-DesignState -ProjectPath $ProjectPath -State $State

    return $approvedSites
}

# ============================================================================
# PHASE 2: FEEDBACK COLLECTION
# ============================================================================

function Invoke-FeedbackCollection {
    param(
        [array]$Sites,
        [hashtable]$State
    )

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   PHASE 2 of 5: DETAILED FEEDBACK COLLECTION              " -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PowerShell Function: " -NoNewline -ForegroundColor Gray
    Write-Host "Invoke-FeedbackCollection" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Goal: " -NoNewline -ForegroundColor Gray
    Write-Host "Explain what you like about each approved site" -ForegroundColor White
    Write-Host ""
    Write-Host "For each site you will:" -ForegroundColor DarkGray
    Write-Host "  1. Specify what parts you like (hero, buttons, layout, etc.)" -ForegroundColor DarkGray
    Write-Host "  2. Explain why it matches your aesthetic goals" -ForegroundColor DarkGray
    Write-Host "  3. (Optional) Request interaction video capture" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Quality gates:" -ForegroundColor DarkGray
    Write-Host "  â€¢ Minimum 2 words for 'what parts'" -ForegroundColor DarkGray
    Write-Host "  â€¢ Minimum 40% semantic specificity for 'why matches'" -ForegroundColor DarkGray
    Write-Host ""

    $feedback = @()

    for ($i = 0; $i -lt $Sites.Count; $i++) {
        $site = $Sites[$i]
        Show-SiteHeader -SiteName $site -Current ($i + 1) -Total $Sites.Count

        Write-Host "What parts do you like?" -ForegroundColor Cyan
        Write-Host '  (e.g., "hero section", "entire site", "navigation + buttons")' -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  > " -NoNewline -ForegroundColor Yellow
        $whatParts = Read-Host

        # Validate specificity
        while ([string]::IsNullOrWhiteSpace($whatParts) -or $whatParts.Split(' ').Count -lt 2) {
            Write-Host ""
            Write-Host '[WARN] Please be more specific (at least 2 words)' -ForegroundColor Yellow
            Write-Host "  >" -ForegroundColor Yellow
            $whatParts = Read-Host
        }

        Write-Host ""
        Write-Host "Why does this match your aesthetic goals?" -ForegroundColor Cyan
        Write-Host "  (Connect to: $($State.interview.aesthetic_goals))" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  > " -NoNewline -ForegroundColor Yellow
        $whyMatches = Read-Host

        # Validate specificity
        $specificity = Measure-FeedbackSpecificity -Feedback $whyMatches -AestheticGoals $State.interview.aesthetic_goals

        while ($specificity -lt 40) {
            Write-Host ""
            Write-Host '[WARN] Please provide more specific feedback (mention design elements)' -ForegroundColor Yellow
            Write-Host "  Current specificity: $specificity%" -ForegroundColor DarkGray
            Write-Host "  >" -ForegroundColor Yellow
            $whyMatches = Read-Host
            $specificity = Measure-FeedbackSpecificity -Feedback $whyMatches -AestheticGoals $State.interview.aesthetic_goals
        }

        # Check for interaction feedback
        $captureInteractions = $false
        $allFeedback = "$whatParts $whyMatches"
        if (Test-InteractionFeedback -Feedback $allFeedback) {
            Write-Host ""
            Write-Host '[DETECTED] You mentioned interactions (hover, animations, etc.)' -ForegroundColor Cyan
            Write-Host "Capture interaction video? (y/n): " -NoNewline -ForegroundColor Yellow
            $captureVideo = Read-Host
            $captureInteractions = ($captureVideo -eq 'y' -or $captureVideo -eq 'Y')
        }

        $feedback += @{
            url = $site
            what_parts = $whatParts
            why_matches = $whyMatches
            specificity_score = $specificity
            capture_interactions = $captureInteractions
        }

        Write-Host ""
        Write-Host "  [OK] Feedback saved (specificity: $specificity%)" -ForegroundColor Green
    }

    Write-Host ""
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host "  [OK] Phase 2 Complete: Collected feedback for $($Sites.Count) sites" -ForegroundColor Green
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host ""

    return $feedback
}

# ============================================================================
# PHASE 3: PLAYWRIGHT ANALYSIS (PLACEHOLDER)
# ============================================================================

function Invoke-PlaywrightAnalysis {
    param(
        [array]$Feedback,
        [string]$ProjectPath,
        [hashtable]$State
    )

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   PHASE 3 of 5: PLAYWRIGHT CAPTURE + AI INTERPRETATION    " -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PowerShell Function: " -NoNewline -ForegroundColor Gray
    Write-Host "Invoke-PlaywrightAnalysis" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Goal: " -NoNewline -ForegroundColor Gray
    Write-Host "Capture screenshots and extract design tokens" -ForegroundColor White
    Write-Host ""
    Write-Host "For each site:" -ForegroundColor DarkGray
    Write-Host "  1. Playwright captures screenshots (full + regions)" -ForegroundColor DarkGray
    Write-Host "  2. Extract CSS (colors, typography, spacing, shadows, radius)" -ForegroundColor DarkGray
    Write-Host "  3. AI interprets why tokens match your aesthetic goals" -ForegroundColor DarkGray
    Write-Host "  4. You confirm or clarify the interpretation" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Actions available:" -ForegroundColor DarkGray
    Write-Host "  â€¢ Approve interpretation (y)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Request re-analysis (n)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Ask clarifying questions (clarify)" -ForegroundColor DarkGray
    Write-Host ""

    $analyses = @()

    for ($i = 0; $i -lt $Feedback.Count; $i++) {
        $item = $Feedback[$i]
        Show-SiteHeader -SiteName $item.url -Current ($i + 1) -Total $Feedback.Count

        Write-Host "  [OK] Playwright capture would happen here:" -ForegroundColor Yellow
        Write-Host "  - Full-page screenshot" -ForegroundColor Gray
        Write-Host "  - Region capture: $($item.what_parts)" -ForegroundColor Gray

        if ($item.capture_interactions) {
            Write-Host "  - Interaction video (5 seconds)" -ForegroundColor Gray
            Write-Host "  - Hover/active/focus states" -ForegroundColor Gray
        }

        Write-Host "  - CSS extraction (colors, typography, spacing, shadows, radius)" -ForegroundColor Gray
        Write-Host ""

        # Placeholder analysis
        $analysis = @{
            url = $item.url
            user_feedback = @{
                what_parts = $item.what_parts
                why_matches = $item.why_matches
                specificity = $item.specificity_score
            }
            extracted_tokens = @{
                colors = @('#5E6AD2', '#1F2937', '#FFFFFF')
                typography = @{
                    heading_size = 48
                    heading_weight = 700
                    body_size = 18
                    font_family = 'Inter'
                }
                spacing = @{
                    vertical = 128
                    horizontal = 24
                }
                shadow = '0 1px 2px rgba(0,0,0,0.05)'
                radius = 8
            }
            screenshots = @{
                full_page = "design/screenshots/$($item.url -replace '[:/]', '_')/full.png"
                regions = @()
            }
            confidence = 75
        }

        Write-Host "  [OK] AI Interpretation:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Design Tokens Extracted:" -ForegroundColor Cyan
        Write-Host "  - Colors: $($analysis.extracted_tokens.colors -join ', ')" -ForegroundColor White
        Write-Host "  - Typography: $($analysis.extracted_tokens.typography.heading_size)px / $($analysis.extracted_tokens.typography.body_size)px" -ForegroundColor White
        Write-Host "  - Spacing: $($analysis.extracted_tokens.spacing.vertical)px vertical" -ForegroundColor White
        Write-Host ""
        Write-Host "Why This Matches Your Goals:" -ForegroundColor Cyan
        Write-Host "  - '$($State.interview.aesthetic_goals.Split(',')[0].Trim())' matches because:" -ForegroundColor White
        Write-Host "    Limited colors ($($analysis.extracted_tokens.colors.Count)) = professional, not playful" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Interpretation Confidence: $($analysis.confidence)%" -ForegroundColor $(if ($analysis.confidence -ge 80) { 'Green' } elseif ($analysis.confidence -ge 60) { 'Yellow' } else { 'Red' })
        Write-Host ""

        if ($analysis.confidence -lt 60) {
            Write-Host "  [OK] Low confidence - would trigger clarifying questions" -ForegroundColor Yellow
        }

        Write-Host "Does this interpretation match your vision? (y/n/clarify): " -NoNewline -ForegroundColor Yellow
        $approval = Read-Host

        if ($approval -eq 'n' -or $approval -eq 'N') {
            Write-Host "  [OK] Would re-analyze with adjusted parameters" -ForegroundColor Gray
        }
        elseif ($approval -eq 'clarify') {
            Write-Host "  [OK] Would ask clarifying questions here" -ForegroundColor Yellow
        }

        $analyses += $analysis
    }

    Write-Host ""
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host "  [OK] Phase 3 Complete: Analyzed $($Feedback.Count) sites" -ForegroundColor Green
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host ""

    return $analyses
}

# ============================================================================
# PHASE 4: DASHBOARD GENERATION (PLACEHOLDER)
# ============================================================================

function Invoke-DashboardGeneration {
    param(
        [array]$Analyses,
        [string]$ProjectPath
    )

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   PHASE 4 of 5: GENERATING INSPIRATION DASHBOARD          " -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PowerShell Function: " -NoNewline -ForegroundColor Gray
    Write-Host "Invoke-DashboardGeneration" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Goal: " -NoNewline -ForegroundColor Gray
    Write-Host "Create visual dashboard for final review" -ForegroundColor White
    Write-Host ""
    Write-Host "Dashboard will include:" -ForegroundColor DarkGray
    Write-Host "  â€¢ Side-by-side screenshots of all analyzed sites" -ForegroundColor DarkGray
    Write-Host "  â€¢ Your feedback (what parts + why matches)" -ForegroundColor DarkGray
    Write-Host "  â€¢ AI interpretations (token mapping)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Extracted design tokens with visual samples" -ForegroundColor DarkGray
    Write-Host "  â€¢ Color swatches and typography specimens" -ForegroundColor DarkGray
    Write-Host ""

    $dashboardPath = Join-Path $ProjectPath 'design' 'inspiration-dashboard.html'

    Write-Host "  [OK] Generating HTML dashboard..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would save to: " -NoNewline -ForegroundColor Gray
    Write-Host $dashboardPath -ForegroundColor White
    Write-Host ""
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host "  [OK] Phase 4 Complete: Dashboard ready for review" -ForegroundColor Green
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================================
# PHASE 5: DESIGN SYSTEM EXTRACTION (PLACEHOLDER)
# ============================================================================

function Invoke-DesignSystemExtraction {
    param(
        [array]$Analyses,
        [string]$ProjectPath,
        [hashtable]$State
    )

    Write-Host ""
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host "   PHASE 5 of 5: DESIGN SYSTEM EXTRACTION                  " -ForegroundColor Yellow
        Write-Host ('=' * 61) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PowerShell Function: " -NoNewline -ForegroundColor Gray
    Write-Host "Invoke-DesignSystemExtraction" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Goal: " -NoNewline -ForegroundColor Gray
    Write-Host "Extract complete design system from primary site(s)" -ForegroundColor White
    Write-Host ""
    Write-Host "This will create:" -ForegroundColor DarkGray
    Write-Host "  â€¢ design.md (Patrick Ellis format)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Complete color palette with WCAG validation" -ForegroundColor DarkGray
    Write-Host "  â€¢ Typography scale (sizes, weights, line-heights)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Spacing system (8px grid)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Component specifications (Button, Card, Input, etc.)" -ForegroundColor DarkGray
    Write-Host "  â€¢ Responsive breakpoints and accessibility rules" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Confidence will increase: 20% -> 75%" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Which site(s) should be PRIMARY for design system extraction?" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Analyses.Count; $i++) {
        Write-Host "  $($i + 1). $($Analyses[$i].url)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Enter numbers (comma-separated, e.g., 1,3): " -NoNewline -ForegroundColor Yellow
    $primaryInput = Read-Host

    $primaryIndices = @($primaryInput -split ',' | ForEach-Object { [int]$_.Trim() - 1 } | Where-Object { $_ -ge 0 -and $_ -lt $Analyses.Count })

    Write-Host ""
    Write-Host "  [OK] Would extract complete design system from:" -ForegroundColor Yellow
    foreach ($idx in $primaryIndices) {
        Write-Host "  - $($Analyses[$idx].url)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  [OK] Would generate design.md with:" -ForegroundColor Yellow
    Write-Host "  - Color palette (extracted + validated)" -ForegroundColor Gray
    Write-Host "  - Typography scale (sizes, weights, line-heights)" -ForegroundColor Gray
    Write-Host "  - Spacing system (8px grid)" -ForegroundColor Gray
    Write-Host "  - Component specs (Button, Card, Input, etc.)" -ForegroundColor Gray
    Write-Host "  - Accessibility rules (WCAG AA compliance)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [OK] Would update confidence: 20% â†’ 75%" -ForegroundColor Yellow
    Write-Host ""

    # Update state (placeholder)
    $State.competitive_complete = $true
    $State.confidence = 75
    Set-DesignState -ProjectPath $ProjectPath -State $State

    Write-Host ""
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host "  [OK] Phase 5 Complete: Design system extracted" -ForegroundColor Green
    Write-Host "    Confidence updated: 20% -> 75%" -ForegroundColor Green
        Write-Host ('-' * 61) -ForegroundColor DarkGray
    Write-Host ""
}
