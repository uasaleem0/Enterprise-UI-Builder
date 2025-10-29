<#
 .SYNOPSIS
     Confidence Scorer - Pattern-Based PRD Completeness Measurement
 .DESCRIPTION
     PURPOSE: Calculate 0-100% deliverable completion for PRD.
     METHOD: Pattern matching against rules; NOT semantic understanding.
     USED BY: forge-import-prd, forge-prd-report
     NOT USED FOR: Semantic model building (see semantic-model-builder.ps1)
#>
# Forge Semantic Validator
# Validates PRD content semantically based on required elements

function Normalize-Text {
    param([string]$Text)

    if (-not $Text) { return $Text }

    $t = $Text
    # Normalize newlines
    $t = $t -replace "\r\n?", "`n"
    # Replace smart quotes/dashes
    $t = $t -replace "[\u2018\u2019]", "'"
    $t = $t -replace "[\u201C\u201D]", '"'
    $t = $t -replace "[\u2013\u2014]", "-"
    # Remove replacement chars
    $t = $t -replace "\uFFFD", ""
    # Fix common corrupted percent artifacts
    $t = $t -replace "\s*�%�\s*", "%"
    $t = $t -replace "\s*�\s*", ""
    return $t
}

function Get-SemanticRules {
    $rulesPath = "$PSScriptRoot\..\core\validation\semantic-rules.json"
    $rules = Get-Content $rulesPath | ConvertFrom-Json
    return $rules
}

function Measure-SemanticSection {
    param(
        [string]$SectionContent,
        [object]$Rules
    )

    # Mild normalization: preserve whitespace; avoid collapsing that breaks patterns
    $SectionContent = $SectionContent -replace "\r\n?", "`n"
    $SectionContent = $SectionContent -replace "[\u2018\u2019]", "'"
    $SectionContent = $SectionContent -replace "[\u201C\u201D]", '"'
    $SectionContent = $SectionContent -replace "[\u2013\u2014]", "-"
    $score = 0
    $maxScore = 0
    $details = @()

    foreach ($element in $Rules.required_elements) {
        $maxScore += $element.points

        if ($element.type -eq "count") {
            # Count matches across all patterns
            $totalMatches = 0
            foreach ($pattern in $element.patterns) {
                $matches = [regex]::Matches($SectionContent, "(?i)$pattern")
                $totalMatches += $matches.Count
            }

            switch ($element.id) {
                'acceptance_criteria' {
                    $checkbox = ([regex]::Matches($SectionContent, '(?im)^\s*[-*]\s*\[[ xX]\]')).Count
                    $musts = ([regex]::Matches($SectionContent, '(?im)^\s*[-*]\s+(must|should|shall)\b')).Count
                    $gherkin = ([regex]::Matches($SectionContent, '(?im)^\s*(Given|When|Then)\b')).Count
                    $totalMatches += ($checkbox + $musts + $gherkin)
                }
                'story_count' {
                    $stories = ([regex]::Matches($SectionContent, '(?im)^\s*[-*]?\s*As\s+a\s+.+?\s+I\s+want\s+.+?\s+so\s+that\s+.+$')).Count
                    if ($stories -gt $totalMatches) { $totalMatches = $stories }
                }
                'measurable' {
                    $pct = ([regex]::Matches($SectionContent, '(?i)\b\d+\s*%')).Count
                    $words = ([regex]::Matches($SectionContent, '(?i)\b\d+\s*(percent|percentage)\b')).Count
                    $numbers = ([regex]::Matches($SectionContent, '(?i)\b\$?\d+\b')).Count
                    $totalMatches += ($pct + $words)
                    if ($numbers -gt 0) { $totalMatches += [Math]::Min(2, [int]($numbers/3)) }
                }
                'kpi_count' {
                    $tableRows = ([regex]::Matches($SectionContent, '(?m)^\|')).Count
                    $bullets = ([regex]::Matches($SectionContent, '(?m)^\s*[-*]\s+')).Count
                    if ($tableRows -gt 2) { $totalMatches = [Math]::Max($totalMatches, $tableRows - 2) }
                    if ($bullets -gt $totalMatches) { $totalMatches = $bullets }
                }
                default { }
            }

            if ($totalMatches -ge $element.minimum) {
                $score += $element.points
                $details += @{
                    element = $element.id
                    status = "PASS"
                    found = $totalMatches
                    required = $element.minimum
                }
            } else {
                $details += @{
                    element = $element.id
                    status = "FAIL"
                    found = $totalMatches
                    required = $element.minimum
                }
            }
        } else {
            # Check if any pattern matches
            $found = $false
            foreach ($pattern in $element.patterns) {
                if ($SectionContent -match "(?i)$pattern") {
                    $found = $true
                    break
                }
            }

            if (-not $found) {
                switch ($element.id) {
                    'demographics' {
                        $age = ($SectionContent -match '(?i)\b\d{2}\s*[-–]\s*\d{2}\b|\byears?\s+old\b')
                        $role = ($SectionContent -match '(?i)\b(role|title|engineer|manager|designer|student|professional)\b')
                        if ($age -and $role) { $found = $true }
                    }
                    default { }
                }
            }
            if ($found) {
                $score += $element.points
                $details += @{
                    element = $element.id
                    status = "PASS"
                }
            } else {
                $details += @{
                    element = $element.id
                    status = "FAIL"
                }
            }
        }
    }

    # Calculate percentage
    $percentage = 0
    if ($maxScore -gt 0) {
        $percentage = [math]::Round(($score / $maxScore) * 100, 0)
    }

    return @{
        score = $score
        max_score = $maxScore
        percentage = $percentage
        details = $details
    }
}

