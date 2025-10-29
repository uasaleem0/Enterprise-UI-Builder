param([string[]]$Args)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\prd-completeness-validator.ps1"
. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\prd-semantic-analyzer.ps1"
. "$ForgeRoot\lib\readiness.ps1"

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

# Get PRD content
$prdText = Get-Content -Path $Path -Raw -Encoding UTF8

# Enforce pipeline: refresh state, then read from state
Refresh-ProjectState -ProjectPath $CurrentPath | Out-Null
$state = Get-ProjectState -ProjectPath $CurrentPath
$completion = $state.deliverables
$confidence = $state.confidence
$semanticAnalysis = $state.semantic_analysis
# Section-level diagnostics for actionable suggestions
$diagnostics = $null
try { $diagnostics = Get-SemanticPrdDiagnostics -PrdPath $Path } catch {}

# Prepare structured feedback
$rule = ('=' * 78)
$sep  = ('-' * 78)

# Strengths - based on deliverable completion
$strengths = New-Object System.Collections.Generic.List[string]
if ($completion) {
  foreach($k in $completion.Keys){
    if ($completion[$k] -ge 95){
      $nm = ($k -replace '_',' ')
      $strengths.Add("Deliverable near-complete: " + $nm + " (" + $completion[$k] + "%)")
    }
  }
}
if ($semanticAnalysis) {
  if (-not $semanticAnalysis.contradictions -or $semanticAnalysis.contradictions.Count -eq 0) {
    $strengths.Add("No contradictions detected")
  }
  if (-not $semanticAnalysis.impossibilities -or $semanticAnalysis.impossibilities.Count -eq 0) {
    $strengths.Add("No impossibilities detected")
  }
}
if ($strengths.Count -eq 0) {
  $strengths.Add("Base structure present; improve deliverable completion.")
}

# Improvement Areas - based on deliverables and semantic analysis
$improve = New-Object System.Collections.Generic.List[string]
if ($completion) {
  foreach($k in $completion.Keys){
    if ($completion[$k] -lt 100){
      $nm=($k -replace '_',' ')
      $improve.Add("Complete '" + $nm + "' to 100% (current: " + $completion[$k] + "%)")
    }
  }
}

# Add semantic issues to improvements
if ($semanticAnalysis) {
  if ($semanticAnalysis.contradictions -and $semanticAnalysis.contradictions.Count -gt 0) {
    foreach ($c in $semanticAnalysis.contradictions) {
      $improve.Add("Resolve contradiction: " + $c)
    }
  }
  if ($semanticAnalysis.impossibilities -and $semanticAnalysis.impossibilities.Count -gt 0) {
    foreach ($i in $semanticAnalysis.impossibilities) {
      $improve.Add("Fix impossibility: " + $i)
    }
  }
  if ($semanticAnalysis.implied_dependencies -and $semanticAnalysis.implied_dependencies.Count -gt 0) {
    foreach ($d in ($semanticAnalysis.implied_dependencies | Select-Object -First 3)) {
      $improve.Add("Add dependency: " + $d)
    }
  }
}

if ($improve.Count -eq 0) {
  $improve.Add("PRD is complete! Ready for implementation.")
}

# Ambiguity / vagueness detection
$ambigTerms = '(?i)\b(TBD|to be (decided|defined)|approx|maybe|possibly|likely|usually|often|optimi[sz]e|fast|easy|user[- ]friendly|robust|scalable|etc\.?|and so on|as needed)\b'
$ambigs = @()
foreach($ln in ($prdText -split "`n")){
  $t = $ln.Trim(); if (-not $t) { continue }
  if ($t -match $ambigTerms){
    $ambigs += ($t.Substring(0,[Math]::Min(120,$t.Length)))
  }
  if ($ambigs.Count -ge 6) { break }
}
if ($ambigs.Count -eq 0) { $ambigs = @("No obvious ambiguity phrases detected.") }

# Clash / contradiction detection (basic heuristics)
$clashes = New-Object System.Collections.Generic.List[string]
if ($semanticAnalysis -and $semanticAnalysis.contradictions -and $semanticAnalysis.contradictions.Count -gt 0) {
  foreach ($c in $semanticAnalysis.contradictions) {
    $clashes.Add($c)
  }
}
if ($clashes.Count -eq 0) { $clashes.Add("No direct contradictions detected.") }

