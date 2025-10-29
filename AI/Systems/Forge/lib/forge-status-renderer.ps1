# Forge Status Renderer
# Renders comprehensive project status display

function Show-ComprehensiveStatus {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $projectName = Split-Path $ProjectPath -Leaf

    # Show all sections
    Show-ProjectOverview -ProjectPath $ProjectPath -State $State
    Write-Host ""
    Write-Host "-------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WORKFLOW STAGES" -ForegroundColor Cyan
    Write-Host ""

    Show-StageInitialization -State $State
    Show-StagePRD -State $State -ProjectPath $ProjectPath
    Show-StageGitHub -State $State -ProjectPath $ProjectPath
    Show-StageIA -State $State -ProjectPath $ProjectPath
    Show-StageDesign -State $State -ProjectPath $ProjectPath
    Show-StageDevelopment -State $State -ProjectPath $ProjectPath

    Write-Host ""
    Write-Host "-------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    Show-SessionNotes -State $State

    Write-Host ""
    Write-Host "-------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    Show-QuickActions
}

function Show-ProjectOverview {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $projectName = Split-Path $ProjectPath -Leaf

    # Get mode
    . "$PSScriptRoot\mode-manager.ps1"
    $mode = (Get-ForgeMode).ToUpper()
    $modeColor = if ($mode -eq "DEV") { "Yellow" } else { "Green" }

    # Calculate time since creation
    $timeSince = "Unknown"
    if ($State.created_at) {
        try {
            $created = [DateTime]::Parse($State.created_at)
            $now = Get-Date
            $diff = $now - $created
            if ($diff.TotalHours -lt 24) {
                $timeSince = "$([math]::Round($diff.TotalHours, 0)) hours ago"
            } else {
                $timeSince = "$([math]::Round($diff.TotalDays, 0)) days ago"
            }
        } catch {
            $timeSince = "Recently"
        }
    }

    # Get last activity
    $lastActivity = "No activity"
    if ($State.current_session -and $State.current_session.ai) {
        $sessionStart = [DateTime]::Parse($State.current_session.started_at)
        $now = Get-Date
        $sessionDiff = $now - $sessionStart
        $sessionMinutes = [math]::Round($sessionDiff.TotalMinutes, 0)
        $lastActivity = "$($State.current_session.ai) ($sessionMinutes minutes ago)"
    } elseif ($State.sessions -and $State.sessions.Count -gt 0) {
        $lastSession = $State.sessions[-1]
        $lastActivity = "$($lastSession.ai) (last session)"
    }

    # Industry
    $industry = if ($State.industry -and $State.industry -ne "unknown") { $State.industry } else { "Not detected" }

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "              FORGE PROJECT STATUS - $projectName" -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Project Overview" -ForegroundColor White
    Write-Host "  Created: $($State.created_at) ($timeSince)" -ForegroundColor Gray
    Write-Host "  Mode: " -NoNewline -ForegroundColor Gray
    Write-Host $mode -ForegroundColor $modeColor
    Write-Host "  Industry: $industry" -ForegroundColor Gray
    Write-Host "  Last Activity: $lastActivity" -ForegroundColor Gray

    # Current session status
    if ($State.current_session) {
        Write-Host "  Current Session: " -NoNewline -ForegroundColor Gray
        Write-Host "Active ($([math]::Round(([DateTime]::Now - [DateTime]::Parse($State.current_session.started_at)).TotalMinutes, 0)) minutes)" -ForegroundColor Green
    } else {
        Write-Host "  Current Session: None" -ForegroundColor Gray
    }
}

