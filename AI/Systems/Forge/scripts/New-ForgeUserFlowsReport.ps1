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
        param([object[]]$Steps, [int]$MaxWidth = 78)
        $o = New-Object System.Collections.Generic.List[string]
        if (-not $Steps -or $Steps.Count -eq 0) { $o.Add('(No steps identified)'); return ($o -join [Environment]::NewLine) }
        $clean = @(); foreach($st in $Steps){ if ($st -is [string]) { $clean += (Normalize-Ascii $st) } else { $clean += $st } }
        $maxRoute = 0; foreach($r in $clean){ if ($r -is [string]){ if ($r.Length -gt $maxRoute) { $maxRoute = $r.Length } } }
        $inner = [Math]::Min([Math]::Max($maxRoute + 2, 18), $MaxWidth - 2)
        for ($i=0; $i -lt $clean.Count; $i++){
            $r = $clean[$i]
            if ($r -is [string]){
                $label = $r
                if ($label.Length -gt ($inner-2)) { $label = $label.Substring(0, $inner-5) + '...' }
                $o.Add('+' + ('-' * $inner) + '+')
                $pad = ' ' * ($inner - 2 - $label.Length)
                $o.Add('| ' + $label + $pad + ' |')
                $o.Add('+' + ('-' * $inner) + '+')
                if ($i -lt $clean.Count-1){
                    $indent = ' ' * ([Math]::Floor($inner/2))
                    $o.Add($indent + '|')
                    $o.Add($indent + 'v')
                }
            } elseif ($r -is [pscustomobject] -and $r.PSObject.Properties.Name -contains 'kind' -and $r.kind -eq 'decision') {
                $msg = if ($r.PSObject.Properties.Name -contains 'message') { Normalize-Ascii $r.message } else { 'decision' }
                $o.Add('(Decision: ' + $msg + ')')
                if ($r.PSObject.Properties.Name -contains 'branches'){
                    foreach($b in $r.branches){
                        $o.Add('  +--> ' + (Normalize-Ascii $b))
                    }
                }
            }
        }
        return ($o -join [Environment]::NewLine)
    }

    # Part 1: Summary
    if ($isPlain) {
        $lines.Add('')
        $lines.Add('PART 1: USER FLOW & FEATURE SUMMARY')
        $lines.Add('')
        $lines.Add('=================================================================')
        $lines.Add('USER FLOW OVERVIEW')
        $lines.Add('=================================================================')
        $lines.Add('')
    } else {
        $lines.Add('---')
        $lines.Add('')
        $lines.Add('### **Part 1: User Flow & Feature Summary**')
        $lines.Add('')
        $lines.Add('=================================================================')
        $lines.Add('**USER FLOW OVERVIEW**')
        $lines.Add('=================================================================')
        $lines.Add('')
    }

    foreach ($flow in ($ReportData.Flows | Where-Object { $_ })) {
        $fName = Normalize-Ascii $flow.Name
        $fPurpose = Normalize-Ascii $flow.Purpose
        if ($isPlain) {
            $lines.Add('Flow: ' + $fName)
            if ($fPurpose) { $lines.Add('  Purpose: ' + $fPurpose) }
        } else {
            $lines.Add('**Flow: `' + $fName + '`**')
            $lines.Add('*   **Purpose:** ' + ($fPurpose))
        }
        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
    }

    if ($isPlain) {
        $lines.Add('=================================================================')
        $lines.Add('FEATURE-TO-FLOW MAPPING')
        $lines.Add('=================================================================')
        $lines.Add('')
    } else {
        $lines.Add('=================================================================')
        $lines.Add('**FEATURE-TO-FLOW MAPPING**')
        $lines.Add('=================================================================')
        $lines.Add('')
    }

    foreach ($map in ($ReportData.FeaturesMapping | Where-Object { $_ })) {
        $mFeature = Normalize-Ascii $map.Feature
        $mDesc = Normalize-Ascii $map.Description
        $mFlow = Normalize-Ascii $map.Flow
        if ($isPlain) {
            $lines.Add('Feature: ' + $mFeature)
            if ($mDesc) { $lines.Add('  Description: ' + $mDesc) }
            $lines.Add('  Implementation: ' + $mFlow)
        } else {
            $lines.Add('**Feature: `' + $mFeature + '`**')
            $lines.Add('*   **Description:** ' + ($mDesc))
            $lines.Add('*   **Implementation:** `' + ($mFlow) + '`')
        }
        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
    }

    if ($isPlain) {
        $lines.Add('FUTURE FEATURES (OUT OF SCOPE FOR V1)')
    } else {
        $lines.Add('#### **Future Features (Out of Scope for v1)**')
    }
    foreach ($f in ($ReportData.FutureFeatures | Where-Object { $_ })) {
        if ($isPlain) {
            $lines.Add('  - ' + $f)
        } else {
            $lines.Add('*   **Feature:** `' + $f + '`')
            $lines.Add('    *   **Description:** ')
            $lines.Add('    *   **Implementation:** (v2 - Not Implemented)')
        }
    }

    $lines.Add('---')
    $lines.Add('')

    # Part 1b: PRD Feature Cross-Reference
    if ($isPlain) {
        $lines.Add('PRD FEATURE CROSS-REFERENCE')
        $lines.Add('')
        $lines.Add('Feature -> Flow Mapping (by name/route semantics)')
        $lines.Add('')
    } else {
        $lines.Add('#### **PRD Feature Cross-Reference**')
        $lines.Add('')
    }

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
        $lines.Add('No PRD features found to cross-reference.')
        $lines.Add('')
    }

    $lines.Add('---')
    $lines.Add('')

    # Part 2: Detailed Flow Analysis
    if ($isPlain) {
        $lines.Add('PART 2: DETAILED FLOW ANALYSIS')
        $lines.Add('')
    } else {
        $lines.Add('### **Part 2: Detailed Flow Analysis**')
        $lines.Add('')
    }

    foreach ($flow in ($ReportData.Flows | Where-Object { $_ })) {
        $lines.Add('=================================================================')
        $fName = Normalize-Ascii $flow.Name
        if ($isPlain) {
            $lines.Add('FLOW: ' + $fName)
        } else {
            $lines.Add('**FLOW: ' + $fName + '**')
        }
        $lines.Add('=================================================================')
        $fPurpose = Normalize-Ascii $flow.Purpose
        if ($isPlain) {
            if ($flow.Purpose) { $lines.Add('Purpose: ' + $fPurpose) }
        } else {
            $lines.Add('**Purpose:** ' + ($fPurpose))
        }

        $entry = Normalize-Ascii $flow.EntryPoint
        $precon = Normalize-Ascii $flow.PreCondition
        if ($isPlain) {
            $lines.Add('')
            $lines.Add('Context & Pre-conditions:')
            $lines.Add('  Entry Point: ' + $entry)
            if ($flow.PreCondition) { $lines.Add('  Pre-condition: ' + $precon) }
        } else {
            $lines.Add('')
            $lines.Add('**Context & Pre-conditions:**')
            $lines.Add('*   **Entry Point:** ' + ($entry))
            if ($flow.PreCondition) { $lines.Add('*   **Pre-condition:** ' + ($precon)) }
        }

        # Visual Flow (simple ASCII steps)
        if ($isPlain) {
            $lines.Add('')
            $lines.Add('Visual Flow:')
        } else {
            $lines.Add('')
            $lines.Add('**Visual Flow:**')
        }
        $diagram = Build-AsciiFlowDiagram -Steps $flow.Steps -MaxWidth $Width
        if (-not $NoFence -and -not $isPlain) {
            $lines.Add('```')
            $lines.Add($diagram)
            $lines.Add('```')
        } else {
            $lines.Add($diagram)
        }

        # Data Interaction
        if ($isPlain) {
            $lines.Add('Data Interaction:')
            $lines.Add('  Data Read:')
            foreach ($e in ($flow.DataRead | Where-Object { $_ })) { $lines.Add('    - ' + (Normalize-Ascii $e)) }
            if ($flow.DataCreated -and $flow.DataCreated.Count -gt 0) {
                $lines.Add('  Data Created:')
                foreach ($e in $flow.DataCreated) { $lines.Add('    - ' + (Normalize-Ascii $e)) }
            }
            if ($flow.DataUpdated -and $flow.DataUpdated.Count -gt 0) {
                $lines.Add('  Data Updated:')
                foreach ($e in $flow.DataUpdated) { $lines.Add('    - ' + (Normalize-Ascii $e)) }
            }
        } else {
            $lines.Add('')
            $lines.Add('**Data Interaction:**')
            $lines.Add('*   **Data Read:**')
            foreach ($e in ($flow.DataRead | Where-Object { $_ })) { $lines.Add('    *   `' + (Normalize-Ascii $e) + '`') }
            if ($flow.DataCreated -and $flow.DataCreated.Count -gt 0) {
                $lines.Add('*   **Data Created:**')
                foreach ($e in $flow.DataCreated) { $lines.Add('    *   `' + (Normalize-Ascii $e) + '`') }
            }
            if ($flow.DataUpdated -and $flow.DataUpdated.Count -gt 0) {
                $lines.Add('*   **Data Updated:**')
                foreach ($e in $flow.DataUpdated) { $lines.Add('    *   `' + (Normalize-Ascii $e) + '`') }
            }
        }

        # Scenario Checklist
        $succ = Normalize-Ascii $flow.SuccessScenario
        if ($isPlain) {
            $lines.Add('Scenario Checklist:')
            if ($succ) { $lines.Add('  Success Scenario: ' + $succ) }
            if ($flow.ErrorStates -and $flow.ErrorStates.Count -gt 0) {
                $lines.Add('  Error States Handled:')
                foreach ($er in $flow.ErrorStates) { $lines.Add('    - ' + (Normalize-Ascii $er)) }
            }
            if ($flow.EmptyStates) { $lines.Add('  Empty States Handled: ' + (Normalize-Ascii $flow.EmptyStates)) }
        } else {
            $lines.Add('')
            $lines.Add('**Scenario Checklist:**')
            if ($succ) { $lines.Add('*   **Success Scenario:** ' + $succ) }
            if ($flow.ErrorStates -and $flow.ErrorStates.Count -gt 0) {
                $lines.Add('*   **Error States Handled:**')
                foreach ($er in $flow.ErrorStates) { $lines.Add('    *   ' + (Normalize-Ascii $er)) }
            }
            if ($flow.EmptyStates) { $lines.Add('*   **Empty States Handled:** ' + (Normalize-Ascii $flow.EmptyStates)) }
        }

        if (-not $NoHr) { $lines.Add('') ; $lines.Add('---') ; $lines.Add('') }
    }

    $out = $lines -join [Environment]::NewLine
    Set-Content -Path $OutputPath -Value $out -Encoding UTF8
    Write-Host 'Successfully generated user flows report at: ' $OutputPath
}
