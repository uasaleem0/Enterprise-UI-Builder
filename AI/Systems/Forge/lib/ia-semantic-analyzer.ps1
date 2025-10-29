<#
 .SYNOPSIS
     Semantic Issues Detector (IA)
 .DESCRIPTION
     PURPOSE: Detect vague flows, route contradictions, impossibilities, implied dependencies.
     METHOD: Deterministic heuristics (pattern-based, no AI).
     USED BY: forge-import-ia, forge-show-ia
#>

# Reuse Normalize-Text from PRD analyzer
function Normalize-Text {
    param([string]$Text)
    if (-not $Text) { return '' }
    $t = $Text -replace "\r\n?", "`n"
    $t = $t -replace "[\u2018\u2019]", "'"
    $t = $t -replace "[\u201C\u201D]", '"'
    $t = $t -replace "[\u2013\u2014\u2212]", '-'
    $t = $t -replace "\u2026", '...'
    $t = $t -replace "\uFFFD", ""
    return $t
}

function Get-IASemanticAnalysis {
    <#
    .SYNOPSIS
    Performs deep semantic analysis on IA content

    .PARAMETER IAPath
    Path to ia/ directory

    .PARAMETER IAModel
    Optional parsed IA model from state (for cross-referencing)

    .OUTPUTS
    Hashtable containing:
    - vague_flows: Array of flows missing required fields
    - route_contradictions: Array of conflicting routes
    - impossibilities: Array of unrealistic patterns
    - implied_dependencies: Array of inferred requirements
    - completeness_issues: Array of missing mappings
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$IAPath,

        [Parameter(Mandatory=$false)]
        [object]$IAModel
    )

    if (-not (Test-Path $IAPath)) {
        throw "IA directory not found: $IAPath"
    }

    $analysis = @{
        vague_flows = @()
        route_contradictions = @()
        impossibilities = @()
        implied_dependencies = @()
        completeness_issues = @()
    }

    # Load IA files
    $sitemapPath = Join-Path $IAPath "sitemap.md"
    $flowsPath = Join-Path $IAPath "flows.md"
    $entitiesPath = Join-Path $IAPath "entities.md"
    $navPath = Join-Path $IAPath "navigation.md"

    $sitemapText = if (Test-Path $sitemapPath) { $raw = Get-Content -Path $sitemapPath -Raw; Normalize-Text $raw } else { '' }
    $flowsText = if (Test-Path $flowsPath) { $raw = Get-Content -Path $flowsPath -Raw; Normalize-Text $raw } else { '' }
    $entitiesText = if (Test-Path $entitiesPath) { $raw = Get-Content -Path $entitiesPath -Raw; Normalize-Text $raw } else { '' }
    $navText = if (Test-Path $navPath) { $raw = Get-Content -Path $navPath -Raw; Normalize-Text $raw } else { '' }

    # --- VAGUE FLOWS DETECTION ---
    $analysis.vague_flows += Get-VagueFlows -FlowsText $flowsText

    # --- ROUTE CONTRADICTIONS DETECTION ---
    $analysis.route_contradictions += Get-RouteContradictions -SitemapText $sitemapText -FlowsText $flowsText

    # --- IMPOSSIBILITIES DETECTION ---
    $analysis.impossibilities += Get-IAImpossibilities -SitemapText $sitemapText -FlowsText $flowsText -NavText $navText

    # --- IMPLIED DEPENDENCIES DETECTION ---
    $analysis.implied_dependencies += Get-IAImpliedDependencies -SitemapText $sitemapText -FlowsText $flowsText

    # --- COMPLETENESS ISSUES DETECTION ---
    $analysis.completeness_issues += Get-IACompletenessIssues -SitemapText $sitemapText -FlowsText $flowsText -EntitiesText $entitiesText -IAModel $IAModel

    return $analysis
}

