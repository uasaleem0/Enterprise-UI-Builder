<#
 .SYNOPSIS
     Document Editor for PRD and IA files
 .DESCRIPTION
     Provides surgical modification capabilities for PRD and IA documents
     Preserves formatting and structure while applying targeted changes
#>

function Normalize-Text {
    param([string]$Text)
    if (-not $Text) { return '' }
    $t = $Text -replace "\r\n?", "`n"
    $t = $t -replace "[\u2018\u2019]", "'"
    $t = $t -replace "[\u201C\u201D]", '"'
    $t = $t -replace "[\u2013\u2014\u2212]", '-'
    $t = $t -replace "\u2026", '...'
    return $t
}

function Update-PRDSection {
    <#
    .SYNOPSIS
    Modifies a specific section of a PRD file

    .PARAMETER PrdPath
    Path to prd.md file

    .PARAMETER Section
    Section to modify: 'features', 'scope', 'nfr', 'kpis', 'user_stories', 'tech_stack'

    .PARAMETER Operation
    Operation to perform: 'add', 'modify', 'remove'

    .PARAMETER Data
    Data for the operation (structure depends on section and operation)

    .EXAMPLE
    Update-PRDSection -PrdPath "prd.md" -Section "features" -Operation "add" -Data @{
        name = "Programs"
        description = "Group multiple workouts into training programs"
        scope = "SHOULD"
    }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PrdPath,

        [Parameter(Mandatory=$true)]
        [ValidateSet('features', 'scope', 'nfr', 'kpis', 'user_stories', 'tech_stack', 'problem_statement', 'personas')]
        [string]$Section,

        [Parameter(Mandatory=$true)]
        [ValidateSet('add', 'modify', 'remove')]
        [string]$Operation,

        [Parameter(Mandatory=$true)]
        [hashtable]$Data
    )

    if (-not (Test-Path $PrdPath)) {
        throw "PRD file not found: $PrdPath"
    }

    $content = Get-Content -Path $PrdPath -Raw -Encoding UTF8 | Normalize-Text
    $originalContent = $content

    try {
        switch ($Section) {
            'features' {
                $content = Update-PRDFeaturesSection -Content $content -Operation $Operation -Data $Data
            }
            'scope' {
                $content = Update-PRDScopeSection -Content $content -Operation $Operation -Data $Data
            }
            'nfr' {
                $content = Update-PRDNFRSection -Content $content -Operation $Operation -Data $Data
            }
            'kpis' {
                $content = Update-PRDKPISection -Content $content -Operation $Operation -Data $Data
            }
            'user_stories' {
                $content = Update-PRDUserStoriesSection -Content $content -Operation $Operation -Data $Data
            }
            'tech_stack' {
                $content = Update-PRDTechStackSection -Content $content -Operation $Operation -Data $Data
            }
            'problem_statement' {
                $content = Update-PRDProblemStatementSection -Content $content -Operation $Operation -Data $Data
            }
            'personas' {
                $content = Update-PRDPersonasSection -Content $content -Operation $Operation -Data $Data
            }
        }

        if ($content -ne $originalContent) {
            Set-Content -Path $PrdPath -Value $content -Encoding UTF8 -NoNewline
            return $true
        }
        return $false

    } catch {
        throw "Failed to update PRD section '$Section': $($_.Exception.Message)"
    }
}

