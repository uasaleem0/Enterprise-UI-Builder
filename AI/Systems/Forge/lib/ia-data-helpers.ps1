# IA Data Helpers - Type-safe extraction utilities
# Handles inconsistent JSON deserialization from any IA source

function Get-EntitiesFromValue {
    <#
    .SYNOPSIS
    Extracts entity names from any value type (string, array, hashtable)

    .DESCRIPTION
    Handles PowerShell JSON deserialization inconsistencies:
    - Single entity: "Exercise" → returns @("Exercise")
    - Multiple entities: array → returns flattened string array
    - Space-separated: "Entity1 Entity2" → returns @("Entity1", "Entity2")
    - Empty hashtable: {} → returns @()
    #>
    param($Value)

    $result = @()

    # Null or empty
    if (-not $Value) { return $result }

    # Empty hashtable (from {})
    if ($Value -is [hashtable] -and $Value.Count -eq 0) {
        return $result
    }

    # String (single entity or space-separated)
    if ($Value -is [string]) {
        $result = $Value -split '\s+' | Where-Object { $_.Trim() }
        return $result
    }

    # Array
    if ($Value -is [array]) {
        foreach ($item in $Value) {
            if ($item -is [string] -and $item) {
                $result += $item.Trim()
            }
        }
        return $result
    }

    # Fallback: try to convert to string
    if ($Value) {
        return @($Value.ToString().Trim())
    }

    return $result
}

function Get-RouteEntities {
    <#
    .SYNOPSIS
    Gets entities for a specific route from entities_by_route

    .DESCRIPTION
    Type-safe access to entities_by_route regardless of whether it's a hashtable or PSCustomObject
    #>
    param(
        $EntitiesByRoute,
        [string]$Route
    )

    if (-not $EntitiesByRoute) { return @() }

    $value = $null

    # Hashtable access
    if ($EntitiesByRoute -is [hashtable]) {
        if ($EntitiesByRoute.ContainsKey($Route)) {
            $value = $EntitiesByRoute[$Route]
        }
    }
    # PSCustomObject access
    elseif ($EntitiesByRoute.PSObject.Properties.Name -contains $Route) {
        $value = $EntitiesByRoute.$Route
    }

    return Get-EntitiesFromValue -Value $value
}

function Get-ErrorStatesFromValue {
    <#
    .SYNOPSIS
    Extracts error states from flow.errors field

    .DESCRIPTION
    Handles various error formats:
    - String: single error message
    - Array: multiple error messages
    - Hashtable: empty {} or structured errors
    #>
    param($Value)

    if (-not $Value) { return @() }

    # Empty hashtable
    if ($Value -is [hashtable] -and $Value.Count -eq 0) {
        return @()
    }

    # String
    if ($Value -is [string]) {
        return @($Value)
    }

    # Array
    if ($Value -is [array]) {
        $result = @()
        foreach ($item in $Value) {
            if ($item -is [string] -and $item) {
                $result += $item
            }
        }
        return $result
    }

    # Structured hashtable (future: could parse error types)
    if ($Value -is [hashtable]) {
        # For now, just return empty - could be enhanced later
        return @()
    }

    return @()
}

function Get-StepsFromValue {
    <#
    .SYNOPSIS
    Extracts steps from flow.steps field

    .DESCRIPTION
    Filters out hashtables and non-string values
    #>
    param($Value)

    if (-not $Value) { return @() }

    # Single string
    if ($Value -is [string]) {
        return @($Value)
    }

    # Array
    if ($Value -is [array]) {
        $result = @()
        foreach ($item in $Value) {
            # Only include string steps, skip hashtables
            if ($item -is [string] -and $item) {
                $result += $item
            }
        }
        return $result
    }

    return @()
}

