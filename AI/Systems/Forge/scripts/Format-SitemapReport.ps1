function Format-SitemapReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReportData,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [switch]$Plain,
        [int]$Width = 90,
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

    $lines = New-Object System.Collections.Generic.List[string]

    # Calculate stats
    $routeCount = $ReportData.Sitemap.Routes.Count
    $featureCount = $ReportData.Features.InScope.Count
    $screenCount = $ReportData.ScreenAnalysis.Count

    # Header with summary
    $lines.Add('+---------------------------------------------------------------+')
    $lines.Add('|              SITEMAP REPORT: ' + (Normalize-Ascii $ReportData.ProjectName).PadRight(23) + '|')
    $lines.Add('|        Routes: ' + $routeCount.ToString().PadRight(2) + ' | Features: ' + $featureCount.ToString().PadRight(2) + ' | Screens: ' + $screenCount.ToString().PadRight(2) + '        |')
    $lines.Add('+---------------------------------------------------------------+')
    $lines.Add('')
    $lines.Add('')

    # Part 1: Overall Sitemap & Scope
    $lines.Add('===============================================================')
    $lines.Add('  PART 1: OVERALL SITEMAP & SCOPE')
    $lines.Add('===============================================================')
    $lines.Add('')
    $lines.Add('+-- SITEMAP ARCHITECTURE ----------------------------------------+')
    $lines.Add('|')
    $lines.Add('|  / (' + (Normalize-Ascii $ReportData.ProjectName) + ')')

    # Routes with proper tree structure
    $routesArray = @($ReportData.Sitemap.Routes)
    for ($i = 0; $i -lt $routesArray.Count; $i++) {
        $route = Normalize-Ascii $routesArray[$i]
        if ($i -eq ($routesArray.Count - 1)) {
            $lines.Add('|    +-- ' + $route)
        } else {
            $lines.Add('|    |-- ' + $route)
        }
    }

    $lines.Add('|')
    $lines.Add('|  Modals & Drawers:')
    foreach ($modal in ($ReportData.Sitemap.Modals | Where-Object { $_ })) {
        $lines.Add('|    * ' + (Normalize-Ascii $modal))
    }

    $lines.Add('|')
    $lines.Add('|  Out of Scope (v1.0):')
    $outOfScopeFiltered = $ReportData.Sitemap.OutOfScope | Where-Object { $_ -and $_ -notmatch '^Totals:' }
    foreach ($item in $outOfScopeFiltered) {
        $lines.Add('|    * ' + (Normalize-Ascii $item))
    }
    $lines.Add('+---------------------------------------------------------------+')
    $lines.Add('')
    $lines.Add('')

    # Part 2: Feature Implementation Map
    $lines.Add('===============================================================')
    $lines.Add('  PART 2: FEATURE IMPLEMENTATION MAP (' + $featureCount + ' Features)')
    $lines.Add('===============================================================')
    $lines.Add('')

    foreach ($feature in ($ReportData.Features.InScope | Where-Object { $_ })) {
        $fName = Normalize-Ascii $feature.Name
        $lines.Add('+-- Feature: ' + $fName + ' ' + ('-' * (49 - $fName.Length)) + '+')

        if ($feature.PSObject.Properties.Name -contains 'Description' -and $feature.Description) {
            $desc = Normalize-Ascii $feature.Description
            $desc = $desc -replace '^\*\*\s*', ''
            $lines.Add('| Description: ' + $desc)
        }

        if ($feature.PSObject.Properties.Name -contains 'Implementation' -and $feature.Implementation) {
            $impl = Normalize-Ascii $feature.Implementation
            $lines.Add('| Screens:     ' + $impl)
        }

        $lines.Add('+---------------------------------------------------------------+')
        $lines.Add('')
    }

    $lines.Add('')

    # Part 3: Screen-by-Screen Breakdown
    $lines.Add('===============================================================')
    $lines.Add('  PART 3: SCREEN-BY-SCREEN BREAKDOWN (' + $screenCount + ' Screens)')
    $lines.Add('===============================================================')
    $lines.Add('')

    foreach ($screen in ($ReportData.ScreenAnalysis | Where-Object { $_ })) {
        $route = Normalize-Ascii $screen.Route
        $lines.Add('+-- ' + $route + ' ' + ('-' * (60 - $route.Length)) + '+')
        $lines.Add('|')

        # Purpose
        $purpose = Normalize-Ascii $screen.Purpose
        $lines.Add('| Purpose:      ' + $purpose)

        # Core Feature
        if ($screen.CoreFeature) {
            $core = Normalize-Ascii $screen.CoreFeature
            $lines.Add('| Core Feature: ' + $core)
        }

        $lines.Add('|')

        # Key Components
        if ($screen.KeyComponents -and $screen.KeyComponents.Count -gt 0) {
            $lines.Add('| Components:   * ' + (Normalize-Ascii $screen.KeyComponents[0]))
            for ($i = 1; $i -lt $screen.KeyComponents.Count; $i++) {
                $comp = Normalize-Ascii $screen.KeyComponents[$i]
                $lines.Add('|               * ' + $comp)
            }
            $lines.Add('|')
        }

        # Data Dependencies
        if ($screen.DataDependencies -and $screen.DataDependencies.Count -gt 0) {
            $lines.Add('| Data:         * ' + (Normalize-Ascii $screen.DataDependencies[0]))
            for ($i = 1; $i -lt $screen.DataDependencies.Count; $i++) {
                $dep = Normalize-Ascii $screen.DataDependencies[$i]
                $lines.Add('|               * ' + $dep)
            }
            $lines.Add('|')
        }

        # Connectivity
        $entries = $screen.Connectivity.EntryPoints
        $exits = $screen.Connectivity.ExitPoints
        if ($entries -is [System.Collections.IEnumerable] -and -not ($entries -is [string])) {
            $entries = ($entries -join ', ')
        }
        if ($exits -is [System.Collections.IEnumerable] -and -not ($exits -is [string])) {
            $exits = ($exits -join ', ')
        }

        $entryText = if ($entries) { Normalize-Ascii $entries } else { 'N/A' }
        $exitText = if ($exits) { Normalize-Ascii $exits } else { 'N/A' }

        $lines.Add('| Navigation:')
        $lines.Add('|   Entry  ->  ' + $entryText)
        $lines.Add('|   Exit   ->  ' + $exitText)
        $lines.Add('|')
        $lines.Add('+---------------------------------------------------------------+')
        $lines.Add('')
    }

    $out = $lines -join [Environment]::NewLine
    Set-Content -Path $OutputPath -Value $out -Encoding UTF8
    Write-Host 'Successfully generated sitemap report at: ' $OutputPath
}
