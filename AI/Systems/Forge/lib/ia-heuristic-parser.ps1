<#
  IA/PRD Report Parser (ASCII-safe)
  - Produces canonical ReportData for sitemap, user flows, and PRD reports
  - Avoids Markdown; normalizes corrupted characters
  - Minimal deterministic heuristics; no network or external deps
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

# Expand domain synonyms for better semantic matching
function Expand-SemanticTokens { param([string[]]$Tokens)
    if (-not $Tokens) { return @() }
    $syn = @{
        # KPIs / Metrics
        'engagement'=@('retention','activation','dau','mau','nps','csat','conversion')
        'retention'=@('churn','activation')
        'latency'=@('response','p95','p99','ms','performance')
        'error'=@('failure','bug','exception','crash')
        'revenue'=@('mrr','arr','arpu','ltv')
        'uptime'=@('availability','reliability','sla','slo')
        'throughput'=@('reqs','requests','qps','rps')
        # NFRs
        'security'=@('auth','oauth','jwt','encryption','encrypt','xss','csrf','owasp','hipaa','gdpr','soc2','iso27001','privacy')
        'performance'=@('latency','throughput','cache','memory','cpu','p95','p99')
        'reliability'=@('resilience','fallback','retry','circuit')
        'availability'=@('uptime','ha','failover')
        'scalability'=@('scale','autoscale')
        'maintainability'=@('modular','documentation','code quality')
        'usability'=@('ux','ui','discoverability')
        'accessibility'=@('a11y','wcag','screenreader')
        'compliance'=@('gdpr','hipaa','soc2','iso27001')
    }
    $out = @($Tokens)
    foreach($t in $Tokens){ if ($syn.ContainsKey($t)) { $out += $syn[$t] } }
    return ($out | Select-Object -Unique)
}

function Get-ProjectNameFromPrdOrFolder {
    param([string]$ProjectPath)
    try {
        $prd = Join-Path $ProjectPath 'prd.md'
        if (Test-Path $prd) {
            $raw = Get-Content -Path $prd -Raw -Encoding UTF8
            if ($raw -match '(?m)^#\s+(.+)$') { return $matches[1].Trim() }
        }
    } catch {}
    return (Split-Path (Resolve-Path $ProjectPath) -Leaf)
}

function Get-IASectionText {
    param([string]$ProjectPath,[string]$Section)
    $ProjectPath = (Resolve-Path $ProjectPath).Path
    $iaDir = Join-Path $ProjectPath 'ia'
    $fileMap = @{ sitemap='sitemap.md'; flows='flows.md'; components='components.md'; entities='entities.md'; navigation='navigation.md' }
    if ($fileMap.ContainsKey($Section)) {
        $p = Join-Path $iaDir $fileMap[$Section]
        if (Test-Path $p) {
            $raw = Normalize-Text (Get-Content -Path $p -Raw -Encoding UTF8)
            $lines = @(); foreach($ln in ($raw -split "`n")){
                if ($ln -match '^#\s' -or $ln -match '^Generated:' -or $ln -match '^Confidence:') { continue }
                $lines += $ln
            }
            return ($lines -join "`n").Trim()
        }
    }
    $iaSingle = Join-Path $ProjectPath 'ia.md'
    if (Test-Path $iaSingle) {
        $txt = Normalize-Text (Get-Content -Path $iaSingle -Raw -Encoding UTF8)
        $marker = switch($Section){
            'sitemap' {'---SITEMAP---'}
            'flows' {'---USER_FLOWS---'}
            'components' {'---COMPONENTS---'}
            'entities' {'---DATA_ENTITIES---'}
            'navigation' {'---NAVIGATION---'}
            default { '' }
        }
        if ($marker -and ($txt -match "(?is)" + [regex]::Escape($marker) + "(.*?)(?=---[A-Z_]+---|$)")) {
            return $matches[1].Trim()
        }
    }
    return ''
}

function Find-RouteForLabel { param($LabelMap,[string]$Label)
    if (-not $LabelMap -or -not $Label) { return $null }
    $clean = ($Label -replace '[^A-Za-z0-9 ]','').Trim().ToLower()
    foreach($k in $LabelMap.Keys){ if ((($k -replace '[^A-Za-z0-9 ]','').Trim().ToLower()) -eq $clean) { return $LabelMap[$k] } }
    foreach($k in $LabelMap.Keys){ if ((($k -replace '[^A-Za-z0-9 ]','').Trim().ToLower()).Contains($clean)) { return $LabelMap[$k] } }
    foreach($k in $LabelMap.Keys){ $ck = ($k -replace '[^A-Za-z0-9 ]','').Trim().ToLower(); if ($clean -and $ck -and ($clean.Contains($ck))) { return $LabelMap[$k] } }
    return $null
}