# Output: structured, copy-pastable feedback
Write-Host $rule -ForegroundColor Cyan
Write-Host "PRD FEEDBACK SUMMARY" -ForegroundColor Cyan
Write-Host $rule -ForegroundColor Cyan
if ($confidence -ne $null) {
  Write-Host ("PRD Confidence : " + $confidence + "%") -ForegroundColor Yellow
} else {
  Write-Host "PRD Confidence : N/A" -ForegroundColor Yellow
}
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

if ($diagnostics) {
  Write-Host "TOP SEMANTIC SUGGESTIONS" -ForegroundColor Cyan
  $shown=0
  foreach($d in $diagnostics){
    if ($d.suggestions -and $d.suggestions.Count -gt 0){
      foreach($s in ($d.suggestions | Select-Object -First 2)){
        Write-Host ("- " + (To-Ascii $s))
      }
      $shown+=2
      if ($shown -ge 8) { break }
    }
  }
  Write-Host $sep -ForegroundColor DarkGray
}

Write-Host "COPY/PASTE THIS INTO YOUR GPT:" -ForegroundColor White
Write-Host $sep -ForegroundColor DarkGray

# Build comprehensive single-paragraph feedback
$gpPrompt = @()
if ($confidence -ne $null) {
  $gpPrompt += "PRD Confidence: $confidence%."
} else {
  $gpPrompt += "PRD Confidence: Unable to calculate."
}

# Semantic issues first (highest priority)
if ($semanticAnalysis) {
    if ($semanticAnalysis.contradictions -and $semanticAnalysis.contradictions.Count -gt 0) {
        $gpPrompt += "Contradictions: " + ($semanticAnalysis.contradictions -join '; ') + "."
    }
    if ($semanticAnalysis.impossibilities -and $semanticAnalysis.impossibilities.Count -gt 0) {
        $gpPrompt += "Impossibilities: " + ($semanticAnalysis.impossibilities -join '; ') + "."
    }
    if ($semanticAnalysis.implied_dependencies -and $semanticAnalysis.implied_dependencies.Count -gt 0) {
        $topDeps = $semanticAnalysis.implied_dependencies | Select-Object -First 5
        $gpPrompt += "Add missing dependencies: " + ($topDeps -join '; ') + "."
    }
}

# Deliverable completion
if ($completion) {
    $incomplete = @()
    foreach ($k in $completion.Keys) {
        if ($completion[$k] -lt 100) {
            $incomplete += ($k -replace '_', ' ') + " to 100% (currently $($completion[$k])%)"
        }
    }
    if ($incomplete.Count -gt 0) {
        $gpPrompt += "Complete deliverables: " + ($incomplete -join '; ') + "."
    }
}

$gpPrompt += "Target: 95%+ confidence for IA phase."

Write-Host (To-Ascii ($gpPrompt -join ' ')) -ForegroundColor White
Write-Host $sep -ForegroundColor DarkGray

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
  $ruleSet = $rules.deliverables.($entry.key)
  $label = $entry.name
  if (-not $ruleSet) { continue }
  Write-Host ('-- ' + $label) -ForegroundColor Cyan
  if (-not $section) {
    Write-Host ('  Section not found by pattern: ' + $entry.pattern) -ForegroundColor Yellow
    Write-Host ''
    continue
  }
  $m = Measure-SemanticSection -SectionContent $section -Rules $ruleSet
  Write-Host ('  Completion: ' + $m.percentage + '%') -ForegroundColor Green
  foreach($elem in $ruleSet.required_elements){
    $status = 'PASS'
    $found = $null
    if ($elem.type -eq 'count') {
      $total = 0
      foreach($pat in $elem.patterns){ $total += ([regex]::Matches($section, "(?im)"+$pat)).Count }
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

Write-Host $rule -ForegroundColor Cyan
Write-Host "END OF FEEDBACK" -ForegroundColor Cyan
Write-Host $rule -ForegroundColor Cyan
