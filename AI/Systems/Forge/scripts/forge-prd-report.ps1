param([string[]]$Args)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\prd-completeness-validator.ps1"
. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\prd-semantic-analyzer.ps1"
. "$ForgeRoot\lib\readiness.ps1"

$CurrentPath = Get-Location
$prdPath = Join-Path $CurrentPath 'prd.md'

if (-not (Test-Path $prdPath)) {
  Write-Host "[ERROR] No project found. Run this from a project directory with prd.md" -ForegroundColor Red
  exit 1
}

# Parse flags
$width = 78
foreach ($a in $Args) { if ($a -match '^--width=(\d+)$') { $width = [int]$matches[1] } }

# Enforce pipeline: refresh state, then render from state
Refresh-ProjectState -ProjectPath $CurrentPath | Out-Null
$state = Get-ProjectState -ProjectPath $CurrentPath
$completion = $state.deliverables
$confidence = $state.confidence
$semanticAnalysis = $state.semantic_analysis
$quality = $state.quality
$nextSteps = Get-NextSteps -State $state

# Diagnostics (section suggestions) from current PRD
$diagnostics = $null
try { $diagnostics = Get-SemanticPrdDiagnostics -PrdPath $prdPath } catch {}

# Build report
$rule = ('=' * $width)
$sep  = ('-' * $width)

function To-Ascii([string]$s){
  if(-not $s){ return '' }
  $s = $s -replace "[\u2018\u2019]","'" -replace "[\u201C\u201D]", '"' -replace "[\u2013\u2014\u2212]", '-' -replace "\u2026", '...'
  $chars=$s.ToCharArray()
  for($i=0;$i -lt $chars.Length;$i++){
    if([int]$chars[$i] -gt 127){ $chars[$i] = [char]'?' }
  }
  return -join $chars
}

$lines = New-Object System.Collections.Generic.List[string]

# Header
$lines.Add($rule)
$lines.Add('PRD ANALYSIS REPORT')
$lines.Add($rule)
$lines.Add('')

# Confidence Summary
$lines.Add('CONFIDENCE & QUALITY SUMMARY')
$lines.Add($sep)
if ($confidence -ne $null) { $lines.Add("Overall Confidence: $confidence% (Completeness)") } else { $lines.Add("Overall Confidence: N/A") }
if ($quality -ne $null)    { $lines.Add("Overall Quality: $quality% (Semantic)") } else { $lines.Add("Overall Quality: N/A") }
$lines.Add('')

# Deliverable Breakdown
if ($completion) {
  $lines.Add('DELIVERABLE COMPLETION')
  $lines.Add($sep)
  foreach ($k in ($completion.Keys | Sort-Object)) {
    $name = ($k -replace '_', ' ')
    $pct = $completion[$k]
    $status = if ($pct -ge 100) { 'COMPLETE' } elseif ($pct -ge 75) { 'GOOD' } elseif ($pct -ge 50) { 'PARTIAL' } else { 'NEEDS WORK' }
    $lines.Add("  - ${name}: ${pct}% [$status]")
  }
  $lines.Add('')
}

