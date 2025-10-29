function Get-EnvOrNull {
    param([string]$Name)
    $val = [Environment]::GetEnvironmentVariable($Name,'Process')
    if (-not $val) { $val = [Environment]::GetEnvironmentVariable($Name,'User') }
    if (-not $val) { $val = [Environment]::GetEnvironmentVariable($Name,'Machine') }
    return $val
}

function Get-HomePath {
    $homePath = [Environment]::GetFolderPath('UserProfile')
    if (-not $homePath -and $env:USERPROFILE) { $homePath = $env:USERPROFILE }
    return $homePath
}

function Get-ConfigValue {
    param(
        [string]$Name,
        [string]$ProjectPath
    )
    $homePath = Get-HomePath
    $paths = @()
    if ($ProjectPath) {
        $paths += (Join-Path $ProjectPath '.forge-ai.json')
        $paths += (Join-Path $ProjectPath '.forge-ai.env')
        $paths += (Join-Path $ProjectPath '.env')
    }
    if ($homePath) {
        $paths += (Join-Path $homePath '.forge-ai.json')
        $paths += (Join-Path $homePath '.forge-ai.env')
    }
    foreach($p in $paths){
        if (-not (Test-Path $p)) { continue }
        try {
            if ($p.ToLower().EndsWith('.json')){
                $json = Get-Content -Path $p -Raw -Encoding UTF8 | ConvertFrom-Json
                switch ($Name.ToLower()){
                    'forge_ai_provider' { if ($json.provider) { return [string]$json.provider } }
                    'openai_api_key' { if ($json.openai_api_key) { return [string]$json.openai_api_key } }
                    'anthropic_api_key' { if ($json.anthropic_api_key) { return [string]$json.anthropic_api_key } }
                    'forge_ai_openai_model' { if ($json.openai_model) { return [string]$json.openai_model } }
                    'forge_ai_anthropic_model' { if ($json.anthropic_model) { return [string]$json.anthropic_model } }
                }
            } else {
                $lines = Get-Content -Path $p -Encoding UTF8
                foreach($ln in $lines){
                    $t=$ln.Trim(); if (-not $t -or $t.StartsWith('#')){ continue }
                    if ($t -match '^(?<k>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?<v>.+)$'){
                        $k=$matches['k']; $v=$matches['v'].Trim([char]34, [char]39)
                        if ($k.ToLower() -eq $Name.ToLower()) { return $v }
                    }
                }
            }
        } catch { continue }
    }
    return $null
}

function Build-PrdExtractionPrompt {
    param(
        [string]$PrdText,
        [switch]$AllowInferred
    )
    $schema = @'
{
  "projectName": "",
  "scope": { "must": [], "should": [], "could": [] },
  "features": [
    {
      "name": "",
      "scope": "MUST|SHOULD|COULD",
      "description": "",
      "stories": ["As a ... I want ... so that ..."],
      "acceptance": ["Given ... When ... Then ..."],
      "nfr": ["Performance|Security|Accessibility|..."],
      "kpis": ["KPI or metric lines with target/timeframe"],
      "derived": false
    }
  ]
}
'@
    $rules = @()
    $rules += 'You are extracting a structured PRD model from the content below.'
    $rules += 'Rules:'
    $rules += '- Do not invent features or scope that are not present.'
    $rules += '- You may make implicit items explicit ONLY if they are directly inferable from text (e.g., convert a goal into acceptance phrasing, summarize a KPI row). Mark such items by setting "derived": true on the feature.'
    $rules += '- Preserve factual consistency and do not add external knowledge.'
    $rules += '- Use only the JSON schema provided. Omit fields that are totally absent.'
    $rules += '- Prefer exact lines for stories/acceptance when possible; concise paraphrase is allowed if clearly present.'
    $prompt = @()
    $prompt += ($rules -join "`n")
    $prompt += ''
    $prompt += 'JSON schema:'
    $prompt += $schema
    $prompt += ''
    $prompt += 'PRD content starts:'
    $prompt += '-----'
    $prompt += $PrdText
    $prompt += '-----'
    return ($prompt -join "`n")
}

