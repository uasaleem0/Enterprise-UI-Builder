#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Display the parsed IA model with all extracted semantic data

.DESCRIPTION
    Shows a formatted diagnostic view of how the system has parsed and understood your IA files,
    including routes, flows, entities, navigation, and extraction quality analysis.

.PARAMETER ProjectPath
    Path to the project directory containing .forge-prd-state.json

.EXAMPLE
    forge show-ia
    forge show-ia -ProjectPath ./my-project
#>

param(
    [string]$ProjectPath = '.'
)

. "$PSScriptRoot/../lib/state-manager.ps1"

function Format-Timestamp {
    param([string]$IsoTimestamp)
    if (-not $IsoTimestamp) { return 'N/A' }
    try {
        return [DateTime]::Parse($IsoTimestamp).ToString('yyyy-MM-dd HH:mm:ss')
    } catch {
        return $IsoTimestamp
    }
}

function Format-Hash {
    param([string]$Hash)
    if (-not $Hash) { return 'N/A' }
    if ($Hash.Length -gt 12) {
        return $Hash.Substring(0, 12) + '...'
    }
    return $Hash
}

# Load state
$ProjectPath = Resolve-Path $ProjectPath
$state = Get-ProjectState -ProjectPath $ProjectPath

if (-not $state.ia_model) {
    Write-Host "No IA model found. Run 'forge import-ia' first." -ForegroundColor Yellow
    return
}

# Extract metadata
$timestamp = if ($state.ia_model.extraction_timestamp) {
    Format-Timestamp $state.ia_model.extraction_timestamp
} else { 'N/A' }

$hash = if ($state.project_model -and $state.project_model.meta -and $state.project_model.meta.ia_hash) {
    Format-Hash $state.project_model.meta.ia_hash
} else { 'N/A' }

$extractionMethod = if ($state.ia_model.extraction_method) {
    $state.ia_model.extraction_method
} else { 'Unknown' }

$ia = $state.ia_model

# Count extracted items
$routeCount = if ($ia.routes) { $ia.routes.Count } else { 0 }
$modalCount = if ($ia.modals) { $ia.modals.Count } else { 0 }
$flowCount = if ($ia.flows) { $ia.flows.Count } else { 0 }
$navCount = if ($ia.primary_nav) { $ia.primary_nav.Count } else { 0 }
$componentCount = 0
if ($ia.components_by_route) {
    foreach ($key in $ia.components_by_route.Keys) {
        $componentCount += $ia.components_by_route[$key].Count
    }
}

# Count unique entities
$uniqueEntities = @{}
if ($ia.entities_by_route) {
    foreach ($key in $ia.entities_by_route.Keys) {
        foreach ($entity in $ia.entities_by_route[$key]) {
            $uniqueEntities[$entity] = $true
        }
    }
}
$entityCount = $uniqueEntities.Count

# Header
Write-Host ""
Write-Host "IA Model View" -ForegroundColor Cyan
Write-Host ("=" * 70)
Write-Host "Extraction Method: " -NoNewline
if ($extractionMethod -eq 'AI') {
    Write-Host $extractionMethod -ForegroundColor Green
} else {
    Write-Host $extractionMethod -ForegroundColor Yellow
}
Write-Host "Last Parsed:       $timestamp"

# Show Confidence & Quality
$iaConfidence = if ($state.ia_confidence) { $state.ia_confidence } else { 0 }
$iaQuality = if ($state.ia_quality) { $state.ia_quality } else { 0 }

Write-Host ""
Write-Host "Confidence:        " -NoNewline
$confColor = if ($iaConfidence -ge 90) { "Green" } elseif ($iaConfidence -ge 75) { "Yellow" } else { "Red" }
Write-Host "$iaConfidence% (Completeness)" -ForegroundColor $confColor

Write-Host "Quality:           " -NoNewline
$qualColor = if ($iaQuality -ge 85) { "Green" } elseif ($iaQuality -ge 70) { "Yellow" } else { "Red" }
Write-Host "$iaQuality% (Semantic Issues)" -ForegroundColor $qualColor
Write-Host "Source Hash:       $hash"
Write-Host ""

