param([string[]]$Args)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\semantic-validator.ps1"
. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\ia-report-parser.ps1"

$Path = $null
foreach ($a in $Args) { if ($a -match '^--path=(.+)$') { $Path = $matches[1] } }

$CurrentPath = Get-Location
if (-not $Path) {
  if (Test-Path "$CurrentPath\prd.md") { $Path = (Join-Path $CurrentPath 'prd.md') }
}
if (-not (Test-Path $Path)) {
  Write-Host "[ERROR] No PRD found. Provide --path=... or run from a project directory with prd.md" -ForegroundColor Red
  exit 1
}

function To-Ascii([string]$s){ if(-not $s){ return '' }; $s = $s -replace "[\u2018\u2019]","'" -replace "[\u201C\u201D]", '"' -replace "[\u2013\u2014\u2212]", '-' -replace "\u2026", '...' ; $chars=$s.ToCharArray(); for($i=0;$i -lt $chars.Length;$i++){ if([int]$chars[$i] -gt 127){ $chars[$i] = [char]'?' } }; return -join $chars }

# Analyze PRD deliverables and diagnostics
$completion = $null
$diagnostics = $null
try {
  $completion = Get-SemanticPrdCompletion -PrdPath $Path
  $diagnostics = Get-SemanticPrdDiagnostics -PrdPath $Path
} catch {}

# Parse PRD model and raw text
$tempDir = Split-Path $Path -Parent
$reportData = Parse-PRDForReport -ProjectPath $tempDir
$prdText = Get-Content -Path $Path -Raw -Encoding UTF8

$features = @($reportData.Features)
$must = @($features | Where-Object { $_.Scope -eq 'MUST' })
$covSet = if ($must.Count -gt 0) { $must } else { $features }
$tot = ($covSet | Measure-Object).Count; if ($tot -lt 1) { $tot = 1 }

$withStories = (@($covSet | Where-Object { $_.Stories -and $_.Stories.Count -gt 0 }) | Measure-Object).Count
$withNfrs    = (@($covSet | Where-Object { $_.NfrAreas -and $_.NfrAreas.Count -gt 0 }) | Measure-Object).Count
$withKpis    = (@($covSet | Where-Object { $_.Kpis -and $_.Kpis.Count -gt 0 }) | Measure-Object).Count

# Partial acceptance credit
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

$confidence = $null
try { if ($completion) { $confidence = Update-ProjectConfidence -ProjectPath $CurrentPath -Deliverables $completion } } catch {}
$finalConfidence = if ($confidence -ne $null) { [math]::Round([math]::Min($confidence, $coverage), 2) } else { $coverage }

# Prepare structured feedback
$rule = ('=' * 78)
$sep  = ('-' * 78)

# Strengths
$strengths = New-Object System.Collections.Generic.List[string]
if ($completion) {
  foreach($k in $completion.Keys){ if ($completion[$k] -ge 95){ $nm = ($k -replace '_',' '); $strengths.Add("Deliverable near-complete: " + $nm + " (" + $completion[$k] + "%)") } }
}
foreach($f in ($covSet | Where-Object { $_.AcceptanceTotal -ge 3 })) { $strengths.Add("Feature ready: " + $f.Name + " (3+ acceptance)") }
foreach($f in ($covSet | Where-Object { $_.Stories -and $_.Stories.Count -gt 0 -and $_.Kpis -and $_.Kpis.Count -gt 0 })) { $strengths.Add("Feature aligns with KPI: " + $f.Name) }
if ($strengths.Count -eq 0) { $strengths.Add("Base structure present; begin by tightening MUST features.") }

