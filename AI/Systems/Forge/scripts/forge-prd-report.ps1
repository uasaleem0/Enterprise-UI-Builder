param([string[]]$Args)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\ia-report-parser.ps1"
. "$ForgeRoot\lib\semantic-validator.ps1"
. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\ai-extractor.ps1"
. "$ForgeRoot\scripts\New-ForgePRDReport.ps1"

$CurrentPath = Get-Location
$modelPath = $null
foreach ($a in $Args) { if ($a -match '^--model=(.+)$') { $modelPath = $matches[1] } }
if (-not (Test-Path "$CurrentPath\prd.md") -and -not $modelPath) {
  Write-Host "[ERROR] No project found. Run this from a project directory, or pass --model=ai_parsed.json" -ForegroundColor Red
  exit 1
}

# Parse flags
$width = 78
foreach ($a in $Args) { if ($a -match '^--width=(\d+)$') { $width = [int]$matches[1] } }

$reportData = [pscustomobject]@{ ProjectName=''; Features=@(); Scope=@{must=@();should=@();could=@()}; NfrAreas=@(); Kpis=@(); UserStories=@() }

# Default AI-assisted extraction: prefer existing model; else auto-call provider or emit prompt
if (-not $modelPath -and (Test-Path (Join-Path $CurrentPath 'ai_parsed_prd.json'))) { $modelPath = (Join-Path $CurrentPath 'ai_parsed_prd.json') }
if (-not $modelPath -and (Test-Path "$CurrentPath\prd.md")) {
  $auto = $true
  try {
    $modelPath = Invoke-ForgeAIExtract -PrdPath (Join-Path $CurrentPath 'prd.md')
    Write-Host "[INFO] AI extraction complete: $modelPath" -ForegroundColor Green
  } catch {
    $auto = $false
    # Fallback: prepare manual prompt
    try {
      $schema = @'
{
  "projectName": "",
  "scope": { "must": [], "should": [], "could": [] },
  "features": [
    { "name": "", "scope": "MUST|SHOULD|COULD", "description": "", "stories": [], "acceptance": [], "nfr": [], "kpis": [] }
  ]
}
'@
      $txt = Get-Content -Path (Join-Path $CurrentPath 'prd.md') -Raw -Encoding UTF8
      $prompt = @()
      $prompt += 'You are extracting structured data from the PRD below.'
      $prompt += 'Rules:'
      $prompt += '- Do NOT invent or assume; only extract info explicitly present.'
      $prompt += '- You may make implicit items explicit if directly inferable; mark such features as derived=true.'
      $prompt += '- Include exact lines in acceptance/stories where possible.'
      $prompt += '- Use only the provided JSON schema.'
      $prompt += '- If an item is not present, omit it (do not guess).'
      $prompt += ''
      $prompt += 'JSON schema:'
      $prompt += $schema
      $prompt += ''
      $prompt += 'PRD content starts:'
      $prompt += '-----'
      $prompt += $txt
      $prompt += '-----'
      $promptPath = Join-Path $CurrentPath 'ai_prd_extract_prompt.txt'
      Set-Content -Path $promptPath -Value ($prompt -join [Environment]::NewLine) -Encoding UTF8
      Write-Host "[INFO] Prepared AI extraction prompt: $promptPath" -ForegroundColor Yellow
      Write-Host "[ACTION REQUIRED] Paste the prompt into your AI, save the JSON as 'ai_parsed_prd.json' next to prd.md, then rerun 'forge prd-report'." -ForegroundColor Yellow
      exit 2
    } catch { throw $_ }
  }
}

