# Forge Semantic Validator
# Validates PRD content semantically based on required elements

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
    $percentage = if ($maxScore -gt 0) {
        [math]::Round(($score / $maxScore) * 100, 0)
    } else {
        0
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
    $section = Get-PrdSection $content "(Non-Functional|Technical Foundation)"
    if ($section) {
        $results.non_functional = (Measure-SemanticSection $section $rules.deliverables.non_functional).percentage
    } else {
        $results.non_functional = 0
    }

    return $results
}