# Improvement Areas (deliverables and traceability)
$improve = New-Object System.Collections.Generic.List[string]
if ($completion) {
  foreach($k in $completion.Keys){ if ($completion[$k] -lt 100){ $nm=($k -replace '_',' '); $improve.Add("Complete '" + $nm + "' to 100% (current: " + $completion[$k] + "%)") } }
}
$missingStories = @($covSet | Where-Object { -not $_.Stories -or $_.Stories.Count -eq 0 }) | Select-Object -First 5
if ($missingStories.Count -gt 0){ $improve.Add("Add user stories for: " + (($missingStories | ForEach-Object { $_.Name }) -join '; ')) }
$weakAcceptance = @($covSet | Where-Object { -not $_.AcceptanceTotal -or $_.AcceptanceTotal -lt 3 }) | Select-Object -First 5
if ($weakAcceptance.Count -gt 0){ $improve.Add("Add acceptance bullets (>=3) for: " + (($weakAcceptance | ForEach-Object { $_.Name + " (" + ([int]($_.AcceptanceTotal)) + ")" }) -join '; ')) }
$missingNfr = @($covSet | Where-Object { -not $_.NfrAreas -or $_.NfrAreas.Count -eq 0 }) | Select-Object -First 5
if ($missingNfr.Count -gt 0){ $improve.Add("Tag NFR areas for: " + (($missingNfr | ForEach-Object { $_.Name }) -join '; ')) }
$missingKpi = @($covSet | Where-Object { -not $_.Kpis -or $_.Kpis.Count -eq 0 }) | Select-Object -First 5
if ($missingKpi.Count -gt 0){ $improve.Add("Link at least one KPI to: " + (($missingKpi | ForEach-Object { $_.Name }) -join '; ')) }

# Ambiguity / vagueness detection (line snippets)
$ambigTerms = '(?i)\b(TBD|to be (decided|defined)|approx|maybe|possibly|likely|usually|often|optimi[sz]e|fast|easy|user[- ]friendly|robust|scalable|etc\.?|and so on|as needed)\b'
$ambigs = @()
foreach($ln in ($prdText -split "`n")){
  $t = $ln.Trim(); if (-not $t) { continue }
  if ($t -match $ambigTerms){ $ambigs += ($t.Substring(0,[Math]::Min(120,$t.Length))) }
  if ($ambigs.Count -ge 6) { break }
}
if ($ambigs.Count -eq 0) { $ambigs = @("No obvious ambiguity phrases detected.") }

# Clash / contradiction detection (heuristics)
$clashes = New-Object System.Collections.Generic.List[string]
try {
  $low = $prdText.ToLower()
  if ($low -match '\boffline\b|air-?gapped|no\s+cloud' -and $low -match '\bcloud\b|saas|sync|real[- ]time'){ $clashes.Add("Offline-only vs Cloud/Realtime sync both present") }
  if ($low -match 'no\s+pii|no\s+personal\s+data' -and $low -match 'email|phone|contact|address'){ $clashes.Add("No PII stated but PII fields mentioned") }
  if ($low -match 'no\s+payments|no\s+billing' -and $low -match 'stripe|billing|subscription|payment'){ $clashes.Add("Payments excluded but payment terms/tools mentioned") }
  if ($low -match 'no\s+accounts|no\s+login' -and $low -match 'login|auth|oauth|signup'){ $clashes.Add("Accounts excluded but authentication present") }
} catch {}
if ($clashes.Count -eq 0) { $clashes.Add("No direct contradictions detected.") }

# Draft acceptance (from stories) for top weak features
$drafts = New-Object System.Collections.Generic.List[string]
foreach($f in ($weakAcceptance | Select-Object -First 3)){
  $story = if ($f.Stories -and $f.Stories.Count -gt 0) { $f.Stories[0] } else { $null }
  if ($story) {
    $drafts.Add("Feature: " + $f.Name)
    $drafts.Add("  - Given a valid user context, When the user performs the primary action from the story, Then the system records the outcome and updates state without errors.")
    $drafts.Add("  - Given an invalid input, When the user submits, Then a clear validation error is shown and no data is persisted.")
    $drafts.Add("  - Given a network disruption, When the user retries, Then the system resumes gracefully and does not duplicate actions.")
  }
}
if ($drafts.Count -eq 0) { $drafts.Add("(No acceptance drafts generated; add a user story first.)") }

