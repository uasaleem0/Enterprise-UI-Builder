function New-ForgePRDReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [pscustomobject]$ReportData,
        [Parameter(Mandatory=$true)] [string]$OutputPath,
        [switch]$Plain,
        [int]$Width = 78,
        [hashtable]$Completion,
        [object[]]$Diagnostics,
        [double]$Confidence = [double]::NaN,
        [object[]]$NextSteps,
        [hashtable]$Traceability,
        [string]$FeedbackText
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $rule = ('=' * [Math]::Max(20,[Math]::Min($Width,120)))
    $sep  = ('-' * [Math]::Max(20,[Math]::Min($Width,120)))

    function Box-AI([string[]]$items){
        $border = '+---------------- AI Analysis ----------------+'
        $o = @($border)
        foreach($i in $items){ if($i){ $o += $i } }
        $o += ('+' + ('-' * 44) + '+')
        return $o
    }

    # Summary
    $lines.Add($rule)
    $lines.Add('== PRD SUMMARY ==')
    $lines.Add($rule)
    $lines.Add('')
    $lines.Add('Project           : ' + $ReportData.ProjectName)
    # counts
    $total = ($ReportData.Features | Measure-Object).Count
    $inMust = ($ReportData.Features | Where-Object { $_.Scope -eq 'MUST' } | Measure-Object).Count
    $inShould = ($ReportData.Scope.should | Measure-Object).Count
    $inCould = ($ReportData.Scope.could | Measure-Object).Count
    $lines.Add('Feature Counts    : Total ' + $total + ' | In Scope (MUST) ' + $inMust + ' | Out of Scope (SHOULD) ' + $inShould + ' | (COULD) ' + $inCould)
    $lines.Add('Notes             : Recommendations are PRD-based (no IA dependency).')
    $lines.Add('')
    $lines.Add($sep)
    $lines.Add('')

    # Copy/Paste Feedback (concise paragraphs for GPT)
    if ($FeedbackText -and $FeedbackText.Trim()) {
        $lines.Add($rule)
        $lines.Add('== PRD FEEDBACK (COPY/PASTE) ==')
        $lines.Add($rule)
        $lines.Add('')
        foreach($ln in ($FeedbackText -split "`n")) { $lines.Add($ln.TrimEnd()) }
        $lines.Add('')
        $lines.Add($sep)
        $lines.Add('')
    }

    # Readiness Summary (reuses forge status gates; no duplication)
    if ($Completion -or $Diagnostics) {
        $lines.Add($rule)
        $lines.Add('== READINESS SUMMARY (PRD COMPLETENESS) ==')
        $lines.Add($rule)
        $lines.Add('')
        if (-not [double]::IsNaN($Confidence)) {
            $gap = [math]::Round(95 - $Confidence, 2)
            $lines.Add('PRD Confidence     : ' + $Confidence + '% (Target 95%)  Gap: ' + (-1 * $gap) + '%')
            $lines.Add('')
        }
        if ($Traceability) {
            $lines.Add('Traceability Coverage (MUST-weighted): ' + $Traceability.coverage + '%')
            $lines.Add('  - Stories    : ' + $Traceability.story_pct + '%')
            $lines.Add('  - Acceptance : ' + $Traceability.acceptance_pct + '%')
            $lines.Add('  - NFR Areas  : ' + $Traceability.nfr_pct + '%')
            $lines.Add('  - KPIs       : ' + $Traceability.kpi_pct + '%')
            $lines.Add('')
        }
        if ($Completion) {
            $lines.Add('Deliverable Completion:')
            foreach ($k in @('problem_statement','tech_stack','success_metrics','mvp_scope','feature_list','user_personas','user_stories','non_functional')) {
                if ($Completion.ContainsKey($k)) {
                    $name = switch($k){
                        'problem_statement' { 'Problem Statement' }
                        'tech_stack'        { 'Tech Stack' }
                        'success_metrics'   { 'Success Metrics' }
                        'mvp_scope'         { 'MVP Scope' }
                        'feature_list'      { 'Feature List' }
                        'user_personas'     { 'User Personas' }
                        'user_stories'      { 'User Stories' }
                        'non_functional'    { 'Non-Functional Reqs' }
                        default { $k }
                    }
                    $pct = [string]$Completion[$k]
                    $lines.Add('  - ' + $name + ': ' + $pct + '%')
                }
            }
            $lines.Add('')
        }
        if ($Diagnostics) {
            $lines.Add('Top Suggestions:')
            $shown = 0
            foreach ($d in $Diagnostics) {
                if ($null -eq $d) { continue }
                $name = if ($d.name) { $d.name } else { $d.key }
                if ($d.suggestions -and $d.suggestions.Count -gt 0) {
                    $lines.Add('  - ' + $name + ':')
                    $c = 0
                    foreach ($s in $d.suggestions) { $lines.Add('    * ' + $s); $c++; if ($c -ge 3) { break } }
                }
                $shown++
                if ($shown -ge 4) { break }
            }
            $lines.Add('')
        }
        if ($NextSteps -and $NextSteps.Count -gt 0) {
            $lines.Add('High-Impact Next Steps:')
            $take = [Math]::Min(5, $NextSteps.Count)
            for ($i=0; $i -lt $take; $i++) {
                $ns = $NextSteps[$i]
                $name = switch ($ns.deliverable) {
                    'problem_statement' { 'Problem Statement' }
                    'tech_stack' { 'Tech Stack' }
                    'success_metrics' { 'Success Metrics' }
                    'mvp_scope' { 'MVP Scope' }
                    'feature_list' { 'Feature List' }
                    'user_personas' { 'User Personas' }
                    'user_stories' { 'User Stories' }
                    'non_functional' { 'Non-Functional Reqs' }
                    default { $ns.deliverable }
                }
                $lines.Add('  - ' + $name + ': add ' + $ns.needed + '% (impact +' + $ns.impact + '%)  -> projected ' + $ns.new_confidence + '%')
            }
            $lines.Add('')
        }
        $lines.Add('Note: AI analysis is advisory; PRD Confidence derives from gates + traceability only.')
        $lines.Add($sep)
        $lines.Add('')
    }

    # Feature Inventory
    $lines.Add($rule)
    $lines.Add('== FEATURE INVENTORY (MVP) ==')
    $lines.Add($rule)
    $lines.Add('')

    $idx = 0
    foreach($f in $ReportData.Features){
        $idx++
        $lines.Add(($idx.ToString() + ') Feature: ' + $f.Name))
        $lines.Add('Scope     : ' + $f.Scope)
        $desc = if ($f.PSObject.Properties.Name -contains 'Description' -and $f.Description -and $f.Description.Trim()) { $f.Description.Trim() } else { '(none specified)' }
        $lines.Add('Description: ' + $desc)
        $lines.Add('Acceptance : ' + $f.AcceptanceDone + '/' + $f.AcceptanceTotal + ' complete')
        $status = if ($f.AcceptanceDone -ge $f.AcceptanceTotal -and $f.AcceptanceTotal -gt 0) { 'Ready' } elseif ($f.AcceptanceTotal -gt 0) { 'Partial Spec' } else { 'Needs Spec' }
        $lines.Add('Status    : ' + $status)
        # AI box condensed
        $ai = @()
        switch -Regex ($f.Name.ToLower()){
            'workout|track' { $ai += '- Ensure edit/delete UX, undo, validation.'; $ai += '- Offline-ready saves with clear states.' }
            'trend|analysis' { $ai += '- Set significance thresholds and N-session gates.'; $ai += '- Virtualize charts; add plain-language deltas.' }
            'recommend' { $ai += '- Surface recs in summary/insights with rationale.'; $ai += '- Cold-start rules and rate-limited load deltas.' }
            'body|metric|photo' { $ai += '- Clarify local storage and export schema.'; $ai += '- Provide compare views and safe deletes.' }
            'habit' { $ai += '- Habit window + confidence, decay and overrides.' }
            'remind|notif' { $ai += '- Window start/end, DND, snooze; measure effectiveness.' }
            'gamif|badge|streak|pr' { $ai += '- Define badge catalog; use cooldowns/rarity.' }
            'correl|insight' { $ai += '- Min data thresholds + effect size/confidence.' }
            'dashboard' { $ai += '- Card priority policy and empty-state patterns.' }
            'sleek|ux' { $ai += '- Design tokens and performance budgets per view.' }
        }
        if ($ai.Count -gt 0){ foreach($l in (Box-AI $ai)){ $lines.Add($l) } }
        $lines.Add('')
        $lines.Add('')
    }

    $lines.Add($sep)
    $lines.Add('')

    # PRD Internal Cross-Reference (no IA)
    $lines.Add($rule)
    $lines.Add('== PRD INTERNAL CROSS-REFERENCE ==')
    $lines.Add($rule)
    $lines.Add('')
    foreach($f in $ReportData.Features){
        $lines.Add('- Feature: ' + $f.Name)
        $lines.Add('  Scope     : ' + $f.Scope)
        $lines.Add('  Acceptance: ' + $f.AcceptanceDone + '/' + $f.AcceptanceTotal)
        if ($f.Stories -and $f.Stories.Count -gt 0){
            $lines.Add('  User Stories:')
            foreach($s in $f.Stories){ $clean = ($s -replace '^\-\s+',''); $lines.Add('    - ' + $clean) }
        } else { $lines.Add('  User Stories: None detected') }
        if ($f.NfrAreas -and $f.NfrAreas.Count -gt 0){
            $lines.Add('  NFR Areas:')
            foreach($n in $f.NfrAreas){ $lines.Add('    - ' + $n) }
        } else { $lines.Add('  NFR Areas: None detected') }
        if ($f.Kpis -and $f.Kpis.Count -gt 0){
            $lines.Add('  KPIs:')
            foreach($k in $f.Kpis){ $lines.Add('    - ' + $k) }
        } else { $lines.Add('  KPIs: None detected') }
        $lines.Add('')
    }

    $lines.Add($sep)
    $lines.Add('')

    # NFRs
    $lines.Add($rule)
    $lines.Add('== NON-FUNCTIONAL REQUIREMENTS ==')
    $lines.Add($rule)
    $lines.Add('')
    if ($ReportData.NfrAreas -and $ReportData.NfrAreas.Count -gt 0){ foreach($n in $ReportData.NfrAreas){ $lines.Add('- ' + $n) } } else { $lines.Add('No NFR categories detected.') }
    $lines.Add('')
    $lines.Add($sep)
    $lines.Add('')

    # KPIs
    $lines.Add($rule)
    $lines.Add('== KPIs ==')
    $lines.Add($rule)
    $lines.Add('')
    if ($ReportData.Kpis -and $ReportData.Kpis.Count -gt 0){ foreach($k in $ReportData.Kpis){ $lines.Add('- ' + $k) } } else { $lines.Add('No KPIs detected.') }
    $lines.Add('')

    # end of report

    $out = $lines -join [Environment]::NewLine
    Set-Content -Path $OutputPath -Value $out -Encoding UTF8
    Write-Host 'Successfully generated PRD report at: ' $OutputPath
}
