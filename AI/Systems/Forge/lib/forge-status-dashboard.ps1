# Forge Status Dashboard - Template 2 Implementation (ASCII Only)
# Enhanced dashboard-style status display

function Show-DashboardStatus {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $projectName = Split-Path $ProjectPath -Leaf

    # Calculate overall metrics
    $metrics = Get-ProjectMetrics -ProjectPath $ProjectPath -State $State
    $currentPhase = Get-CurrentPhaseInfo -ProjectPath $ProjectPath -State $State
    $phaseDetails = Get-CurrentPhaseDetails -ProjectPath $ProjectPath -State $State -CurrentPhase $currentPhase

    # Render dashboard sections
    Show-DashboardHeader -ProjectName $projectName
    Show-ProjectHealthPanel -Metrics $metrics -CurrentPhase $currentPhase -State $State
    Show-PhaseProgressionPanel -Metrics $metrics -CurrentPhase $currentPhase
    Show-CurrentFocusPanel -PhaseDetails $phaseDetails -CurrentPhase $currentPhase -ProjectPath $ProjectPath
    Show-KeyMetricsPanel -State $State -Metrics $metrics
    Show-WhatsNextPanel -PhaseDetails $phaseDetails -CurrentPhase $currentPhase
}

function Show-DashboardHeader {
    param([string]$ProjectName)

    Write-Host ""
    Write-Host ("=" * 61) -ForegroundColor Cyan
    $title = "FORGE CONTROL PANEL - $ProjectName"
    $padding = 61 - $title.Length
    $leftPad = [math]::Floor($padding / 2)
    $rightPad = $padding - $leftPad
    Write-Host ((' ' * $leftPad) + $title + (' ' * $rightPad)) -ForegroundColor Cyan
    Write-Host ("=" * 61) -ForegroundColor Cyan
    Write-Host ""
}

