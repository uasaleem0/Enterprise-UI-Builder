<#
 .SYNOPSIS
     Semantic Issues Detector (PRD)
 .DESCRIPTION
     PURPOSE: Detect contradictions, implied dependencies, impossibilities, vagueness.
     METHOD: Text heuristics (no model building).
     USED BY: forge-import-prd, forge-prd-report/feedback
     NOT USED FOR: Semantic model building (see semantic-model-builder.ps1)
#>
# Forge Semantic Analyzer - Deep PRD Intelligence
# Detects implied dependencies, contradictions, impossibilities, and vagueness

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

function Get-SemanticAnalysis {
    <#
    .SYNOPSIS
    Performs deep semantic analysis on PRD content and AI-extracted model

    .PARAMETER PrdPath
    Path to prd.md file

    .PARAMETER AiModelPath
    Path to ai_parsed_prd.json (optional)

    .OUTPUTS
    Hashtable containing:
    - implied_dependencies: Array of inferred requirements
    - contradictions: Array of conflicting statements
    - impossibilities: Array of unrealistic constraints
    - vague_features: Array of under-specified features
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PrdPath,

        [Parameter(Mandatory=$false)]
        [string]$AiModelPath
    )

    if (-not (Test-Path $PrdPath)) {
        throw "PRD not found: $PrdPath"
    }

    $prdText = Get-Content -Path $PrdPath -Raw -Encoding UTF8 | Normalize-Text
    $prdLower = $prdText.ToLower()

    # Load AI model if available
    $aiModel = $null
    if ($AiModelPath -and (Test-Path $AiModelPath)) {
        try {
            $aiModel = Get-Content -Path $AiModelPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-Verbose "Failed to parse AI model: $_"
        }
    }

    $analysis = @{
        implied_dependencies = @()
        contradictions = @()
        impossibilities = @()
        vague_features = @()
    }

    # --- IMPLIED DEPENDENCIES DETECTION ---
    $analysis.implied_dependencies += Get-ImpliedDependencies -PrdText $prdLower -AiModel $aiModel

    # --- CONTRADICTIONS DETECTION ---
    $analysis.contradictions += Get-Contradictions -PrdText $prdLower

    # --- IMPOSSIBILITIES DETECTION ---
    $analysis.impossibilities += Get-Impossibilities -PrdText $prdLower -AiModel $aiModel

    # --- VAGUENESS DETECTION ---
    $analysis.vague_features += Get-VagueFeatures -PrdText $prdText -AiModel $aiModel

    return $analysis
}

function Get-ImpliedDependencies {
    param(
        [string]$PrdText,
        [object]$AiModel
    )

    $dependencies = @()

    # Authentication dependencies
    if ($PrdText -match '\b(user account|login|signup|sign up|registration|logout|profile|session)\b') {
        $hasAuth = $PrdText -match '\b(auth|authentication|oauth|jwt|clerk|supabase auth|firebase auth|auth0)\b'
        $hasAuthFeature = $false
        if ($AiModel -and $AiModel.PSObject.Properties.Name -contains 'features' -and $AiModel.features) {
            foreach ($f in $AiModel.features) {
                if ($f.PSObject.Properties.Name -contains 'name' -and $f.name -match '(?i)auth') {
                    $hasAuthFeature = $true
                    break
                }
            }
        }
        if (-not $hasAuth -and -not $hasAuthFeature) {
            $dependencies += "User accounts mentioned but no authentication system specified in tech stack or features"
        }
    }

    # Payment dependencies
    if ($PrdText -match '\b(payment|billing|subscription|checkout|stripe|invoice|receipt)\b') {
        $hasPaymentProvider = $PrdText -match '\b(stripe|paypal|square|braintree|paddle)\b'
        $hasPaymentFeature = $false
        if ($AiModel -and $AiModel.PSObject.Properties.Name -contains 'features' -and $AiModel.features) {
            foreach ($f in $AiModel.features) {
                if ($f.PSObject.Properties.Name -contains 'name' -and $f.name -match '(?i)(payment|billing|checkout)') {
                    $hasPaymentFeature = $true
                    break
                }
            }
        }
        if (-not $hasPaymentProvider -and -not $hasPaymentFeature) {
            $dependencies += "Payment functionality mentioned but no payment provider or feature defined"
        }
    }

    # Email dependencies
    if ($PrdText -match '\b(email notification|send email|email alert|email confirmation)\b') {
        $hasEmailProvider = $PrdText -match '\b(sendgrid|mailgun|resend|postmark|ses|smtp)\b'
        if (-not $hasEmailProvider) {
            $dependencies += "Email notifications mentioned but no email provider specified in tech stack"
        }
    }

    # Real-time dependencies
    if ($PrdText -match '\b(real-?time|live update|websocket|push notification|instant)\b') {
        $hasRealtimeProvider = $PrdText -match '\b(websocket|socket\.io|pusher|ably|supabase realtime|firebase realtime)\b'
        if (-not $hasRealtimeProvider) {
            $dependencies += "Real-time features mentioned but no WebSocket/real-time provider specified"
        }
    }

    # File storage dependencies
    if ($PrdText -match '\b(upload|file upload|image upload|photo|attachment|document)\b') {
        $hasStorageProvider = $PrdText -match '\b(s3|cloudinary|uploadcare|supabase storage|firebase storage|azure blob)\b'
        if (-not $hasStorageProvider) {
            $dependencies += "File uploads mentioned but no cloud storage provider specified in tech stack"
        }
    }

    # Multi-user dependencies
    if ($PrdText -match '\b(share|collaborate|team|invite|permissions|role)\b') {
        $hasRBAC = $PrdText -match '\b(rbac|role-based|permissions|access control)\b'
        if (-not $hasRBAC) {
            $dependencies += "Multi-user/sharing features mentioned but no RBAC or permissions system specified"
        }
    }

    # Search dependencies
    if ($PrdText -match '\b(search|filter|query|find)\b' -and $PrdText -match '\b(large dataset|thousands|10k\+|scale)\b') {
        $hasSearchProvider = $PrdText -match '\b(elasticsearch|algolia|typesense|meilisearch|postgres full-?text)\b'
        if (-not $hasSearchProvider) {
            $dependencies += "Advanced search at scale mentioned but no search provider specified"
        }
    }

    # Analytics dependencies
    if ($PrdText -match '\b(analytics|track|metrics|events|telemetry)\b') {
        $hasAnalyticsProvider = $PrdText -match '\b(mixpanel|amplitude|segment|posthog|google analytics)\b'
        if (-not $hasAnalyticsProvider) {
            $dependencies += "Analytics/tracking mentioned but no analytics provider specified in tech stack"
        }
    }

    return $dependencies
}

