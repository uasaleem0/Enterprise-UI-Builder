function New-ForgeSitemapReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReportData,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [switch]$Plain,
        [int]$Width = 78,
        [switch]$NoHr
    )

    function Normalize-Ascii {
        param([string]$Text)
        if (-not $Text) { return '' }
        $s = $Text
        $s = $s -replace "[\u2018\u2019]", "'"
        $s = $s -replace "[\u201C\u201D]", '"'
        $s = $s -replace "[\u2013\u2014\u2212]", '-'
        $s = $s -replace "\u2026", '...'
        $chars = $s.ToCharArray()
        for($i=0;$i -lt $chars.Length;$i++){ if([int]$chars[$i] -gt 127){ $chars[$i] = [char]'?' } }
        return -join $chars
    }

    $rule = ('=' * [Math]::Max(20,[Math]::Min($Width,120)))
    $sep  = ('-' * [Math]::Max(20,[Math]::Min($Width,120)))
    $lines = New-Object System.Collections.Generic.List[string]

    # Part 1: Sitemap & Scope (ASCII-only)
    $lines.Add($rule)
    $lines.Add('OVERALL SITEMAP & SCOPE')
    $lines.Add($rule)
    $lines.Add('')
    $lines.Add('ROOT: /' + (Normalize-Ascii $ReportData.ProjectName))
    foreach ($route in $ReportData.Sitemap.Routes) { $lines.Add('- ' + (Normalize-Ascii $route)) }
    $lines.Add('')
    $lines.Add('Modals & Drawers (No URL):')
    foreach ($modal in ($ReportData.Sitemap.Modals | Where-Object { $_ })) { $lines.Add('- ' + (Normalize-Ascii $modal)) }
    $lines.Add('')
    $lines.Add('Out of Scope (Version 1.0):')
    foreach ($item in ($ReportData.Sitemap.OutOfScope | Where-Object { $_ })) { $lines.Add('- ' + (Normalize-Ascii $item)) }
    if (-not $NoHr) { $lines.Add($sep) ; $lines.Add('') }

    # Part 2: Feature Implementation Map (ASCII-only)
    $lines.Add($rule)
    $lines.Add('FEATURE IMPLEMENTATION MAP')
    $lines.Add($rule)
    $lines.Add('')
    foreach ($feature in ($ReportData.Features.InScope | Where-Object { $_ })) {
        $lines.Add('Feature      : ' + (Normalize-Ascii $feature.Name))
        if ($feature.PSObject.Properties.Name -contains 'Description') {
            $lines.Add('Description  : ' + (Normalize-Ascii ($feature.Description)))
        }
        if ($feature.PSObject.Properties.Name -contains 'Implementation') {
            $lines.Add('Implementation: ' + (Normalize-Ascii ($feature.Implementation)))
        }
        $lines.Add('')
    }
    if (-not $NoHr) { $lines.Add($sep) ; $lines.Add('') }

    # Part 3: Screen-by-Screen Breakdown (ASCII-only)
    $lines.Add($rule)
    $lines.Add('SCREEN-BY-SCREEN BREAKDOWN')
    $lines.Add($rule)
    $lines.Add('')
    foreach ($screen in ($ReportData.ScreenAnalysis | Where-Object { $_ })) {
        $lines.Add('Route        : ' + (Normalize-Ascii $screen.Route))
        $lines.Add('Purpose      : ' + (Normalize-Ascii ($screen.Purpose)))
        $lines.Add('Core Feature : ' + (Normalize-Ascii ($screen.CoreFeature)))
        $lines.Add('Key Components:')
        foreach ($component in ($screen.KeyComponents | Where-Object { $_ })) { $lines.Add('  - ' + (Normalize-Ascii $component)) }
        $lines.Add('Data Dependencies:')
        foreach ($dependency in ($screen.DataDependencies | Where-Object { $_ })) { $lines.Add('  - ' + (Normalize-Ascii $dependency)) }
        $entries = $screen.Connectivity.EntryPoints
        $exits = $screen.Connectivity.ExitPoints
        if ($entries -is [System.Collections.IEnumerable] -and -not ($entries -is [string])) { $entries = ($entries -join ', ') }
        if ($exits -is [System.Collections.IEnumerable] -and -not ($exits -is [string])) { $exits = ($exits -join ', ') }
        $lines.Add('Entry Points : ' + (Normalize-Ascii ($entries)))
        $lines.Add('Exit Points  : ' + (Normalize-Ascii ($exits)))
        $lines.Add('')
    }

    $out = $lines -join [Environment]::NewLine
    Set-Content -Path $OutputPath -Value $out -Encoding UTF8
    Write-Host 'Successfully generated sitemap report at: ' $OutputPath
}