function Get-PrdSection {
    param(
        [string]$Content,
        [string]$SectionPattern
    )

    # Split by ## headers
    $sections = $Content -split '(?m)^##\s+'

    foreach ($section in $sections) {
        if ($section -match "(?i)^[^\n]*$SectionPattern[^\n]*") {
            return $section
        }
    }

    return $null
}

function Get-SemanticPrdCompletion {
    param([string]$PrdPath)

    if (-not (Test-Path $PrdPath)) {
        throw "PRD file not found: $PrdPath"
    }

    $content = Get-Content $PrdPath -Raw
    $rules = Get-SemanticRules

    $results = @{}

    # Problem Statement / Executive Summary
    $section = Get-PrdSection $content "(Executive Summary|Problem)"
    if ($section) {
        $results.problem_statement = (Measure-SemanticSection $section $rules.deliverables.problem_statement).percentage
    } else {
        $results.problem_statement = 0
    }

    # User Personas
    $section = Get-PrdSection $content "(User Personas|Personas)"
    if ($section) {
        $results.user_personas = (Measure-SemanticSection $section $rules.deliverables.user_personas).percentage
    } else {
        $results.user_personas = 0
    }

    # User Stories
    $section = Get-PrdSection $content "(User Stories|Stories)"
    if ($section) {
        $results.user_stories = (Measure-SemanticSection $section $rules.deliverables.user_stories).percentage
    } else {
        $results.user_stories = 0
    }

    # Features
    $section = Get-PrdSection $content "(Features|Requirements)"
    if ($section) {
        $results.feature_list = (Measure-SemanticSection $section $rules.deliverables.feature_list).percentage
    } else {
        $results.feature_list = 0
    }

    # Tech Stack
    $section = Get-PrdSection $content "(Tech Stack|Technical Foundation)"
    if ($section) {
        $results.tech_stack = (Measure-SemanticSection $section $rules.deliverables.tech_stack).percentage
    } else {
        $results.tech_stack = 0
    }

    # Success Metrics
    $section = Get-PrdSection $content "(Success Metrics|Success|KPIs)"
    if ($section) {
        $results.success_metrics = (Measure-SemanticSection $section $rules.deliverables.success_metrics).percentage
    } else {
        $results.success_metrics = 0
    }

    # MVP Scope
    $section = Get-PrdSection $content "(MVP|Roadmap|Scope)"
    if ($section) {
        $results.mvp_scope = (Measure-SemanticSection $section $rules.deliverables.mvp_scope).percentage
    } else {
        $results.mvp_scope = 0
    }

    # Non-Functional Requirements
    $section = Get-PrdSection $content "(Non-Functional|Quality Attributes|Constraints)"
    if ($section) {
        $results.non_functional = (Measure-SemanticSection $section $rules.deliverables.non_functional).percentage
    } else {
        $results.non_functional = 0
    }

    return $results
}