function Parse-SitemapSection { param([string]$SitemapText)
    $routes = New-Object System.Collections.Generic.List[string]
    $modals = New-Object System.Collections.Generic.List[string]
    $outOfScope = New-Object System.Collections.Generic.List[string]
    $labelMap = @{}
    $purposeMap = @{}
    if (-not $SitemapText) { return [pscustomobject]@{ Routes=@(); Modals=@(); OutOfScope=@(); LabelMap=@{}; PurposeMap=@{} } }
    $lines = ($SitemapText -split "`n")
    $idxRoutes = -1; $idxModals = -1; $idxOut = -1

    # Enhanced patterns for section headers to handle multiple variations
    # Routes section: Screens, Pages, Routes, Views, URLs, etc.
    $routesPattern = '(?i)^(?:V\d+\s+)?(?:Screens?|Pages?|Routes?|Views?|URLs?|Paths?)(?:\s*[/&\-]\s*(?:Routes?|Pages?|Screens?))?\s*:?'
    # Modals section: Modals, Dialogs, Overlays, Popups (non-routed)
    $modalsPattern = '(?i)^(?:Modals?|Dialogs?|Overlays?|Popups?|Drawers?)(?:\s*[&/\-]\s*(?:Modals?|Dialogs?|Drawers?))?\s*\((?:No\s+(?:URL|Route|Path)|Non\s*-?\s*Routed)\)\s*:?'
    # Out of scope section
    $outOfScopePattern = '(?i)^(?:Out\s*-?\s*of\s*-?\s*Scope|Not\s+in\s+Scope|Future|Deferred|Excluded).*:?'

    for($i=0;$i -lt $lines.Count;$i++){
        $t = $lines[$i].Trim()
        if ($idxRoutes -lt 0 -and $t -match $routesPattern) { $idxRoutes = $i; continue }
        if ($idxModals -lt 0 -and $t -match $modalsPattern) { $idxModals = $i; continue }
        if ($idxOut -lt 0 -and $t -match $outOfScopePattern) { $idxOut = $i; continue }
    }
    function Clean([string]$ln){ return ($ln -replace '^\s*[-*]+\s*','').Trim() }
    function Take([int]$start,[int]$end){ $items=@(); for($j=$start;$j -lt $end -and $j -ge 0 -and $j -lt $lines.Count;$j++){ $x=Clean $lines[$j]; if($x){ $items+=$x } }; return $items }
    $routesEnd = @($idxModals,$idxOut,$lines.Count) | Where-Object { $_ -gt $idxRoutes } | Sort-Object | Select-Object -First 1
    if ($idxRoutes -ge 0){
        foreach($rc in (Take ($idxRoutes+1) $routesEnd)){
            # Support tab-separated table format: "Screen	/route	Purpose" or "Label	/route"
            if ($rc -match '\t') {
                $parts = $rc -split '\t' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                if ($parts.Count -ge 2) {
                    $label = $parts[0]
                    $route = $parts[1]
                    $purpose = if ($parts.Count -ge 3) { $parts[2] } else { '' }
                    # Check if second column is a route
                    if ($route -match '^(/[A-Za-z0-9][A-Za-z0-9/_:\-]*)') {
                        $route = $matches[1]
                        if (-not ($routes -contains $route)) { $routes.Add($route) }
                        if ($label -and $label -notmatch '^(Screen|Route|Label)$') { $labelMap[$label] = $route }
                        if ($purpose) { $purposeMap[$route] = $purpose }
                    }
                }
                continue
            }
            # Original format: "label: /route" or "/route"
            if ($rc -match '^(?<label>[^:]+):\s*(?<route>/[A-Za-z0-9][A-Za-z0-9/_:\-]*)\s*$'){
                $label=$matches['label'].Trim(); $route=$matches['route'];
                if (-not ($routes -contains $route)) { $routes.Add($route) }
                if ($label) { $labelMap[$label]=$route }
            }
            elseif ($rc -match '^(?<route>/[A-Za-z0-9][A-Za-z0-9/_:\-]*)\s*$'){
                $route=$matches['route'];
                if (-not ($routes -contains $route)) { $routes.Add($route) }
            }
        }
    } else {
        foreach($ln in $lines){ $t=$ln.Trim(); if ($t -match '^/[A-Za-z0-9][A-Za-z0-9/_:\-]*$'){ if (-not ($routes -contains $t)) { $routes.Add($t) } } }
    }
    if ($idxModals -ge 0){ $modEnd = @($idxOut,$lines.Count) | Where-Object { $_ -gt $idxModals } | Sort-Object | Select-Object -First 1; foreach($m in (Take ($idxModals+1) $modEnd)){ if ($m -notmatch '^/') { $modals.Add($m) } } }
    if ($idxOut -ge 0){ foreach($o in (Take ($idxOut+1) $lines.Count)){ if ($o){ $outOfScope.Add($o) } } }
    return [pscustomobject]@{ Routes=$routes; Modals=$modals; OutOfScope=$outOfScope; LabelMap=$labelMap; PurposeMap=$purposeMap }
}

function Parse-FeaturesFromFlows { param([string]$FlowsText,[string[]]$Routes)
    $result = @(); if (-not $FlowsText) { return $result }
    $lines = $FlowsText -split "`n"
    foreach($ln in $lines){ $t=$ln.Trim(); if ($t -match '(?i)^(Primary\s+Flow|Secondary\s+Flow|Tertiary\s+Flow|Flow\s*\d+|Flow|Feature)\s*:\s*(.+)$'){
        $raw = $matches[2].Trim(); $name=$raw; $desc=''
        if ($raw -match '^(.*?)\s+-\s+(.*)$'){ $name=$matches[1].Trim(); $desc=$matches[2].Trim() }
        $impl = '/'
        if ($Routes -and $Routes.Count -gt 0) { $impl = $Routes[0] }
        $result += [pscustomobject]@{ Name=$name; Description=$desc; Implementation=$impl }
    } }
    return $result
}