function Show-ProjectHealthPanel {
    param(
        [hashtable]$Metrics,
        [hashtable]$CurrentPhase,
        [hashtable]$State
    )

    # Calculate time invested
    $timeSince = "Unknown"
    if ($State.created_at) {
        try {
            $created = [DateTime]::Parse($State.created_at)
            $now = Get-Date
            $diff = $now - $created
            if ($diff.TotalHours -lt 24) {
                $timeSince = "$([math]::Round($diff.TotalHours, 1)) hours"
            } else {
                $timeSince = "$([math]::Round($diff.TotalDays, 1)) days"
            }
        } catch {
            $timeSince = "Recently"
        }
    }

    # Status text
    $statusIcon = if ($CurrentPhase.statusComplete) { "[OK]" } else { "[>>]" }
    $statusText = "$statusIcon Active - $($CurrentPhase.statusText)"

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host "| PROJECT HEALTH" + (' ' * 45) + "|" -ForegroundColor White
    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray

    # Overall Progress
    $overallProgress = $Metrics.overallProgress
    $progressBar = Get-ProgressBar -Percent $overallProgress -Width 10
    $line1 = "| Overall Progress:  [$progressBar] $overallProgress%"
    Write-Host ($line1 + (' ' * (61 - $line1.Length)) + "|") -ForegroundColor Gray

    # Current Phase
    $phaseText = "$($CurrentPhase.name) (Phase $($CurrentPhase.number) of 6)"
    $line2 = "| Current Phase:     $phaseText"
    Write-Host ($line2 + (' ' * (61 - $line2.Length)) + "|") -ForegroundColor Gray

    # Status
    $line3 = "| Status:            $statusText"
    Write-Host ($line3 + (' ' * (61 - $line3.Length)) + "|") -ForegroundColor Gray

    # Time Invested
    $line4 = "| Time Invested:     $timeSince"
    Write-Host ($line4 + (' ' * (61 - $line4.Length)) + "|") -ForegroundColor Gray

    # Confidence Score
    $confidenceScore = if ($State.confidence) { "$($State.confidence)% (Excellent)" } else { "N/A" }
    $line5 = "| Confidence Score:  $confidenceScore"
    Write-Host ($line5 + (' ' * (61 - $line5.Length)) + "|") -ForegroundColor Gray

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-PhaseProgressionPanel {
    param(
        [hashtable]$Metrics,
        [hashtable]$CurrentPhase
    )

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host "| PHASE PROGRESSION" + (' ' * 42) + "|" -ForegroundColor White
    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray

    $phases = @(
        @{num=1; name="PRD Development"; percent=$Metrics.prdProgress; complete=$Metrics.prdComplete},
        @{num=2; name="Architecture & IA"; percent=$Metrics.iaProgress; complete=$Metrics.iaComplete},
        @{num=3; name="Visual Design"; percent=$Metrics.designProgress; complete=$Metrics.designComplete},
        @{num=4; name="Development Setup"; percent=$Metrics.githubProgress; complete=$Metrics.githubComplete},
        @{num=5; name="Implementation"; percent=$Metrics.devProgress; complete=$Metrics.devComplete},
        @{num=6; name="Launch & Deploy"; percent=$Metrics.launchProgress; complete=$Metrics.launchComplete}
    )

    foreach ($phase in $phases) {
        $icon = if ($phase.complete) { "[OK]" }
                elseif ($phase.num -eq $CurrentPhase.number) { "[>>]" }
                else { "[  ]" }

        $progressBar = Get-ProgressBar -Percent $phase.percent -Width 10
        $phaseLine = "  $($phase.num). $icon $($phase.name.PadRight(20)) [$progressBar] $($phase.percent.ToString().PadLeft(2))%"

        $indicator = if ($phase.num -eq $CurrentPhase.number) { " <- NOW" } else { "" }
        $totalLength = $phaseLine.Length + $indicator.Length
        $padding = 61 - $totalLength

        $color = if ($phase.num -eq $CurrentPhase.number) { "Yellow" } else { "Gray" }
        Write-Host ("| " + $phaseLine + $indicator + (' ' * $padding) + "|") -ForegroundColor $color
    }

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-CurrentFocusPanel {
    param(
        [hashtable]$PhaseDetails,
        [hashtable]$CurrentPhase,
        [string]$ProjectPath
    )

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    $header = " CURRENT FOCUS: $($CurrentPhase.name) Phase"
    Write-Host ("| " + $header + (' ' * (59 - $header.Length)) + "|") -ForegroundColor White
    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray

    $workflowTitle = " >> $($PhaseDetails.workflowName)"
    Write-Host ("| " + $workflowTitle + (' ' * (59 - $workflowTitle.Length)) + "|") -ForegroundColor Cyan
    Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray

    foreach ($step in $PhaseDetails.steps) {
        $checkbox = if ($step.done) { "[X]" } else { "[ ]" }
        $stepLine = " $($step.name.PadRight(35)) $checkbox $($step.status)"
        $padding = 59 - $stepLine.Length
        Write-Host ("| " + $stepLine + (' ' * $padding) + "|") -ForegroundColor Gray

        if ($step.command) {
            $cmdLine = "   --> $($step.command)"
            $cmdPadding = 59 - $cmdLine.Length
            Write-Host ("| " + $cmdLine + (' ' * $cmdPadding) + "|") -ForegroundColor DarkGray
        }

        Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray
    }

    $estimatedTime = " Estimated Time: $($PhaseDetails.estimatedTime)"
    Write-Host ("| " + $estimatedTime + (' ' * (59 - $estimatedTime.Length)) + "|") -ForegroundColor Gray

    $criteria = " Completion Criteria: $($PhaseDetails.completionCriteria)"
    Write-Host ("| " + $criteria + (' ' * (59 - $criteria.Length)) + "|") -ForegroundColor Gray
    Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-KeyMetricsPanel {
    param(
        [hashtable]$State,
        [hashtable]$Metrics
    )

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host "| KEY METRICS" + (' ' * 48) + "|" -ForegroundColor White
    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray

    # PRD Confidence
    $prdConf = if ($State.confidence) { $State.confidence } else { 0 }
    $prdBar = Get-ProgressBar -Percent $prdConf -Width 10 -Char '#'
    $prdLine = " PRD Confidence:     $prdConf%  [$prdBar]"
    Write-Host ("| " + $prdLine + (' ' * (59 - $prdLine.Length)) + "|") -ForegroundColor Gray

    # IA Quality
    $iaQual = if ($State.ia_quality) { $State.ia_quality } else { 0 }
    $iaBar = Get-ProgressBar -Percent $iaQual -Width 10 -Char '#'
    $iaLine = " IA Quality:         $iaQual%  [$iaBar]"
    Write-Host ("| " + $iaLine + (' ' * (59 - $iaLine.Length)) + "|") -ForegroundColor Gray

    # Features Defined
    $featureCount = 0
    if ($State.project_model -and $State.project_model.feature_to_routes) {
        $featureCount = ($State.project_model.feature_to_routes | Get-Member -MemberType NoteProperty).Count
    }
    $featLine = " Features Defined:   $featureCount   (All documented)"
    Write-Host ("| " + $featLine + (' ' * (59 - $featLine.Length)) + "|") -ForegroundColor Gray

    # User Flows
    $flowCount = if ($State.ia_model -and $State.ia_model.flows) { $State.ia_model.flows.Count } else { 0 }
    $flowLine = " User Flows:         $flowCount   (All mapped)"
    Write-Host ("| " + $flowLine + (' ' * (59 - $flowLine.Length)) + "|") -ForegroundColor Gray

    # Entities
    $entityCount = 0
    if ($State.ia_model -and $State.ia_model.entities_by_route) {
        $allEntities = New-Object System.Collections.Generic.HashSet[string]
        if ($State.ia_model.entities_by_route -is [hashtable]) {
            foreach ($route in $State.ia_model.entities_by_route.Keys) {
                $entities = $State.ia_model.entities_by_route[$route]
                if ($entities -is [array]) {
                    foreach ($e in $entities) { $allEntities.Add($e) | Out-Null }
                }
            }
        }
        $entityCount = $allEntities.Count
    }
    $entLine = " Entities:           $entityCount    (ERD complete)"
    Write-Host ("| " + $entLine + (' ' * (59 - $entLine.Length)) + "|") -ForegroundColor Gray

    # Routes
    $routeCount = if ($State.ia_model -and $State.ia_model.routes) { $State.ia_model.routes.Count } else { 0 }
    $routeLine = " Routes:             $routeCount    (Sitemap ready)"
    Write-Host ("| " + $routeLine + (' ' * (59 - $routeLine.Length)) + "|") -ForegroundColor Gray

    # Blockers
    $blockerCount = 0
    if ($State.semantic_analysis) {
        if ($State.semantic_analysis.contradictions) { $blockerCount += @($State.semantic_analysis.contradictions.PSObject.Properties).Count }
        if ($State.semantic_analysis.impossibilities) { $blockerCount += @($State.semantic_analysis.impossibilities.PSObject.Properties).Count }
    }
    $blockerText = if ($blockerCount -eq 0) { "[OK] None!" } else { "$blockerCount found" }
    $blockLine = " Blockers:           $blockerText"
    Write-Host ("| " + $blockLine + (' ' * (59 - $blockLine.Length)) + "|") -ForegroundColor Gray

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ""
}

function Show-WhatsNextPanel {
    param(
        [hashtable]$PhaseDetails,
        [hashtable]$CurrentPhase
    )

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host "| WHAT'S NEXT?" + (' ' * 47) + "|" -ForegroundColor White
    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray

    Write-Host "| Immediate Actions (This Session):" + (' ' * 26) + "|" -ForegroundColor Cyan

    $actionNum = 1
    foreach ($action in $PhaseDetails.immediateActions) {
        $actionLine = "   $actionNum. [>>] $($action.command)"
        $padding = 59 - $actionLine.Length
        Write-Host ("| " + $actionLine + (' ' * $padding) + "|") -ForegroundColor Yellow

        $descLine = "      $($action.description)"
        $descPadding = 59 - $descLine.Length
        Write-Host ("| " + $descLine + (' ' * $descPadding) + "|") -ForegroundColor Gray
        Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray
        $actionNum++
    }

    if ($PhaseDetails.futureActions -and $PhaseDetails.futureActions.Count -gt 0) {
        $futureHeader = " After $($CurrentPhase.name) Phase:"
        Write-Host ("| " + $futureHeader + (' ' * (59 - $futureHeader.Length)) + "|") -ForegroundColor Cyan

        foreach ($action in $PhaseDetails.futureActions) {
            $futLine = "   $actionNum. [  ] $($action.command)"
            $futPadding = 59 - $futLine.Length
            Write-Host ("| " + $futLine + (' ' * $futPadding) + "|") -ForegroundColor Gray

            $futDescLine = "      $($action.description)"
            $futDescPadding = 59 - $futDescLine.Length
            Write-Host ("| " + $futDescLine + (' ' * $futDescPadding) + "|") -ForegroundColor DarkGray
            Write-Host ("|" + (' ' * 59) + "|") -ForegroundColor Gray
            $actionNum++
        }
    }

    Write-Host "+" + ("-" * 59) + "+" -ForegroundColor Gray
    Write-Host ""
}

function Get-ProgressBar {
    param(
        [int]$Percent,
        [int]$Width = 10,
        [char]$Char = '#'
    )

    $filled = [math]::Floor($Percent / 10)
    if ($filled > $Width) { $filled = $Width }
    $empty = $Width - $filled
    return (([string]$Char) * $filled) + (('-') * $empty)
}

function Get-ProjectMetrics {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    # PRD metrics
    $prdProgress = if ($State.confidence) { $State.confidence } else { 0 }
    $prdComplete = $prdProgress -ge 95

    # IA metrics
    $iaProgress = if ($State.ia_confidence) { $State.ia_confidence } else { 0 }
    $iaComplete = $iaProgress -ge 95

    # Design metrics
    $designExists = Test-Path "$ProjectPath\design\aesthetic-brief.md"
    $compAnalysisExists = Test-Path "$ProjectPath\design\competitive-analysis.md"
    $designProgress = if ($designExists -and $compAnalysisExists) { 100 } elseif ($designExists) { 50 } else { 0 }
    $designComplete = $designProgress -eq 100

    # GitHub metrics
    $gitHubSetup = Test-Path "$ProjectPath\.github"
    $gitInit = Test-Path "$ProjectPath\.git"
    $githubProgress = if ($gitHubSetup -and $gitInit) { 100 } elseif ($gitInit) { 50 } else { 0 }
    $githubComplete = $githubProgress -eq 100

    # Development metrics (placeholder)
    $devProgress = 0
    $devComplete = $false

    # Launch metrics (placeholder)
    $launchProgress = 0
    $launchComplete = $false

    # Overall progress (average of completed phases)
    $completedPhases = 0
    if ($prdComplete) { $completedPhases++ }
    if ($iaComplete) { $completedPhases++ }
    if ($designComplete) { $completedPhases++ }
    if ($githubComplete) { $completedPhases++ }
    if ($devComplete) { $completedPhases++ }
    if ($launchComplete) { $completedPhases++ }
    $overallProgress = [math]::Round(($completedPhases / 6) * 100, 0)

    return @{
        prdProgress = $prdProgress
        prdComplete = $prdComplete
        iaProgress = $iaProgress
        iaComplete = $iaComplete
        designProgress = $designProgress
        designComplete = $designComplete
        githubProgress = $githubProgress
        githubComplete = $githubComplete
        devProgress = $devProgress
        devComplete = $devComplete
        launchProgress = $launchProgress
        launchComplete = $launchComplete
        overallProgress = $overallProgress
    }
}

function Get-CurrentPhaseInfo {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $metrics = Get-ProjectMetrics -ProjectPath $ProjectPath -State $State

    # Determine current phase based on completion status
    if (-not $metrics.prdComplete) {
        return @{ number=1; name="PRD"; statusText="PRD Development Pending"; statusComplete=$false }
    }
    elseif (-not $metrics.iaComplete) {
        return @{ number=2; name="IA"; statusText="IA Import Pending"; statusComplete=$false }
    }
    elseif (-not $metrics.designComplete) {
        return @{ number=3; name="Design"; statusText="Design Brief Pending"; statusComplete=$false }
    }
    elseif (-not $metrics.githubComplete) {
        return @{ number=4; name="GitHub"; statusText="GitHub Setup Pending"; statusComplete=$false }
    }
    elseif (-not $metrics.devComplete) {
        return @{ number=5; name="Development"; statusText="Implementation In Progress"; statusComplete=$false }
    }
    else {
        return @{ number=6; name="Launch"; statusText="Ready for Launch"; statusComplete=$false }
    }
}

function Get-CurrentPhaseDetails {
    param(
        [string]$ProjectPath,
        [hashtable]$State,
        [hashtable]$CurrentPhase
    )

    switch ($CurrentPhase.name) {
        "PRD" {
            return @{
                workflowName = "PRD DEVELOPMENT WORKFLOW"
                estimatedTime = "2-4 hours"
                completionCriteria = "95% confidence score"
                steps = @(
                    @{name="Problem Statement"; done=($State.deliverables.problem_statement -ge 100); status=""; command=""},
                    @{name="Tech Stack"; done=($State.deliverables.tech_stack -ge 100); status=""; command=""},
                    @{name="Feature List"; done=($State.deliverables.feature_list -ge 100); status=""; command=""},
                    @{name="MVP Scope"; done=($State.deliverables.mvp_scope -ge 100); status=""; command=""}
                )
                immediateActions = @(
                    @{command="forge evolve-spec"; description="Refine PRD interactively"},
                    @{command="forge prd-report"; description="Review PRD completeness"}
                )
                futureActions = @(
                    @{command="forge import-ia [file]"; description="Import Information Architecture"}
                )
            }
        }
        "IA" {
            $iaExists = $State.ia_model -and $State.ia_model.routes
            return @{
                workflowName = "INFORMATION ARCHITECTURE WORKFLOW"
                estimatedTime = "1-2 hours"
                completionCriteria = "IA imported + 95% quality"
                steps = @(
                    @{name="Import IA"; done=$iaExists; status=""; command="forge import-ia [file]"},
                    @{name="Review Sitemap"; done=$false; status=""; command="forge ia-sitemap-report"},
                    @{name="Review User Flows"; done=$false; status=""; command="forge ia-userflows-report"},
                    @{name="Review ERD"; done=$false; status=""; command="forge ia-erd-report"}
                )
                immediateActions = @(
                    @{command="forge import-ia [file]"; description="Import IA report"},
                    @{command="forge ia-sitemap-report"; description="Review sitemap visualization"}
                )
                futureActions = @(
                    @{command="forge design-brief website"; description="Start design phase"}
                )
            }
        }
        "Design" {
            $designExists = Test-Path "$ProjectPath\design\aesthetic-brief.md"
            $compExists = Test-Path "$ProjectPath\design\competitive-analysis.md"
            return @{
                workflowName = "DESIGN BRIEF WORKFLOW"
                estimatedTime = "1-2 hours"
                completionCriteria = "2 design docs created"
                steps = @(
                    @{name="Design Interview"; done=$designExists; status="Not Started"; command="forge design-brief website"},
                    @{name="Competitive Analysis"; done=$compExists; status="Not Started"; command=""},
                    @{name="Color and Typography"; done=$false; status="Not Started"; command=""},
                    @{name="Reference Collection"; done=$false; status="Not Started"; command=""}
                )
                immediateActions = @(
                    @{command="forge design-brief website"; description="Complete 10-minute design interview"},
                    @{command="Review competitor sites"; description="Gather 3-5 aesthetic references"}
                )
                futureActions = @(
                    @{command="forge setup-repo"; description="Initialize GitHub and generate issues"},
                    @{command="Begin implementation"; description="Process issues one by one"}
                )
            }
        }
        "GitHub" {
            return @{
                workflowName = "GITHUB SETUP WORKFLOW"
                estimatedTime = "30 minutes"
                completionCriteria = "Repo + issues created"
                steps = @(
                    @{name="Initialize Repository"; done=$false; status=""; command="forge setup-repo"},
                    @{name="Generate Issues"; done=$false; status=""; command="forge generate-issues"},
                    @{name="Configure CI/CD"; done=$false; status=""; command=""}
                )
                immediateActions = @(
                    @{command="forge setup-repo [name]"; description="Initialize GitHub repository"},
                    @{command="forge generate-issues"; description="Create implementation issues"}
                )
                futureActions = @(
                    @{command="forge issue [number]"; description="Begin development workflow"}
                )
            }
        }
        "Development" {
            return @{
                workflowName = "IMPLEMENTATION WORKFLOW"
                estimatedTime = "Varies by scope"
                completionCriteria = "All features implemented"
                steps = @(
                    @{name="Process Issues"; done=$false; status=""; command="forge issue [number]"},
                    @{name="Run Tests"; done=$false; status=""; command="forge test"},
                    @{name="Code Review"; done=$false; status=""; command="forge review-pr"}
                )
                immediateActions = @(
                    @{command="forge issue [number]"; description="Start working on an issue"},
                    @{command="forge test"; description="Run test suite"}
                )
                futureActions = @(
                    @{command="forge deploy"; description="Deploy to production"}
                )
            }
        }
        "Launch" {
            return @{
                workflowName = "LAUNCH WORKFLOW"
                estimatedTime = "1-2 hours"
                completionCriteria = "Production deployment"
                steps = @(
                    @{name="Deploy Production"; done=$false; status=""; command="forge deploy"},
                    @{name="Setup Monitoring"; done=$false; status=""; command=""},
                    @{name="User Feedback"; done=$false; status=""; command=""}
                )
                immediateActions = @(
                    @{command="forge deploy"; description="Deploy to production"},
                    @{command="Setup monitoring"; description="Configure analytics"}
                )
                futureActions = @()
            }
        }
    }
}