function Get-SemanticPrdDiagnostics {
    param(
        [string]$PrdPath
    )

    if (-not (Test-Path $PrdPath)) { throw "PRD file not found: $PrdPath" }

    $content = Get-Content $PrdPath -Raw
    $rules   = Get-SemanticRules

    $diagnostics = @()

    $map = @(
        @{ key = 'problem_statement'; pattern = '(Executive Summary|Problem)'; name = 'Problem Statement' },
        @{ key = 'user_personas';     pattern = '(User Personas|Personas)';    name = 'User Personas' },
        @{ key = 'user_stories';      pattern = '(User Stories|Stories)';      name = 'User Stories' },
        @{ key = 'feature_list';      pattern = '(Features|Requirements)';     name = 'Feature List' },
        @{ key = 'tech_stack';        pattern = '(Tech Stack|Technical Foundation)'; name = 'Tech Stack' },
        @{ key = 'success_metrics';   pattern = '(Success Metrics|Success|KPIs)'; name = 'Success Metrics' },
        @{ key = 'mvp_scope';         pattern = '(MVP|Roadmap|Scope)';         name = 'MVP Scope' },
        @{ key = 'non_functional';    pattern = '(Non-Functional|Technical Foundation)'; name = 'Non-Functional' }
    )

    foreach ($entry in $map) {
        $section = Get-PrdSection $content $entry.pattern
        $suggestions = @()
        $percentage  = 0

        if (-not $section) {
            $suggestions += "Add a '## $($entry.name)' section with required content."
        } else {
            # Measure and gather failed elements
            $rule = $rules.deliverables.($entry.key)
            $measure = Measure-SemanticSection -SectionContent $section -Rules $rule
            $percentage = $measure.percentage

            foreach ($detail in $measure.details) {
                if ($detail.status -ne 'FAIL') { continue }
                # Find rule element by id
                $ruleElem = $rule.required_elements | Where-Object { $_.id -eq $detail.element }
                if ($null -eq $ruleElem) { continue }

                if ($ruleElem.type -eq 'count') {
                    $min = [int]$ruleElem.minimum
                    $found = 0
                    if ($detail.PSObject.Properties.Name -contains 'found' -and $detail.found) { $found = [int]$detail.found }
                    $need = [math]::Max(0, $min - $found)
                    $desc = $ruleElem.id
                    if ($ruleElem.PSObject.Properties.Name -contains 'description' -and $ruleElem.description) { $desc = $ruleElem.description }
                    $suggestions += "Add $need more to meet minimum: $desc"
                } else {
                    $desc = $ruleElem.id
                    if ($ruleElem.PSObject.Properties.Name -contains 'description' -and $ruleElem.description) { $desc = $ruleElem.description }
                    $suggestions += "Include: $desc"
                }
            }
        }

        $diagnostics += @{
            key = $entry.key
            name = $entry.name
            completion = $percentage
            suggestions = $suggestions
        }
    }

    return $diagnostics
}

# =============================================================================
# IA COMPLETENESS VALIDATION (Deterministic)
# =============================================================================

function Get-IACompletion {
    <#
    .SYNOPSIS
    Calculates IA completeness score (0-100%) based on required elements

    .DESCRIPTION
    Deterministic pattern-based validation:
    - Sitemap: Routes have purposes, descriptions
    - Flows: Have entry, steps, success, errors
    - Entities: Have fields/attributes
    - Navigation: Primary/secondary nav defined

    .PARAMETER IAPath
    Path to ia/ directory

    .OUTPUTS
    Hashtable with completion percentages per section
    #>
    param([string]$IAPath)

    if (-not (Test-Path $IAPath)) {
        throw "IA directory not found: $IAPath"
    }

    $results = @{
        sitemap_completeness = 0
        flows_completeness = 0
        entities_completeness = 0
        navigation_completeness = 0
    }

    # Sitemap completeness
    $sitemapPath = Join-Path $IAPath "sitemap.md"
    if (Test-Path $sitemapPath) {
        $results.sitemap_completeness = Measure-SitemapCompleteness -Path $sitemapPath
    }

    # Flows completeness
    $flowsPath = Join-Path $IAPath "flows.md"
    if (Test-Path $flowsPath) {
        $results.flows_completeness = Measure-FlowsCompleteness -Path $flowsPath
    }

    # Entities completeness
    $entitiesPath = Join-Path $IAPath "entities.md"
    if (Test-Path $entitiesPath) {
        $results.entities_completeness = Measure-EntitiesCompleteness -Path $entitiesPath
    }

    # Navigation completeness
    $navPath = Join-Path $IAPath "navigation.md"
    if (Test-Path $navPath) {
        $results.navigation_completeness = Measure-NavigationCompleteness -Path $navPath
    }

    return $results
}

