function Get-EnvOrNull { param([string]$Name) if ($env:$Name) { return $env:$Name } return $null }

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

function Invoke-OpenAIExtraction {
    param(
        [string]$PrdText,
        [string]$Model = 'gpt-4o-mini'
    )
    $apiKey = Get-EnvOrNull 'OPENAI_API_KEY'
    if (-not $apiKey) { throw 'OPENAI_API_KEY not set' }
    $body = @{ 
        model = $Model
        response_format = @{ type = 'json_object' }
        messages = @(
            @{ role='system'; content='You extract structured PRD data as strict JSON. Follow user rules exactly.' },
            @{ role='user'; content=(Build-PrdExtractionPrompt -PrdText $PrdText -AllowInferred) }
        )
        temperature = 0.1
    } | ConvertTo-Json -Depth 6
    $headers = @{ 'Authorization' = "Bearer $apiKey"; 'Content-Type' = 'application/json' }
    $res = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if (-not $res -or -not $res.choices -or -not $res.choices[0].message.content) { throw 'OpenAI: empty response' }
    return $res.choices[0].message.content
}

function Invoke-AnthropicExtraction {
    param(
        [string]$PrdText,
        [string]$Model = 'claude-3-5-sonnet-20240620'
    )
    $apiKey = Get-EnvOrNull 'ANTHROPIC_API_KEY'
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
    switch -Regex ($provider.ToLower()) {
        '^openai' { $model = (Get-EnvOrNull 'FORGE_AI_OPENAI_MODEL'); if (-not $model) { $model='gpt-4o-mini' }; $jsonText = Invoke-OpenAIExtraction -PrdText $text -Model $model }
        '^anthropic' { $model = (Get-EnvOrNull 'FORGE_AI_ANTHROPIC_MODEL'); if (-not $model) { $model='claude-3-5-sonnet-20240620' }; $jsonText = Invoke-AnthropicExtraction -PrdText $text -Model $model }
        default { throw "Unsupported provider: $provider (set FORGE_AI_PROVIDER=openai|anthropic)" }
    }
    # Validate JSON
    try { $obj = $jsonText | ConvertFrom-Json -ErrorAction Stop } catch { throw "AI returned invalid JSON: $($_.Exception.Message)" }
    if (-not $OutJsonPath) { $OutJsonPath = (Join-Path (Split-Path $PrdPath -Parent) 'ai_parsed_prd.json') }
    Set-Content -Path $OutJsonPath -Value ($jsonText.Trim()) -Encoding UTF8
    return $OutJsonPath
}

