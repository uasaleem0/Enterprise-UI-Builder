# Forge Design State Manager
# Handles Phase 2.5 (Visual Design) state persistence and retrieval

function Initialize-DesignState {
    param(
        [string]$ProjectPath,
        [string]$Type
    )

    $statePath = "$ProjectPath\.forge-design-state.json"

    # Skip if already exists
    if (Test-Path $statePath) {
        Write-Host "[INFO] Design state already exists" -ForegroundColor Gray
        return
    }

    # Create initial state structure
    $state = @{
        version = "1.0"
        type = $Type
        phase = "interview"
        confidence = 20
        created = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

        interview = @{
            who_for = ""
            aesthetic_goals = ""
            anti_patterns = ""
            brand_line = ""
            color_range = @{
                warm_cool = ""
                light_dark = ""
                accents_include = @()
                accents_exclude = @()
            }
            features = @()
            color_preferences = ""  # legacy
            inspiration_sites = @()
        }

        interview_complete = $false
        competitive_complete = $false
        palette_complete = $false
        mockup_complete = $false

        competitive_analysis = @{}
        palette = @{}
        mockups = @{}
    }

    # Save to file
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath
    Write-Host "[OK] Design state initialized" -ForegroundColor Green
}

function Get-DesignState {
    param([string]$ProjectPath)

    $statePath = "$ProjectPath\.forge-design-state.json"

    if (-not (Test-Path $statePath)) {
        return $null
    }

    try {
        $json = Get-Content $statePath -Raw | ConvertFrom-Json

        # Convert to hashtable for easier manipulation
        $state = @{
            version = $json.version
            type = $json.type
            phase = $json.phase
            confidence = $json.confidence
            created = $json.created
            updated = $json.updated
            interview = @{
                who_for = if ($json.interview.who_for) { $json.interview.who_for } else { "" }
                aesthetic_goals = $json.interview.aesthetic_goals
                anti_patterns = $json.interview.anti_patterns
                brand_line = if ($json.interview.brand_line) { $json.interview.brand_line } else { "" }
                color_range = @{
                    warm_cool = if ($json.interview.color_range.warm_cool) { $json.interview.color_range.warm_cool } else { "" }
                    light_dark = if ($json.interview.color_range.light_dark) { $json.interview.color_range.light_dark } else { "" }
                    accents_include = @()
                    accents_exclude = @()
                }
                features = @()
                color_preferences = if ($json.interview.color_preferences) { $json.interview.color_preferences } else { "" }
                inspiration_sites = @()
            }
            interview_complete = $json.interview_complete
            competitive_complete = $json.competitive_complete
            palette_complete = $json.palette_complete
            mockup_complete = $json.mockup_complete
            competitive_analysis = if ($json.competitive_analysis) { $json.competitive_analysis } else { @{} }
            palette = if ($json.palette) { $json.palette } else { @{} }
            mockups = if ($json.mockups) { $json.mockups } else { @{} }
        }

        # Preserve arrays if present
        if ($json.interview -and $json.interview.features) { $state.interview.features = @($json.interview.features) }
        if ($json.interview -and $json.interview.inspiration_sites) { $state.interview.inspiration_sites = @($json.interview.inspiration_sites) }
        if ($json.interview -and $json.interview.color_range) {
            if ($json.interview.color_range.accents_include) { $state.interview.color_range.accents_include = @($json.interview.color_range.accents_include) }
            if ($json.interview.color_range.accents_exclude) { $state.interview.color_range.accents_exclude = @($json.interview.color_range.accents_exclude) }
        }

        return $state
    } catch {
        Write-Host "[ERROR] Failed to parse design state: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Set-DesignState {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $statePath = "$ProjectPath\.forge-design-state.json"

    # Update timestamp
    $State.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

    try {
        # Ensure arrays are preserved in JSON
        $jsonSettings = @{
            Depth = 10
            Compress = $false
        }

        $State | ConvertTo-Json @jsonSettings | Set-Content $statePath
    } catch {
        Write-Host "[ERROR] Failed to save design state: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Get-DesignPhase {
    param([string]$ProjectPath)

    $state = Get-DesignState -ProjectPath $ProjectPath

    if (-not $state) {
        return "none"
    }

    return $state.phase
}

function Update-DesignPhase {
    param(
        [string]$ProjectPath,
        [ValidateSet('interview', 'competitive', 'palette', 'mockup', 'implementation')]
        [string]$NewPhase
    )

    $state = Get-DesignState -ProjectPath $ProjectPath

    if (-not $state) {
        Write-Host "[ERROR] No design state found" -ForegroundColor Red
        return
    }

    $state.phase = $NewPhase
    Set-DesignState -ProjectPath $ProjectPath -State $state
}

function Update-DesignConfidence {
    param(
        [string]$ProjectPath,
        [int]$NewConfidence
    )

    $state = Get-DesignState -ProjectPath $ProjectPath

    if (-not $state) {
        Write-Host "[ERROR] No design state found" -ForegroundColor Red
        return
    }

    $state.confidence = $NewConfidence
    Set-DesignState -ProjectPath $ProjectPath -State $state
}

function Test-DesignStateExists {
    param([string]$ProjectPath)

    $statePath = "$ProjectPath\.forge-design-state.json"
    return (Test-Path $statePath)
}

# Update or change the design type at any time (accepts any non-empty string)
function Update-DesignType {
    param(
        [string]$ProjectPath,
        [string]$Type
    )

    if ([string]::IsNullOrWhiteSpace($Type)) {
        Write-Host "[ERROR] Type cannot be empty" -ForegroundColor Red
        return
    }

    $state = Get-DesignState -ProjectPath $ProjectPath
    if (-not $state) {
        Write-Host "[INFO] No existing design state. Initializing..." -ForegroundColor Gray
        Initialize-DesignState -ProjectPath $ProjectPath -Type $Type
        return
    }

    $state.type = $Type
    Set-DesignState -ProjectPath $ProjectPath -State $state
    Write-Host "[OK] Design type set to: $Type" -ForegroundColor Green
}
