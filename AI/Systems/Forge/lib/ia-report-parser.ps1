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
            $raw = Get-Content -Path $p -Raw -Encoding UTF8 | Normalize-Text
            $lines = @(); foreach($ln in ($raw -split "`n")){
                if ($ln -match '^#\s' -or $ln -match '^Generated:' -or $ln -match '^Confidence:') { continue }
                $lines += $ln
            }
            return ($lines -join "`n").Trim()
        }
    }
    $iaSingle = Join-Path $ProjectPath 'ia.md'
    if (Test-Path $iaSingle) {
        $txt = Get-Content -Path $iaSingle -Raw -Encoding UTF8 | Normalize-Text
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
    if (-not $SitemapText) { return [pscustomobject]@{ Routes=@(); Modals=@(); OutOfScope=@(); LabelMap=@{} } }
    $lines = ($SitemapText -split "`n")
    $idxRoutes = -1; $idxModals = -1; $idxOut = -1
    for($i=0;$i -lt $lines.Count;$i++){
        $t = $lines[$i].Trim()
        if ($idxRoutes -lt 0 -and $t -match '(?i)^(V\d+\s+)?Screens\s*/\s*Routes\s*:') { $idxRoutes = $i; continue }
        if ($idxModals -lt 0 -and $t -match '(?i)^Modals(\s*[&/\-]\s*Drawers)?\s*\((No\s+URL|No\s+Route)\)\s*:') { $idxModals = $i; continue }
        if ($idxOut -lt 0 -and $t -match '(?i)^Out\s*-?\s*of\s*-?\s*Scope.*:') { $idxOut = $i; continue }
    }
    function Clean([string]$ln){ return ($ln -replace '^\s*[-*]+\s*','').Trim() }
    function Take([int]$start,[int]$end){ $items=@(); for($j=$start;$j -lt $end -and $j -ge 0 -and $j -lt $lines.Count;$j++){ $x=Clean $lines[$j]; if($x){ $items+=$x } }; return $items }
    $routesEnd = @($idxModals,$idxOut,$lines.Count) | Where-Object { $_ -gt $idxRoutes } | Sort-Object | Select-Object -First 1
    if ($idxRoutes -ge 0){ foreach($rc in (Take ($idxRoutes+1) $routesEnd)){
        if ($rc -match '^(?<label>[^:]+):\s*(?<route>/[A-Za-z0-9][A-Za-z0-9/_\-]*)\s*$'){ $label=$matches['label'].Trim(); $route=$matches['route']; if (-not ($routes -contains $route)) { $routes.Add($route) }; if ($label) { $labelMap[$label]=$route } }
        elseif ($rc -match '^(?<route>/[A-Za-z0-9][A-Za-z0-9/_\-]*)\s*$'){ $route=$matches['route']; if (-not ($routes -contains $route)) { $routes.Add($route) } }
    } } else {
        foreach($ln in $lines){ $t=$ln.Trim(); if ($t -match '^/[A-Za-z0-9][A-Za-z0-9/_\-]*$'){ if (-not ($routes -contains $t)) { $routes.Add($t) } } }
    }
    if ($idxModals -ge 0){ $modEnd = @($idxOut,$lines.Count) | Where-Object { $_ -gt $idxModals } | Sort-Object | Select-Object -First 1; foreach($m in (Take ($idxModals+1) $modEnd)){ if ($m -notmatch '^/') { $modals.Add($m) } } }
    if ($idxOut -ge 0){ foreach($o in (Take ($idxOut+1) $lines.Count)){ if ($o){ $outOfScope.Add($o) } } }
    return [pscustomobject]@{ Routes=$routes; Modals=$modals; OutOfScope=$outOfScope; LabelMap=$labelMap }
}

function Parse-FeaturesFromFlows { param([string]$FlowsText,[string[]]$Routes)
    $result = @(); if (-not $FlowsText) { return $result }
    $lines = $FlowsText -split "`n"
    foreach($ln in $lines){ $t=$ln.Trim(); if ($t -match '(?i)^(Primary\s+Flow|Secondary\s+Flow|Tertiary\s+Flow|Flow\s*\d+|Flow|Feature)\s*:\s*(.+)$'){
        $raw = $matches[2].Trim(); $name=$raw; $desc=''
        if ($raw -match '^(.*?)\s+-\s+(.*)$'){ $name=$matches[1].Trim(); $desc=$matches[2].Trim() }
        $impl = if ($Routes -and $Routes.Count -gt 0) { $Routes[0] } else { '/' }
        $result += [pscustomobject]@{ Name=$name; Description=$desc; Implementation=$impl }
    } }
    return $result
}