# Output: structured, copy-pastable feedback
Write-Host $rule -ForegroundColor Cyan
Write-Host "PRD FEEDBACK SUMMARY" -ForegroundColor Cyan
Write-Host $rule -ForegroundColor Cyan
Write-Host ("PRD Confidence : " + $finalConfidence + "%  |  Traceability (stories:" + $storyPct + "%, acceptance:" + $accPct + "%, NFR:" + $nfrPct + "%, KPIs:" + $kpiPct + "%)") -ForegroundColor Yellow
Write-Host $sep -ForegroundColor DarkGray

Write-Host "WHAT'S WORKING" -ForegroundColor Green
foreach($s in $strengths){ Write-Host ("- " + (To-Ascii $s)) }
Write-Host $sep -ForegroundColor DarkGray

Write-Host "WHAT NEEDS IMPROVEMENT" -ForegroundColor Red
foreach($s in $improve){ Write-Host ("- " + (To-Ascii $s)) }
Write-Host $sep -ForegroundColor DarkGray

Write-Host "AMBIGUITIES / VAGUENESS (EXTRACTS)" -ForegroundColor Yellow
foreach($a in $ambigs){ Write-Host ("- " + (To-Ascii $a)) }
Write-Host $sep -ForegroundColor DarkGray

Write-Host "POTENTIAL CLASHES / CONTRADICTIONS" -ForegroundColor Magenta
foreach($c in $clashes){ Write-Host ("- " + (To-Ascii $c)) }
Write-Host $sep -ForegroundColor DarkGray

Write-Host "SUGGESTED ACCEPTANCE DRAFTS (SEED)" -ForegroundColor Cyan
foreach($d in $drafts){ Write-Host (To-Ascii $d) }
Write-Host $sep -ForegroundColor DarkGray

if ($diagnostics) {
  Write-Host "TOP SEMANTIC SUGGESTIONS" -ForegroundColor Cyan
  $shown=0
  foreach($d in $diagnostics){ if ($d.suggestions -and $d.suggestions.Count -gt 0){ foreach($s in ($d.suggestions | Select-Object -First 2)){ Write-Host ("- " + (To-Ascii $s)) }; $shown+=2; if ($shown -ge 8) { break } } }
  Write-Host $sep -ForegroundColor DarkGray
}

Write-Host "COPY/PASTE THIS INTO YOUR GPT:" -ForegroundColor White
$prompt = @()
$prompt += "Improve the PRD using the structured feedback above."
$prompt += ("Target Confidence: " + $finalConfidence + "%. Prioritize the 'WHAT NEEDS IMPROVEMENT' items.")
$prompt += "Rewrite ambiguous lines, resolve contradictions, add user stories and acceptance criteria (3+ bullets per MUST), tag NFR areas, and link at least one KPI per MUST feature."
Write-Host (To-Ascii ($prompt -join ' ')) -ForegroundColor White

