<#
 .SYNOPSIS
     Change Analyzer for PRD and IA Evolution
 .DESCRIPTION
     Analyzes the impact of requested changes across PRD and IA
     Identifies affected routes, features, and potential conflicts
#>

. "$PSScriptRoot\state-manager.ps1"
. "$PSScriptRoot\ia-heuristic-parser.ps1"
. "$PSScriptRoot\prd-semantic-analyzer.ps1"

function Get-ChangeImpact {
    <#
    .SYNOPSIS
    Analyzes the impact of a requested change across PRD and IA

    .PARAMETER ProjectPath
    Path to project directory

    .PARAMETER UserRequest
    Plain English description of the change

    .PARAMETER CurrentState
    Current project state from .forge-model.json

    .OUTPUTS
    Hashtable containing impact analysis
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$true)]
        [string]$UserRequest,

        [Parameter(Mandatory=$true)]
        [hashtable]$CurrentState
    )

    $analysis = @{
        request = $UserRequest
        intent = $null
        prd_changes = @{}
        ia_changes = @{}
        affected_routes = @()
        affected_features = @()
        affected_flows = @()
        semantic_issues = @()
        confidence_impact = 0
        recommendations = @()
    }

    # Step 1: Parse user intent
    $intent = Get-ChangeIntent -Request $UserRequest
    $analysis.intent = $intent

    # Step 2: Determine PRD changes
    $prdChanges = Get-PRDChanges -Intent $intent -CurrentState $CurrentState -ProjectPath $ProjectPath
    $analysis.prd_changes = $prdChanges

    # Step 3: Determine IA changes
    $iaChanges = Get-IAChanges -Intent $intent -CurrentState $CurrentState -ProjectPath $ProjectPath
    $analysis.ia_changes = $iaChanges

    # Step 4: Identify affected areas
    $analysis.affected_routes = Get-AffectedRoutes -PRDChanges $prdChanges -IAChanges $iaChanges -CurrentState $CurrentState
    $analysis.affected_features = Get-AffectedFeatures -IAChanges $iaChanges -CurrentState $CurrentState
    $analysis.affected_flows = Get-AffectedFlows -IAChanges $iaChanges -CurrentState $CurrentState

    # Step 5: Detect semantic issues
    $analysis.semantic_issues = Get-ChangeSemanticIssues -PRDChanges $prdChanges -IAChanges $iaChanges -CurrentState $CurrentState

    # Step 6: Calculate confidence impact
    $analysis.confidence_impact = Get-ConfidenceImpact -PRDChanges $prdChanges -CurrentState $CurrentState

    # Step 7: Generate recommendations
    $analysis.recommendations = Get-ChangeRecommendations -Analysis $analysis

    return $analysis
}

function Get-ChangeIntent {
    param([string]$Request)

    $requestLower = $Request.ToLower()
    $intent = @{
        operation = 'add'  # add, modify, remove
        target = 'feature'  # feature, route, flow, component, entity
        entity_name = $null
        keywords = @()
        scope = 'SHOULD'  # MUST, SHOULD, COULD
    }

    # Detect operation
    if ($requestLower -match '\b(add|create|new|include)\b') {
        $intent.operation = 'add'
    }
    elseif ($requestLower -match '\b(modify|update|change|edit|refactor)\b') {
        $intent.operation = 'modify'
    }
    elseif ($requestLower -match '\b(remove|delete|drop)\b') {
        $intent.operation = 'remove'
    }

    # Detect target type
    if ($requestLower -match '\b(feature|functionality|capability)\b') {
        $intent.target = 'feature'
    }
    elseif ($requestLower -match '\b(route|page|screen|view)\b') {
        $intent.target = 'route'
    }
    elseif ($requestLower -match '\b(flow|journey|process)\b') {
        $intent.target = 'flow'
    }
    elseif ($requestLower -match '\b(component|widget|element)\b') {
        $intent.target = 'component'
    }
    elseif ($requestLower -match '\b(entity|model|data)\b') {
        $intent.target = 'entity'
    }

    # Detect scope
    if ($requestLower -match '\b(must|required|critical|essential)\b') {
        $intent.scope = 'MUST'
    }
    elseif ($requestLower -match '\b(could|nice[- ]to[- ]have|optional)\b') {
        $intent.scope = 'COULD'
    }

    # Extract entity name (capitalize first letter of each word)
    if ($Request -match '\b(?:add|create|new)\s+(?:a\s+)?["\'']?([A-Z][a-zA-Z0-9\s]+?)["\'']?\s+(?:feature|route|flow|component|entity)') {
        $intent.entity_name = $matches[1].Trim()
    }
    elseif ($Request -match '["\'']([A-Z][a-zA-Z0-9\s]+?)["\'']') {
        $intent.entity_name = $matches[1].Trim()
    }
    elseif ($Request -match '\b([A-Z][a-zA-Z0-9]+(?:\s+[A-Z][a-zA-Z0-9]+)?)\b') {
        $intent.entity_name = $matches[1].Trim()
    }

    # Extract keywords for context
    $words = $Request -split '\s+' | Where-Object { $_.Length -gt 3 -and $_ -notmatch '^(the|and|for|with|that|this|from|into)$' }
    $intent.keywords = @($words | Select-Object -First 10)

    return $intent
}