# Optional: merge AI-extracted model
if ($modelPath) {
  try {
    $ai = Get-Content -Path $modelPath -Raw -Encoding UTF8 | ConvertFrom-Json
    function Norm([string]$s){ if(-not $s){ return '' }; return (($s.ToLower() -replace '[^a-z0-9 ]','').Trim()) }
    if ($ai.ProjectName -and -not $reportData.ProjectName){ $reportData | Add-Member -NotePropertyName ProjectName -NotePropertyValue $ai.ProjectName -Force }
    # Merge features
    foreach($af in $ai.features){
      $an = Norm $af.name
      if (-not $an) { continue }
      $match = $null
      foreach($rf in $reportData.Features){ if (Norm $rf.Name -eq $an) { $match = $rf; break } }
      if (-not $match) {
        $match = [pscustomobject]@{ Name=$af.name; Scope='UNKNOWN'; Description=''; AcceptanceDone=0; AcceptanceTotal=0; Stories=@(); NfrAreas=@(); Kpis=@() }
        $reportData.Features += ,$match
      }
      if (-not $match.Description -and $af.PSObject.Properties.Name -contains 'description' -and $af.description){ $match | Add-Member -NotePropertyName Description -NotePropertyValue $af.description -Force }
      if ($af.PSObject.Properties.Name -contains 'stories' -and $af.stories){ $match | Add-Member -NotePropertyName Stories -NotePropertyValue (@($match.Stories + $af.stories) | Select-Object -Unique) -Force }
      if ($af.PSObject.Properties.Name -contains 'nfr' -and $af.nfr){ $match | Add-Member -NotePropertyName NfrAreas -NotePropertyValue (@($match.NfrAreas + $af.nfr) | Select-Object -Unique) -Force }
      if ($af.PSObject.Properties.Name -contains 'kpis' -and $af.kpis){ $match | Add-Member -NotePropertyName Kpis -NotePropertyValue (@($match.Kpis + $af.kpis) | Select-Object -Unique) -Force }
      if ($af.PSObject.Properties.Name -contains 'acceptance' -and $af.acceptance){
        $total = ($af.acceptance | Measure-Object).Count
        $done = 0
        foreach($aic in $af.acceptance){ if ($aic -match '(?i)must|shall|given|when|then') { $done++ } }
        if ($total -gt 0){ $match | Add-Member -NotePropertyName AcceptanceTotal -NotePropertyValue $total -Force; $match | Add-Member -NotePropertyName AcceptanceDone -NotePropertyValue $done -Force }
      }
      if ($af.PSObject.Properties.Name -contains 'scope' -and $af.scope){ $match | Add-Member -NotePropertyName Scope -NotePropertyValue ([string]$af.scope).ToUpper() -Force }
    }
    # Merge scope lists if provided
    if ($ai.PSObject.Properties.Name -contains 'scope'){
      if (-not $reportData.Scope){ $reportData | Add-Member -NotePropertyName Scope -NotePropertyValue (@{must=@();should=@();could=@()}) -Force }
      if ($ai.scope.must){ $reportData.Scope.must = @($reportData.Scope.must + $ai.scope.must) | Select-Object -Unique }
      if ($ai.scope.should){ $reportData.Scope.should = @($reportData.Scope.should + $ai.scope.should) | Select-Object -Unique }
      if ($ai.scope.could){ $reportData.Scope.could = @($reportData.Scope.could + $ai.scope.could) | Select-Object -Unique }
    }
  } catch {
    Write-Host "[WARNING] Failed to merge AI model: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# Reuse existing status gates for readiness/completeness (no duplication)
$completion = $null
$diagnostics = $null
try {
  $completion = Get-SemanticPrdCompletion -PrdPath (Join-Path $CurrentPath 'prd.md')
  $diagnostics = Get-SemanticPrdDiagnostics -PrdPath (Join-Path $CurrentPath 'prd.md')
} catch {
  # Fallback silently if validator not available
}

# Compute overall confidence and next steps using existing gates
$confidence = $null
$nextSteps = $null
if ($completion) {
  try {
    $confidence = Update-ProjectConfidence -ProjectPath $CurrentPath -Deliverables $completion
    $state = @{ confidence = $confidence; deliverables = $completion }
    $nextSteps = Get-NextSteps -State $state
  } catch { }
}

# Derive traceability coverage from PRD-only cross-references (MUST-weighted)
$traceability = $null
try {
  $features = @($reportData.Features)
  $must = @($features | Where-Object { $_.Scope -eq 'MUST' })
  $covSet = if ($must.Count -gt 0) { $must } else { $features }
  $tot = ($covSet | Measure-Object).Count; if ($tot -lt 1) { $tot = 1 }

  $withStories = (@($covSet | Where-Object { $_.Stories -and $_.Stories.Count -gt 0 }) | Measure-Object).Count
  $withNfrs    = (@($covSet | Where-Object { $_.NfrAreas -and $_.NfrAreas.Count -gt 0 }) | Measure-Object).Count
  $withKpis    = (@($covSet | Where-Object { $_.Kpis -and $_.Kpis.Count -gt 0 }) | Measure-Object).Count

  # Acceptance with partial credit: 3+ = 100%, 2=67%, 1=33%, 0 but has stories=50%, 0=0%
  $accScores = 0.0
  foreach($f in $covSet){
    $accTotal = if ($f.PSObject.Properties.Name -contains 'AcceptanceTotal') { [int]$f.AcceptanceTotal } else { 0 }
    $hasStories = ($f.Stories -and $f.Stories.Count -gt 0)
    $score = 0.0
    if ($accTotal -ge 3) { $score = 1.0 }
    elseif ($accTotal -eq 2) { $score = 0.67 }
    elseif ($accTotal -eq 1) { $score = 0.33 }
    elseif ($accTotal -eq 0 -and $hasStories) { $score = 0.5 }
    $accScores += $score
  }
  $accPct = [math]::Round(100.0 * ($accScores / $tot), 2)

  $storyPct = [math]::Round(100.0 * $withStories / $tot, 2)
  $nfrPct   = [math]::Round(100.0 * $withNfrs   / $tot, 2)
  $kpiPct   = [math]::Round(100.0 * $withKpis   / $tot, 2)

  $coverage = [math]::Round(($storyPct*0.4 + $accPct*0.2 + $nfrPct*0.2 + $kpiPct*0.2), 2)

  $finalConfidence = $coverage
  if ($confidence -ne $null) { $finalConfidence = [math]::Round([math]::Min($confidence, $coverage), 2) }

  $traceability = @{
    story_pct = $storyPct
    nfr_pct = $nfrPct
    kpi_pct = $kpiPct
    acceptance_pct = $accPct
    coverage = $coverage
    base_confidence = $confidence
    final_confidence = $finalConfidence
    used = ($covSet | Measure-Object).Count
    total = ($features | Measure-Object).Count
  }
} catch { }

$outPath = Join-Path $CurrentPath 'prd_report.md'
## Build copy/paste feedback paragraphs
$feedbackLines = New-Object System.Collections.Generic.List[string]
try {
  $covSet = @($reportData.Features | Where-Object { $_.Scope -eq 'MUST' })
  if ($covSet.Count -eq 0) { $covSet = @($reportData.Features) }
  $needStories = @($covSet | Where-Object { -not $_.Stories -or $_.Stories.Count -eq 0 } | Select-Object -First 3)
  $needAcc = @($covSet | Where-Object { -not $_.AcceptanceTotal -or $_.AcceptanceTotal -lt 3 } | Select-Object -First 3)
  $needNfr = @($covSet | Where-Object { -not $_.NfrAreas -or $_.NfrAreas.Count -eq 0 } | Select-Object -First 3)
  $needKpi = @($covSet | Where-Object { -not $_.Kpis -or $_.Kpis.Count -eq 0 } | Select-Object -First 3)
  $p1 = ''
  if ($traceability -and $traceability.final_confidence -ne $null) {
    $p1 = 'PRD Confidence is ' + $traceability.final_confidence + '%. Coverage across MUST features: stories ' + $traceability.story_pct + '%, acceptance ' + $traceability.acceptance_pct + '%, NFR ' + $traceability.nfr_pct + '%, KPIs ' + $traceability.kpi_pct + '%. Focus on closing the largest gaps first.'
  } elseif ($confidence -ne $null) {
    $p1 = 'PRD Confidence (gates) is ' + $confidence + '%. Add per-feature traceability (stories/NFR/KPIs) to raise overall readiness.'
  }
  if ($p1) { $feedbackLines.Add($p1) }
  $actions = @()
  if ($needStories.Count -gt 0) { $actions += ('add 1–2 user stories to ' + (($needStories | ForEach-Object { $_.Name }) -join ', ')) }
  if ($needAcc.Count -gt 0)     { $actions += ('add ≥3 acceptance bullets to ' + (($needAcc | ForEach-Object { $_.Name }) -join ', ')) }
  if ($needNfr.Count -gt 0)     { $actions += ('tag NFR areas (e.g., Performance/Security/Accessibility) for ' + (($needNfr | ForEach-Object { $_.Name }) -join ', ')) }
  if ($needKpi.Count -gt 0)     { $actions += ('link at least one KPI to ' + (($needKpi | ForEach-Object { $_.Name }) -join ', ')) }
  if ($actions.Count -gt 0) { $feedbackLines.Add(('Next edits: ' + ($actions -join '; ') + '.')) }
  # Deliverables under 100%
  if ($completion) {
    $miss = @(); foreach($k in $completion.Keys){ if ($completion[$k] -lt 100){ $miss += ($k -replace '_',' ') + ' ' + $completion[$k] + '%'} }
    if ($miss.Count -gt 0) { $feedbackLines.Add('Finish deliverables: ' + ($miss -join ', ') + '.') }
  }
} catch { }
$feedbackText = ($feedbackLines -join [Environment]::NewLine)

if ($completion -or $diagnostics -or $confidence -or $nextSteps -or $traceability) {
  $confToShow = if ($traceability -and $traceability.final_confidence -ne $null) { $traceability.final_confidence } else { $confidence }
  if ($null -eq $confToShow) { $confToShow = [double]::NaN }
  New-ForgePRDReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -Completion $completion -Diagnostics $diagnostics -Confidence $confToShow -NextSteps $nextSteps -Traceability $traceability -FeedbackText $feedbackText
} else {
  New-ForgePRDReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -FeedbackText $feedbackText
}

function To-Ascii([string]$s){ if(-not $s){ return '' }; $s = $s -replace "[\u2018\u2019]","'" -replace "[\u201C\u201D]", '"' -replace "[\u2013\u2014\u2212]", '-' -replace "\u2026", '...' ; $chars=$s.ToCharArray(); for($i=0;$i -lt $chars.Length;$i++){ if([int]$chars[$i] -gt 127){ $chars[$i] = [char]'?' } }; return -join $chars }
$content = Get-Content -Path $outPath -Raw -Encoding UTF8 | ForEach-Object { $_ }
$content = To-Ascii $content

Write-Host ''
Write-Host '[PRD_REPORT_START]' -ForegroundColor Cyan
Write-Host $content -ForegroundColor White
Write-Host '[PRD_REPORT_END]' -ForegroundColor Cyan
Write-Host ''