function Get-VagueFlows {
    param([string]$FlowsText)

    $vagueFlows = @()

    # Extract flows
    $flowPattern = '(?im)^(?:###?\s+|(?:\d+\.\s*)?(?:Primary|Secondary|Tertiary)?\s*(?:Flow|Journey|Process):\s*)(.+?)$'
    $flows = [regex]::Matches($FlowsText, $flowPattern)

    foreach ($match in $flows) {
        $flowName = $match.Groups[1].Value.Trim()
        $issues = @()

        # Extract flow block
        $startIdx = $match.Index
        $nextFlow = [regex]::Matches($FlowsText.Substring($startIdx + 1), $flowPattern) | Select-Object -First 1
        $endIdx = if ($nextFlow) { $startIdx + $nextFlow.Index + 1 } else { $FlowsText.Length }
        $flowBlock = $FlowsText.Substring($startIdx, $endIdx - $startIdx)

        # Check required fields
        if ($flowBlock -notmatch '(?i)(purpose|goal):\s*\S+') {
            $issues += "Missing Purpose/Goal"
        }
        if ($flowBlock -notmatch '(?i)(entry|trigger|start):\s*\S+') {
            $issues += "Missing Entry point"
        }
        if ($flowBlock -notmatch '(?i)(success|outcome|result):\s*\S+') {
            $issues += "Missing Success outcome"
        }
        if ($flowBlock -notmatch '(?i)(error|failure|exception)s?:\s*\S+') {
            $issues += "Missing Error handling"
        }

        # Check for single-word steps
        if ($flowBlock -match '(?i)(steps?|flow):\s*([^\n]+)') {
            $stepsLine = $matches[2]
            if ($stepsLine -match '^\w+$') {
                $issues += "Steps too vague (single word)"
            }
        }

        if ($issues.Count -gt 0) {
            $vagueFlows += [PSCustomObject]@{
                Name = $flowName
                Issues = $issues
            }
        }
    }

    return $vagueFlows
}

function Get-RouteContradictions {
    param([string]$SitemapText, [string]$FlowsText)

    $contradictions = @()

# PLACEHOLDER_SITEMAP
# PLACEHOLDER_SITEMAP
# PLACEHOLDER_SITEMAP

    # Check for duplicates
    $routeCounts = @{}
    foreach ($route in $routes) {
        if ($routeCounts.ContainsKey($route)) {
            $routeCounts[$route]++
        } else {
            $routeCounts[$route] = 1
        }
    }

    foreach ($route in $routeCounts.Keys) {
        if ($routeCounts[$route] -gt 1) {
            $contradictions += "Duplicate route: $route (appears $($routeCounts[$route]) times)"
        }
    }

    # Check for routes in flows but not sitemap
# PLACEHOLDER_FLOWS

    foreach ($flowRoute in $flowRoutes) {
        if ($routes -notcontains $flowRoute) {
            $contradictions += "Route $flowRoute referenced in flow but not in sitemap"
        }
    }

    return $contradictions
}

function Get-IAImpossibilities {
    param([string]$SitemapText, [string]$FlowsText, [string]$NavText)

    $impossibilities = @()

    # Detect circular flow dependencies
    $flowPattern = '(?im)^(?:###?\s+|(?:\d+\.\s*)?(?:Primary|Secondary|Tertiary)?\s*(?:Flow|Journey|Process):\s*)(.+?)$'
    $flows = [regex]::Matches($FlowsText, $flowPattern)

    $flowDeps = @{}
    foreach ($match in $flows) {
        $flowName = $match.Groups[1].Value.Trim()
        $startIdx = $match.Index
        $nextFlow = [regex]::Matches($FlowsText.Substring($startIdx + 1), $flowPattern) | Select-Object -First 1
        $endIdx = if ($nextFlow) { $startIdx + $nextFlow.Index + 1 } else { $FlowsText.Length }
        $flowBlock = $FlowsText.Substring($startIdx, $endIdx - $startIdx)

        # Find references to other flows
        $deps = @()
        foreach ($otherMatch in $flows) {
            $otherName = $otherMatch.Groups[1].Value.Trim()
            if ($otherName -ne $flowName -and $flowBlock -match [regex]::Escape($otherName)) {
                $deps += $otherName
            }
        }
        $flowDeps[$flowName] = $deps
    }

    # Detect cycles
    foreach ($flowName in $flowDeps.Keys) {
        foreach ($dep in $flowDeps[$flowName]) {
            if ($flowDeps.ContainsKey($dep) -and $flowDeps[$dep] -contains $flowName) {
                $impossibilities += "Circular flow dependency: '$flowName' <-> '$dep'"
            }
        }
    }

    # Detect orphaned routes (in sitemap but not in navigation)
    $routes = [regex]::Matches($SitemapText, '(?m)^\s*[-*]\s+(/[^\s]+)') | ForEach-Object { $_.Groups[1].Value }
    $navRoutes = [regex]::Matches($NavText, '/[A-Za-z0-9][A-Za-z0-9/_:\-]*') | ForEach-Object { $_.Value }

    foreach ($route in $routes) {
        if ($navRoutes -notcontains $route -and $route -notmatch '^/(login|signup|404|error|unauthorized)') {
            $impossibilities += "Orphaned route: $route (not in navigation, potentially unreachable)"
        }
    }

    return $impossibilities
}

