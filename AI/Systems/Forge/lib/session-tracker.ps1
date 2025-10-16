# Forge Session Tracker
# Automatic per-project session tracking with context preservation

function Get-CurrentAI {
    # Try environment variable first (recommended setup)
    if ($env:FORGE_AI) {
        return $env:FORGE_AI
    }

    # Try to auto-detect from environment
    $detected = $null

    # Check for Warp terminal
    if ($env:TERM_PROGRAM -eq "WarpTerminal" -or $env:WARP_IS_LOCAL_SHELL_SESSION) {
        $detected = "Warp"
    }
    # Check for Cursor/Codex (has specific env vars)
    elseif ($env:CURSOR_DIR -or (Get-Process -Name "Cursor" -ErrorAction SilentlyContinue)) {
        $detected = "Codex"
    }
    # Check for Claude Code (has specific paths)
    elseif ($env:CLAUDE_CODE_DIR -or (Get-Process -Name "Claude" -ErrorAction SilentlyContinue)) {
        $detected = "Claude"
    }

    if ($detected) {
        Write-Host "[INFO] Auto-detected AI: $detected" -ForegroundColor Gray
        $env:FORGE_AI = $detected
        return $detected
    }

    # Fallback: prompt user once (works in all IDEs/terminals)
    Write-Host ""
    Write-Host "Which AI are you using? " -NoNewline -ForegroundColor Cyan
    Write-Host "[C]laude / Co[d]ex / [W]arp / [Enter for Claude]: " -NoNewline -ForegroundColor Yellow
    $response = (Read-Host).ToUpper()

    # Map response to AI name
    $ai = switch ($response) {
        'C' { 'Claude' }
        'D' { 'Codex' }
        'X' { 'Codex' }
        'W' { 'Warp' }
        '' { 'Claude' }
        default { 'Claude' }
    }

    # Save to env for this PowerShell session
    $env:FORGE_AI = $ai

    Write-Host "[OK] Using AI: $ai (set " -NoNewline -ForegroundColor Green
    Write-Host '$env:FORGE_AI = "' -NoNewline -ForegroundColor Gray
    Write-Host $ai -NoNewline -ForegroundColor White
    Write-Host '"' -NoNewline -ForegroundColor Gray
    Write-Host " in `$PROFILE to skip this prompt)" -ForegroundColor Gray
    Write-Host ""

    return $ai
}

function Start-ForgeSession {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    # Check if session already active
    if ($State.current_session -and $State.current_session.started_at) {
        return  # Already active
    }

    $ai = Get-CurrentAI
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $projectName = Split-Path $ProjectPath -Leaf

    # Create new session
    $State.current_session = @{
        id = $timestamp
        ai = $ai
        project = $projectName
        started_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        confidence_start = $State.confidence
        commands = @()
        files_modified = @()
        user_notes = @()
        bugs_identified = @()
        deliverables_changed = @()
    }

    # Save state
    . "$PSScriptRoot\state-manager.ps1"
    Set-ProjectState -ProjectPath $ProjectPath -State $State

    Write-Host "[INFO] Session started for $projectName ($ai)" -ForegroundColor Cyan
}

function Track-Command {
    param(
        [string]$ProjectPath,
        [string]$Command,
        [array]$Arguments
    )

    . "$PSScriptRoot\state-manager.ps1"
    $state = Get-ProjectState -ProjectPath $ProjectPath

    if (-not $state.current_session) {
        Start-ForgeSession -ProjectPath $ProjectPath -State $state
        $state = Get-ProjectState -ProjectPath $ProjectPath
    }

    $commandEntry = @{
        time = Get-Date -Format "HH:mm:ss"
        command = "forge $Command"
        args = ($Arguments -join ' ')
    }

    # Ensure commands is a proper array
    if ($null -eq $state.current_session.commands) {
        $state.current_session.commands = @()
    }
    $state.current_session.commands = @($state.current_session.commands) + $commandEntry
    Set-ProjectState -ProjectPath $ProjectPath -State $state
}