# --- Deliverable Audit (integrated) ---
Write-Host ''
Write-Host $rule -ForegroundColor Cyan
Write-Host "DELIVERABLE AUDIT (Confidence Checker Rules)" -ForegroundColor Cyan
Write-Host $rule -ForegroundColor Cyan
$rules = Get-SemanticRules
$sectionMap = @(
  @{ key = 'problem_statement'; pattern = '(Executive Summary|Problem)'; name = 'Problem Statement' },
  @{ key = 'user_personas';     pattern = '(User Personas|Personas)';    name = 'User Personas' },
  @{ key = 'user_stories';      pattern = '(User Stories|Stories)';      name = 'User Stories' },
  @{ key = 'feature_list';      pattern = '(Features|Requirements|Functional Requirements|Feature List)'; name = 'Feature List' },
  @{ key = 'tech_stack';        pattern = '(Tech Stack|Technical Foundation)'; name = 'Tech Stack' },
  @{ key = 'success_metrics';   pattern = '(Success Metrics|KPIs|Objectives|Outcomes)'; name = 'Success Metrics' },
  @{ key = 'mvp_scope';         pattern = '(MVP|Roadmap|Scope)';         name = 'MVP Scope' },
  @{ key = 'non_functional';    pattern = '(Non-Functional|Quality Attributes|Constraints)'; name = 'Non-Functional' }
)
function Get-Section([string]$pat){ return (Get-PrdSection -Content $prdText -SectionPattern $pat) }
foreach ($entry in $sectionMap) {
  $section = Get-Section $entry.pattern
  $rule = $rules.deliverables.($entry.key)
  $label = $entry.name
  if (-not $rule) { continue }
  Write-Host ('-- ' + $label) -ForegroundColor Cyan
  if (-not $section) {
    Write-Host ('  Section not found by pattern: ' + $entry.pattern) -ForegroundColor Yellow
    Write-Host ''
    continue
  }
  $m = Measure-SemanticSection -SectionContent $section -Rules $rule
  Write-Host ('  Completion: ' + $m.percentage + '%') -ForegroundColor Green
  foreach($elem in $rule.required_elements){
    $status = 'PASS'
    $found = $null
    if ($elem.type -eq 'count') {
      $total = 0
      foreach($pat in $elem.patterns){ $total += ([regex]::Matches($section, "(?i)"+$pat)).Count }
      if ($elem.id -eq 'acceptance_criteria') { $total += ([regex]::Matches($section, '(?im)^\s*(Given|When|Then)\b')).Count }
      if ($elem.id -eq 'story_count' -or $elem.id -eq 'story_format') {
        $alt1 = ([regex]::Matches($section, '(?im)^\s*As\s+an?\s+.+?\s+(I\s+(want|can|need)\s+.+?)\s+(so\s+(that|I\s+can)\s+.+)$')).Count
        $alt2 = ([regex]::Matches($section, '(?im)^\s*In\s+order\s+to\s+.+,\s*As\s+an?\s+.+,\s*I\s+(want|can|need)\s+.+$')).Count
        $total = [Math]::Max($total, $alt1 + $alt2)
      }
      $found = $total
      if ($elem.PSObject.Properties.Name -contains 'minimum' -and $total -lt [int]$elem.minimum) { $status='FAIL' }
    } else {
      $ok = $false
      foreach($pat in $elem.patterns){ if ($section -match ("(?i)"+$pat)) { $ok=$true; break } }
      if ($ok) { $status = 'PASS' } else { $status = 'FAIL' }
    }
    $line = '    - ' + $elem.id + ' : ' + $status
    if ($found -ne $null) {
      $minPart = ''
      if ($elem.PSObject.Properties.Name -contains 'minimum' -and $elem.minimum) { $minPart = '/min ' + $elem.minimum }
      $line += (' (found ' + $found + ' ' + $minPart).TrimEnd() + ')'
    }
    $color = 'Yellow'
    if ($status -eq 'PASS') { $color = 'Green' }
    Write-Host $line -ForegroundColor $color
  }
  Write-Host ''
}

# Feature traceability snapshot
Write-Host $rule -ForegroundColor Cyan
Write-Host "FEATURE TRACEABILITY SNAPSHOT (Top 10)" -ForegroundColor Cyan
Write-Host $rule -ForegroundColor Cyan
$max = [Math]::Min(10, $reportData.Features.Count)
for($i=0;$i -lt $max;$i++){
  $f = $reportData.Features[$i]
  $desc = if ($f.PSObject.Properties.Name -contains 'Description' -and $f.Description) { 'Y' } else { 'N' }
  $stories = if ($f.Stories) { $f.Stories.Count } else { 0 }
  $acc = if ($f.PSObject.Properties.Name -contains 'AcceptanceTotal') { $f.AcceptanceTotal } else { 0 }
  $nfr = if ($f.NfrAreas) { $f.NfrAreas.Count } else { 0 }
  $kpi = if ($f.Kpis) { $f.Kpis.Count } else { 0 }
  Write-Host (' - ' + $f.Name + ' | Desc:' + $desc + ' | Stories:' + $stories + ' | Acc:' + $acc + ' | NFR:' + $nfr + ' | KPI:' + $kpi)
}