function Build-IAExtractionPrompt {
    param(
        [string]$PrdText,
        [hashtable]$IaSections
    )
    $schema = @'
{
  "routes": ["/dashboard", "/workout/start"],
  "modals": ["AddExerciseModal"],
  "out_of_scope": ["Cloud sync", "Social feed"],
  "primary_nav": ["Dashboard", "Workouts", "Templates", "Insights", "Journal", "Progress", "Settings"],
  "purpose_map": {"/dashboard": "Central home with CTA", "/workout/start": "Begin workout session"},
  "components_by_route": {"/dashboard": ["StartCTA", "StreakWidget"]},
  "entities_by_route": {"/workout/session": ["WorkoutSession", "Set"], "/exercises": ["Exercise"]},
  "flows": [
    {"name":"Start Workout","purpose":"Begin quickly","steps":["/dashboard","/workout/start","/workout/session"],"success":"Session saved","errors":["Empty template"],"entry":"/dashboard"}
  ]
}
'@
    $rules = @()
    $rules += 'You extract a structured IA model for the app. Use only provided content. Do not invent routes or components not present.'
    $rules += '- Normalize route strings to "/...".'
    $rules += '- Extract purpose_map: for each route, provide a concise purpose description from the sitemap.'
    $rules += '- Derive primary_nav as labels mapped to existing routes if possible.'
    $rules += '- If something is truly missing, omit the field rather than fabricating content.'

    $prompt = @()
    $prompt += ($rules -join "`n")
    $prompt += ''
    $prompt += 'JSON schema:'
    $prompt += $schema
    $prompt += ''
    $prompt += 'PRD content (for context):'
    $prompt += '-----'
    $prompt += $PrdText
    $prompt += '-----'
    foreach($k in @('sitemap','components','entities','navigation','flows')){
        if ($IaSections.ContainsKey($k) -and $IaSections[$k]){
            $prompt += ("IA " + $k.ToUpper() + ' section:')
            $prompt += '-----'
            $prompt += $IaSections[$k]
            $prompt += '-----'
        }
    }
    return ($prompt -join "`n")
}

function Invoke-IAOpenAIExtraction {
    param(
        [string]$Prompt,
        [string]$Model = 'gpt-4o-mini'
    )
    $apiKey = Get-EnvOrNull 'OPENAI_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'OPENAI_API_KEY not set' }

    $debug = Get-EnvOrNull 'FORGE_AI_DEBUG'
    if ($debug -eq '1' -or $debug -eq 'true') {
        Write-Host "  [DEBUG] Model: $Model" -ForegroundColor Gray
        Write-Host "  [DEBUG] Prompt length: $($Prompt.Length) chars" -ForegroundColor Gray
    }

    $body = @{
        model = $Model
        response_format = @{ type = 'json_object' }
        messages = @(
            @{ role='system'; content='You extract IA as strict JSON. Follow user rules exactly.' },
            @{ role='user'; content=$Prompt }
        )
        temperature = 0.1
    } | ConvertTo-Json -Depth 10 -Compress

    if ($debug -eq '1' -or $debug -eq 'true') {
        # Save with UTF8 no BOM
        [System.IO.File]::WriteAllText('debug-openai-request.json', $body, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "  [DEBUG] Request saved to debug-openai-request.json" -ForegroundColor Gray
    }

    $headers = @{ 'Authorization' = "Bearer $apiKey"; 'Content-Type' = 'application/json; charset=utf-8' }

    try {
        # Use UTF8 encoding without BOM
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $bodyBytes -ErrorAction Stop
        if (-not $res -or -not $res.choices -or -not $res.choices[0].message.content) { throw 'OpenAI: empty response (IA)' }
        return $res.choices[0].message.content
    } catch {
        $errorDetail = if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.ReadToEnd()
        } else { $_.Exception.Message }
        throw "OpenAI API error: $errorDetail"
    }
}