function Get-PRDChanges {
    param(
        [hashtable]$Intent,
        [hashtable]$CurrentState,
        [string]$ProjectPath
    )

    $changes = @{
        features_add = @()
        features_modify = @()
        features_remove = @()
        scope_add = @()
        nfr_add = @()
        kpis_add = @()
        user_stories_add = @()
    }

    if ($Intent.operation -eq 'add' -and $Intent.target -eq 'feature') {
        $feature = @{
            name = $Intent.entity_name
            description = "New feature: $($Intent.entity_name)"
            scope = $Intent.scope
            acceptance_criteria = @()
            user_stories = @()
        }

        # Infer description from keywords
        if ($Intent.keywords.Count -gt 0) {
            $feature.description = "$($Intent.entity_name) enables $($Intent.keywords -join ' ')"
        }

        $changes.features_add += $feature

        # Add to scope
        $changes.scope_add += @{
            name = $Intent.entity_name
            scope = $Intent.scope
            description = $feature.description
        }

        # Generate default user story
        $changes.user_stories_add += @{
            story = "As a user, I want to use $($Intent.entity_name) so that I can improve my workflow"
        }
    }

    if ($Intent.operation -eq 'modify' -and $Intent.target -eq 'feature') {
        # Find existing feature in current state
        if ($CurrentState.prd_model -and $CurrentState.prd_model.features) {
            $existingFeature = $CurrentState.prd_model.features | Where-Object { $_.name -eq $Intent.entity_name } | Select-Object -First 1
            if ($existingFeature) {
                $changes.features_modify += @{
                    name = $Intent.entity_name
                    description = "Modified: $($Intent.entity_name)"
                    scope = $existingFeature.scope
                }
            }
        }
    }

    if ($Intent.operation -eq 'remove' -and $Intent.target -eq 'feature') {
        $changes.features_remove += @{
            name = $Intent.entity_name
        }
    }

    # Check if NFRs or KPIs are implied
    $requestLower = $Intent.keywords -join ' '
    if ($requestLower -match '\b(performance|speed|fast|latency|response)\b') {
        $changes.nfr_add += @{
            category = 'Performance'
            requirement = "$($Intent.entity_name) should have optimal performance with <200ms response time"
        }
    }

    if ($requestLower -match '\b(security|auth|permission|access)\b') {
        $changes.nfr_add += @{
            category = 'Security'
            requirement = "$($Intent.entity_name) should implement proper authentication and authorization"
        }
    }

    return $changes
}