# Extraction Summary
Write-Host ("-" * 70)
Write-Host "EXTRACTION SUMMARY" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Routes Extracted:        $routeCount"
Write-Host "  Modals Extracted:        $modalCount"
Write-Host "  Flows Extracted:         $flowCount"
Write-Host "  Entities Extracted:      $entityCount"
if ($componentCount -gt 0) {
    Write-Host "  Components Extracted:    $componentCount"
} else {
    Write-Host "  Components Extracted:    " -NoNewline
    Write-Host "0  " -NoNewline -ForegroundColor Gray
    Write-Host "[Not extracted - design phase data]" -ForegroundColor Gray
}
Write-Host "  Primary Nav Extracted:   $navCount"
Write-Host ""

# Routes Section
Write-Host ("-" * 70)
Write-Host "ROUTES " -NoNewline -ForegroundColor Cyan
Write-Host "($routeCount Extracted)"
Write-Host ""

if ($ia.routes -and $ia.routes.Count -gt 0) {
    foreach ($route in $ia.routes) {
        Write-Host "  $route" -ForegroundColor White

        # Purpose
        $purpose = 'N/A'
        if ($ia.purpose_map -and $ia.purpose_map.ContainsKey($route)) {
            $purpose = $ia.purpose_map[$route]
        }
        Write-Host "    [Purpose]    " -NoNewline -ForegroundColor Gray
        Write-Host $purpose

        # Entities
        $entities = @()
        if ($ia.entities_by_route -and $ia.entities_by_route.ContainsKey($route)) {
            $entities = @($ia.entities_by_route[$route])
        }
        Write-Host "    [Entities]   " -NoNewline -ForegroundColor Gray
        if ($entities.Count -gt 0) {
            Write-Host ($entities -join ', ')
        } else {
            Write-Host "(None mapped)" -ForegroundColor Gray
        }

        # Components (if any)
        $components = @()
        if ($ia.components_by_route -and $ia.components_by_route.ContainsKey($route)) {
            $components = @($ia.components_by_route[$route])
        }
        if ($components.Count -gt 0) {
            Write-Host "    [Components] " -NoNewline -ForegroundColor Gray
            Write-Host ($components -join ', ')
        }

        Write-Host ""
    }
} else {
    Write-Host "  No routes extracted" -ForegroundColor Red
    Write-Host ""
}

# Modals / Non-Routed UI
Write-Host ("-" * 70)
Write-Host "MODALS / NON-ROUTED UI " -NoNewline -ForegroundColor Cyan
Write-Host "($modalCount Extracted)"
Write-Host ""

if ($ia.modals -and $ia.modals.Count -gt 0) {
    foreach ($modal in $ia.modals) {
        Write-Host "  - $modal"
    }
    Write-Host ""
} else {
    Write-Host "  No modals extracted" -ForegroundColor Gray
    Write-Host ""
}

# Out of Scope
$oosCount = if ($ia.out_of_scope) { $ia.out_of_scope.Count } else { 0 }
Write-Host ("-" * 70)
Write-Host "OUT OF SCOPE " -NoNewline -ForegroundColor Cyan
Write-Host "($oosCount Items)"
Write-Host ""

if ($ia.out_of_scope -and $ia.out_of_scope.Count -gt 0) {
    foreach ($oos in $ia.out_of_scope) {
        Write-Host "  - $oos"
    }
    Write-Host ""
} else {
    Write-Host "  No out-of-scope items defined" -ForegroundColor Gray
    Write-Host ""
}

# Navigation Structure
Write-Host ("-" * 70)
Write-Host "NAVIGATION STRUCTURE " -NoNewline -ForegroundColor Cyan
Write-Host "($navCount Items)"
Write-Host ""

if ($ia.primary_nav -and $ia.primary_nav.Count -gt 0) {
    foreach ($navItem in $ia.primary_nav) {
        # Nav items might be strings or objects
        if ($navItem -is [string]) {
            Write-Host "  - $navItem"
        } else {
            Write-Host "  - $navItem"
        }
    }
    Write-Host ""
} else {
    Write-Host "  No primary navigation defined" -ForegroundColor Yellow
    Write-Host ""
}