# ---------- IA: Sitemap Report ----------
function Parse-IAForSitemapReport { param([string]$ProjectPath)
    $projectName = Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath
    # Prefer project model from state
    try {
        $state = Get-ProjectState -ProjectPath $ProjectPath
        if ($state -and $state.ContainsKey('project_model') -and $state.project_model -and $state.ContainsKey('ia_model') -and $state.ia_model) {
            $routes = @($state.ia_model.routes)
            $modals = @($state.ia_model.modals)
            $oos = @($state.ia_model.out_of_scope)
            $features = @()
            if ($state.ContainsKey('prd_model') -and $state.prd_model -and $state.prd_model.ContainsKey('features')){
                foreach($f in $state.prd_model.features){
                    $impl = ''
                    if ($state.project_model.feature_to_routes.ContainsKey($f.name) -and $state.project_model.feature_to_routes[$f.name].Count -gt 0){ $impl = ($state.project_model.feature_to_routes[$f.name] -join ', ') }
                    $features += [pscustomobject]@{ Name=$f.name; Description=$f.description; Implementation=$impl }
                }
            }
            # Build reverse mapping from feature_to_routes if route_to_features is incomplete
            if (-not $state.project_model.route_to_features -or $state.project_model.route_to_features.Count -eq 0) {
                $state.project_model.route_to_features = @{}
            }
            foreach ($feature in $state.project_model.feature_to_routes.GetEnumerator()) {
                foreach ($route in $feature.Value) {
                    if (-not $state.project_model.route_to_features.ContainsKey($route)) {
                        $state.project_model.route_to_features[$route] = @()
                    }
                    if ($state.project_model.route_to_features[$route] -notcontains $feature.Key) {
                        $state.project_model.route_to_features[$route] += $feature.Key
                    }
                }
            }
            $screens = @()
            foreach($r in $routes){
                $core = ''
                if ($state.project_model.route_to_features.ContainsKey($r)){
                    $coreVal = $state.project_model.route_to_features[$r]
                    if ($coreVal -is [string]){ $core = $coreVal }
                    elseif ($coreVal -and $coreVal.Count -gt 0){ $core = $coreVal[0] }
                }
                # Filter out empty hashtables and ensure we get real component/entity arrays
                $kc = @()
                if ($state.ia_model.components_by_route.ContainsKey($r)){
                    $kcVal = $state.ia_model.components_by_route.$r
                    if ($kcVal -and $kcVal -isnot [hashtable] -and $kcVal.Count -gt 0){ $kc = @($kcVal) }
                }
                $dd = @()
                if ($state.ia_model.entities_by_route.ContainsKey($r)){
                    $ddVal = $state.ia_model.entities_by_route.$r
                    if ($ddVal -and $ddVal -isnot [hashtable] -and $ddVal.Count -gt 0){ $dd = @($ddVal) }
                }
                $purpose = 'TBD'
                if ($state.ia_model.purpose_map -and $state.ia_model.purpose_map.ContainsKey($r)) { $purpose = $state.ia_model.purpose_map[$r] }

                # Extract connectivity from flows
                $entryPoints = @()
                $exitPoints = @()
                if ($state.ia_model.flows) {
                    foreach ($flow in $state.ia_model.flows) {
                        if ($flow.steps) {
                            $stepArray = @()
                            if ($flow.steps -is [string]) {
                                $stepArray = @($flow.steps)
                            } elseif ($flow.steps -is [array]) {
                                $stepArray = $flow.steps
                            }

                            if ($stepArray.Count -gt 0) {
                                if ($stepArray[0] -eq $r) {
                                    $entryPoints += $flow.name
                                }
                                if ($stepArray[-1] -eq $r) {
                                    $exitPoints += $flow.name
                                }
                            }
                        }
                    }
                }
                $entryText = if ($entryPoints.Count -gt 0) { $entryPoints -join ', ' } else { 'N/A' }
                $exitText = if ($exitPoints.Count -gt 0) { $exitPoints -join ', ' } else { 'N/A' }

                $screens += [pscustomobject]@{ Route=$r; Purpose=$purpose; CoreFeature=$core; KeyComponents=@($kc); DataDependencies=@($dd); Connectivity=@{ EntryPoints=$entryText; ExitPoints=$exitText } }
            }
            return [pscustomobject]@{ ProjectName=$projectName; Sitemap=@{ Routes=$routes; Modals=@($modals); OutOfScope=@($oos) }; Features=@{ InScope=@($features); OutOfScope=@() }; ScreenAnalysis=@($screens) }
        }
    } catch {}
    $sitemapText = Get-IASectionText -ProjectPath $ProjectPath -Section 'sitemap'
    $flowsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'flows'
    $componentsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'components'
    $entitiesText = Get-IASectionText -ProjectPath $ProjectPath -Section 'entities'
    $navigationText = Get-IASectionText -ProjectPath $ProjectPath -Section 'navigation'

    # Prefer IA model from project state if available
    $state = $null
    try { $state = Get-ProjectState -ProjectPath $ProjectPath } catch {}
    $routes = @()
    $modals = @()
    $outOfScope = @()
    $labelMap = @{}
    $componentsByRoute = @{}
    $entitiesByRoute = @{}
    if ($state -and $state.ContainsKey('ia_model') -and $state.ia_model) {
        if ($state.ia_model.PSObject.Properties.Name -contains 'routes') { $routes = @($state.ia_model.routes) }
        if ($state.ia_model.PSObject.Properties.Name -contains 'modals') { $modals = @($state.ia_model.modals) }
        if ($state.ia_model.PSObject.Properties.Name -contains 'out_of_scope') { $outOfScope = @($state.ia_model.out_of_scope) }
        if ($state.ia_model.PSObject.Properties.Name -contains 'components_by_route') { $componentsByRoute = @{}; foreach($k in $state.ia_model.components_by_route.PSObject.Properties.Name){ $componentsByRoute[$k] = @($state.ia_model.components_by_route.$k) } }
        if ($state.ia_model.PSObject.Properties.Name -contains 'entities_by_route') { $entitiesByRoute = @{}; foreach($k in $state.ia_model.entities_by_route.PSObject.Properties.Name){ $entitiesByRoute[$k] = @($state.ia_model.entities_by_route.$k) } }
    }

    if (-not $routes -or $routes.Count -eq 0) {
        $sitemap = Parse-SitemapSection -SitemapText $sitemapText
        $routes = @($sitemap.Routes)
        if (-not $routes -or $routes.Count -eq 0) { $routes = @('/home') }
        $modals = @($sitemap.Modals)
        $outOfScope = @($sitemap.OutOfScope)
        $labelMap = $sitemap.LabelMap
    }

    # Features for report: prefer PRD features with descriptions; fallback to flows
    function Tokenize-Name([string]$s){ if(-not $s){ return @() }; return ($s.ToLower() -replace '[^a-z0-9 ]','').Split(' ') | ? { $_.Length -ge 4 } }
    function RouteHint-ForToken([string]$tok){ switch -Regex ($tok){ 'workout|session|set' { '/workout' } 'template|assign|plan' { '/templates' } 'insight|trend|correl' { '/insights' } 'dash|home' { '/dashboard' } 'journal|habit' { '/journal' } 'progress|photo|metric' { '/progress' } 'export' { '/export' } 'exercise' { '/exercises' } default { $null } } }

    $features = @()
    $prdFeaturesFull = Parse-PRDFeaturesFull -ProjectPath $ProjectPath
    if ($prdFeaturesFull -and $prdFeaturesFull.Count -gt 0) {
        foreach($pf in $prdFeaturesFull){
            $hints=@(); foreach($t in (Tokenize-Name ($pf.Name + ' ' + $pf.Description))){ $h = RouteHint-ForToken $t; if ($h) { $hints += $h } }
            $hints = ($hints | Select-Object -Unique)
            $impl = if ($hints -and $hints.Count -gt 0) { ($hints -join ', ') } elseif ($routes.Count -gt 0) { $routes[0] } else { '/' }
            $features += [pscustomobject]@{ Name=$pf.Name; Description=($pf.Description); Implementation=$impl }
        }
    } else {
        $features = Parse-FeaturesFromFlows -FlowsText $flowsText -Routes $routes
    }

    # Components by route
    $componentsByRoute = @{}; foreach($r in $routes){ $componentsByRoute[$r]=@() }
    if ($componentsText) {
        $cl = $componentsText -split "`n"
        # Pattern 1: Headings like '# /route' then bullet list
        for($i=0;$i -lt $cl.Count;$i++){
            if ($cl[$i].Trim() -match '^#+\s*(/[^\s]+)\s*$'){
                $route = $matches[1]
                $items = @()
                for($j=$i+1;$j -lt $cl.Count;$j++){
                    $t = $cl[$j].Trim(); if ($t -match '^#'){ break }
                    if ($t -match '^[-*]\s+(.+)$'){ $items += $matches[1].Trim() }
                }
                $componentsByRoute[$route] = $items
            }
        }
        # Pattern 2: Inline mappings like '/route: ItemA, ItemB, ItemC'
        for($i=0;$i -lt $cl.Count;$i++){
            $t = $cl[$i].Trim()
            if ($t -match '^(?<route>/[A-Za-z0-9][A-Za-z0-9/_:\-]*)\s*:\s*(?<items>.+)$'){
                $route = $matches['route']
                $items = @($matches['items'].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                if (-not $componentsByRoute.ContainsKey($route) -or ($componentsByRoute[$route].Count -eq 0)){
                    $componentsByRoute[$route] = $items
                } else {
                    $componentsByRoute[$route] = @($componentsByRoute[$route] + $items | Select-Object -Unique)
                }
            }
        }
    }

    # Entities (merge IA model + parsed)
    if (-not $entitiesByRoute -or $entitiesByRoute.Keys.Count -eq 0){ $entitiesByRoute = @{}; foreach($r in $routes){ $entitiesByRoute[$r]=@() } }
    if ($entitiesText -and $entitiesText.Trim()) {
        # Fallback A: simple global bullet list
        $globals = @(); foreach($ln in ($entitiesText -split "`n")){ if ($ln.Trim() -match '^[*-]\s+(.+)$'){ $globals += $matches[1].Trim() } }
        if ($globals.Count -gt 0){ foreach($r in $routes){ $entitiesByRoute[$r] = $globals } }
        else {
            # Fallback B: parse 'Entity: Name' blocks with 'Used On: /route, /route'
            $currentName = $null
            foreach($ln in ($entitiesText -split "`n")){
                $t = $ln.Trim()
                if ($t -match '^(?i)Entity\s*:\s*(.+)$'){ $currentName = $matches[1].Trim(); continue }
                if ($currentName -and ($t -match '^(?i)Used\s*On\s*:\s*(.+)$')){
                    $routesListed = @($matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                    foreach($rl in $routesListed){ if ($routes -contains $rl){ $entitiesByRoute[$rl] = @($entitiesByRoute[$rl] + $currentName) } }
                    $currentName = $null
                }
            }
            foreach($k in @($entitiesByRoute.Keys)) { $entitiesByRoute[$k] = @($entitiesByRoute[$k] | Select-Object -Unique) }
        }
    }

    # Primary nav labels
    $primaryNav = @()
    if ($navigationText -and ($navigationText -match '(?im)^Primary\s+Navigation\s*:\s*(.+)$')){
        $labels = $matches[1] -split '[,|]+'
        foreach($lab in $labels){ $r = Find-RouteForLabel -LabelMap $sitemap.LabelMap -Label $lab.Trim(); if ($r) { $primaryNav += $r } }
        $primaryNav = $primaryNav | Select-Object -Unique
    }
    if (($primaryNav.Count -eq 0) -and ($state -and $state.ia_model -and $state.ia_model.PSObject.Properties.Name -contains 'primary_nav')){
        foreach($lab in $state.ia_model.primary_nav){ $r = Find-RouteForLabel -LabelMap $labelMap -Label $lab; if ($r) { $primaryNav += $r } }
        $primaryNav = $primaryNav | Select-Object -Unique
    }

    $screens = @()
    foreach($r in $routes){
        $coreFeature = ''
        if ($features -and $features.Count -gt 0) { $coreFeature = $features[0].Name }

        $keyComponents = @()
        if ($componentsByRoute.ContainsKey($r)) { $keyComponents = @($componentsByRoute[$r]) }

        $dataDependencies = @()
        if ($entitiesByRoute.ContainsKey($r)) { $dataDependencies = @($entitiesByRoute[$r]) }

        # Calculate entry/exit points from flows
        $entryFlows = @()
        $exitFlows = @()
        if ($state.ia_model.flows) {
            foreach($fl in $state.ia_model.flows){
                # Handle both hashtable and PSCustomObject
                $flowSteps = if ($fl -is [hashtable] -and $fl.ContainsKey('steps')) { $fl['steps'] } elseif ($fl.PSObject.Properties['steps']) { $fl.steps } else { @() }
                $flowName = if ($fl -is [hashtable]) { $fl['name'] } else { $fl.name }

                if ($flowSteps -and $flowSteps.Count -gt 0){
                    $firstStep = $flowSteps[0]
                    $lastStep = $flowSteps[$flowSteps.Count - 1]
                    if ($firstStep -eq $r){ $entryFlows += $flowName }
                    if ($lastStep -eq $r){ $exitFlows += $flowName }
                }
            }
        }

        $entryPoints = if ($entryFlows.Count -gt 0) { $entryFlows -join ', ' } elseif ($primaryNav -and ($primaryNav -contains $r)) { 'Primary Navigation' } else { 'N/A' }
        $exitPoints = if ($exitFlows.Count -gt 0) { $exitFlows -join ', ' } else { 'N/A' }
        $connectivity = @{ EntryPoints = $entryPoints; ExitPoints = $exitPoints }

        $screens += [pscustomobject]@{
            Route = $r
            Purpose = 'TBD'
            CoreFeature = $coreFeature
            KeyComponents = @($keyComponents)
            DataDependencies = @($dataDependencies)
            Connectivity = $connectivity
        }
    }

    $future = @($outOfScope)
    return [pscustomobject]@{
        ProjectName = $projectName
        Sitemap = @{ Routes = $routes; Modals = @($modals); OutOfScope = @($outOfScope) }
        Features = @{ InScope = @($features); OutOfScope = @() }
        ScreenAnalysis = @($screens)
    }
}

# ---------- IA: User Flows Report ----------
function Parse-IAForUserFlowsReport { param([string]$ProjectPath)
    $projectName = Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath
    # Prefer project model flows/routes from state
    try {
        $state = Get-ProjectState -ProjectPath $ProjectPath
        if ($state -and $state.ContainsKey('project_model') -and $state.project_model -and $state.ContainsKey('ia_model') -and $state.ia_model) {
            $flows = @()
            # Handle both hashtable and PSCustomObject
            $hasFlows = $false
            if ($state.ia_model -is [System.Collections.IDictionary]) {
                $hasFlows = $state.ia_model.ContainsKey('flows')
            } elseif ($state.ia_model.PSObject.Properties.Name -contains 'flows') {
                $hasFlows = $true
            }
            if ($hasFlows){
                foreach($fl in $state.ia_model.flows){
                    # Handle errors - can be array or empty hashtable from JSON deserialization
                    $errorStates = @()
                    if ($fl.errors) {
                        if ($fl.errors -is [array]) {
                            $errorStates = @($fl.errors)
                        } elseif ($fl.errors -is [System.Collections.IDictionary] -and $fl.errors.Count -gt 0) {
                            $errorStates = @($fl.errors.Values)
                        }
                    }
                    $goal = if ($fl.PSObject.Properties.Name -contains 'goal') { $fl.goal } elseif ($fl -is [System.Collections.IDictionary] -and $fl.ContainsKey('goal')) { $fl.goal } else { '' }
                    $obj = [pscustomobject]@{ Name=$fl.name; Purpose=$fl.purpose; Goal=$goal; EntryPoint=$fl.entry; Steps=@($fl.steps); SuccessScenario=$fl.success; ErrorStates=$errorStates; PreCondition=''; DataRead=@(); DataCreated=@(); DataUpdated=@(); EmptyStates='' }
                    $flows += ,$obj
                }
            }
            $maps = @()
            foreach($f in $flows){
                $impl = if ($f.EntryPoint) { $f.EntryPoint } elseif ($f.Steps -and $f.Steps.Count -gt 0) { $f.Steps[0] } else { '/' + ($f.Name.ToLower() -replace '[^a-z0-9 ]','' -replace '\s+','-') }
                $maps += [pscustomobject]@{ Feature=$f.Name; Description=$f.Purpose; Flow=$impl }
            }
            $oos = @()
            $hasOOS = if ($state.ia_model -is [System.Collections.IDictionary]) { $state.ia_model.ContainsKey('out_of_scope') } else { $state.ia_model.PSObject.Properties.Name -contains 'out_of_scope' }
            if ($hasOOS){ $oos = @($state.ia_model.out_of_scope | Where-Object { $_ -and ($_ -notmatch '^Totals:') }) }
            return [pscustomobject]@{ ProjectName=$projectName; Flows=@($flows); FeaturesMapping=@($maps); FutureFeatures=@($oos); PrdFeatureCoverage=@() }
        }
    } catch {}
    $sitemapText = Get-IASectionText -ProjectPath $ProjectPath -Section 'sitemap'
    $flowsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'flows'
    $sitemap = Parse-SitemapSection -SitemapText $sitemapText
    $routes = @($sitemap.Routes); if (-not $routes -or $routes.Count -eq 0){ $routes = @('/home') }

    $flows = @(); if ($flowsText){
        $lines = $flowsText -split "`n"; $current = $null
        foreach($ln in $lines){ $t = $ln.Trim()
            if ($t -match '(?i)^(Primary\s+Flow|Secondary\s+Flow|Tertiary\s+Flow|Flow\s*\d+|Flow|Feature)\s*:\s*(.+)$'){
                if ($current -ne $null) { $flows += ,$current; $current = $null }
                $raw = $matches[2].Trim(); $name=$raw; $purpose=''
                if ($raw -match '^(.*?)\s+-\s+(.*)$'){ $name=$matches[1].Trim(); $purpose=$matches[2].Trim() }
                $current = [pscustomobject]@{
                    Name=$name; Purpose=$purpose; EntryPoint='N/A'; PreCondition=''; Steps=@(); DataRead=@(); DataCreated=@(); DataUpdated=@(); SuccessScenario=''; ErrorStates=@(); EmptyStates=''
                }
                continue
            }
            if ($current -ne $null) {
                if ($t -match '^/[A-Za-z0-9][A-Za-z0-9/_\-]*'){ $current.Steps += $t; if ($current.EntryPoint -eq 'N/A'){ $current.EntryPoint = $t } }
                if ($t -match '(?i)success\s*:\s*(.+)$'){ $current.SuccessScenario = $matches[1].Trim() }
                if ($t -match '(?i)pre-?condition\s*:\s*(.+)$'){ $current.PreCondition = $matches[1].Trim() }
                if ($t -match '(?i)error\s*:\s*(.+)$'){ $current.ErrorStates += $matches[1].Trim() }
                if ($t -match '(?i)empty\s*:\s*(.+)$'){ $current.EmptyStates = $matches[1].Trim() }
            }
        }
        if ($current -ne $null) { $flows += ,$current }
    }

    # Heuristic data inference from route token verbs
    foreach($f in $flows){
        $read=@(); $created=@(); $updated=@()
        foreach($st in $f.Steps){
            $low = $st.ToLower()
            if ($low -match '/new|/create|add') { $created += 'Record' }
            elseif ($low -match '/edit|/update') { $updated += 'Record' }
            else { $read += 'Record' }
        }
        $f | Add-Member -NotePropertyName DataRead -NotePropertyValue (@($read | Select-Object -Unique)) -Force
        $f | Add-Member -NotePropertyName DataCreated -NotePropertyValue (@($created | Select-Object -Unique)) -Force
        $f | Add-Member -NotePropertyName DataUpdated -NotePropertyValue (@($updated | Select-Object -Unique)) -Force
    }

    # Feature mapping (flow heading to feature list)
        $maps = @()
    foreach($f in $flows){
        $flowPath = '/'+($f.Name.ToLower() -replace '[^a-z0-9 ]','' -replace '\s+','-')
        $impl = $flowPath
        if ($f.EntryPoint -and $f.EntryPoint -ne 'N/A') { $impl = $f.EntryPoint }
        $maps += [pscustomobject]@{ Feature=$f.Name; Description=$f.Purpose; Flow=$impl }
    }

    # PRD Feature Cross-Reference (PRD-only data)
    function Get-PrdText([string]$ProjectPath){ $p = Join-Path $ProjectPath 'prd.md'; if (Test-Path $p) { return (Get-Content $p -Raw -Encoding UTF8) } return '' }
    function Parse-PRDFeatures { param([string]$ProjectPath)
        $txt = Get-PrdText $ProjectPath; if (-not $txt) { return @() }
        $features = @()
        if ($txt -match '(?is)##\s*Features\s*(.*?)(?=\n##\s|\Z)'){
            $block = $matches[1]
            foreach($ln in ($block -split "`n")){
                $t=$ln.Trim(); if ($t -match '^###\s*\d+\.\s*(.+)$'){ $features += [pscustomobject]@{ Name=$matches[1].Trim(); Scope='unknown' } }
            }
        }
        if ($txt -match '(?is)##\s*MVP\s*Scope\s*(.*?)(?=\n##\s|\Z)'){
            $scopeBlock=$matches[1]
            $must=@(); $should=@(); $could=@()
            if ($scopeBlock -match '(?is)Must-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $must = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
            if ($scopeBlock -match '(?is)Should-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $should = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
            if ($scopeBlock -match '(?is)Could-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $could = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
            function Norm([string]$s){ return (($s.ToLower() -replace '[^a-z0-9 ]','').Trim()) }
            for($i=0;$i -lt $features.Count;$i++){
                $n = Norm $features[$i].Name; $sc='unknown'
                foreach($x in $must){ if (Norm $x -eq $n){ $sc='must'; break } }
                if ($sc -eq 'unknown'){ foreach($x in $should){ if (Norm $x -eq $n){ $sc='should'; break } } }
                if ($sc -eq 'unknown'){ foreach($x in $could){ if (Norm $x -eq $n){ $sc='could'; break } } }
                $features[$i] = [pscustomobject]@{ Name=$features[$i].Name; Scope=$sc }
            }
        }
        return $features
    }
    function Tokenize([string]$s){ if(-not $s){ return @() }; return ($s.ToLower() -replace '[^a-z0-9 ]','').Split(' ') | ? { $_.Length -ge 4 } }
    function RoutesForToken([string]$tok){ switch -Regex ($tok){ 'workout|session|set' { '/workout' } 'template|assign|plan' { '/templates' } 'insight|trend|correl' { '/insights' } 'dash|home' { '/dashboard' } default { $null } } }
    function Map-FeaturesToFlows { param($prdFeatures,$flows)
        $out=@()
        foreach($pf in $prdFeatures){
            $ftoks = Tokenize $pf.Name
            $routeHints = @(); foreach($t in $ftoks){ $h = RoutesForToken $t; if ($h) { $routeHints += $h } }
            $matchedFlows=@()
            foreach($fl in $flows){
                $nametoks = Tokenize $fl.Name
                $score = (@($nametoks | ? { $ftoks -contains $_ })).Count
                $routesOk = $false
                foreach($st in $fl.Steps){ if ($st -is [string]){ foreach($rh in $routeHints){ if ($st.ToLower().StartsWith($rh)) { $routesOk=$true; break } } }; if ($routesOk){ break } }
                if ($score -gt 0 -or $routesOk){ $matchedFlows += $fl.Name }
            }
            $matchedFlows = $matchedFlows | Select-Object -Unique
            $notes = ''
            if (-not ($matchedFlows -and $matchedFlows.Count -gt 0)) { $notes = 'No matching flow found; consider adding or updating flows.' }
            $out += [pscustomobject]@{ Feature=$pf.Name; Scope=$pf.Scope; Flows=@($matchedFlows); Notes=$notes }
        }
        return $out
    }
    $prdFeatures = Parse-PRDFeatures -ProjectPath $ProjectPath
    $prdCoverage = Map-FeaturesToFlows -prdFeatures $prdFeatures -flows $flows

    return [pscustomobject]@{
        ProjectName = $projectName
        Flows = @($flows)
        FeaturesMapping = @($maps)
        FutureFeatures = @($sitemap.OutOfScope)
        PrdFeatureCoverage = @($prdCoverage)
    }
}

# ---------- PRD parsing for PRD-report (PRD-only, no IA deps) ----------
function Get-PrdText { param([string]$ProjectPath)
    $p = Join-Path $ProjectPath 'prd.md'
    if (Test-Path $p) { return (Get-Content $p -Raw -Encoding UTF8) }
    return ''
}

function Parse-PRDFeaturesFull { param([string]$ProjectPath)
    $txt = Get-PrdText $ProjectPath; if (-not $txt) { return @() }
    $features = @()

    # Enhanced feature section header patterns to match multiple variations
    # Matches: Features, Requirements, Capabilities, Functionality, Functional Requirements, Feature List, etc.
    $featurePattern = '(?is)##\s*(?:Features?|Functional\s*Requirements?|Requirements?|Capabilities?|Functionality|Feature\s*List|Core\s*Features?|Key\s*Features?|Product\s*Features?)\s*(.*?)(?=\n##\s|\Z)'
    if ($txt -match $featurePattern){
        $block = $matches[1]
        $lines = $block -split "`n"
        $current = $null
        $section = ''
        $descBuf = @()
        foreach($ln in $lines){
            $t = $ln.Trim()
            if ($t -match '^(?:###|####)\s*(?:\d+\.\s*)?(.+)$' -or $t -match '^(?i)\s*Feature\s*:\s*(.+)$'){
                if ($current -ne $null) { $features += ,$current; $current=$null }
                $name = if ($matches[1]) { $matches[1].Trim() } elseif ($matches[0] -match 'Feature\s*:\s*(.+)$'){ $matches[1].Trim() } else { $t }
                $current = [pscustomobject]@{ Name=$name; Description=''; AcceptanceDone=0; AcceptanceTotal=0; Stories=@(); NfrInline=@(); KpisInline=@() }
                $section = ''
                $descBuf = @()
                continue
            }
            if ($current -eq $null) { continue }

            # Section cues within a feature block
            if ($t -match '^(?i)####\s*(User\s*Stories|Stories)'){ $section='stories'; continue }
            if ($t -match '^(?i)####\s*(Acceptance|Acceptance\s*Criteria|Definition\s*of\s*Done|Done\s*When|Success\s*Criteria)'){ $section='acceptance'; continue }
            if ($t -match '^(?i)####\s*(NFRs?|Non\s*-?\s*Functional|Quality\s*Attributes|Constraints)'){ $section='nfr'; continue }
            if ($t -match '^(?i)####\s*(KPI|KPIs|Metrics|Success\s*Metrics|Objectives)'){ $section='kpi'; continue }

            # Description
            if ($t -match '^(?i)(Description|Summary|Overview|Goal|Objective|Purpose)\s*:\s*(.+)$'){ $current.Description = $matches[2].Trim(); continue }
            # Unlabeled description paragraphs before any subsection
            if (-not $section -and $t -and -not ($t -match '^(?:###|####)') -and -not ($t -match '^(?i)(User\s*Stories|Stories|Acceptance|Definition\s*of\s*Done|Done\s*When|Success\s*Criteria|NFR|Non\s*-?\s*Functional|Quality\s*Attributes|Constraints|KPI|KPIs|Metrics|Objectives)\b') ){
                # Avoid counting pure acceptance/story bullets as description
                if (-not ($t -match '^(?i)(As\s+a\s+)|(Given|When|Then)\b')) { $descBuf += $t }
            }

            # Stories (inline or section)
            if ($t -match '(?i)^(?:[-*]\s+)?As\s+a\s+.+?\s+I\s+want\s+.+?\s+so\s+that\s+.+$' -or $section -eq 'stories'){
                if ($t){ if ($t -match '(?i)As\s+a'){ $current.Stories += $t } }
            }
            # Capture story labels
            if ($t -match '^(?i)(User\s*Story|Story)\s*:\s*(.+)$'){ $current.Stories += $matches[2].Trim() }

            # Acceptance (bullets or Gherkin lines) — count regardless of section
            if ($t -match '^(?i)[*-]\s+(.+)$'){
                $current.AcceptanceTotal++
                if ($t -match '(?i)must|shall|given|when|then') { $current.AcceptanceDone++ }
                if ($section -eq 'kpi') { $current.KpisInline += $matches[1].Trim() }
                if ($section -eq 'nfr') { $current.NfrInline  += $matches[1].Trim() }
            } elseif ($t -match '^(?i)(Given|When|Then)\b'){
                $current.AcceptanceTotal++
                $current.AcceptanceDone++
            } elseif ($section -eq 'kpi' -and $t){
                $current.KpisInline += $t
            } elseif ($section -eq 'nfr' -and $t){
                $current.NfrInline += $t
            }

            # KPI heuristics in free text (table or inline)
            if ($t -match '(?i)\b(KPI|metric|target|timeframe|increase|decrease|by\s*\d+%|\b\d+%\b|OKR|goal|p9[59]|ms|seconds|req/s|qps|rps)\b' -or $t -match '^\|.+\|.+\|'){ $current.KpisInline += $t }
            # NFR heuristics in free text
            if ($t -match '(?i)performance|latency|throughput|security|privacy|gdpr|hipaa|soc2|iso\s*27001|availability|uptime|reliability|scalability|maintainability|usability|accessibility|compliance|audit|encryption|p95|p99') { $current.NfrInline += $t }
        }
        if ($current -ne $null) {
            # Finalize description if empty
            if (-not $current.Description -and $descBuf.Count -gt 0){
                $desc = ($descBuf -join ' ') -replace '\s+',' '
                if ($desc.Length -gt 240) { $desc = $desc.Substring(0,237) + '...' }
                $current | Add-Member -NotePropertyName Description -NotePropertyValue $desc -Force
            }
            elseif (-not $current.Description -and $current.Stories -and $current.Stories.Count -gt 0){
                $story = $current.Stories[0]
                if ($story -match '(?i)^As\s+a\s+(.+?)\s+I\s+want\s+(.+?)\s+so\s+that\s+(.+)$'){
                    $role=$matches[1].Trim(); $want=$matches[2].Trim(); $why=$matches[3].Trim()
                    $desc = ('For ' + $role + ': ' + $want + ' so that ' + $why + '.')
                } else { $desc = $story }
                if ($desc.Length -gt 240) { $desc = $desc.Substring(0,237) + '...' }
                $current | Add-Member -NotePropertyName Description -NotePropertyValue $desc -Force
            }
            $features += ,$current
        }
    }
    return $features
}

function Parse-PRDScope { param([string]$ProjectPath)
    $txt = Get-PrdText $ProjectPath; $scope = @{ must=@(); should=@(); could=@() }
    if (-not $txt) { return $scope }

    # Match scope section with multiple header variations
    $scopePattern = '(?is)##\s*(MVP\s*)?(?:Scope|Roadmap|Priorities|Phase\s*1|V1\s*Scope)\s*(.*?)(?=\n##\s|\Z)'
    if ($txt -match $scopePattern){
        $block = $matches[2]

        # Match MUST-HAVE variations: "Must-Have", "Must Have", "Essential", "Required", "Core", "Critical", "P0"
        $mustPattern = '(?is)(?:Must-?Have|Essential|Required|Core|Critical|P0|High\s*Priority).*?\n(.+?)(?=\n\s*###|\Z)'
        if ($block -match $mustPattern){
            $scope.must = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ })
        }

        # Match SHOULD-HAVE variations: "Should-Have", "Should Have", "Important", "Desired", "P1"
        $shouldPattern = '(?is)(?:Should-?Have|Important|Desired|Nice\s*to\s*Have|P1|Medium\s*Priority).*?\n(.+?)(?=\n\s*###|\Z)'
        if ($block -match $shouldPattern){
            $scope.should = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ })
        }

        # Match COULD-HAVE variations: "Could-Have", "Could Have", "Optional", "Future", "P2", "Low Priority"
        $couldPattern = '(?is)(?:Could-?Have|Optional|Future|Later|P2|Low\s*Priority|Stretch\s*Goals?).*?\n(.+?)(?=\n\s*###|\Z)'
        if ($block -match $couldPattern){
            $scope.could = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ })
        }
    }
    return $scope
}