function Measure-SitemapCompleteness {
    param([string]$Path)

    $rawContent = Get-Content -Path $Path -Raw
    $content = Normalize-Text $rawContent

    # Count routes - support both bullet list and table formats
    # Bullet format: - /dashboard
    # Table format: Dashboard	/dashboard	Purpose text
    $bulletPattern = '(?m)^\s*[-*]\s+(/[^\s]+)'
    $tablePattern = '(?m)^\s*\S+\s+(/[^\s\t]+)'

    $bulletRoutes = [regex]::Matches($content, $bulletPattern)
    $tableRoutes = [regex]::Matches($content, $tablePattern)
    $routes = if ($bulletRoutes.Count -gt 0) { $bulletRoutes } else { $tableRoutes }

    $lines = $content -split "`n"
    $score = 0
    $maxScore = $routes.Count * 2  # 1 point for route, 1 for description

    foreach ($match in $routes) {
        $score++  # Route exists

        # Find the line index where this route appears
        $routeLineIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match [regex]::Escape($match.Groups[1].Value)) {
                $routeLineIndex = $i
                break
            }
        }

        # Check next 3 lines for Purpose or Description
        if ($routeLineIndex -ge 0) {
            $hasPurpose = $false
            for ($i = $routeLineIndex + 1; $i -lt [Math]::Min($routeLineIndex + 4, $lines.Count); $i++) {
                if ($lines[$i] -match '(?i)(purpose|description):\s*\S+' -or ($lines[$routeLineIndex] -match '\t.*\t.+')) {
                    $hasPurpose = $true
                    break
                }
            }
            if ($hasPurpose) { $score++ }
        }
    }

    return [Math]::Round(($score / $maxScore) * 100, 0)
}

function Measure-FlowsCompleteness {
    param([string]$Path)

    $rawContent = Get-Content -Path $Path -Raw
    $content = Normalize-Text $rawContent

    # Count flows - support markdown headers, labeled flows, and plain text headers ending with "Flow"
    # Formats: ### Workout Flow, Flow:, or plain "Workout Tracking Flow"
    $flowPattern = '(?im)^(.+?\s+(?:Flow|Journey|Process))\s*$'
    $flows = [regex]::Matches($content, $flowPattern)

    $score = 0
    $maxScore = $flows.Count * 4  # Entry, Steps, Success, Errors

    foreach ($match in $flows) {
        $flowName = $match.Groups[1].Value.Trim()

        # Extract flow block (until next flow or end)
        $startIdx = $match.Index
        $matchEnd = $match.Index + $match.Length
        $nextFlow = [regex]::Matches($content.Substring($matchEnd), $flowPattern) | Select-Object -First 1
        $endIdx = if ($nextFlow) { $matchEnd + $nextFlow.Index } else { $content.Length }
        $flowBlock = $content.Substring($startIdx, $endIdx - $startIdx)

        # Check for required fields
        if ($flowBlock -match '(?i)(entry|trigger|start|goal):\s*\S+') { $score++ }
        if ($flowBlock -match '(?i)(steps?|flow):\s*\S+') { $score++ }
        if ($flowBlock -match '(?i)(success|outcome|result|goal):\s*\S+') { $score++ }
        if ($flowBlock -match '(?i)(error|failure|exception)s?:\s*\S+') { $score++ }
    }

    return [Math]::Round(($score / $maxScore) * 100, 0)
}

function Measure-EntitiesCompleteness {
    param([string]$Path)

    $rawContent = Get-Content -Path $Path -Raw
    $content = Normalize-Text $rawContent

    # Count entities
    $entityPattern = '(?im)^(?:[-*]\s+|###?\s+|Entity:\s+)([A-Z][A-Za-z]+)(?:\s+Entity)?'
    $entities = [regex]::Matches($content, $entityPattern)
    if ($entities.Count -eq 0) { return 0 }

    $score = 0
    $maxScore = $entities.Count * 2  # Entity + Fields

    foreach ($match in $entities) {
        $score++  # Entity exists

        # Check if entity has fields
        $entityName = $match.Groups[1].Value
        $startIdx = $match.Index
        $nextEntity = [regex]::Matches($content.Substring($startIdx + 1), $entityPattern) | Select-Object -First 1
        $endIdx = if ($nextEntity) { $startIdx + $nextEntity.Index + 1 } else { $content.Length }
        $entityBlock = $content.Substring($startIdx, $endIdx - $startIdx)

        if ($entityBlock -match '(?i)(field|attribute|propert)s?:\s*\S+') { $score++ }
    }

    return [Math]::Round(($score / $maxScore) * 100, 0)
}

function Measure-NavigationCompleteness {
    param([string]$Path)

    $rawContent = Get-Content -Path $Path -Raw
    $content = Normalize-Text $rawContent

    $score = 0
    $maxScore = 2  # Primary + Secondary

    # Check for primary navigation
    if ($content -match '(?i)(primary|main|top)\s+(nav|navigation)') { $score++ }

    # Check for secondary navigation
    if ($content -match '(?i)(secondary|footer|bottom|side)\s*(nav|navigation|:)') { $score++ }

    if ($maxScore -eq 0) { return 0 }
    return [Math]::Round(($score / $maxScore) * 100, 0)
}