function Get-IAChanges {
    param(
        [hashtable]$Intent,
        [hashtable]$CurrentState,
        [string]$ProjectPath
    )

    $changes = @{
        routes_add = @()
        routes_modify = @()
        routes_remove = @()
        modals_add = @()
        flows_add = @()
        flows_modify = @()
        components_add = @()
        entities_add = @()
    }

    if ($Intent.operation -eq 'add') {
        # Generate route from entity name
        if ($Intent.entity_name) {
            $routeName = '/' + ($Intent.entity_name.ToLower() -replace '\s+', '-')

            if ($Intent.target -eq 'feature' -or $Intent.target -eq 'route') {
                $changes.routes_add += @{
                    route = $routeName
                    description = $Intent.entity_name
                }

                # Generate default flow
                $entryRoute = '/dashboard'
                if ($CurrentState.ia_model -and $CurrentState.ia_model.routes -and $CurrentState.ia_model.routes.Count -gt 0) {
                    $entryRoute = $CurrentState.ia_model.routes[0]
                }

                $changes.flows_add += @{
                    name = "Access $($Intent.entity_name)"
                    purpose = "Navigate to $($Intent.entity_name)"
                    entry = $entryRoute
                    steps = @($entryRoute, $routeName)
                    success = "$($Intent.entity_name) loaded successfully"
                    errors = @("Navigation failed", "Unauthorized access")
                }

                # Generate default components
                $componentPrefix = ($Intent.entity_name -replace '\s+', '')
                $changes.components_add += @{
                    route = $routeName
                    components = @(
                        "${componentPrefix}Header",
                        "${componentPrefix}Content",
                        "${componentPrefix}Actions"
                    )
                }

                # Generate entity if data-related keywords present
                $keywordsText = ($Intent.keywords -join ' ').ToLower()
                if ($keywordsText -match '\b(data|list|collection|record|item|entry|store|save)\b') {
                    $changes.entities_add += @{
                        name = $Intent.entity_name -replace '\s+', ''
                        fields = @('id', 'name', 'createdAt', 'updatedAt')
                    }
                }
            }
        }
    }

    return $changes
}

function Get-AffectedRoutes {
    param(
        [hashtable]$PRDChanges,
        [hashtable]$IAChanges,
        [hashtable]$CurrentState
    )

    $routes = @()

    # Routes from IA changes
    if ($IAChanges.routes_add) {
        $routes += $IAChanges.routes_add | ForEach-Object { $_.route }
    }

    # Routes linked to modified features
    if ($PRDChanges.features_modify -and $CurrentState.project_model -and $CurrentState.project_model.feature_to_routes) {
        foreach ($feature in $PRDChanges.features_modify) {
            if ($CurrentState.project_model.feature_to_routes.ContainsKey($feature.name)) {
                $routes += $CurrentState.project_model.feature_to_routes[$feature.name]
            }
        }
    }

    return ($routes | Select-Object -Unique)
}

function Get-AffectedFeatures {
    param(
        [hashtable]$IAChanges,
        [hashtable]$CurrentState
    )

    $features = @()

    # Features linked to modified routes
    if ($IAChanges.routes_modify -and $CurrentState.project_model -and $CurrentState.project_model.route_to_features) {
        foreach ($route in $IAChanges.routes_modify) {
            if ($CurrentState.project_model.route_to_features.ContainsKey($route.route)) {
                $features += $CurrentState.project_model.route_to_features[$route.route]
            }
        }
    }

    return ($features | Select-Object -Unique)
}

function Get-AffectedFlows {
    param(
        [hashtable]$IAChanges,
        [hashtable]$CurrentState
    )

    $flows = @()

    # Flows containing modified routes
    if ($IAChanges.routes_modify -and $CurrentState.ia_model -and $CurrentState.ia_model.flows) {
        foreach ($route in $IAChanges.routes_modify) {
            foreach ($flow in $CurrentState.ia_model.flows) {
                if ($flow.steps -and ($flow.steps -contains $route.route)) {
                    $flows += $flow.name
                }
            }
        }
    }

    return ($flows | Select-Object -Unique)
}