function Parse-PRDUserStories { param([string]$ProjectPath)
    $txt = Get-PrdText $ProjectPath; $stories=@()
    if (-not $txt) { return $stories }
    # Global user stories section
    if ($txt -match '(?is)##\s*User\s*Stories\s*(.*?)(?=\n##\s|\Z)'){
        $block = $matches[1]
        foreach($ln in ($block -split "`n")){
            $t=$ln.Trim(); if ($t -match '^(?i)[*-]\s+(.+)$'){ $stories += $matches[1].Trim() }
        }
    }
    # Also extract any classic story lines anywhere
    foreach($ln in ($txt -split "`n")){
        $t=$ln.Trim(); if ($t -match '(?i)^As\s+a\s+.+?\s+I\s+want\s+.+?\s+so\s+that\s+.+$'){ $stories += $t }
    }
    return ($stories | Select-Object -Unique)
}

function Parse-PRDNFRs { param([string]$ProjectPath)
    $txt = Get-PrdText $ProjectPath; $areas=@()
    if (-not $txt) { return $areas }
    if ($txt -match '(?is)##\s*Non-\s*Functional.*?\n(.*?)(?=\n##\s|\Z)'){
        $block = $matches[1]
        foreach($ln in ($block -split "`n")){
            $t=$ln.Trim(); if ($t -match '^(?i)[*-]\s+(.+)$'){ $areas += $matches[1].Trim() }
        }
    }
    return ($areas | Select-Object -Unique)
}