function Get-IAImpliedDependencies {
    param([string]$SitemapText, [string]$FlowsText)

    $dependencies = @()

    # Protected routes without auth flow
    $protectedRoutes = @('/dashboard', '/settings', '/profile', '/account', '/admin')
    $hasAuthFlow = $FlowsText -match '(?i)(login|auth|sign\s*in|authentication)\s+(flow|journey|process)'

    foreach ($route in $protectedRoutes) {
        if ($SitemapText -match [regex]::Escape($route) -and -not $hasAuthFlow) {
            $dependencies += "Protected route $route exists but no authentication flow defined"
            break
        }
    }

    # Payment routes without payment flow
    if ($SitemapText -match '/(payment|billing|checkout|subscription)' -and
        $FlowsText -notmatch '(?i)(payment|checkout|billing)\s+(flow|journey|process)') {
        $dependencies += "Payment-related routes exist but no payment flow defined"
    }

    # Search routes without search infrastructure
    if ($SitemapText -match '/search' -and
        $FlowsText -notmatch '(?i)search\s+(flow|journey|process)') {
        $dependencies += "Search route exists but no search flow defined"
    }

    return $dependencies
}

function Get-IACompletenessIssues {
    param([string]$SitemapText, [string]$FlowsText, [string]$EntitiesText, [object]$IAModel)

    $issues = @()

    # Routes without entity mappings (if IAModel available)
    if ($IAModel -and $IAModel.PSObject.Properties.Name -contains 'entities_by_route') {
        $routes = [regex]::Matches($SitemapText, '(?m)^\s*[-*]\s+(/[^\s]+)') | ForEach-Object { $_.Groups[1].Value }

        foreach ($route in $routes) {
            if (-not $IAModel.entities_by_route.ContainsKey($route) -or
                $IAModel.entities_by_route[$route].Count -eq 0) {
                if ($route -notmatch '^/(login|signup|404|error|about|contact|help)') {
                    $issues += "Route $route has no entity mappings (where's the data?)"
                }
            }
        }
    }

    # Entities without any route references
    $entities = [regex]::Matches($EntitiesText, '(?im)^(?:[-*]\s+|###?\s+)([A-Z][A-Za-z]+)') | ForEach-Object { $_.Groups[1].Value }

    foreach ($entity in $entities) {
        if ($SitemapText -notmatch [regex]::Escape($entity) -and
            $FlowsText -notmatch [regex]::Escape($entity)) {
            $issues += "Entity '$entity' defined but not referenced in any route or flow"
        }
    }

    return $issues
}

function Get-IAQualityScore {
    <#
    .SYNOPSIS
    Calculates deterministic quality score from IA semantic analysis

    .DESCRIPTION
    Weighted severity scoring (0-100%):
    - Impossibilities: -10 each (critical)
    - Route Contradictions: -5 each (high)
    - Vague Flows: -3 each (medium)
    - Implied Dependencies: -2 each (low)
    - Completeness Issues: -2 each (low)

    .PARAMETER SemanticAnalysis
    Output from Get-IASemanticAnalysis

    .OUTPUTS
    Integer 0-100 representing quality score
    #>
    param([hashtable]$SemanticAnalysis)

    $severityScore = 0
    $severityScore += $SemanticAnalysis.impossibilities.Count * 10
    $severityScore += $SemanticAnalysis.route_contradictions.Count * 5
    $severityScore += $SemanticAnalysis.vague_flows.Count * 3
    $severityScore += $SemanticAnalysis.implied_dependencies.Count * 2
    $severityScore += $SemanticAnalysis.completeness_issues.Count * 2

    return [Math]::Max(0, 100 - $severityScore)
}

$isModuleContext = $false
try { if ($MyInvocation.MyCommand.Module) { $isModuleContext = $true } } catch { $isModuleContext = $false }
if ($isModuleContext) {
    Export-ModuleMember -Function Get-IASemanticAnalysis, Get-IAQualityScore
}
