# Forge Session Formatter
# Template-based formatting for session reports and handoffs

function Format-SessionCloseReport {
    param(
        [hashtable]$Session,
        [hashtable]$State
    )

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "     SESSION CLOSE - $($Session.project) ($($Session.ai))    " -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Duration and commands
    Write-Host "Session Duration: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($Session.duration_minutes) minutes"
    Write-Host "Commands Run: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($Session.commands_count)"
    Write-Host "Confidence Change: " -NoNewline -ForegroundColor Yellow

    $start = $Session.confidence_start
    $end = $Session.confidence_end
    $delta = $Session.confidence_delta

    if ($delta -gt 0) {
        Write-Host "$start% → $end% (+" -NoNewline
        Write-Host "$delta" -NoNewline -ForegroundColor Green
        Write-Host "%)"
    } elseif ($delta -lt 0) {
        Write-Host "$start% → $end% (" -NoNewline
        Write-Host "$delta" -NoNewline -ForegroundColor Red
        Write-Host "%)"
    } else {
        Write-Host "$start% → $end% (no change)"
    }
    Write-Host ""

    # Accomplishments
    if ($Session.deliverables_changed.Count -gt 0) {
        Write-Host "Deliverables Updated:" -ForegroundColor Green
        foreach ($change in $Session.deliverables_changed) {
            $name = $change.deliverable -replace '_', ' '
            $name = (Get-Culture).TextInfo.ToTitleCase($name)
            $icon = if ($change.delta -gt 0) { "✅" } else { "⚠️" }
            Write-Host "  $icon ${name}: " -NoNewline
            Write-Host "$($change.old)% → $($change.new)% " -NoNewline
            if ($change.delta -gt 0) {
                Write-Host "(+$($change.delta)%)" -ForegroundColor Green
            }
        }
        Write-Host ""
    }

    # User notes
    if ($Session.user_notes.Count -gt 0) {
        Write-Host "User Feedback & Concerns:" -ForegroundColor Yellow
        foreach ($note in $Session.user_notes) {
            Write-Host "  ⚠️  $($note.note)"
        }
        Write-Host ""
    }

    # Bugs identified
    if ($Session.bugs_identified.Count -gt 0) {
        Write-Host "Bugs & Issues Identified:" -ForegroundColor Red
        foreach ($bug in $Session.bugs_identified) {
            Write-Host "  🐛 $($bug.note)"
        }
        Write-Host ""
    }

    # Files modified
    if ($Session.files_modified.Count -gt 0) {
        Write-Host "Files Modified:" -ForegroundColor Cyan
        foreach ($file in $Session.files_modified) {
            Write-Host "  - $file"
        }
        Write-Host ""
    }

    Write-Host "=============================================================" -ForegroundColor Cyan
}