# ---------- IA: Sitemap Report ----------
function Parse-IAForSitemapReport { param([string]$ProjectPath)
    $projectName = Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath
    $sitemapText = Get-IASectionText -ProjectPath $ProjectPath -Section 'sitemap'
    $flowsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'flows'
    $componentsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'components'
    $entitiesText = Get-IASectionText -ProjectPath $ProjectPath -Section 'entities'
    $navigationText = Get-IASectionText -ProjectPath $ProjectPath -Section 'navigation'

    $sitemap = Parse-SitemapSection -SitemapText $sitemapText
    $routes = @($sitemap.Routes); if (-not $routes -or $routes.Count -eq 0) { $routes = @('/home') }
    $features = Parse-FeaturesFromFlows -FlowsText $flowsText -Routes $routes

    # Components by route (headings like '# /route' then bullets)
    $componentsByRoute = @{}; foreach($r in $routes){ $componentsByRoute[$r]=@() }
    if ($componentsText) {
        $cl = $componentsText -split "`n"
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
    }

    # Entities (global list fallback)
    $entitiesByRoute = @{}; foreach($r in $routes){ $entitiesByRoute[$r]=@() }
    if ($entitiesText) {
        $globals = @(); foreach($ln in ($entitiesText -split "`n")){ if ($ln.Trim() -match '^[*-]\s+(.+)$'){ $globals += $matches[1].Trim() } }
        if ($globals.Count -gt 0){ foreach($r in $routes){ $entitiesByRoute[$r] = $globals } }
    }

    # Primary nav labels
    $primaryNav = @()
    if ($navigationText -and ($navigationText -match '(?im)^Primary\s+Navigation\s*:\s*(.+)$')){
        $labels = $matches[1] -split '[,|]+'
        foreach($lab in $labels){ $r = Find-RouteForLabel -LabelMap $sitemap.LabelMap -Label $lab.Trim(); if ($r) { $primaryNav += $r } }
        $primaryNav = $primaryNav | Select-Object -Unique
    }

    $screens = @()
    foreach($r in $routes){
        $screens += [pscustomobject]@{
            Route = $r
            Purpose = 'TBD'
            CoreFeature = if ($features.Count -gt 0) { $features[0].Name } else { '' }
            KeyComponents = if ($componentsByRoute.ContainsKey($r)) { $componentsByRoute[$r] } else { @() }
            DataDependencies = if ($entitiesByRoute.ContainsKey($r)) { $entitiesByRoute[$r] } else { @() }
            Connectivity = @{ EntryPoints = (if ($primaryNav -contains $r) { 'Primary Navigation' } else { 'N/A' }); ExitPoints = 'N/A' }
        }
    }

    $future = @($sitemap.OutOfScope)
    return [pscustomobject]@{
        ProjectName = $projectName
        Sitemap = @{ Routes = $routes; Modals = @($sitemap.Modals); OutOfScope = @($sitemap.OutOfScope) }
        Features = @{ InScope = @($features); OutOfScope = @() }
        ScreenAnalysis = @($screens)
    }
}

# ---------- IA: User Flows Report ----------
function Parse-IAForUserFlowsReport { param([string]$ProjectPath)
    $projectName = Get-ProjectNameFromPrdOrFolder -ProjectPath $ProjectPath
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
    $maps = @(); foreach($f in $flows){ $maps += [pscustomobject]@{ Feature=$f.Name; Description=$f.Purpose; Flow=(if ($f.EntryPoint -ne 'N/A'){ $f.EntryPoint } else { '/'+($f.Name.ToLower() -replace '[^a-z0-9 ]','' -replace '\s+','-') }) } }

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
            $notes = if ($matchedFlows -and $matchedFlows.Count -gt 0){ '' } else { 'No matching flow found; consider adding or updating flows.' }
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
    # Accept several common feature section headings
    if ($txt -match '(?is)##\s*(Features|Functional\s*Requirements|Requirements|Feature\s*List)\s*(.*?)(?=\n##\s|\Z)'){
        $block = $matches[2]
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
    if ($txt -match '(?is)##\s*MVP\s*Scope\s*(.*?)(?=\n##\s|\Z)'){
        $block = $matches[1]
        if ($block -match '(?is)Must-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $scope.must = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
        if ($block -match '(?is)Should-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $scope.should = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
        if ($block -match '(?is)Could-?Have.*?\n(.+?)(?=\n\s*###|\Z)'){ $scope.could = (($matches[1] -split ',\s*|\n') | % { $_.Trim().Trim('.') } | ? { $_ }) }
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
        $existing = if ($f.PSObject.Properties.Name -contains 'Stories') { $f.Stories } else { @() }
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
