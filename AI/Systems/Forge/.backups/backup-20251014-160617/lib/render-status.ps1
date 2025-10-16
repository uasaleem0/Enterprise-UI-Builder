# Forge Status Renderer
# Renders confidence tracker with ASCII art

function Show-ConfidenceTracker {
    param(
        [string]$ProjectName,
        [double]$Confidence,
        [hashtable]$Deliverables
    )

    $gap = 95 - $Confidence
    $status = if ($Confidence -ge 95) { "[READY]" } else { "[BLOCKED]" }

    # Progress bar
    $filled = [math]::Floor($Confidence / 10)
    $empty = 10 - $filled
    $progressBar = "[" + ("#" * $filled) + ("-" * $empty) + "]"

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "         FORGE PRD CONFIDENCE TRACKER - $ProjectName" -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Overall: $($Confidence)% $progressBar | Target: 95% | Gap: $(if($gap -gt 0){'-'}else{'+'})$([math]::Abs($gap))%" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "-------------------------------------------------------------"
    Write-Host " Deliverable              | Weight | Status | Contribution"
    Write-Host "-------------------------------------------------------------"

    $deliverableOrder = @(
        @{key="problem_statement"; name="Problem Statement"; weight=10},
        @{key="tech_stack"; name="Tech Stack"; weight=20},
        @{key="success_metrics"; name="Success Metrics"; weight=15},
        @{key="mvp_scope"; name="MVP Scope"; weight=15},
        @{key="feature_list"; name="Feature List"; weight=25},
        @{key="user_personas"; name="User Personas"; weight=7},
        @{key="user_stories"; name="User Stories"; weight=5},
        @{key="non_functional"; name="Non-Functional"; weight=3}
    )

    foreach ($item in $deliverableOrder) {
        $status = $Deliverables[$item.key]
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

        Write-Host " " -NoNewline
        Write-Host "$icon" -ForegroundColor $iconColor -NoNewline
        Write-Host " $name | $weightStr | $statusStr | $contribStr"
    }

    Write-Host "-------------------------------------------------------------"
    Write-Host ""

    if ($Confidence -ge 95) {
        Write-Host "[READY] Ready for GitHub setup!" -ForegroundColor Green
    } else {
        Write-Host "[BLOCKED] Need $([math]::Round($gap, 2))% more confidence to proceed" -ForegroundColor Red
    }

    Write-Host ""
}

function Show-NextSteps {
    param([array]$Steps)

    Write-Host "Next Steps to 95%:" -ForegroundColor Yellow
    Write-Host ""

    $i = 1
    foreach ($step in $Steps) {
        $deliverable = $step.deliverable -replace '_', ' '
        $deliverable = (Get-Culture).TextInfo.ToTitleCase($deliverable)

        Write-Host "$i. Complete $deliverable " -NoNewline
        Write-Host "(+$($step.impact)%)" -ForegroundColor Cyan -NoNewline
        Write-Host " -> $($step.new_confidence)%"

        $i++
        if ($i -gt 5) { break }  # Show top 5 only
    }

    Write-Host ""
}