function Add-SessionNote {
    param(
        [string]$ProjectPath,
        [string]$Note,
        [string]$Category = "general"
    )

    . "$PSScriptRoot\state-manager.ps1"
    $state = Get-ProjectState -ProjectPath $ProjectPath

    if (-not $state.current_session) {
        Write-Host "[ERROR] No active session. Run a forge command first." -ForegroundColor Red
        return
    }

    $noteEntry = @{
        time = Get-Date -Format "HH:mm:ss"
        note = $Note
        category = $Category
    }

    # Categorize - only match bug keywords at start of note
    if ($Category -eq "bug" -or $Note -match "(?i)^(bug|issue|error|broken):") {
        $state.current_session.bugs_identified = @($state.current_session.bugs_identified) + $noteEntry
        Write-Host "[BUG] Noted: $Note" -ForegroundColor Yellow
    } else {
        $state.current_session.user_notes = @($state.current_session.user_notes) + $noteEntry
        Write-Host "[NOTE] Saved: $Note" -ForegroundColor Green
    }

    Set-ProjectState -ProjectPath $ProjectPath -State $state
}

function Close-ForgeSession {
    param([string]$ProjectPath)

    . "$PSScriptRoot\state-manager.ps1"
    . "$PSScriptRoot\session-formatter.ps1"

    $state = Get-ProjectState -ProjectPath $ProjectPath

    if (-not $state.current_session) {
        Write-Host "[ERROR] No active session to close." -ForegroundColor Red
        return
    }

    $session = $state.current_session

    # Calculate duration
    $start = [DateTime]::Parse($session.started_at)
    $end = Get-Date
    $duration = $end - $start
    $durationMinutes = [math]::Round($duration.TotalMinutes, 0)

    # Prompt for final insights
    Write-Host ""
    Write-Host "Session Close - Any final notes/insights? (Y/n): " -NoNewline -ForegroundColor Cyan
    $response = Read-Host

    if ($response -ne 'n' -and $response -ne 'N') {
        do {
            Write-Host "Note: " -NoNewline -ForegroundColor Yellow
            $note = Read-Host
            if ($note) {
                Add-SessionNote -ProjectPath $ProjectPath -Note $note
            }
            Write-Host "Add another? (Y/n): " -NoNewline -ForegroundColor Cyan
            $more = Read-Host
        } while ($more -ne 'n' -and $more -ne 'N')

        # Reload state to get new notes
        $state = Get-ProjectState -ProjectPath $ProjectPath
        $session = $state.current_session
    }

    # Finalize session
    $session.ended_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $session.duration_minutes = $durationMinutes
    $session.confidence_end = $state.confidence
    $session.confidence_delta = [math]::Round($state.confidence - $session.confidence_start, 2)
    $session.commands_count = $session.commands.Count

    # Generate simple summary for history view
    $accomplishments = @()
    if ($session.deliverables_changed.Count -gt 0) {
        $accomplishments += "$($session.deliverables_changed.Count) deliverable(s) improved"
    }
    if ($session.user_notes.Count -gt 0) {
        $accomplishments += "$($session.user_notes.Count) note(s) captured"
    }
    if ($session.bugs_identified.Count -gt 0) {
        $accomplishments += "$($session.bugs_identified.Count) bug(s) identified"
    }
    $session.summary = if ($accomplishments.Count -gt 0) { $accomplishments -join '; ' } else { "Session logged" }

    # Archive to history
    if (-not $state.sessions) {
        $state.sessions = @()
    }
    # Ensure sessions is always an array
    $state.sessions = @($state.sessions) + $session

    # Clear current session
    $state.current_session = $null

    # Save
    Set-ProjectState -ProjectPath $ProjectPath -State $state

    # Display close report
    Format-SessionCloseReport -Session $session -State $state

    Write-Host ""
    Write-Host "[OK] Session archived. Ready for handoff." -ForegroundColor Green
    Write-Host "Run 'forge show last-session' to review anytime." -ForegroundColor Gray
}

function Show-PreviousSessionNotes {
    param([string]$ProjectPath)

    . "$PSScriptRoot\state-manager.ps1"
    . "$PSScriptRoot\session-formatter.ps1"

    $state = Get-ProjectState -ProjectPath $ProjectPath

    # Get last session
    if (-not $state.sessions -or $state.sessions.Count -eq 0) {
        return  # No previous session
    }

    $lastSession = $state.sessions[-1]

    # Calculate time since
    $timeSinceStr = "unknown"
    if ($lastSession.ended_at) {
        try {
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
        } catch {
            $timeSinceStr = "recently"
        }
    }

    Format-PreviousSessionNotes -Session $lastSession -State $state -TimeSince $timeSinceStr
}

function Check-SessionExists {
    param([string]$ProjectPath)

    . "$PSScriptRoot\state-manager.ps1"
    $state = Get-ProjectState -ProjectPath $ProjectPath

    return ($state.current_session -ne $null)
}