function Parse-PRDKPIs { param([string]$ProjectPath)
    $txt = Get-PrdText $ProjectPath; $kpis=@()
    if (-not $txt) { return $kpis }
    if ($txt -match '(?is)##\s*(Success\s*Metrics|KPIs).*?\n(.*?)(?=\n##\s|\Z)'){
        $block = $matches[2]
        foreach($ln in ($block -split "`n")){
            $t=$ln.Trim(); if ($t -match '^(?i)[*-]\s+(.+)$'){ $kpis += $matches[1].Trim() }
            elseif ($t -match '^\|'){ $kpis += $t }
        }
    }
    return $kpis
}

function Map-PRDFeatureMeta { param($features,$scope,$stories,$nfrs,$kpis)
    function Norm([string]$s){ return (($s.ToLower() -replace '[^a-z0-9 ]','').Trim()) }
    function Tokens([string]$s){ if(-not $s){ return @() }; return (Norm $s).Split(' ') | ? { $_.Length -ge 3 } }
    # scope mapping
    foreach($f in $features){
        $n = Norm $f.Name; $sc='UNKNOWN'
        foreach($x in $scope.must){ if (Norm $x -eq $n){ $sc='MUST'; break } }
        if ($sc -eq 'UNKNOWN'){ foreach($x in $scope.should){ if (Norm $x -eq $n){ $sc='SHOULD'; break } } }
        if ($sc -eq 'UNKNOWN'){ foreach($x in $scope.could){ if (Norm $x -eq $n){ $sc='COULD'; break } } }
        $f | Add-Member -NotePropertyName Scope -NotePropertyValue $sc -Force
    }
    # stories: prefer inline, then map from globals
    foreach($f in $features){
        $existing = @()
        if ($f.PSObject.Properties.Name -contains 'Stories') { $existing = $f.Stories }
        $assigned = @()
        if ($existing -and $existing.Count -gt 0) { $assigned = @($existing) }
        else {
            $ft = Expand-SemanticTokens (Tokens ($f.Name + ' ' + $f.Description))
            foreach($s in $stories){ $st=Expand-SemanticTokens (Tokens $s); if ((@($ft | ? { $st -contains $_ })).Count -gt 0){ $assigned += $s } }
        }
        $f | Add-Member -NotePropertyName Stories -NotePropertyValue @($assigned | Select-Object -Unique) -Force
    }
    # NFR areas: combine inline cues + global area list intersection + name heuristics
    $validAreas = @('Performance','Security','Privacy','Reliability','Availability','Scalability','Maintainability','Usability','Accessibility','Compliance')
    foreach($f in $features){
        $areas=@()
        if ($f.PSObject.Properties.Name -contains 'NfrInline'){
            $t = ($f.NfrInline -join ' ').ToLower()
            foreach($a in $validAreas){ $al=$a.ToLower(); if ($t -match [regex]::Escape($al)) { $areas += $a } }
        }
        # Intersect recognized areas with global NFR list if provided
        if ($nfrs -and $nfrs.Count -gt 0){ $areas = @($areas | Where-Object { $nfrs -contains $_ }) }
        # Heuristics from name as fallback
        if ($areas.Count -eq 0){ $name=$f.Name.ToLower(); if ($name -match 'perf|latency|load|scale|cach'){ $areas += 'Performance' }; if ($name -match 'secur|auth|encrypt|privacy'){ $areas += 'Security' }; if ($name -match 'accessib|a11y|ux|usabil'){ $areas += 'Accessibility' } }
        $f | Add-Member -NotePropertyName NfrAreas -NotePropertyValue @($areas | Select-Object -Unique) -Force
    }
    # KPIs: prefer inline, then map from globals
    foreach($f in $features){
        $assigned=@()
        if ($f.PSObject.Properties.Name -contains 'KpisInline' -and $f.KpisInline -and $f.KpisInline.Count -gt 0){ $assigned = @($f.KpisInline) }
        else {
            $ft=Expand-SemanticTokens (Tokens ($f.Name + ' ' + $f.Description))
            foreach($k in $kpis){ $kt=Expand-SemanticTokens (Tokens $k); if ((@($ft | ? { $kt -contains $_ })).Count -gt 0){ $assigned += $k } }
        }
        $f | Add-Member -NotePropertyName Kpis -NotePropertyValue @($assigned | Select-Object -Unique) -Force
    }
    return $features
}

function Parse-PRDForReport { param([string]$ProjectPath)
    $projectName = Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath
    $features = Parse-PRDFeaturesFull -ProjectPath $ProjectPath
    $scope = Parse-PRDScope -ProjectPath $ProjectPath
    $stories = Parse-PRDUserStories -ProjectPath $ProjectPath
    $nfrs = Parse-PRDNFRs -ProjectPath $ProjectPath
    $kpis = Parse-PRDKPIs -ProjectPath $ProjectPath
    $features = Map-PRDFeatureMeta -features $features -scope $scope -stories $stories -nfrs $nfrs -kpis $kpis
    return [pscustomobject]@{
        ProjectName = $projectName
        Features = @($features)
        Scope = $scope
        NfrAreas = @($nfrs)
        Kpis = @($kpis)
        UserStories = @($stories)
    }
}