# User Flows
Write-Host ("-" * 70)
Write-Host "USER FLOWS " -NoNewline -ForegroundColor Cyan
Write-Host "($flowCount Extracted)"
Write-Host ""

if ($ia.flows -and $ia.flows.Count -gt 0) {
    foreach ($flow in $ia.flows) {
        Write-Host "  ### FLOW: " -NoNewline -ForegroundColor White
        Write-Host $flow.name -ForegroundColor Cyan

        # Extraction method for this flow (if available)
        if ($extractionMethod -eq 'AI') {
            Write-Host "  [Extraction]  " -NoNewline -ForegroundColor Gray
            Write-Host "AI-generated" -ForegroundColor Green
        } else {
            Write-Host "  [Extraction]  " -NoNewline -ForegroundColor Gray
            Write-Host "Parsed from flows.md" -ForegroundColor Yellow
        }

        # Purpose/Goal
        $flowPurpose = if ($flow.purpose) { $flow.purpose } elseif ($flow.goal) { $flow.goal } else { 'N/A' }
        Write-Host "  [Purpose]     " -NoNewline -ForegroundColor Gray
        Write-Host $flowPurpose

        # Entry point
        $entry = if ($flow.entry) { $flow.entry } else { 'N/A' }
        Write-Host "  [Entry]       " -NoNewline -ForegroundColor Gray
        Write-Host $entry

        # Steps
        if ($flow.steps -and $flow.steps.Count -gt 0) {
            $stepsList = $flow.steps -join ' → '
            Write-Host "  [Steps]       " -NoNewline -ForegroundColor Gray
            Write-Host $stepsList
        }

        # Success criteria
        $success = if ($flow.success) { $flow.success } else { 'Not defined' }
        Write-Host "  [Success]     " -NoNewline -ForegroundColor Gray
        if ($success -eq 'Not defined') {
            Write-Host $success -ForegroundColor Yellow
        } else {
            Write-Host $success
        }

        # Errors
        if ($flow.errors -and $flow.errors.Count -gt 0) {
            Write-Host "  [Errors]      " -NoNewline -ForegroundColor Gray
            Write-Host ($flow.errors -join ', ')
        } else {
            Write-Host "  [Errors]      " -NoNewline -ForegroundColor Gray
            Write-Host "None defined" -ForegroundColor Yellow
        }

        Write-Host ""
    }
} else {
    Write-Host "  No user flows extracted" -ForegroundColor Red
    Write-Host ""
}

# Data Entities
Write-Host ("-" * 70)
Write-Host "DATA ENTITIES " -NoNewline -ForegroundColor Cyan
Write-Host "($entityCount Found)"
Write-Host ""