function Invoke-IAAnthropicExtraction {
    param(
        [string]$Prompt,
        [string]$Model = 'claude-3-5-sonnet-20240620'
    )
    $apiKey = Get-EnvOrNull 'ANTHROPIC_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'ANTHROPIC_API_KEY not set' }
    $headers = @{ 'x-api-key' = $apiKey; 'anthropic-version' = '2023-06-01'; 'content-type'='application/json' }
    $messages = @(
        @{ role='user'; content=@(@{ type='text'; text=$Prompt }) }
    )
    $body = @{ model=$Model; max_tokens=4000; messages=$messages; temperature=0.1 } | ConvertTo-Json -Depth 8
    $res = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if (-not $res -or -not $res.content -or -not $res.content[0].text) { throw 'Anthropic: empty response (IA)' }
    return $res.content[0].text
}



function Invoke-OpenAIExtraction {
    param(
        [string]$PrdText,
        [string]$Model = 'gpt-4o-mini'
    )
    $apiKey = Get-EnvOrNull 'OPENAI_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'OPENAI_API_KEY not set' }

    $debug = Get-EnvOrNull 'FORGE_AI_DEBUG'
    if ($debug -eq '1' -or $debug -eq 'true') {
        Write-Host "  [DEBUG] Model: $Model" -ForegroundColor Gray
        Write-Host "  [DEBUG] PRD length: $($PrdText.Length) chars" -ForegroundColor Gray
    }

    $body = @{
        model = $Model
        response_format = @{ type = 'json_object' }
        messages = @(
            @{ role='system'; content='You extract structured PRD data as strict JSON. Follow user rules exactly.' },
            @{ role='user'; content=(Build-PrdExtractionPrompt -PrdText $PrdText -AllowInferred) }
        )
        temperature = 0.1
    } | ConvertTo-Json -Depth 6 -Compress

    if ($debug -eq '1' -or $debug -eq 'true') {
        # Save with UTF8 no BOM for debugging
        [System.IO.File]::WriteAllText('debug-openai-prd-request.json', $body, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "  [DEBUG] Request saved to debug-openai-prd-request.json" -ForegroundColor Gray
    }

    $headers = @{ 'Authorization' = "Bearer $apiKey"; 'Content-Type' = 'application/json; charset=utf-8' }

    try {
        # Use UTF8 encoding without BOM (matches IA extraction pattern)
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $bodyBytes -ErrorAction Stop
        if (-not $res -or -not $res.choices -or -not $res.choices[0].message.content) { throw 'OpenAI: empty response' }
        $raw = $res.choices[0].message.content
        if ($raw -match '```\s*json\s*(?<j>{[\s\S]*})\s*```') { return $matches['j'] }
        if ($raw -match '```\s*(?<j>{[\s\S]*})\s*```') { return $matches['j'] }
        return $raw
    } catch {
        $errorDetail = if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.ReadToEnd()
        } else { $_.Exception.Message }
        throw "OpenAI API error (PRD extraction): $errorDetail"
    }
}

function Invoke-AnthropicExtraction {
    param(
        [string]$PrdText,
        [string]$Model = 'claude-3-5-sonnet-20240620'
    )
    $apiKey = Get-EnvOrNull 'ANTHROPIC_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'ANTHROPIC_API_KEY not set' }
    $headers = @{ 'x-api-key' = $apiKey; 'anthropic-version' = '2023-06-01'; 'content-type'='application/json' }
    $messages = @(
        @{ role='user'; content=@(@{ type='text'; text=(Build-PrdExtractionPrompt -PrdText $PrdText -AllowInferred) }) }
    )
    $body = @{ model=$Model; max_tokens=4000; messages=$messages; temperature=0.1 } | ConvertTo-Json -Depth 8
    $res = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if (-not $res -or -not $res.content -or -not $res.content[0].text) { throw 'Anthropic: empty response' }
    return $res.content[0].text
}