function Get-Contradictions {
    param([string]$PrdText)

    $contradictions = @()

    # Offline vs Cloud
    if ($PrdText -match '\b(offline|offline-first|no internet|air-?gapped|local-only)\b' -and
        $PrdText -match '\b(cloud|saas|sync|real-?time|server|api)\b') {
        $contradictions += "Offline-only stated but cloud/sync features also present"
    }

    # No PII vs PII collection
    if ($PrdText -match '\b(no pii|no personal data|anonymous)\b' -and
        $PrdText -match '\b(email|phone|address|name|contact)\b') {
        $contradictions += "No PII collection stated but personal data fields (email/phone/address) mentioned"
    }

    # No payments vs payment features
    if ($PrdText -match '\b(no payment|no billing|free|no monetization)\b' -and
        $PrdText -match '\b(stripe|payment|billing|subscription|checkout)\b') {
        $contradictions += "No payments stated but payment/billing features mentioned"
    }

    # No accounts vs authentication
    if ($PrdText -match '\b(no account|no login|no signup|anonymous)\b' -and
        $PrdText -match '\b(login|signup|authentication|oauth|profile)\b') {
        $contradictions += "No user accounts stated but authentication/login features mentioned"
    }

    # Single-player vs multi-user
    if ($PrdText -match '\b(single user|personal|solo|individual only)\b' -and
        $PrdText -match '\b(share|collaborate|team|multi-user|invite)\b') {
        $contradictions += "Single-user app stated but collaboration/sharing features mentioned"
    }

    # Privacy-first vs tracking
    if ($PrdText -match '\b(privacy-first|no tracking|no analytics|private)\b' -and
        $PrdText -match '\b(google analytics|mixpanel|track user|telemetry)\b') {
        $contradictions += "Privacy-first stated but user tracking/analytics tools mentioned"
    }

    return $contradictions
}

function Get-Impossibilities {
    param(
        [string]$PrdText,
        [object]$AiModel
    )

    $impossibilities = @()

    # Timeline vs scope analysis
    if ($AiModel -and $AiModel.PSObject.Properties.Name -contains 'features' -and $AiModel.features) {
        $mustFeatures = @($AiModel.features | Where-Object { $_.PSObject.Properties.Name -contains 'scope' -and $_.scope -eq 'MUST' })
        $featureCount = $mustFeatures.Count

        # Extract timeline
        $weeks = 0
        if ($PrdText -match '\b(\d+)\s*weeks?\b') { $weeks = [int]$matches[1] }
        if ($PrdText -match '\b(\d+)\s*months?\b') { $weeks = [int]$matches[1] * 4 }

        if ($weeks -gt 0 -and $featureCount -gt 0) {
            $weeksPerFeature = $weeks / $featureCount
            if ($weeksPerFeature -lt 0.5 -and $featureCount -ge 5) {
                $impossibilities += "Timeline allows $weeks weeks for $featureCount MUST features ($([math]::Round($weeksPerFeature,1)) weeks/feature) - likely unrealistic"
            }
        }
    }

    # Performance impossibilities
    if ($PrdText -match '<\s*(\d+)\s*ms' -or $PrdText -match 'under\s+(\d+)\s*ms') {
        $targetMs = [int]$matches[1]
        if ($targetMs -lt 50 -and $PrdText -match '\b(ai|machine learning|recommendation|analysis)\b') {
            $impossibilities += "Sub-${targetMs}ms response time specified for AI/ML features - likely impossible"
        }
    }

    # Scale impossibilities
    if ($PrdText -match '\b(million|1m\+|1,000,000)\s+(users|requests)\b' -and
        $PrdText -notmatch '\b(cdn|load balanc|cache|redis|horizontal scal|cluster)\b') {
        $impossibilities += "Million-scale targets mentioned without scalability infrastructure (CDN, load balancing, caching)"
    }

    # Budget vs scope
    if ($PrdText -match '\$(\d+)' -and $PrdText -match '\b(mvp|phase 1|v1)\b') {
        $budget = [int]$matches[1]
        if ($budget -lt 5000 -and $AiModel -and $AiModel.PSObject.Properties.Name -contains 'features' -and $AiModel.features) {
            $mustCount = @($AiModel.features | Where-Object { $_.PSObject.Properties.Name -contains 'scope' -and $_.scope -eq 'MUST' }).Count
            if ($mustCount -ge 8) {
                $impossibilities += "Budget of \$$budget for $mustCount MUST features - likely insufficient"
            }
        }
    }

    return $impossibilities
}

