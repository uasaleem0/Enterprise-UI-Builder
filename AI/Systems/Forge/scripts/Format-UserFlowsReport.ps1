function New-ForgeUserFlowsReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReportData,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [switch]$Plain,
        [int]$Width = 78,
        [switch]$NoFence,
        [switch]$NoHr
    )

    $isPlain = $Plain.IsPresent
    $lines = New-Object System.Collections.Generic.List[string]

    function Normalize-Ascii {
        param([string]$Text)
        if (-not $Text) { return '' }
        $s = $Text
        $s = $s -replace '\u2018|\u2019', "'" -replace '\u201C|\u201D', '"'
        $s = $s -replace '\u2013|\u2014|\u2212', '-'
        $s = $s -replace '\u2026', '...'
        $s = $s -replace '([^\w])\?([^\w])', '$1->$2'
        $s = $s -replace '(?<a>\d)\?(?<b>\d)', '${a}-${b}'
        $s = $s -replace '(?<a>[A-Za-z]{3})\?(?<b>[A-Za-z]{3})', '${a}-${b}'
        $s = $s -replace '(?<w>\w)\?s\b', "${w}'s"
        return $s
    }

    function Build-AsciiFlowDiagram {
        param([object[]]$Steps, [int]$MaxWidth = 60)
        $o = New-Object System.Collections.Generic.List[string]

        if (-not $Steps -or $Steps.Count -eq 0) {
            $o.Add('  (No steps defined)')
            return ($o -join [Environment]::NewLine)
        }

        # Filter to only strings and normalize
        $clean = @()
        foreach($st in $Steps){
            if ($st -is [string] -and $st) {
                $clean += (Normalize-Ascii $st)
            }
        }

        if ($clean.Count -eq 0) {
            $o.Add('  (No steps defined)')
            return ($o -join [Environment]::NewLine)
        }

        # Find max width for boxes
        $maxLen = 0
        foreach($step in $clean) {
            if ($step.Length -gt $maxLen) { $maxLen = $step.Length }
        }
        $boxWidth = [Math]::Min($maxLen + 4, $MaxWidth)

        # Build diagram with boxes and arrows
        for ($i=0; $i -lt $clean.Count; $i++){
            $step = $clean[$i]
            $label = $step

            # Truncate if too long
            if ($label.Length -gt ($boxWidth - 4)) {
                $label = $label.Substring(0, $boxWidth - 7) + '...'
            }

            # Draw box
            $o.Add('+' + ('-' * ($boxWidth - 2)) + '+')
            $padding = ' ' * (($boxWidth - 2 - $label.Length) / 2)
            $o.Add('|' + $padding + $label + $padding + ('  '[$padding.Length + $label.Length + 1 -ge ($boxWidth - 1)]) + '|')
            $o.Add('+' + ('-' * ($boxWidth - 2)) + '+')

            # Add arrow if not last
            if ($i -lt $clean.Count - 1){
                $arrowIndent = ' ' * ([Math]::Floor(($boxWidth - 2) / 2))
                $o.Add($arrowIndent + '|')
                $o.Add($arrowIndent + 'v')
            }
        }

        return ($o -join [Environment]::NewLine)
    }

    # Header with summary
    $flowCount = ($ReportData.Flows | Where-Object { $_ }).Count
    $lines.Add('+---------------------------------------------------------------+')
    $pname = (Normalize-Ascii $ReportData.ProjectName).PadRight(22)
    $lines.Add('|           USER FLOWS REPORT: ' + $pname + '           |')
    $lines.Add('|                      Flows: ' + $flowCount.ToString().PadLeft(2) + '                             |')
    $lines.Add('+---------------------------------------------------------------+')
    $lines.Add('')
    $lines.Add('')

    # Part 1: User Flow & Feature Summary
    $lines.Add('===============================================================')
    $lines.Add('  PART 1: USER FLOW & FEATURE SUMMARY')
    $lines.Add('===============================================================')
    $lines.Add('')

    # Section 1a: User Flow Overview
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('  USER FLOW OVERVIEW')
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('')

    foreach ($flow in ($ReportData.Flows | Where-Object { $_ })) {
        $fName = Normalize-Ascii $flow.Name
        $fGoal = if ($flow.Goal) { Normalize-Ascii $flow.Goal } else { '' }
        $fPurpose = Normalize-Ascii $flow.Purpose

        $lines.Add('Flow: ' + $fName)
        if ($fGoal) { $lines.Add('  Goal: ' + $fGoal) }
        if ($fPurpose) { $lines.Add('  Purpose: ' + $fPurpose) }
        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
    }

    # Section 1b: Feature-to-Flow Mapping
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('  FEATURE-TO-FLOW MAPPING')
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('')

    if ($ReportData.FeaturesMapping -and $ReportData.FeaturesMapping.Count -gt 0) {
        foreach ($map in ($ReportData.FeaturesMapping | Where-Object { $_ })) {
            $mFeature = Normalize-Ascii $map.Feature
            $mDesc = Normalize-Ascii $map.Description
            $mFlow = Normalize-Ascii $map.Flow

            $lines.Add('Feature: ' + $mFeature)
            if ($mDesc) { $lines.Add('  Description: ' + $mDesc) }
            $lines.Add('  Implementation: ' + $mFlow)
            $lines.Add('')
            $lines.Add('---')
            $lines.Add('')
        }
    } else {
        $lines.Add('(No feature-to-flow mappings available)')
        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
    }

    # Section 1c: Future Features
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('  FUTURE FEATURES (OUT OF SCOPE FOR V1)')
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('')

    if ($ReportData.FutureFeatures -and $ReportData.FutureFeatures.Count -gt 0) {
        foreach ($f in ($ReportData.FutureFeatures | Where-Object { $_ })) {
            $lines.Add('  * ' + (Normalize-Ascii $f))
        }
    } else {
        $lines.Add('(No future features defined)')
    }

    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')

    # Section 1d: PRD Feature Cross-Reference
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('  PRD FEATURE CROSS-REFERENCE')
    $lines.Add('---------------------------------------------------------------')
    $lines.Add('')
    $lines.Add('Feature -> Flow Mapping (by name/route semantics)')
    $lines.Add('')

    if ($ReportData.PrdFeatureCoverage -and $ReportData.PrdFeatureCoverage.Count -gt 0) {
        foreach ($pc in $ReportData.PrdFeatureCoverage) {
            $f = Normalize-Ascii $pc.Feature
            $scope = if ($pc.Scope) { $pc.Scope.ToUpper() } else { 'UNKNOWN' }
            $flows = if ($pc.Flows -and $pc.Flows.Count -gt 0) { ($pc.Flows -join ', ') } else { 'Not Covered' }
            $note = Normalize-Ascii $pc.Notes

            $lines.Add('- Feature: ' + $f)
            $lines.Add('  Scope : ' + $scope)
            $lines.Add('  Flows : ' + (Normalize-Ascii $flows))
            if ($note) { $lines.Add('  Notes : ' + $note) }
            $lines.Add('')
        }
    } else {
        $lines.Add('(No PRD features found to cross-reference)')
        $lines.Add('')
    }

    $lines.Add('---')
    $lines.Add('')

    # Part 2: Detailed Flow Analysis
    $lines.Add('===============================================================')
    $lines.Add('  PART 2: DETAILED FLOW ANALYSIS')
    $lines.Add('===============================================================')
    $lines.Add('')

    foreach ($flow in ($ReportData.Flows | Where-Object { $_ })) {
        $fName = Normalize-Ascii $flow.Name
        $fGoal = if ($flow.Goal) { Normalize-Ascii $flow.Goal } else { '' }
        $fPurpose = Normalize-Ascii $flow.Purpose
        $entry = Normalize-Ascii $flow.EntryPoint
        $precon = Normalize-Ascii $flow.PreCondition
        $succ = Normalize-Ascii $flow.SuccessScenario

        $lines.Add('---------------------------------------------------------------')
        $lines.Add('FLOW: ' + $fName)
        $lines.Add('---------------------------------------------------------------')

        if ($fGoal) { $lines.Add('Goal: ' + $fGoal) }
        if ($fPurpose) { $lines.Add('Purpose: ' + $fPurpose) }

        # Context & Pre-conditions
        $lines.Add('')
        $lines.Add('Context & Pre-conditions:')
        $lines.Add('  Entry Point: ' + $entry)
        if ($flow.PreCondition) { $lines.Add('  Pre-condition: ' + $precon) }

        # Visual Flow Diagram
        $lines.Add('')
        $lines.Add('Visual Flow:')
        $lines.Add('')
        $diagram = Build-AsciiFlowDiagram -Steps $flow.Steps -MaxWidth $Width
        $lines.Add($diagram)

        # Data Interaction
        $lines.Add('')
        $lines.Add('Data Interaction:')

        $lines.Add('  Data Read:')
        if ($flow.DataRead -and $flow.DataRead.Count -gt 0) {
            foreach ($e in ($flow.DataRead | Where-Object { $_ })) {
                $lines.Add('    - ' + (Normalize-Ascii $e))
            }
        } else {
            $lines.Add('    (none)')
        }

        if ($flow.DataCreated -and $flow.DataCreated.Count -gt 0) {
            $lines.Add('  Data Created:')
            foreach ($e in $flow.DataCreated) {
                $lines.Add('    - ' + (Normalize-Ascii $e))
            }
        }

        if ($flow.DataUpdated -and $flow.DataUpdated.Count -gt 0) {
            $lines.Add('  Data Updated:')
            foreach ($e in $flow.DataUpdated) {
                $lines.Add('    - ' + (Normalize-Ascii $e))
            }
        }

        # Scenario Checklist
        $lines.Add('')
        $lines.Add('Scenario Checklist:')
        if ($succ) { $lines.Add('  Success Scenario: ' + $succ) }

        if ($flow.ErrorStates -and $flow.ErrorStates.Count -gt 0) {
            $lines.Add('  Error States Handled:')
            foreach ($er in $flow.ErrorStates) {
                if ($er -is [string]) {
                    $lines.Add('    - ' + (Normalize-Ascii $er))
                }
            }
        }

        if ($flow.EmptyStates) {
            $lines.Add('  Empty States Handled: ' + (Normalize-Ascii $flow.EmptyStates))
        }

        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
    }

    # Write output
    $out = $lines -join [Environment]::NewLine
    Set-Content -Path $OutputPath -Value $out -Encoding UTF8
    Write-Host 'Successfully generated user flows report at: ' $OutputPath
}