function Show-StageInitialization {
    param([hashtable]$State)

    Write-Host "+- STAGE 1: INITIALIZATION " -NoNewline
    Write-Host ("-" * 36) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host "[OK] COMPLETE" -ForegroundColor Green -NoNewline
    Write-Host (" " * 46) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host " Project directory created" -NoNewline
    Write-Host (" " * 30) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host " PRD file initialized" -NoNewline
    Write-Host (" " * 36) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host " State tracking active" -NoNewline
    Write-Host (" " * 34) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host " Session started" -NoNewline
    Write-Host (" " * 41) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-StagePRD {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    $confidence = $State.confidence
    $gap = 95 - $confidence

    # Determine status
    $statusText = if ($confidence -ge 95) { "[OK] COMPLETE ($confidence%)" } else { "[~] IN PROGRESS ($confidence% confidence)" }
    $statusColor = if ($confidence -ge 95) { "Green" } else { "Yellow" }

    # Progress bar
    $filled = [math]::Floor($confidence / 10)
    $empty = 10 - $filled
    $progressBar = ("#" * $filled) + ("-" * $empty)

    Write-Host "+- STAGE 2: PRD DEVELOPMENT " -NoNewline
    Write-Host ("-" * 32) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor -NoNewline
    $padding = 61 - $statusText.Length - 8
    Write-Host (" " * $padding) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    if ($confidence -lt 95) {
        Write-Host "| Target: 95% | Gap: -$gap%" -NoNewline
        Write-Host (" " * 39) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Confidence: $confidence% [$progressBar] (Completeness)" -NoNewline
    $barPadding = 61 - 14 - $confidence.ToString().Length - 10 - 2 - 15
    Write-Host (" " * $barPadding) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    # Add quality metric
    $quality = if ($State.quality) { $State.quality } else { 0 }
    $qualFilled = [math]::Floor($quality / 10)
    $qualEmpty = 10 - $qualFilled
    $qualBar = ("#" * $qualFilled) + ("-" * $qualEmpty)
    Write-Host "| Quality:    $quality% [$qualBar] (Semantic)" -NoNewline
    $qualPadding = 61 - 14 - $quality.ToString().Length - 10 - 2 - 11
    Write-Host (" " * $qualPadding) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Deliverable Breakdown:" -NoNewline
    Write-Host (" " * 38) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 59) -NoNewline
    Write-Host " |" -ForegroundColor Gray
    Write-Host "|  Deliverable              Weight   Status   Contribution" -NoNewline
    Write-Host "  |" -ForegroundColor Gray
    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 59) -NoNewline
    Write-Host " |" -ForegroundColor Gray

    # Deliverable order
    $deliverableOrder = @(
        @{key="problem_statement"; name="Problem Statement"; weight=10},
        @{key="tech_stack"; name="Tech Stack"; weight=20},
        @{key="success_metrics"; name="Success Metrics"; weight=15},
        @{key="mvp_scope"; name="MVP Scope"; weight=15},
        @{key="feature_list"; name="Feature List"; weight=25},
        @{key="user_personas"; name="User Personas"; weight=7},
        @{key="user_stories"; name="User Stories"; weight=5},
        @{key="non_functional"; name="Non-Functional Reqs"; weight=3}
    )

    foreach ($item in $deliverableOrder) {
        $status = $State.deliverables[$item.key]
        $contribution = ($status / 100) * $item.weight

        $icon = if ($status -eq 100) { "[OK]" }
                elseif ($status -ge 75) { "[!!]" }
                else { "[XX]" }

        $iconColor = if ($status -eq 100) { "Green" }
                     elseif ($status -ge 75) { "Yellow" }
                     else { "Red" }

        $name = $item.name.PadRight(24)
        $weightStr = "$($item.weight)%".PadLeft(5)
        $statusStr = "$status%".PadLeft(5)
        $contribStr = "$([math]::Round($contribution, 2))%".PadLeft(7)

        Write-Host "|  " -NoNewline -ForegroundColor Gray
        Write-Host "$icon" -ForegroundColor $iconColor -NoNewline
        Write-Host " $name  $weightStr   $statusStr   $contribStr" -NoNewline
        Write-Host "  |" -ForegroundColor Gray
    }

    Write-Host "| " -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 59) -NoNewline
    Write-Host " |" -ForegroundColor Gray

    # Show incomplete milestones if not at 95%
    if ($confidence -lt 95) {
        Write-Host "|" -NoNewline -ForegroundColor Gray
        Write-Host (" " * 61) -NoNewline
        Write-Host "|" -ForegroundColor Gray
        Write-Host "| Incomplete Milestones:" -NoNewline
        Write-Host (" " * 38) -NoNewline
        Write-Host "|" -ForegroundColor Gray

        # Load next steps
        . "$PSScriptRoot\state-manager.ps1"
        $nextSteps = Get-NextSteps -State $State

        $stepCount = 0
        foreach ($step in $nextSteps) {
            if ($stepCount -ge 4) { break }  # Show top 4

            $deliverable = $step.deliverable -replace '_', ' '
            $deliverable = (Get-Culture).TextInfo.ToTitleCase($deliverable)

            $line = "  [~] Complete $deliverable (+$($step.impact)%) -> $($step.new_confidence)%"
            Write-Host "|  " -NoNewline -ForegroundColor Gray
            Write-Host "[~]" -ForegroundColor Yellow -NoNewline
            Write-Host " Complete $deliverable " -NoNewline
            Write-Host "(+$($step.impact)%)" -ForegroundColor Cyan -NoNewline
            Write-Host " -> $($step.new_confidence)%" -NoNewline
            $linePadding = 61 - $line.Length + 2
            Write-Host (" " * $linePadding) -NoNewline
            Write-Host "|" -ForegroundColor Gray

            # Show missing items if available
            if ($step.current -lt 100) {
                Write-Host "|     Missing: [details would go here]" -NoNewline
                Write-Host (" " * 22) -NoNewline
                Write-Host "|" -ForegroundColor Gray
            }

            if ($stepCount -lt 3) {
                Write-Host "|" -NoNewline -ForegroundColor Gray
                Write-Host (" " * 61) -NoNewline
                Write-Host "|" -ForegroundColor Gray
            }

            $stepCount++
        }

        Write-Host "|" -NoNewline -ForegroundColor Gray
        Write-Host (" " * 61) -NoNewline
        Write-Host "|" -ForegroundColor Gray
        Write-Host "| Next Action: Complete highest impact deliverable" -NoNewline
        Write-Host (" " * 10) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    } else {
        Write-Host "|" -NoNewline -ForegroundColor Gray
        Write-Host (" " * 61) -NoNewline
        Write-Host "|" -ForegroundColor Gray
        Write-Host "| " -NoNewline -ForegroundColor Gray
        Write-Host "[OK]" -ForegroundColor Green -NoNewline
        Write-Host " PRD complete and ready for GitHub setup!" -NoNewline
        Write-Host (" " * 15) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-StageGitHub {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    # Check if GitHub is set up
    $gitHubSetup = Test-Path "$ProjectPath\.github"
    $gitInit = Test-Path "$ProjectPath\.git"

    # Check for remote repository
    $hasRemote = $false
    if ($gitInit) {
        Push-Location $ProjectPath
        $remoteCheck = git remote -v 2>$null
        Pop-Location
        $hasRemote = $remoteCheck -ne $null -and $remoteCheck.Length -gt 0
    }

    # Check for generated issues
    $hasIssues = Test-Path "$ProjectPath\.github\ISSUE_TEMPLATE\*.md"

    # Determine status
    if ($gitHubSetup -and $gitInit -and $hasRemote) {
        $statusText = "[OK] COMPLETE"
        $statusColor = "Green"
    } elseif ($State.confidence -lt 95) {
        $statusText = "[XX] NOT STARTED"
        $statusColor = "Red"
    } else {
        $statusText = "[  ] READY TO START"
        $statusColor = "Yellow"
    }

    Write-Host "+- STAGE 3: GITHUB SETUP " -NoNewline
    Write-Host ("-" * 35) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor -NoNewline
    $padding = 61 - $statusText.Length - 8
    Write-Host (" " * $padding) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    if (-not $gitHubSetup -and $State.confidence -lt 95) {
        Write-Host "| Blocked: PRD must reach 95% confidence first" -NoNewline
        Write-Host (" " * 16) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Required Milestones:" -NoNewline
    Write-Host (" " * 40) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    # Milestones
    $milestones = @(
        @{text="Run 'forge setup-repo <project-name>'"; done=$gitHubSetup},
        @{text="Initialize git repository"; done=$gitInit},
        @{text="Create GitHub repository (gh repo create)"; done=$hasRemote},
        @{text="Install GitHub templates (CI/CD, issues, PR)"; done=$gitHubSetup},
        @{text="Generate issues from PRD features"; done=$hasIssues}
    )

    foreach ($m in $milestones) {
        $icon = if ($m.done) { "[OK]" } else { "[  ]" }
        $iconColor = if ($m.done) { "Green" } else { "Gray" }

        Write-Host "|  " -NoNewline -ForegroundColor Gray
        Write-Host $icon -ForegroundColor $iconColor -NoNewline
        Write-Host " $($m.text)" -NoNewline
        $padding = 61 - $m.text.Length - 6
        Write-Host (" " * $padding) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Completion Criteria: Remote repository configured + issues" -NoNewline
    Write-Host "  |" -ForegroundColor Gray
    Write-Host "| created" -NoNewline
    Write-Host (" " * 53) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-StageIA {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    # Check if IA exists - look for ia/ directory or check state
    $iaExists = (Test-Path "$ProjectPath\ia") -and ($State.ia_confidence -gt 0)

    # Check individual IA components
    $hasSitemap = Test-Path "$ProjectPath\ia\sitemap.md"
    $hasFlows = Test-Path "$ProjectPath\ia\flows.md"
    $hasEntities = Test-Path "$ProjectPath\ia\entities.md"
    $hasNavigation = Test-Path "$ProjectPath\ia\navigation.md"

    $statusText = if ($iaExists) { "[OK] IMPORTED ($($State.ia_confidence)%)" } else { "[  ] NOT IMPORTED" }
    $statusColor = if ($iaExists) { "Green" } else { "Gray" }

    Write-Host "+- STAGE 4: INFORMATION ARCHITECTURE " -NoNewline
    Write-Host ("-" * 23) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor -NoNewline
    $padding = 61 - $statusText.Length - 8
    Write-Host (" " * $padding) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    # Show IA metrics if available
    if ($iaExists) {
        $iaConfidence = if ($State.ia_confidence) { $State.ia_confidence } else { 0 }
        $iaQuality = if ($State.ia_quality) { $State.ia_quality } else { 0 }

        $iaConfFilled = [math]::Floor($iaConfidence / 10)
        $iaConfEmpty = 10 - $iaConfFilled
        $iaConfBar = ("#" * $iaConfFilled) + ("-" * $iaConfEmpty)

        $iaQualFilled = [math]::Floor($iaQuality / 10)
        $iaQualEmpty = 10 - $iaQualFilled
        $iaQualBar = ("#" * $iaQualFilled) + ("-" * $iaQualEmpty)

        Write-Host "| Confidence: $iaConfidence% [$iaConfBar] (Completeness)" -NoNewline
        $iaConfPadding = 61 - 14 - $iaConfidence.ToString().Length - 10 - 2 - 15
        Write-Host (" " * $iaConfPadding) -NoNewline
        Write-Host "|" -ForegroundColor Gray

        Write-Host "| Quality:    $iaQuality% [$iaQualBar] (Semantic)" -NoNewline
        $iaQualPadding = 61 - 14 - $iaQuality.ToString().Length - 10 - 2 - 11
        Write-Host (" " * $iaQualPadding) -NoNewline
        Write-Host "|" -ForegroundColor Gray

        Write-Host "|" -NoNewline -ForegroundColor Gray
        Write-Host (" " * 61) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "| External Creation (Custom GPT):" -NoNewline
    Write-Host (" " * 29) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    # Sitemap
    $icon1 = if ($hasSitemap) { "[OK]" } else { "[  ]" }
    $color1 = if ($hasSitemap) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon1 -ForegroundColor $color1 -NoNewline
    Write-Host " Sitemap structure" -NoNewline
    Write-Host (" " * 37) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    # User flows
    $icon2 = if ($hasFlows) { "[OK]" } else { "[  ]" }
    $color2 = if ($hasFlows) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon2 -ForegroundColor $color2 -NoNewline
    Write-Host " User flows" -NoNewline
    Write-Host (" " * 44) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    # ERD
    $icon3 = if ($hasEntities) { "[OK]" } else { "[  ]" }
    $color3 = if ($hasEntities) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon3 -ForegroundColor $color3 -NoNewline
    Write-Host " Entity Relationship Diagram (ERD)" -NoNewline
    Write-Host (" " * 21) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    # Navigation
    $icon4 = if ($hasNavigation) { "[OK]" } else { "[  ]" }
    $color4 = if ($hasNavigation) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon4 -ForegroundColor $color4 -NoNewline
    Write-Host " Page hierarchy" -NoNewline
    Write-Host (" " * 40) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Forge Review (After Import):" -NoNewline
    Write-Host (" " * 32) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    # Import IA
    $iconImport = if ($iaExists) { "[OK]" } else { "[  ]" }
    $colorImport = if ($iaExists) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $iconImport -ForegroundColor $colorImport -NoNewline
    Write-Host " Import IA report ('forge import-ia')" -NoNewline
    Write-Host (" " * 19) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Review sitemap (Format-SitemapReport)" -NoNewline
    Write-Host (" " * 15) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Review user flows" -NoNewline
    Write-Host (" " * 37) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Review ERD" -NoNewline
    Write-Host (" " * 44) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Apply refinements ('forge evolve-spec')" -NoNewline
    Write-Host (" " * 15) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    if ($iaExists) {
        Write-Host "| Next Action: Review IA files and refine if needed" -NoNewline
    } else {
        if ($iaExists) {
        Write-Host "| Next Action: Review IA files and refine if needed" -NoNewline
    } else {
        Write-Host "| Next Action: Create IA in Custom GPT, then import" -NoNewline
    }
    }
    Write-Host (" " * 10) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-StageDesign {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    # Check if design exists
    $designExists = Test-Path "$ProjectPath\design\aesthetic-brief.md"
    $compAnalysisExists = Test-Path "$ProjectPath\design\competitive-analysis.md"

    $statusText = if ($designExists -and $compAnalysisExists) { "[OK] COMPLETE" }
                  elseif ($designExists) { "[~] IN PROGRESS" }
                  else { "[  ] NOT STARTED" }
    $statusColor = if ($designExists -and $compAnalysisExists) { "Green" }
                   elseif ($designExists) { "Yellow" }
                   else { "Gray" }

    Write-Host "+- STAGE 5: DESIGN " -NoNewline
    Write-Host ("-" * 42) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor -NoNewline
    $padding = 61 - $statusText.Length - 8
    Write-Host (" " * $padding) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Required Milestones:" -NoNewline
    Write-Host (" " * 40) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    $icon1 = if ($designExists) { "[OK]" } else { "[  ]" }
    $color1 = if ($designExists) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon1 -ForegroundColor $color1 -NoNewline
    Write-Host " Run 'forge design-brief <type>'" -NoNewline
    Write-Host (" " * 28) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon1 -ForegroundColor $color1 -NoNewline
    Write-Host " Complete aesthetic brief interview" -NoNewline
    Write-Host (" " * 24) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    Write-Host "|     � Target audience/feel" -NoNewline
    Write-Host (" " * 34) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|     � Anti-patterns to avoid" -NoNewline
    Write-Host (" " * 32) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|     � Color preferences" -NoNewline
    Write-Host (" " * 37) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|     � Key features for design" -NoNewline
    Write-Host (" " * 31) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|     � Inspiration references" -NoNewline
    Write-Host (" " * 32) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    $icon2 = if ($compAnalysisExists) { "[OK]" } else { "[  ]" }
    $color2 = if ($compAnalysisExists) { "Green" } else { "Gray" }
    Write-Host "|  " -NoNewline -ForegroundColor Gray
    Write-Host $icon2 -ForegroundColor $color2 -NoNewline
    Write-Host " Competitor analysis" -NoNewline
    Write-Host (" " * 40) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    Write-Host "|  [  ] Design reference collection" -NoNewline
    Write-Host (" " * 26) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Completion Criteria: design/aesthetic-brief.md exists +" -NoNewline
    Write-Host "    |" -ForegroundColor Gray
    Write-Host "| competitive-analysis.md complete" -NoNewline
    Write-Host (" " * 28) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-StageDevelopment {
    param(
        [hashtable]$State,
        [string]$ProjectPath
    )

    # Check if GitHub is set up
    $gitHubSetup = Test-Path "$ProjectPath\.github"

    $statusText = if (-not $gitHubSetup) { "[XX] BLOCKED" } else { "[  ] READY" }
    $statusColor = if (-not $gitHubSetup) { "Red" } else { "Yellow" }

    Write-Host "+- STAGE 6: DEVELOPMENT " -NoNewline
    Write-Host ("-" * 36) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host "| Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor -NoNewline
    $padding = 61 - $statusText.Length - 8
    Write-Host (" " * $padding) -NoNewline
    Write-Host "|" -ForegroundColor Gray

    if (-not $gitHubSetup) {
        Write-Host "| Blocked: GitHub setup required first" -NoNewline
        Write-Host (" " * 24) -NoNewline
        Write-Host "|" -ForegroundColor Gray
    }

    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Development Workflow:" -NoNewline
    Write-Host (" " * 39) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Process issues ('forge issue <number>')" -NoNewline
    Write-Host (" " * 16) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|     � Plan -> Create -> Test -> Deploy" -NoNewline
    Write-Host (" " * 22) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Code review ('forge review-pr <number>')" -NoNewline
    Write-Host (" " * 14) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Run tests ('forge test')" -NoNewline
    Write-Host (" " * 30) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|  [  ] Monitor deployment ('forge deploy')" -NoNewline
    Write-Host (" " * 19) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "|" -NoNewline -ForegroundColor Gray
    Write-Host (" " * 61) -NoNewline
    Write-Host "|" -ForegroundColor Gray
    Write-Host "| Progress: 0/0 issues completed (no issues generated yet)" -NoNewline
    Write-Host "   |" -ForegroundColor Gray
    Write-Host "+" -NoNewline -ForegroundColor Gray
    Write-Host ("-" * 61) -NoNewline
    Write-Host "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-SessionNotes {
    param([hashtable]$State)

    Write-Host "SESSION NOTES" -ForegroundColor Cyan

    if ($State.current_session) {
        $session = $State.current_session
        $noteCount = if ($session.user_notes) { $session.user_notes.Count } else { 0 }
        $bugCount = if ($session.bugs_identified) { $session.bugs_identified.Count } else { 0 }
        $confidenceGain = $session.confidence_start
        if ($State.confidence -and $confidenceGain) {
            $confidenceGain = [math]::Round($State.confidence - $confidenceGain, 2)
        } else {
            $confidenceGain = 0
        }

        Write-Host "  � $noteCount notes captured this session" -ForegroundColor Gray
        Write-Host "  � $bugCount bugs identified" -ForegroundColor Gray
        Write-Host "  � Confidence gain: +$confidenceGain% this session" -ForegroundColor Gray
    } else {
        Write-Host "  � No active session" -ForegroundColor Gray
    }
}

function Show-QuickActions {
    Write-Host "QUICK ACTIONS" -ForegroundColor Cyan
    Write-Host "  � forge status            - Refresh this view" -ForegroundColor Gray
    Write-Host "  � forge show blockers     - See detailed PRD blockers" -ForegroundColor Gray
    Write-Host "  � forge evolve-spec       - Refine PRD/IA interactively" -ForegroundColor Gray
    Write-Host "  � forge close-session     - End session & save notes" -ForegroundColor Gray
    Write-Host ""
}



function Show-ConfidenceTracker {
    param(
        [string]$ProjectName,
        [int]$Confidence,
        [hashtable]$Deliverables
    )
    
    Write-Host ""
    Write-Host "PROJECT: $ProjectName" -ForegroundColor Cyan
    Write-Host ""
    
    # Calculate progress bar
    $filled = [math]::Floor($Confidence / 10)
    $empty = 10 - $filled
    $progressBar = ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
    
    $color = if ($Confidence -ge 80) { "Green" } elseif ($Confidence -ge 50) { "Yellow" } else { "Red" }
    Write-Host "Confidence: $Confidence% [$progressBar]" -ForegroundColor $color
    Write-Host ""
    
    # Show deliverables summary
    if ($Deliverables) {
        $completed = ($Deliverables.Values | Where-Object { $_ -ge 100 }).Count
        $total = $Deliverables.Count
        Write-Host "Deliverables: $completed/$total completed" -ForegroundColor Cyan
        
        foreach ($key in $Deliverables.Keys | Sort-Object) {
            $status = if ($Deliverables[$key] -ge 100) { "[X]" } else { "[ ]" }
            $color = if ($Deliverables[$key] -ge 100) { "Green" } else { "Gray" }
            Write-Host "  $status $key" -ForegroundColor $color
        }
    }
    Write-Host ""
}

function Show-NextSteps {
    param(
        [array]$Steps
    )
    
    Write-Host "NEXT STEPS" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Steps -and $Steps.Count -gt 0) {
        # Check if steps are hashtables (from state-manager Get-NextSteps) or strings
        $firstStep = $Steps[0]
        if ($firstStep -is [hashtable]) {
            # Format deliverable-based steps from state-manager
            Write-Host "  Complete these PRD sections to increase confidence:" -ForegroundColor Yellow
            Write-Host ""
            $displayCount = [Math]::Min($Steps.Count, 3)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $step = $Steps[$i]
                $deliverableName = ($step.deliverable -replace '_', ' ')
                $deliverableName = (Get-Culture).TextInfo.ToTitleCase($deliverableName)
                $impact = $step.impact
                Write-Host "  $($i + 1). $deliverableName (Current: $($step.current)%, Impact: +$impact%)" -ForegroundColor Yellow
            }
        } else {
            # Format string steps
            for ($i = 0; $i -lt $Steps.Count; $i++) {
                $step = $Steps[$i]
                Write-Host "  $($i + 1). $step" -ForegroundColor Yellow
            }
        }
    } else {
        # Default next steps
        Write-Host "  1. Review PRD completeness" -ForegroundColor Yellow
        Write-Host "  2. Import or define IA (Information Architecture)" -ForegroundColor Yellow
        Write-Host "  3. Generate GitHub issues from PRD" -ForegroundColor Yellow
    }
    Write-Host ""
}
