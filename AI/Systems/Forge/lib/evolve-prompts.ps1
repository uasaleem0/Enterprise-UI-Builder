<#
 .SYNOPSIS
     Prompt Builder for Evolve-Spec AI Integration
 .DESCRIPTION
     Builds structured prompts for AI-powered change analysis and implementation
#>

function Build-EvolveAnalysisPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to analyze change impact

    .PARAMETER UserRequest
    The user's plain English request

    .PARAMETER PrdContent
    Current PRD content

    .PARAMETER PRDModel
    Parsed PRD model (features, scope, etc.)

    .PARAMETER IAModel
    Parsed IA model (routes, flows, components)

    .OUTPUTS
    String containing the analysis prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserRequest,

        [Parameter(Mandatory=$true)]
        [string]$PrdContent,

        [Parameter(Mandatory=$false)]
        [hashtable]$PRDModel,

        [Parameter(Mandatory=$false)]
        [hashtable]$IAModel
    )

    $schema = @'
{
  "intent": {
    "operation": "add|modify|remove",
    "target": "feature|route|flow|component|entity",
    "entity_name": "Name of the entity",
    "scope": "MUST|SHOULD|COULD"
  },
  "prd_changes": {
    "features_add": [
      {
        "name": "Feature Name",
        "description": "Detailed description",
        "scope": "MUST|SHOULD|COULD",
        "acceptance_criteria": ["Given X, When Y, Then Z"],
        "user_stories": ["As a user, I want X so that Y"]
      }
    ],
    "scope_add": [{"name": "Feature", "scope": "MUST|SHOULD|COULD", "description": "..."}],
    "nfr_add": [{"category": "Performance|Security|...", "requirement": "..."}],
    "kpis_add": [{"metric": "Metric name", "target": "Target value", "timeframe": "Timeline"}]
  },
  "ia_changes": {
    "routes_add": [{"route": "/path", "description": "Purpose"}],
    "flows_add": [
      {
        "name": "Flow Name",
        "purpose": "Purpose",
        "entry": "/entry-route",
        "steps": ["/route1", "/route2"],
        "success": "Success criteria",
        "errors": ["Error conditions"]
      }
    ],
    "components_add": [{"route": "/path", "components": ["ComponentName"]}],
    "entities_add": [{"name": "EntityName", "fields": ["field1", "field2"]}]
  },
  "semantic_issues": ["Potential conflict or inconsistency"],
  "recommendations": ["Suggested improvements"]
}
'@

    $prompt = @()
    $prompt += "You are a Senior Systems Engineer analyzing a change request for a product."
    $prompt += ""
    $prompt += "RULES:"
    $prompt += "1. Analyze the user's request and determine the intent"
    $prompt += "2. Propose specific changes to both PRD and IA"
    $prompt += "3. Ensure consistency between PRD features and IA routes"
    $prompt += "4. Identify potential conflicts with existing content"
    $prompt += "5. Provide actionable recommendations"
    $prompt += "6. Return ONLY valid JSON matching the schema below"
    $prompt += ""
    $prompt += "JSON SCHEMA:"
    $prompt += $schema
    $prompt += ""
    $prompt += "USER REQUEST:"
    $prompt += $UserRequest
    $prompt += ""

    if ($PRDModel -and $PRDModel.features) {
        $prompt += "EXISTING PRD FEATURES:"
        foreach ($feature in $PRDModel.features) {
            $prompt += "- $($feature.name) [$($feature.scope)]"
        }
        $prompt += ""
    }

    if ($IAModel -and $IAModel.routes) {
        $prompt += "EXISTING IA ROUTES:"
        foreach ($route in $IAModel.routes) {
            $prompt += "- $route"
        }
        $prompt += ""
    }

    if ($IAModel -and $IAModel.flows) {
        $prompt += "EXISTING USER FLOWS:"
        foreach ($flow in $IAModel.flows) {
            $prompt += "- $($flow.name): $($flow.steps -join ' -> ')"
        }
        $prompt += ""
    }

    $prompt += "PRD CONTENT (first 3000 chars):"
    $prompt += "-----"
    $prompt += $PrdContent.Substring(0, [Math]::Min(3000, $PrdContent.Length))
    $prompt += "-----"
    $prompt += ""
    $prompt += "Return your analysis as JSON matching the schema above."

    return ($prompt -join "`n")
}