function Get-VagueFeatures {
    param(
        [string]$PrdText,
        [object]$AiModel
    )

    # Helper to check property existence (works for both hashtables and PSCustomObjects)
    function Has-Property($obj, $propName) {
        if ($null -eq $obj) { return $false }
        if ($obj -is [hashtable]) {
            return $obj.ContainsKey($propName)
        } elseif ($null -ne $obj.PSObject) {
            return $obj.PSObject.Properties.Name -contains $propName
        }
        return $false
    }

    $vagueFeatures = @()

    if (-not $AiModel -or -not (Has-Property $AiModel 'features') -or -not $AiModel.features) {
        return $vagueFeatures
    }

    foreach ($feature in $AiModel.features) {
        $featureScope = if (Has-Property $feature 'scope') { $feature.scope } else { $null }
        if ($featureScope -ne 'MUST') { continue }

        $issues = @()

        # Check acceptance criteria
        $accCount = 0
        if ((Has-Property $feature 'acceptance') -and $feature.acceptance) {
            $accCount = @($feature.acceptance).Count
        }
        if ($accCount -lt 3) {
            $issues += "Only $accCount acceptance criteria (need 3+)"
        }

        # Check for vague acceptance language
        if ((Has-Property $feature 'acceptance') -and $feature.acceptance) {
            $vaguePatterns = '(?i)\b(tbd|to be|maybe|possibly|likely|should work|user-friendly|fast|easy|good|better|optimiz)\b'
            foreach ($acc in $feature.acceptance) {
                if ($acc -match $vaguePatterns) {
                    $issues += "Vague acceptance: '$acc'"
                    break
                }
            }
        }

        # Check description
        $hasDesc = (Has-Property $feature 'description') -and $feature.description
        if (-not $hasDesc -or $feature.description.Trim().Length -lt 20) {
            $issues += "Missing or minimal description"
        }

        # Check user stories
        $hasStories = (Has-Property $feature 'stories') -and $feature.stories
        if (-not $hasStories -or @($feature.stories).Count -eq 0) {
            $issues += "No user stories linked"
        }

        # Check NFR areas
        $hasNfr = (Has-Property $feature 'nfr') -and $feature.nfr
        if (-not $hasNfr -or @($feature.nfr).Count -eq 0) {
            $issues += "No NFR areas tagged"
        }

        # Check KPIs
        $hasKpis = (Has-Property $feature 'kpis') -and $feature.kpis
        if (-not $hasKpis -or @($feature.kpis).Count -eq 0) {
            $issues += "No KPIs linked"
        }

        if ($issues.Count -gt 0) {
            $featureName = if (Has-Property $feature 'name') { $feature.name } else { 'Unknown Feature' }
            $vagueFeatures += [PSCustomObject]@{
                Name = $featureName
                Issues = $issues
            }
        }
    }

    return $vagueFeatures
}

function Get-PRDQualityScore {
    <#
    .SYNOPSIS
    Calculates deterministic quality score from semantic analysis

    .DESCRIPTION
    Weighted severity scoring (0-100%):
    - Impossibilities: -10 each (critical)
    - Contradictions: -5 each (high)
    - Vague Features: -3 each (medium)
    - Implied Dependencies: -2 each (low)

    .PARAMETER SemanticAnalysis
    Output from Get-SemanticAnalysis

    .OUTPUTS
    Integer 0-100 representing quality score
    #>
    param([hashtable]$SemanticAnalysis)

    $severityScore = 0
    $severityScore += $SemanticAnalysis.impossibilities.Count * 10
    $severityScore += $SemanticAnalysis.contradictions.Count * 5
    $severityScore += $SemanticAnalysis.vague_features.Count * 3
    $severityScore += $SemanticAnalysis.implied_dependencies.Count * 2

    return [Math]::Max(0, 100 - $severityScore)
}

$isModuleContext = $false
try { if ($MyInvocation.MyCommand.Module) { $isModuleContext = $true } } catch { $isModuleContext = $false }
if ($isModuleContext) {
    Export-ModuleMember -Function Get-SemanticAnalysis, Get-PRDQualityScore
}