function Invoke-ForgeAIExtract {
    param(
        [string]$PrdPath,
        [string]$OutJsonPath
    )
    if (-not (Test-Path $PrdPath)) { throw "PRD not found: $PrdPath" }
    $provider = (Get-EnvOrNull 'FORGE_AI_PROVIDER')
    if (-not $provider) { $provider = 'openai' }
    $text = Get-Content -Path $PrdPath -Raw -Encoding UTF8
    $jsonText = $null

    $debug = Get-EnvOrNull 'FORGE_AI_DEBUG'

    try {
        switch -Regex ($provider.ToLower()) {
            '^openai' {
                $model = (Get-EnvOrNull 'FORGE_AI_OPENAI_MODEL')
                if (-not $model) { $model='gpt-4o-mini' }
                if ($debug -eq '1' -or $debug -eq 'true') {
                    Write-Host "  [AI] Extracting with OpenAI ($model)..." -ForegroundColor Cyan
                }
                $jsonText = Invoke-OpenAIExtraction -PrdText $text -Model $model
            }
            '^anthropic' {
                $model = (Get-EnvOrNull 'FORGE_AI_ANTHROPIC_MODEL')
                if (-not $model) { $model='claude-3-5-sonnet-20240620' }
                if ($debug -eq '1' -or $debug -eq 'true') {
                    Write-Host "  [AI] Extracting with Anthropic ($model)..." -ForegroundColor Cyan
                }
                $jsonText = Invoke-AnthropicExtraction -PrdText $text -Model $model
            }
            default { throw "Unsupported provider: $provider (set FORGE_AI_PROVIDER=openai|anthropic)" }
        }

        # Validate JSON
        try {
            $obj = $jsonText | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $errMsg = "AI returned invalid JSON: $($_.Exception.Message)"
            if ($debug -eq '1' -or $debug -eq 'true') {
                Write-Host "  [ERROR] $errMsg" -ForegroundColor Red
                Write-Host "  [DEBUG] Raw AI response saved to debug-ai-invalid-response.txt" -ForegroundColor Gray
                Set-Content -Path 'debug-ai-invalid-response.txt' -Value $jsonText -Encoding UTF8
            }
            throw $errMsg
        }

        if (-not $OutJsonPath) { $OutJsonPath = (Join-Path (Split-Path $PrdPath -Parent) 'ai_parsed_prd.json') }
        Set-Content -Path $OutJsonPath -Value ($jsonText.Trim()) -Encoding UTF8

        if ($debug -eq '1' -or $debug -eq 'true') {
            Write-Host "  [AI] Extraction successful: $OutJsonPath" -ForegroundColor Green
        }

        return $OutJsonPath
    } catch {
        # Return null on failure instead of throwing - allows fallback to heuristics
        $errorMsg = $_.Exception.Message
        if ($debug -eq '1' -or $debug -eq 'true') {
            Write-Host "  [ERROR] AI extraction failed: $errorMsg" -ForegroundColor Red
        }
        return $null
    }
}

# ============================================================================
# EVOLVE-SPEC AI INTEGRATION
# ============================================================================

. "$PSScriptRoot\evolve-prompts.ps1"