function Build-EvolveRefinementPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to refine and enhance the initial analysis

    .PARAMETER InitialAnalysis
    The initial analysis result from Build-EvolveAnalysisPrompt

    .PARAMETER PrdContent
    Current PRD content

    .PARAMETER UserFeedback
    Optional user feedback on the initial analysis

    .OUTPUTS
    String containing the refinement prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$InitialAnalysis,

        [Parameter(Mandatory=$true)]
        [string]$PrdContent,

        [Parameter(Mandatory=$false)]
        [string]$UserFeedback
    )

    $prompt = @()
    $prompt += "You are refining a change analysis for a product evolution."
    $prompt += ""
    $prompt += "INITIAL ANALYSIS:"
    $prompt += ($InitialAnalysis | ConvertTo-Json -Depth 10)
    $prompt += ""

    if ($UserFeedback) {
        $prompt += "USER FEEDBACK:"
        $prompt += $UserFeedback
        $prompt += ""
        $prompt += "TASK: Refine the analysis based on user feedback."
    } else {
        $prompt += "TASK: Enhance the analysis with:"
        $prompt += "1. More detailed acceptance criteria"
        $prompt += "2. Additional user stories"
        $prompt += "3. More specific component names"
        $prompt += "4. Comprehensive error conditions"
        $prompt += "5. Additional NFRs if applicable"
    }

    $prompt += ""
    $prompt += "Return the refined analysis as JSON in the same format."

    return ($prompt -join "`n")
}

function Build-EvolveValidationPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to validate proposed changes against existing content

    .PARAMETER ProposedChanges
    The proposed changes from analysis

    .PARAMETER PrdContent
    Current PRD content

    .PARAMETER IAContent
    Current IA content (combined)

    .OUTPUTS
    String containing the validation prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ProposedChanges,

        [Parameter(Mandatory=$true)]
        [string]$PrdContent,

        [Parameter(Mandatory=$false)]
        [string]$IAContent
    )

    $prompt = @()
    $prompt += "You are validating proposed changes for consistency and conflicts."
    $prompt += ""
    $prompt += "PROPOSED CHANGES:"
    $prompt += ($ProposedChanges | ConvertTo-Json -Depth 10)
    $prompt += ""
    $prompt += "CURRENT PRD:"
    $prompt += "-----"
    $prompt += $PrdContent
    $prompt += "-----"
    $prompt += ""

    if ($IAContent) {
        $prompt += "CURRENT IA:"
        $prompt += "-----"
        $prompt += $IAContent
        $prompt += "-----"
        $prompt += ""
    }

    $prompt += "VALIDATION TASKS:"
    $prompt += "1. Check for duplicate features or routes"
    $prompt += "2. Identify contradictions with existing content"
    $prompt += "3. Verify all features have corresponding routes"
    $prompt += "4. Ensure flows reference valid routes"
    $prompt += "5. Check for semantic inconsistencies"
    $prompt += ""
    $prompt += "Return JSON:"
    $prompt += @'
{
  "is_valid": true|false,
  "conflicts": ["List of conflicts found"],
  "warnings": ["List of warnings"],
  "suggestions": ["List of improvement suggestions"]
}
'@

    return ($prompt -join "`n")
}