function Update-PRDFeaturesSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inFeatures = $false
    $featureAdded = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect features section
        if ($line -match '^##\s+(Features?|Feature List|Functional Requirements)') {
            $inFeatures = $true
            $result.Add($line)
            continue
        }

        # Exit features section on next ## header
        if ($inFeatures -and $line -match '^##\s+' -and $line -notmatch '^##\s+(Features?|Feature List)') {
            $inFeatures = $false

            # Add new feature before next section if not already added
            if ($Operation -eq 'add' -and -not $featureAdded) {
                $result.Add("")
                $result.Add("### $($Data.name)")
                if ($Data.description) {
                    $result.Add($Data.description)
                }
                if ($Data.acceptance_criteria) {
                    $result.Add("")
                    $result.Add("**Acceptance Criteria:**")
                    foreach ($ac in $Data.acceptance_criteria) {
                        $result.Add("- $ac")
                    }
                }
                if ($Data.user_stories) {
                    $result.Add("")
                    $result.Add("**User Stories:**")
                    foreach ($us in $Data.user_stories) {
                        $result.Add("- $us")
                    }
                }
                $result.Add("")
                $featureAdded = $true
            }
        }

        # Handle operations within features section
        if ($inFeatures) {
            if ($Operation -eq 'add' -and $line.Trim() -eq '' -and -not $featureAdded) {
                # Add feature at first blank line in section
                $result.Add("### $($Data.name)")
                if ($Data.description) {
                    $result.Add($Data.description)
                }
                if ($Data.acceptance_criteria) {
                    $result.Add("")
                    $result.Add("**Acceptance Criteria:**")
                    foreach ($ac in $Data.acceptance_criteria) {
                        $result.Add("- $ac")
                    }
                }
                if ($Data.user_stories) {
                    $result.Add("")
                    $result.Add("**User Stories:**")
                    foreach ($us in $Data.user_stories) {
                        $result.Add("- $us")
                    }
                }
                $result.Add("")
                $featureAdded = $true
            }
            elseif ($Operation -eq 'remove' -and $line -match "^###\s+$([regex]::Escape($Data.name))") {
                # Skip this feature and its content until next ### or ##
                while ($i -lt $lines.Count - 1) {
                    $i++
                    if ($lines[$i] -match '^###\s+' -or $lines[$i] -match '^##\s+') {
                        $i--
                        break
                    }
                }
                continue
            }
            elseif ($Operation -eq 'modify' -and $line -match "^###\s+$([regex]::Escape($Data.name))") {
                # Replace feature content
                $result.Add("### $($Data.name)")
                if ($Data.description) {
                    $result.Add($Data.description)
                }
                if ($Data.acceptance_criteria) {
                    $result.Add("")
                    $result.Add("**Acceptance Criteria:**")
                    foreach ($ac in $Data.acceptance_criteria) {
                        $result.Add("- $ac")
                    }
                }
                if ($Data.user_stories) {
                    $result.Add("")
                    $result.Add("**User Stories:**")
                    foreach ($us in $Data.user_stories) {
                        $result.Add("- $us")
                    }
                }

                # Skip old content
                while ($i -lt $lines.Count - 1) {
                    $i++
                    if ($lines[$i] -match '^###\s+' -or $lines[$i] -match '^##\s+') {
                        $i--
                        break
                    }
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDScopeSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inScope = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Scope|MVP Scope|Project Scope)') {
            $inScope = $true
            $result.Add($line)
            continue
        }

        if ($inScope -and $line -match '^##\s+') {
            $inScope = $false
        }

        if ($inScope -and $Operation -eq 'add') {
            # Find the appropriate scope level (MUST/SHOULD/COULD)
            $scopeLevel = if ($Data.scope) { $Data.scope.ToUpper() } else { 'SHOULD' }

            if ($line -match "^\*\*($scopeLevel)\*\*" -or $line -match "^###\s+$scopeLevel") {
                $result.Add($line)
                # Add item after the scope header
                if ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -eq '') {
                    $result.Add($lines[$i + 1])
                    $i++
                }
                $result.Add("- $($Data.name): $($Data.description)")
                continue
            }
        }


        if ($inScope -and $Operation -eq 'modify') {
            # Move item from old scope to new scope
            $itemNamePattern = [regex]::Escape($Data.name)
            
            # Skip line containing the item (remove from old scope)
            if ($line -match $itemNamePattern) {
                continue
            }

            # Add under new scope heading
            $newScopeLevel = if ($Data.new_scope) { $Data.new_scope.ToUpper() } else { 'MUST' }
            if ($line -match "^\*\*.*$newScopeLevel.*\*\*" -or $line -match "^###\s+.*$newScopeLevel") {
                $result.Add($line)
                # Look ahead for blank lines
                $j = $i + 1
                while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') {
                    $result.Add($lines[$j])
                    $i++
                    $j++
                }
                # Add the item name
                $result.Add($Data.name)
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDNFRSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inNFR = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Non[- ]?Functional Requirements?|NFRs?)') {
            $inNFR = $true
            $result.Add($line)
            continue
        }

        if ($inNFR -and $line -match '^##\s+') {
            $inNFR = $false
        }

        if ($inNFR -and $Operation -eq 'add') {
            # Find appropriate subsection (Performance, Security, etc.)
            if ($Data.category) {
                if ($line -match "^###\s+$([regex]::Escape($Data.category))") {
                    $result.Add($line)
                    if ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -eq '') {
                        $result.Add($lines[$i + 1])
                        $i++
                    }
                    $result.Add("- $($Data.requirement)")
                    continue
                }
            } else {
                # Add to first list in NFR section
                if ($line.Trim().StartsWith('-') -and $result[-1].Trim() -ne '') {
                    $result.Add("- $($Data.requirement)")
                }
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDKPISection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inKPI = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Success Metrics?|KPIs?|Key Performance Indicators?)') {
            $inKPI = $true
            $result.Add($line)
            continue
        }

        if ($inKPI -and $line -match '^##\s+') {
            $inKPI = $false
        }

        if ($inKPI -and $Operation -eq 'add') {
            # Add after first blank line or list start
            if (($line.Trim() -eq '' -or $line.Trim().StartsWith('-')) -and $result[-1] -match '^\s*$|^##') {
                if ($Data.metric -and $Data.target) {
                    $result.Add("- **$($Data.metric)**: $($Data.target)")
                    if ($Data.timeframe) {
                        $result[$result.Count - 1] += " ($($Data.timeframe))"
                    }
                } else {
                    $result.Add("- $($Data.description)")
                }
                $result.Add($line)
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDUserStoriesSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inUserStories = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(User Stories?|Stories)') {
            $inUserStories = $true
            $result.Add($line)
            continue
        }

        if ($inUserStories -and $line -match '^##\s+') {
            $inUserStories = $false
        }

        if ($inUserStories -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^\s*$|^##') {
                $result.Add("- $($Data.story)")
                $result.Add($line)
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDTechStackSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inTechStack = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Tech(?:nology)? Stack|Technical Stack)') {
            $inTechStack = $true
            $result.Add($line)
            continue
        }

        if ($inTechStack -and $line -match '^##\s+') {
            $inTechStack = $false
        }

        if ($inTechStack -and $Operation -eq 'add') {
            if ($Data.category) {
                if ($line -match "^###\s+$([regex]::Escape($Data.category))") {
                    $result.Add($line)
                    if ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -eq '') {
                        $result.Add($lines[$i + 1])
                        $i++
                    }
                    $result.Add("- **$($Data.technology)**: $($Data.description)")
                    continue
                }
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-PRDProblemStatementSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    if ($Operation -eq 'modify' -and $Data.statement) {
        $Content = $Content -replace '(?s)(##\s+Problem Statement.*?)(##|\z)', "`$1`n`n$($Data.statement)`n`n`$2"
    }

    return $Content
}

