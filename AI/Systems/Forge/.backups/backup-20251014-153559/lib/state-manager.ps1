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
        $json = Get-Content $statePath | ConvertFrom-Json
        return ConvertTo-Hashtable $json
    }

    # Return default state
    return @{
        project_name = Split-Path $ProjectPath -Leaf
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        confidence = 0
        industry = "unknown"
        validated = $false
        blockers = @()
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

    # Ensure arrays are preserved in JSON (force single-item arrays to remain arrays)
    $jsonSettings = @{
        Depth = 10
        Compress = $false
    }

    $State | ConvertTo-Json @jsonSettings | Set-Content $statePath
}

function Update-ProjectConfidence {
    param(
        [string]$ProjectPath,
        [hashtable]$Deliverables
    )

    # Load confidence weights
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

    # Check tech stack
    if ($State.deliverables.tech_stack -lt 100) {
        $foundBlockers += @{
            id = "missing_tech_stack"
            message = "Tech Stack Incomplete"
            resolution = "Complete all 5 components"
        }
    }

    # Check overall confidence
    if ($State.confidence -lt $blocks.minimum_confidence) {
        $foundBlockers += @{
            id = "low_confidence"
            message = "Confidence Below 95%"
            resolution = "Complete missing deliverables"
        }
    }

    # Check feature clarity
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

    # Find incomplete deliverables
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

    # Sort by impact (highest first)
    return $steps | Sort-Object -Property impact -Descending
}