function Invoke-OpenAIEvolveAnalysis {
    param(
        [string]$Prompt,
        [string]$Model = 'gpt-4o'
    )
    $apiKey = Get-EnvOrNull 'OPENAI_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'OPENAI_API_KEY not set' }
    $body = @{ 
        model = $Model
        response_format = @{ type = 'json_object' }
        messages = @(
            @{ role='system'; content='You analyze product change requests and return structured JSON analysis.' },
            @{ role='user'; content=$Prompt }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 6
    $headers = @{ 'Authorization' = "Bearer $apiKey"; 'Content-Type' = 'application/json' }
    $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if (-not $res -or -not $res.choices -or -not $res.choices[0].message.content) { throw 'OpenAI: empty response (evolve)' }
    return $res.choices[0].message.content
}

function Invoke-AnthropicEvolveAnalysis {
    param(
        [string]$Prompt,
        [string]$Model = 'claude-3-5-sonnet-20241022'
    )
    $apiKey = Get-EnvOrNull 'ANTHROPIC_API_KEY'
    if ($apiKey) { $apiKey = $apiKey.Trim(); $apiKey = $apiKey.Trim([char]34, [char]39) }
    if (-not $apiKey) { throw 'ANTHROPIC_API_KEY not set' }
    $headers = @{ 'x-api-key' = $apiKey; 'anthropic-version' = '2023-06-01'; 'content-type'='application/json' }
    $messages = @(
        @{ role='user'; content=@(@{ type='text'; text=$Prompt }) }
    )
    $body = @{ model=$Model; max_tokens=8000; messages=$messages; temperature=0.2 } | ConvertTo-Json -Depth 8
    $res = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if (-not $res -or -not $res.content -or -not $res.content[0].text) { throw 'Anthropic: empty response (evolve)' }
    return $res.content[0].text
}

function Invoke-ForgeEvolveAnalysis {
    <#
    .SYNOPSIS
    Analyzes a change request using AI

    .PARAMETER ProjectPath
    Path to project directory

    .PARAMETER UserRequest
    User's plain English change request

    .OUTPUTS
    Hashtable containing structured analysis
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$true)]
        [string]$UserRequest
    )

    if (-not (Test-Path $ProjectPath)) { throw "Project path not found: $ProjectPath" }
    
    $prdPath = Join-Path $ProjectPath 'prd.md'
    if (-not (Test-Path $prdPath)) { throw "PRD not found: $prdPath" }
    
    $prdContent = Get-Content -Path $prdPath -Raw -Encoding UTF8
    
    # Load state for context
    . "$PSScriptRoot\state-manager.ps1"
    $state = Get-ProjectState -ProjectPath $ProjectPath
    
    $prdModel = if ($state.prd_model) { $state.prd_model } else { $null }
    $iaModel = if ($state.ia_model) { $state.ia_model } else { $null }
    
    # Build analysis prompt
    $prompt = Build-EvolveAnalysisPrompt -UserRequest $UserRequest -PrdContent $prdContent -PRDModel $prdModel -IAModel $iaModel
    
    # Call AI
    $provider = (Get-ConfigValue -Name 'FORGE_AI_PROVIDER' -ProjectPath $ProjectPath)
    if (-not $provider) { $provider = (Get-EnvOrNull 'FORGE_AI_PROVIDER') }
    if (-not $provider) { $provider = 'openai' }
    
    $jsonText = $null
    switch -Regex ($provider.ToLower()) {
        '^openai' {
            $model = (Get-ConfigValue -Name 'FORGE_AI_OPENAI_MODEL' -ProjectPath $ProjectPath)
            if (-not $model) { $model = (Get-EnvOrNull 'FORGE_AI_OPENAI_MODEL') }
            if (-not $model) { $model = 'gpt-4o' }
            $jsonText = Invoke-OpenAIEvolveAnalysis -Prompt $prompt -Model $model
        }
        '^anthropic' {
            $model = (Get-ConfigValue -Name 'FORGE_AI_ANTHROPIC_MODEL' -ProjectPath $ProjectPath)
            if (-not $model) { $model = (Get-EnvOrNull 'FORGE_AI_ANTHROPIC_MODEL') }
            if (-not $model) { $model = 'claude-3-5-sonnet-20241022' }
            $jsonText = Invoke-AnthropicEvolveAnalysis -Prompt $prompt -Model $model
        }
        default { throw "Unsupported provider: $provider (set FORGE_AI_PROVIDER=openai|anthropic)" }
    }
    
    # Parse and return
    try {
        $analysis = $jsonText | ConvertFrom-Json -ErrorAction Stop
        # Convert to hashtable for consistency
        . "$PSScriptRoot\..\lib\state-manager.ps1"
        return (ConvertTo-Hashtable $analysis)
    } catch {
        throw "AI returned invalid JSON: $($_.Exception.Message)"
    }
}