function Update-PRDPersonasSection {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inPersonas = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(User Personas?|Personas?|Target Users?)') {
            $inPersonas = $true
            $result.Add($line)
            continue
        }

        if ($inPersonas -and $line -match '^##\s+') {
            $inPersonas = $false
        }

        if ($inPersonas -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^##') {
                $result.Add("")
                $result.Add("### $($Data.name)")
                if ($Data.description) { $result.Add($Data.description) }
                if ($Data.goals) {
                    $result.Add("**Goals:**")
                    foreach ($g in $Data.goals) { $result.Add("- $g") }
                }
                if ($Data.pain_points) {
                    $result.Add("**Pain Points:**")
                    foreach ($p in $Data.pain_points) { $result.Add("- $p") }
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-IASection {
    <#
    .SYNOPSIS
    Modifies a specific section of an IA file

    .PARAMETER IAPath
    Path to IA file (sitemap.md, flows.md, components.md, entities.md, navigation.md)

    .PARAMETER Section
    Section to modify: 'routes', 'modals', 'flows', 'components', 'entities', 'navigation'

    .PARAMETER Operation
    Operation to perform: 'add', 'modify', 'remove'

    .PARAMETER Data
    Data for the operation
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$IAPath,

        [Parameter(Mandatory=$true)]
        [ValidateSet('routes', 'modals', 'flows', 'components', 'entities', 'navigation')]
        [string]$Section,

        [Parameter(Mandatory=$true)]
        [ValidateSet('add', 'modify', 'remove')]
        [string]$Operation,

        [Parameter(Mandatory=$true)]
        [hashtable]$Data
    )

    if (-not (Test-Path $IAPath)) {
        throw "IA file not found: $IAPath"
    }

    $content = Get-Content -Path $IAPath -Raw -Encoding UTF8 | Normalize-Text
    $originalContent = $content

    try {
        switch ($Section) {
            'routes' {
                $content = Update-IASitemapRoutes -Content $content -Operation $Operation -Data $Data
            }
            'modals' {
                $content = Update-IASitemapModals -Content $content -Operation $Operation -Data $Data
            }
            'flows' {
                $content = Update-IAFlows -Content $content -Operation $Operation -Data $Data
            }
            'components' {
                $content = Update-IAComponents -Content $content -Operation $Operation -Data $Data
            }
            'entities' {
                $content = Update-IAEntities -Content $content -Operation $Operation -Data $Data
            }
            'navigation' {
                $content = Update-IANavigation -Content $content -Operation $Operation -Data $Data
            }
        }

        if ($content -ne $originalContent) {
            Set-Content -Path $IAPath -Value $content -Encoding UTF8 -NoNewline
            return $true
        }
        return $false

    } catch {
        throw "Failed to update IA section '$Section': $($_.Exception.Message)"
    }
}

function Update-IASitemapRoutes {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inRoutes = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Routes?|Sitemap|Page Structure)') {
            $inRoutes = $true
            $result.Add($line)
            continue
        }

        if ($inRoutes -and $line -match '^##\s+') {
            $inRoutes = $false
        }

        if ($inRoutes -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^##') {
                $indent = if ($Data.parent) { '  ' } else { '' }
                $result.Add("$indent- $($Data.route)")
                if ($Data.description) {
                    $result.Add("$indent  Description: $($Data.description)")
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-IASitemapModals {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inModals = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+Modals?') {
            $inModals = $true
            $result.Add($line)
            continue
        }

        if ($inModals -and $line -match '^##\s+') {
            $inModals = $false
        }

        if ($inModals -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^##') {
                $result.Add("- $($Data.name)")
                if ($Data.description) {
                    $result.Add("  Purpose: $($Data.description)")
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-IAFlows {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]

    if ($Operation -eq 'add') {
        # Find the end of the last flow or start of document
        $insertIndex = $lines.Count

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^##\s+' -and $lines[$i] -notmatch '^##\s+(Flows?|User Flows?)') {
                $insertIndex = $i
                break
            }
        }

        # Build new flow content
        $flowLines = @()
        $flowLines += ""
        $flowLines += "### $($Data.name)"
        if ($Data.purpose) { $flowLines += "Purpose: $($Data.purpose)" }
        if ($Data.entry) { $flowLines += "Entry: $($Data.entry)" }
        if ($Data.steps) {
            $flowLines += "Steps: $($Data.steps -join ' -> ')"
        }
        if ($Data.success) { $flowLines += "Success: $($Data.success)" }
        if ($Data.errors) {
            $flowLines += "Errors: $($Data.errors -join ', ')"
        }
        $flowLines += ""

        # Insert at appropriate position
        $result = $lines[0..($insertIndex - 1)] + $flowLines + $lines[$insertIndex..($lines.Count - 1)]
        return ($result -join "`n")
    }

    return $Content
}

function Update-IAComponents {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]

    if ($Operation -eq 'add' -and $Data.route -and $Data.components) {
        $inComponents = $false
        $routeFound = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            if ($line -match '^##\s+Components?') {
                $inComponents = $true
            }

            if ($inComponents -and $line -match "^##\s+$([regex]::Escape($Data.route))") {
                $routeFound = $true
                $result.Add($line)

                # Add components
                foreach ($comp in $Data.components) {
                    $result.Add("- $comp")
                }

                # Skip existing components for this route
                while ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim().StartsWith('-')) {
                    $i++
                }
                continue
            }

            $result.Add($line)
        }

        # If route not found, add new section
        if ($inComponents -and -not $routeFound) {
            $result.Add("")
            $result.Add("## $($Data.route)")
            foreach ($comp in $Data.components) {
                $result.Add("- $comp")
            }
        }

        return ($result -join "`n")
    }

    return $Content
}

function Update-IAEntities {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inEntities = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Data )?Entities?') {
            $inEntities = $true
            $result.Add($line)
            continue
        }

        if ($inEntities -and $line -match '^##\s+') {
            $inEntities = $false
        }

        if ($inEntities -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^##') {
                $result.Add("- $($Data.name)")
                if ($Data.fields) {
                    $result.Add("  Fields: $($Data.fields -join ', ')")
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}

function Update-IANavigation {
    param([string]$Content, [string]$Operation, [hashtable]$Data)

    $lines = $Content -split "`n"
    $result = New-Object System.Collections.Generic.List[string]
    $inNav = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^##\s+(Primary )?Navigation') {
            $inNav = $true
            $result.Add($line)
            continue
        }

        if ($inNav -and $line -match '^##\s+') {
            $inNav = $false
        }

        if ($inNav -and $Operation -eq 'add') {
            if ($line.Trim() -eq '' -and $result[-1] -match '^##') {
                $result.Add("- $($Data.label)")
                if ($Data.route) {
                    $result.Add("  Route: $($Data.route)")
                }
                continue
            }
        }

        $result.Add($line)
    }

    return ($result -join "`n")
}