function Build-EvolveDescriptionPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to generate detailed descriptions and acceptance criteria

    .PARAMETER FeatureName
    Name of the feature

    .PARAMETER Context
    Context from PRD and user request

    .OUTPUTS
    String containing the description generation prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName,

        [Parameter(Mandatory=$true)]
        [string]$Context
    )

    $prompt = @()
    $prompt += "You are writing detailed documentation for a new feature."
    $prompt += ""
    $prompt += "FEATURE NAME: $FeatureName"
    $prompt += ""
    $prompt += "CONTEXT:"
    $prompt += $Context
    $prompt += ""
    $prompt += "Generate:"
    $prompt += "1. A clear, comprehensive description (2-3 sentences)"
    $prompt += "2. 3-5 acceptance criteria in Given/When/Then format"
    $prompt += "3. 2-3 user stories in 'As a... I want... so that...' format"
    $prompt += ""
    $prompt += "Return JSON:"
    $prompt += @'
{
  "description": "Detailed feature description",
  "acceptance_criteria": [
    "Given the user is authenticated, When they click 'Programs', Then they see a list of programs"
  ],
  "user_stories": [
    "As a coach, I want to create programs so that I can organize workouts for my clients"
  ]
}
'@

    return ($prompt -join "`n")
}

function Build-EvolveComponentsPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to suggest component architecture

    .PARAMETER FeatureName
    Name of the feature

    .PARAMETER Route
    The route/page for this feature

    .PARAMETER Context
    Context from PRD

    .OUTPUTS
    String containing the components suggestion prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName,

        [Parameter(Mandatory=$true)]
        [string]$Route,

        [Parameter(Mandatory=$true)]
        [string]$Context
    )

    $prompt = @()
    $prompt += "You are a UI architect designing component structure."
    $prompt += ""
    $prompt += "FEATURE: $FeatureName"
    $prompt += "ROUTE: $Route"
    $prompt += ""
    $prompt += "CONTEXT:"
    $prompt += $Context
    $prompt += ""
    $prompt += "Suggest 3-8 React/Next.js components for this page."
    $prompt += "Use PascalCase naming. Be specific and semantic."
    $prompt += ""
    $prompt += "Example component types:"
    $prompt += "- Layout components (Header, Sidebar, Footer)"
    $prompt += "- List/Grid components (ProgramsList, ProgramCard)"
    $prompt += "- Form components (CreateProgramForm, ProgramFormFields)"
    $prompt += "- Action components (ProgramActions, DeleteProgramButton)"
    $prompt += "- Display components (ProgramDetails, ProgramStats)"
    $prompt += ""
    $prompt += "Return JSON:"
    $prompt += @'
{
  "components": ["ComponentName1", "ComponentName2"]
}
'@

    return ($prompt -join "`n")
}

function Build-EvolveFlowPrompt {
    <#
    .SYNOPSIS
    Builds a prompt for AI to design user flows

    .PARAMETER FeatureName
    Name of the feature

    .PARAMETER Routes
    Available routes in the app

    .PARAMETER Context
    Context from PRD

    .OUTPUTS
    String containing the flow design prompt
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName,

        [Parameter(Mandatory=$true)]
        [array]$Routes,

        [Parameter(Mandatory=$true)]
        [string]$Context
    )

    $prompt = @()
    $prompt += "You are designing user flows for a feature."
    $prompt += ""
    $prompt += "FEATURE: $FeatureName"
    $prompt += ""
    $prompt += "AVAILABLE ROUTES:"
    foreach ($route in $Routes) {
        $prompt += "- $route"
    }
    $prompt += ""
    $prompt += "CONTEXT:"
    $prompt += $Context
    $prompt += ""
    $prompt += "Design 1-3 user flows showing how users interact with this feature."
    $prompt += "Include primary flow and important secondary flows."
    $prompt += ""
    $prompt += "Return JSON:"
    $prompt += @'
{
  "flows": [
    {
      "name": "Create New Program",
      "purpose": "Allow users to create training programs",
      "entry": "/dashboard",
      "steps": ["/dashboard", "/programs", "/programs/new", "/programs/:id"],
      "success": "Program created and visible in list",
      "errors": ["Invalid program data", "Save failed"]
    }
  ]
}
'@

    return ($prompt -join "`n")
}
