# Forge State Manager
# Handles project state persistence and retrieval

function ConvertTo-Hashtable {
    param([Parameter(ValueFromPipeline)]$InputObject)

    process {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @()
            foreach ($item in $InputObject) {
                $collection += ConvertTo-Hashtable $item
            }
            return $collection
        }

        if ($InputObject -is [PSCustomObject]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }
            return $hash
        }

        return $InputObject
    }
}

function Get-ProjectState {
    param([string]$ProjectPath)

    $statePath = "$ProjectPath\.forge-state.json"

    if (Test-Path $statePath) {
        # Robust read with raw mode and small retry to avoid partial reads during concurrent writes
        $attempts = 0
        do {
            try {
                $raw = Get-Content -Path $statePath -Raw -ErrorAction Stop
                if (-not [string]::IsNullOrWhiteSpace($raw)) {
                    $json = $raw | ConvertFrom-Json -ErrorAction Stop
                    return ConvertTo-Hashtable $json
                }
            } catch {
                Start-Sleep -Milliseconds 50
            }
            $attempts++
        } while ($attempts -lt 5)
        throw "Failed to read project state from $statePath"
    }

    # Return default state
    return @{
        project_name = Split-Path $ProjectPath -Leaf
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        confidence = 0
        industry = "unknown"
        validated = $false
        ia_model = $null
        prd_model = $null
        project_model = $null
        deliverables = @{
            problem_statement = 0
            user_personas = 0
            user_stories = 0
            feature_list = 0
            tech_stack = 0
            success_metrics = 0
            mvp_scope = 0
            non_functional = 0
        }
        current_session = $null
        sessions = @()
    }
}

function Set-ProjectState {
    param(
        [string]$ProjectPath,
        [hashtable]$State
    )

    $statePath = "$ProjectPath\.forge-state.json"

    $jsonSettings = @{
        Depth = 10
        Compress = $false
    }

    # Sanitize: ensure all dictionary keys are strings to satisfy JSON serializer
    function Convert-KeysToString {
        param($Obj)
        if ($null -eq $Obj) { return $null }
        # CRITICAL: Check for string FIRST before IEnumerable check
        # Strings are IEnumerable, and -isnot check may not work reliably in all cases
        if ($Obj -is [string]) { return $Obj }
        if ($Obj -is [hashtable]) {
            $out = @{}
            foreach ($k in $Obj.Keys) {
                $ks = [string]$k
                $out[$ks] = Convert-KeysToString $Obj[$k]
            }
            return $out
        } elseif ($Obj -is [System.Collections.IDictionary]) {
            $out = @{}
            foreach ($k in $Obj.Keys) {
                $ks = [string]$k
                $out[$ks] = Convert-KeysToString $Obj[$k]
            }
            return $out
        } elseif ($Obj -is [System.Collections.IEnumerable]) {
            $arr = @()
            foreach ($it in $Obj) { $arr += ,(Convert-KeysToString $it) }
            return $arr
        } elseif ($Obj -is [PSCustomObject]) {
            $hash = @{}
            foreach ($p in $Obj.PSObject.Properties) { $hash[$p.Name] = Convert-KeysToString $p.Value }
            return $hash
        }
        return $Obj
    }

    $sanitized = Convert-KeysToString $State

    # Safe write: write to temp file then atomically replace
    $jsonText = $sanitized | ConvertTo-Json @jsonSettings
    $tempPath = "$statePath.tmp"
    $jsonText | Set-Content -Path $tempPath -Encoding UTF8
    Move-Item -Path $tempPath -Destination $statePath -Force
}

function Update-ProjectConfidence {
    param(
        [string]$ProjectPath,
        [hashtable]$Deliverables
    )

    $weightsPath = "$PSScriptRoot\..\core\validation\confidence-weights.json"
    $weights = Get-Content $weightsPath | ConvertFrom-Json

    $confidence = 0
    $confidence += $Deliverables.feature_list * $weights.base_weights.feature_list.weight
    $confidence += $Deliverables.tech_stack * $weights.base_weights.tech_stack.weight
    $confidence += $Deliverables.success_metrics * $weights.base_weights.success_metrics.weight
    $confidence += $Deliverables.mvp_scope * $weights.base_weights.mvp_scope.weight
    $confidence += $Deliverables.problem_statement * $weights.base_weights.problem_statement.weight
    $confidence += $Deliverables.user_personas * $weights.base_weights.user_personas.weight
    $confidence += $Deliverables.user_stories * $weights.base_weights.user_stories.weight
    $confidence += $Deliverables.non_functional * $weights.base_weights.non_functional_requirements.weight

    return [math]::Round($confidence, 2)
}

function Test-ValidationBlocks {
    param([hashtable]$State)

    $blocksPath = "$PSScriptRoot\..\core\validation\hard-blocks.json"
    $blocks = Get-Content $blocksPath | ConvertFrom-Json

    $foundBlockers = @()

    if ($State.deliverables.tech_stack -lt 100) {
        $foundBlockers += @{
            id = "missing_tech_stack"
            message = "Tech Stack Incomplete"
            resolution = "Complete all 5 components"
        }
    }

    if ($State.confidence -lt $blocks.minimum_confidence) {
        $foundBlockers += @{
            id = "low_confidence"
            message = "Confidence Below 95%"
            resolution = "Complete missing deliverables"
        }
    }

    if ($State.deliverables.feature_list -lt 75) {
        $foundBlockers += @{
            id = "vague_features"
            message = "Features Too Vague"
            resolution = "Add acceptance criteria"
        }
    }

    return $foundBlockers
}

function Get-NextSteps {
    param(
        [hashtable]$State,
        [double]$TargetConfidence = 95
    )

    $weightsPath = "$PSScriptRoot\..\core\validation\confidence-weights.json"
    $weights = Get-Content $weightsPath | ConvertFrom-Json

    $gap = $TargetConfidence - $State.confidence
    $steps = @()

    foreach ($key in $State.deliverables.Keys) {
        $completion = $State.deliverables.$key
        if ($completion -lt 100) {
            $remaining = 100 - $completion
            $weightKey = $key
            if ($key -eq "non_functional") { $weightKey = "non_functional_requirements" }

            $weight = $weights.base_weights.$weightKey.weight
            $impact = ($remaining / 100) * $weight * 100

            $steps += @{
                deliverable = $key
                current = $completion
                needed = $remaining
                impact = [math]::Round($impact, 2)
                new_confidence = [math]::Round($State.confidence + $impact, 2)
            }
        }
    }

    return $steps | Sort-Object -Property impact -Descending
}