function Get-ChangeSemanticIssues {
    param(
        [hashtable]$PRDChanges,
        [hashtable]$IAChanges,
        [hashtable]$CurrentState
    )

    $issues = @()

    # Check for duplicate features
    if ($PRDChanges.features_add -and $CurrentState.prd_model -and $CurrentState.prd_model.features) {
        foreach ($newFeature in $PRDChanges.features_add) {
            $existing = $CurrentState.prd_model.features | Where-Object { $_.name -eq $newFeature.name }
            if ($existing) {
                $issues += "Feature '$($newFeature.name)' already exists in PRD"
            }
        }
    }

    # Check for duplicate routes
    if ($IAChanges.routes_add -and $CurrentState.ia_model -and $CurrentState.ia_model.routes) {
        foreach ($newRoute in $IAChanges.routes_add) {
            if ($CurrentState.ia_model.routes -contains $newRoute.route) {
                $issues += "Route '$($newRoute.route)' already exists in IA"
            }
        }
    }

    # Check for orphaned routes (routes without features)
    if ($IAChanges.routes_add -and $PRDChanges.features_add.Count -eq 0) {
        foreach ($newRoute in $IAChanges.routes_add) {
            $issues += "Route '$($newRoute.route)' added without corresponding feature"
        }
    }

    # Check for missing routes (features without routes)
    if ($PRDChanges.features_add -and $IAChanges.routes_add.Count -eq 0) {
        foreach ($newFeature in $PRDChanges.features_add) {
            $issues += "Feature '$($newFeature.name)' added without corresponding route"
        }
    }

    return $issues
}

function Get-ConfidenceImpact {
    param(
        [hashtable]$PRDChanges,
        [hashtable]$CurrentState
    )

    $impact = 0.0

    # Adding features improves feature_list completeness
    if ($PRDChanges.features_add -and $PRDChanges.features_add.Count -gt 0) {
        $impact += 2.0 * $PRDChanges.features_add.Count
    }

    # Adding NFRs improves non_functional completeness
    if ($PRDChanges.nfr_add -and $PRDChanges.nfr_add.Count -gt 0) {
        $impact += 1.5 * $PRDChanges.nfr_add.Count
    }

    # Adding KPIs improves success_metrics completeness
    if ($PRDChanges.kpis_add -and $PRDChanges.kpis_add.Count -gt 0) {
        $impact += 1.0 * $PRDChanges.kpis_add.Count
    }

    # Adding user stories improves user_stories completeness
    if ($PRDChanges.user_stories_add -and $PRDChanges.user_stories_add.Count -gt 0) {
        $impact += 0.5 * $PRDChanges.user_stories_add.Count
    }

    # Removing features may decrease confidence
    if ($PRDChanges.features_remove -and $PRDChanges.features_remove.Count -gt 0) {
        $impact -= 1.0 * $PRDChanges.features_remove.Count
    }

    # Cap impact
    if ($impact -gt 10) { $impact = 10 }
    if ($impact -lt -10) { $impact = -10 }

    return [math]::Round($impact, 2)
}

function Get-ChangeRecommendations {
    param([hashtable]$Analysis)

    $recommendations = @()

    # Recommend adding acceptance criteria
    if ($Analysis.prd_changes.features_add) {
        foreach ($feature in $Analysis.prd_changes.features_add) {
            if (-not $feature.acceptance_criteria -or $feature.acceptance_criteria.Count -eq 0) {
                $recommendations += "Add acceptance criteria for feature '$($feature.name)'"
            }
        }
    }

    # Recommend linking features to routes
    if ($Analysis.semantic_issues -contains "Feature added without corresponding route") {
        $recommendations += "Consider adding routes for new features to improve IA completeness"
    }

    # Recommend adding flows for new routes
    if ($Analysis.ia_changes.routes_add -and $Analysis.ia_changes.flows_add.Count -eq 0) {
        $recommendations += "Consider adding user flows for new routes"
    }

    # Recommend NFRs for critical features
    if ($Analysis.intent.scope -eq 'MUST' -and $Analysis.prd_changes.nfr_add.Count -eq 0) {
        $recommendations += "Consider adding non-functional requirements for critical features"
    }

    return $recommendations
}