if ($uniqueEntities.Count -gt 0) {
    foreach ($entityName in ($uniqueEntities.Keys | Sort-Object)) {
        Write-Host "  $entityName" -ForegroundColor White

        # Find which routes use this entity
        $usedOnRoutes = @()
        if ($ia.entities_by_route) {
            foreach ($route in $ia.entities_by_route.Keys) {
                if ($ia.entities_by_route[$route] -contains $entityName) {
                    $usedOnRoutes += $route
                }
            }
        }

        Write-Host "    [Used On]  " -NoNewline -ForegroundColor Gray
        if ($usedOnRoutes.Count -gt 0) {
            Write-Host ($usedOnRoutes -join ', ')
        } else {
            Write-Host "(Not mapped to any route)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
} else {
    Write-Host "  No entities extracted" -ForegroundColor Red
    Write-Host ""
}

# Route Purposes (Quick Reference)
Write-Host ("-" * 70)
Write-Host "ROUTE PURPOSES (Quick Reference)" -ForegroundColor Cyan
Write-Host ""

if ($ia.routes -and $ia.routes.Count -gt 0 -and $ia.purpose_map) {
    foreach ($route in $ia.routes) {
        $purpose = if ($ia.purpose_map.ContainsKey($route)) { $ia.purpose_map[$route] } else { 'N/A' }
        $maxRouteLen = 25
        $paddedRoute = $route.PadRight($maxRouteLen)
        Write-Host "  $paddedRoute → " -NoNewline
        Write-Host $purpose
    }
    Write-Host ""
} else {
    Write-Host "  No route purposes defined" -ForegroundColor Gray
    Write-Host ""
}

# Extraction Quality Analysis
Write-Host ("-" * 70)
Write-Host "EXTRACTION QUALITY ANALYSIS" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$checks = @()

# Check: All routes have purposes
$routesWithPurpose = 0
if ($ia.routes -and $ia.purpose_map) {
    foreach ($route in $ia.routes) {
        if ($ia.purpose_map.ContainsKey($route) -and $ia.purpose_map[$route]) {
            $routesWithPurpose++
        }
    }
}
if ($routesWithPurpose -eq $routeCount) {
    $checks += @{ status = 'pass'; message = "All routes have purpose descriptions" }
} else {
    $checks += @{ status = 'warn'; message = "$($routeCount - $routesWithPurpose) routes missing purpose descriptions" }
}

# Check: All routes have entity mappings
$routesWithEntities = 0
if ($ia.routes -and $ia.entities_by_route) {
    foreach ($route in $ia.routes) {
        if ($ia.entities_by_route.ContainsKey($route) -and $ia.entities_by_route[$route].Count -gt 0) {
            $routesWithEntities++
        }
    }
}
if ($routesWithEntities -eq $routeCount) {
    $checks += @{ status = 'pass'; message = "All routes have entity mappings" }
} else {
    $checks += @{ status = 'warn'; message = "$($routeCount - $routesWithEntities) routes missing entity mappings" }
}

# Check: Components
if ($componentCount -eq 0) {
    $checks += @{ status = 'info'; message = "0 routes have component mappings (Expected - not in IA scope)" }
} else {
    $checks += @{ status = 'info'; message = "$componentCount components mapped (Implementation detail)" }
}

# Check: User flows defined
if ($flowCount -gt 0) {
    $checks += @{ status = 'pass'; message = "$flowCount user flows defined" }

    # Check flow completeness
    $flowsWithErrors = 0
    if ($ia.flows) {
        foreach ($flow in $ia.flows) {
            if ($flow.errors -and $flow.errors.Count -gt 0) {
                $flowsWithErrors++
            }
        }
    }
    if ($flowsWithErrors -eq $flowCount) {
        $checks += @{ status = 'pass'; message = "All flows have error states defined" }
    } else {
        $checks += @{ status = 'warn'; message = "$($flowCount - $flowsWithErrors) flows missing error states" }
    }
} else {
    $checks += @{ status = 'error'; message = "No user flows defined" }
}

# Check: Navigation coverage
if ($navCount -gt 0) {
    if ($navCount -eq $routeCount) {
        $checks += @{ status = 'pass'; message = "Navigation covers all routes" }
    } elseif ($navCount -lt $routeCount) {
        $diff = $routeCount - $navCount
        $checks += @{ status = 'warn'; message = "Navigation has $navCount items but $routeCount routes ($diff routes not in nav)" }
    } else {
        $checks += @{ status = 'info'; message = "Navigation has more items than routes (may include external links)" }
    }
} else {
    $checks += @{ status = 'warn'; message = "No primary navigation defined" }
}

# Check: Unused entities
$unusedEntities = @()
foreach ($entityName in $uniqueEntities.Keys) {
    $usedOnRoutes = @()
    if ($ia.entities_by_route) {
        foreach ($route in $ia.entities_by_route.Keys) {
            if ($ia.entities_by_route[$route] -contains $entityName) {
                $usedOnRoutes += $route
            }
        }
    }
    if ($usedOnRoutes.Count -le 1) {
        $unusedEntities += $entityName
    }
}
if ($unusedEntities.Count -gt 0) {
    $checks += @{ status = 'warn'; message = "$($unusedEntities.Count) entities used on only 1 route or less" }
}

# Display checks
foreach ($check in $checks) {
    switch ($check.status) {
        'pass' {
            Write-Host "  [" -NoNewline
            Write-Host "✓" -NoNewline -ForegroundColor Green
            Write-Host "] $($check.message)"
        }
        'warn' {
            Write-Host "  [" -NoNewline
            Write-Host "!" -NoNewline -ForegroundColor Yellow
            Write-Host "] $($check.message)"
        }
        'error' {
            Write-Host "  [" -NoNewline
            Write-Host "✗" -NoNewline -ForegroundColor Red
            Write-Host "] $($check.message)"
        }
        'info' {
            Write-Host "  [" -NoNewline
            Write-Host "i" -NoNewline -ForegroundColor Cyan
            Write-Host "] $($check.message)"
        }
    }
}

Write-Host ""

# Missing or Incomplete Data section
$missingItems = @()

# Check for route parameters not documented
$routesWithParams = @($ia.routes | Where-Object { $_ -match ':' })
if ($routesWithParams.Count -gt 0) {
    $missingItems += "Route parameters present ($($routesWithParams.Count) routes) but not documented"
}

# Check for flows with minimal error states
if ($ia.flows) {
    $sparseFlows = @($ia.flows | Where-Object { -not $_.errors -or $_.errors.Count -lt 2 })
    if ($sparseFlows.Count -gt 0) {
        foreach ($flow in $sparseFlows) {
            $errorCount = if ($flow.errors) { $flow.errors.Count } else { 0 }
            $missingItems += "Flow '$($flow.name)' has $errorCount error states (consider adding more)"
        }
    }
}

if ($missingItems.Count -gt 0) {
    Write-Host "Missing or Incomplete Data:" -ForegroundColor Yellow
    foreach ($item in $missingItems) {
        Write-Host "  - $item" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host ("=" * 70)

# Semantic Analysis Section
if ($state.ia_semantic_analysis) {
    Write-Host ""
    Write-Host "Semantic Analysis" -ForegroundColor Cyan
    Write-Host ("=" * 70)

    $sem = $state.ia_semantic_analysis
    $totalIssues = $sem.vague_flows.Count + $sem.route_contradictions.Count +
                   $sem.impossibilities.Count + $sem.implied_dependencies.Count +
                   $sem.completeness_issues.Count

    if ($totalIssues -eq 0) {
        Write-Host "[OK] No semantic issues detected!" -ForegroundColor Green
    } else {
        Write-Host "Total Issues: $totalIssues" -ForegroundColor Yellow
        Write-Host ""

        # Vague Flows
        if ($sem.vague_flows.Count -gt 0) {
            Write-Host "[!] Vague Flows ($($sem.vague_flows.Count)):" -ForegroundColor Yellow
            foreach ($flow in $sem.vague_flows) {
                Write-Host "  - $($flow.Name)" -ForegroundColor Yellow
                foreach ($issue in $flow.Issues) {
                    Write-Host "      * $issue" -ForegroundColor Gray
                }
            }
            Write-Host ""
        }

        # Route Contradictions
        if ($sem.route_contradictions.Count -gt 0) {
            Write-Host "[X] Route Contradictions ($($sem.route_contradictions.Count)):" -ForegroundColor Red
            foreach ($c in $sem.route_contradictions) {
                Write-Host "  - $c" -ForegroundColor Red
            }
            Write-Host ""
        }

        # Impossibilities
        if ($sem.impossibilities.Count -gt 0) {
            Write-Host "[X] Impossibilities ($($sem.impossibilities.Count)):" -ForegroundColor Red
            foreach ($i in $sem.impossibilities) {
                Write-Host "  - $i" -ForegroundColor Red
            }
            Write-Host ""
        }

        # Implied Dependencies
        if ($sem.implied_dependencies.Count -gt 0) {
            Write-Host "[i] Implied Dependencies ($($sem.implied_dependencies.Count)):" -ForegroundColor Cyan
            foreach ($d in $sem.implied_dependencies) {
                Write-Host "  - $d" -ForegroundColor Cyan
            }
            Write-Host ""
        }

        # Completeness Issues
        if ($sem.completeness_issues.Count -gt 0) {
            Write-Host "[?] Completeness Issues ($($sem.completeness_issues.Count)):" -ForegroundColor Yellow
            foreach ($c in $sem.completeness_issues) {
                Write-Host "  - $c" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }

    Write-Host ("=" * 70)
}

Write-Host ""