function Format-PreviousSessionNotes {
    param(
        [hashtable]$Session,
        [hashtable]$State,
        [string]$TimeSince
    )

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Yellow
    Write-Host "  PREVIOUS SESSION NOTES ($($Session.ai) - $TimeSince)  " -ForegroundColor Yellow
    Write-Host "=============================================================" -ForegroundColor Yellow
    Write-Host ""

    # Duration and confidence
    Write-Host "Duration: " -NoNewline
    Write-Host "$($Session.duration_minutes) minutes" -ForegroundColor White
    Write-Host "Confidence Change: " -NoNewline

    $delta = $Session.confidence_delta
    if ($delta -gt 0) {
        Write-Host "$($Session.confidence_start)% → $($Session.confidence_end)% (+" -NoNewline
        Write-Host "$delta" -NoNewline -ForegroundColor Green
        Write-Host "%)"
    } else {
        Write-Host "$($Session.confidence_start)% → $($Session.confidence_end)%"
    }
    Write-Host ""

    # What was accomplished
    if ($Session.deliverables_changed.Count -gt 0) {
        Write-Host "What Was Accomplished:" -ForegroundColor Green
        foreach ($change in $Session.deliverables_changed) {
            $name = $change.deliverable -replace '_', ' '
            $name = (Get-Culture).TextInfo.ToTitleCase($name)
            Write-Host "  ✅ $name improved ($($change.old)% → $($change.new)%)"
        }
        Write-Host ""
    }

    # User concerns
    if ($Session.user_notes.Count -gt 0) {
        Write-Host "User Concerns & Feedback:" -ForegroundColor Yellow
        foreach ($note in $Session.user_notes) {
            Write-Host "  ⚠️  $($note.note)"
        }
        Write-Host ""
    }

    # Known issues
    if ($Session.bugs_identified.Count -gt 0) {
        Write-Host "Known Issues:" -ForegroundColor Red
        foreach ($bug in $Session.bugs_identified) {
            Write-Host "  🐛 $($bug.note)"
        }
        Write-Host ""
    }

    # Files modified
    if ($Session.files_modified.Count -gt 0) {
        Write-Host "Files Modified:" -ForegroundColor Cyan
        $fileList = $Session.files_modified -join ', '
        Write-Host "  $fileList"
        Write-Host ""
    }

    # What's still needed
    if ($State.confidence -lt 95) {
        Write-Host "What's Still Needed (Current: $($State.confidence)%, Target: 95%):" -ForegroundColor Cyan

        . "$PSScriptRoot\state-manager.ps1"
        $nextSteps = Get-NextSteps -State $State

        $count = 0
        foreach ($step in $nextSteps | Select-Object -First 3) {
            $count++
            $name = $step.deliverable -replace '_', ' '
            $name = (Get-Culture).TextInfo.ToTitleCase($name)
            Write-Host "  $count. Complete $name (+" -NoNewline
            Write-Host "$($step.impact)" -NoNewline -ForegroundColor Green
            Write-Host "%) → $($step.new_confidence)%"
        }
        Write-Host ""
    }

    Write-Host "=============================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Format-SessionHistory {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "       SESSION HISTORY - $($State.project_name)             " -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not $State.sessions -or $State.sessions.Count -eq 0) {
        Write-Host "No previous sessions found." -ForegroundColor Gray
        Write-Host ""
        return
    }

    $sessionNum = 1
    foreach ($session in $State.sessions) {
        # Skip empty sessions
        if (-not $session.started_at -or -not $session.ai) {
            continue
        }

        $started = [DateTime]::Parse($session.started_at)
        $dateStr = $started.ToString("yyyy-MM-dd HH:mm")

        Write-Host "Session ${sessionNum}: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($session.ai) " -NoNewline -ForegroundColor White
        Write-Host "($dateStr)" -ForegroundColor Gray

        Write-Host "  Duration: $($session.duration_minutes) minutes" -ForegroundColor White
        Write-Host "  Confidence: $($session.confidence_start)% → $($session.confidence_end)% " -NoNewline

        $delta = $session.confidence_delta
        if ($delta -gt 0) {
            Write-Host "(+$delta%)" -ForegroundColor Green
        } elseif ($delta -lt 0) {
            Write-Host "($delta%)" -ForegroundColor Red
        } else {
            Write-Host "(no change)" -ForegroundColor Gray
        }

        Write-Host "  Summary: $($session.summary)" -ForegroundColor Gray
        Write-Host ""

        $sessionNum++
    }

    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Format-LastSession {
    param([string]$ProjectPath)

    . "$PSScriptRoot\state-manager.ps1"
    $state = Get-ProjectState -ProjectPath $ProjectPath

    if (-not $state.sessions -or $state.sessions.Count -eq 0) {
        Write-Host ""
        Write-Host "[INFO] No previous sessions found for this project." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $lastSession = $state.sessions[-1]

    # Calculate time since
    $ended = [DateTime]::Parse($lastSession.ended_at)
    $now = Get-Date
    $timeSince = $now - $ended

    if ($timeSince.TotalHours -lt 1) {
        $timeSinceStr = "$([math]::Round($timeSince.TotalMinutes, 0)) minutes ago"
    } elseif ($timeSince.TotalDays -lt 1) {
        $timeSinceStr = "$([math]::Round($timeSince.TotalHours, 0)) hours ago"
    } else {
        $timeSinceStr = "$([math]::Round($timeSince.TotalDays, 0)) days ago"
    }

    Format-PreviousSessionNotes -Session $lastSession -State $state -TimeSince $timeSinceStr
}