# Semantic Analysis
if ($semanticAnalysis) {
  $hasIssues = $false
  $hasIssues = $hasIssues -or ($semanticAnalysis.contradictions -and $semanticAnalysis.contradictions.Count -gt 0)
  $hasIssues = $hasIssues -or ($semanticAnalysis.impossibilities -and $semanticAnalysis.impossibilities.Count -gt 0)
  $hasIssues = $hasIssues -or ($semanticAnalysis.implied_dependencies -and $semanticAnalysis.implied_dependencies.Count -gt 0)
  $hasIssues = $hasIssues -or ($semanticAnalysis.vague_features -and $semanticAnalysis.vague_features.Count -gt 0)

  if ($hasIssues) {
    $lines.Add('SEMANTIC ANALYSIS')
    $lines.Add($sep)

    if ($semanticAnalysis.contradictions -and $semanticAnalysis.contradictions.Count -gt 0) {
      $lines.Add('Contradictions Found:')
      foreach ($c in $semanticAnalysis.contradictions) {
        $lines.Add("  - $c")
      }
      $lines.Add('')
    }

    if ($semanticAnalysis.impossibilities -and $semanticAnalysis.impossibilities.Count -gt 0) {
      $lines.Add('Impossibilities Found:')
      foreach ($i in $semanticAnalysis.impossibilities) {
        $lines.Add("  - $i")
      }
      $lines.Add('')
    }

    if ($semanticAnalysis.implied_dependencies -and $semanticAnalysis.implied_dependencies.Count -gt 0) {
      $lines.Add('Implied Dependencies:')
      foreach ($d in $semanticAnalysis.implied_dependencies) {
        $lines.Add("  - $d")
      }
      $lines.Add('')
    }

    if ($semanticAnalysis.vague_features -and $semanticAnalysis.vague_features.Count -gt 0) {
      $lines.Add('Vague/Incomplete Features:')
      foreach ($v in ($semanticAnalysis.vague_features | Select-Object -First 5)) {
        if ($v -is [hashtable] -or $v -is [pscustomobject]) {
          $name = if ($v.Name) { [string]$v.Name } elseif ($v['Name']) { [string]$v['Name'] } else { '[Unnamed Feature]' }
          $issuesVal = if ($v.Issues) { $v.Issues } elseif ($v['Issues']) { $v['Issues'] } else { @() }
          $lines.Add("  - $name")
          if ($issuesVal) {
            foreach ($iss in @($issuesVal)) { $lines.Add("      * " + [string]$iss) }
          }
        } else {
          $lines.Add("  - " + [string]$v)
        }
      }
      $lines.Add('')
    }
  } else {
    $lines.Add('SEMANTIC ANALYSIS')
    $lines.Add($sep)
    $lines.Add('No semantic issues detected!')
    $lines.Add('')
  }
}

# Next Steps
if ($nextSteps -and $nextSteps.Count -gt 0) {
  $lines.Add('NEXT STEPS')
  $lines.Add($sep)
  foreach ($step in $nextSteps) {
    if ($step -is [hashtable]) {
      $name = ($step.deliverable -replace '_', ' ')
      $impact = if ($step.impact) { "+$($step.impact)%" } else { "" }
      $lines.Add("  - Complete '$name' to 100% (currently $($step.current)%) $impact")
    } else {
      $lines.Add("  - $step")
    }
  }
  $lines.Add('')
}

# Diagnostics
if ($diagnostics) {
  $hasContent = $false
  foreach ($d in $diagnostics) {
    if ($d.name -and $d.suggestions -and $d.suggestions.Count -gt 0) {
      $hasContent = $true
      break
    }
  }

  if ($hasContent) {
    $lines.Add('DETAILED DIAGNOSTICS')
    $lines.Add($sep)
    foreach ($d in $diagnostics) {
      if ($d.name -and $d.suggestions -and $d.suggestions.Count -gt 0) {
        $lines.Add("$($d.name):")
        foreach ($s in $d.suggestions) {
          $lines.Add("  - $s")
        }
        $lines.Add('')
      }
    }
  }
}

# Footer
$lines.Add($rule)
$lines.Add('END OF REPORT')
$lines.Add($rule)

# Write to file
$outPath = Join-Path $CurrentPath 'prd_report.md'
$content = ($lines -join "`n")
$content = To-Ascii $content
[System.IO.File]::WriteAllText($outPath, $content, [System.Text.Encoding]::UTF8)

# Display to console
Write-Host ''
Write-Host '[PRD_REPORT_START]' -ForegroundColor Cyan
Write-Host $content -ForegroundColor White
Write-Host '[PRD_REPORT_END]' -ForegroundColor Cyan
Write-Host ''
Write-Host "[OK] Report saved to: prd_report.md" -ForegroundColor Green
