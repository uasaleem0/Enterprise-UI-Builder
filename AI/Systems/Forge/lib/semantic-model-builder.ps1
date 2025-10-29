<#
 Project Model Builder
 - Builds a single derived project_model in .forge-prd-state.json by linking PRD and IA models
 - Works offline (heuristic parsers); optionally benefits from AI models if present
 - Keeps project_model lean: only links + meta, no duplication of PRD/IA content
#>

. "$PSScriptRoot/state-manager.ps1"
. "$PSScriptRoot/ia-heuristic-parser.ps1"
. "$PSScriptRoot/ai-extractor.ps1"

function Get-TextHash {
    param([string]$Text)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = $sha1.ComputeHash($bytes)
    ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-ProjectSourcesHash {
    param([string]$ProjectPath)
    $prd = ''
    $prdPath = Join-Path $ProjectPath 'prd.md'
    if (Test-Path $prdPath) { $prd = Get-Content -Path $prdPath -Raw -Encoding UTF8 }
    $iaDir = Join-Path $ProjectPath 'ia'
    $iaConcat = ''
    if (Test-Path $iaDir) {
        $files = Get-ChildItem $iaDir -File | Sort-Object Name
        foreach ($f in $files) { $iaConcat += (Get-Content -Path $f.FullName -Raw -Encoding UTF8) }
    }
    return @{ prd_hash = (Get-TextHash $prd); ia_hash = (Get-TextHash $iaConcat) }
}

function Build-ProjectSemanticModel {
    param([string]$ProjectPath)

    $state = Get-ProjectState -ProjectPath $ProjectPath

    # Ensure minimal PRD model (heuristic if AI not used)
    $currentHash = Get-ProjectSourcesHash -ProjectPath $ProjectPath
    $needsPrdRebuild = $true
    if ($state.ContainsKey('prd_model') -and $state.prd_model) {
        $needsPrdRebuild = $false
        # Rebuild if PRD hash changed or acceptance property missing
        if ($state.ContainsKey('project_model') -and $state.project_model -and $state.project_model.meta -and $state.project_model.meta.prd_hash) {
            if ($state.project_model.meta.prd_hash -ne $currentHash.prd_hash) { $needsPrdRebuild = $true }
        }
        if (-not $needsPrdRebuild) {
            try {
                foreach ($f in $state.prd_model.features) { if (-not ($f.PSObject.Properties.Name -contains 'acceptance')) { $needsPrdRebuild = $true; break } }
            } catch { $needsPrdRebuild = $true }
        }
    }
    if ($needsPrdRebuild) {
        # Always parse from source PRD to build baseline (heuristic-first)
        Write-Host "  Building PRD model using heuristic parsing..." -ForegroundColor Cyan
        $features = Parse-PRDFeaturesFull -ProjectPath $ProjectPath
        $scope = Parse-PRDScope -ProjectPath $ProjectPath
        $pm = @()
        foreach($f in $features){
            $sc = 'UNKNOWN'
            if ($scope.must -and ($scope.must -contains $f.Name)) { $sc='MUST' }
            elseif ($scope.should -and ($scope.should -contains $f.Name)) { $sc='SHOULD' }
            elseif ($scope.could -and ($scope.could -contains $f.Name)) { $sc='COULD' }

            # Canonicalize feature properties to lowercase keys expected by analyzers
            $name = if ($f.PSObject.Properties.Name -contains 'name') { $f.name } else { $f.Name }
            $desc = if ($f.PSObject.Properties.Name -contains 'description') { $f.description } elseif ($f.PSObject.Properties.Name -contains 'Description') { $f.Description } else { '' }
            $acc  = @()
            if ($f.PSObject.Properties.Name -contains 'acceptance') { $acc = @($f.acceptance) }
            elseif ($f.PSObject.Properties.Name -contains 'Acceptance') { $acc = @($f.Acceptance) }
            $accDone = 0; $accTotal = 0
            if ($f.PSObject.Properties.Name -contains 'AcceptanceDone') { $accDone = [int]$f.AcceptanceDone }
            if ($f.PSObject.Properties.Name -contains 'AcceptanceTotal') { $accTotal = [int]$f.AcceptanceTotal }
            $stories = @()
            if ($f.PSObject.Properties.Name -contains 'stories') { $stories = @($f.stories) }
            elseif ($f.PSObject.Properties.Name -contains 'Stories') { $stories = @($f.Stories) }
            $nfr = @()
            if ($f.PSObject.Properties.Name -contains 'nfr') { $nfr = @($f.nfr) }
            elseif ($f.PSObject.Properties.Name -contains 'NfrAreas') { $nfr = @($f.NfrAreas) }
            elseif ($f.PSObject.Properties.Name -contains 'NfrInline') { $nfr = @($f.NfrInline) }
            $kpis = @()
            if ($f.PSObject.Properties.Name -contains 'kpis') { $kpis = @($f.kpis) }
            elseif ($f.PSObject.Properties.Name -contains 'Kpis') { $kpis = @($f.Kpis) }
            elseif ($f.PSObject.Properties.Name -contains 'KpisInline') { $kpis = @($f.KpisInline) }

            $pm += [pscustomobject]@{
                name = $name
                scope = $sc
                description = $desc
                acceptance = @($acc)
                acceptance_done = $accDone
                acceptance_total = $accTotal
                stories = @($stories)
                nfr = @($nfr)
                kpis = @($kpis)
            }
        }
        $state.prd_model = @{ features = @($pm) }
        Write-Host "  PRD model built: $($pm.Count) features extracted" -ForegroundColor Green

        # Optional AI enrichment (non-blocking, merge-only)
        try {
            $provider = Get-EnvOrNull 'FORGE_AI_PROVIDER'
            if ($provider) {
                $tmpJson = Join-Path $ProjectPath 'ai_parsed_prd.json.tmp'
                $outPath = Invoke-ForgeAIExtract -PrdPath (Join-Path $ProjectPath 'prd.md') -OutJsonPath $tmpJson
                if (Test-Path $outPath) {
                    $ai = Get-Content -Path $outPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($ai -and $ai.PSObject.Properties.Name -contains 'features') {
                        $baseline = $state.prd_model.features
                        $enriched = @()
                        foreach($bf in $baseline){
                            $match = $null
                            foreach($af in $ai.features){ if ($af.name -and $af.name.ToLower() -eq $bf.name.ToLower()) { $match = $af; break } }
                            if ($match) {
                                # Merge: append/infer but do not overwrite existing baseline fields
                                $desc = if ($bf.description) { $bf.description } else { $match.description }
                                $acc = @($bf.acceptance + @(if ($match.acceptance) { $match.acceptance } else { @() })) | Select-Object -Unique
                                $stories = @($bf.stories + @(if ($match.stories) { $match.stories } else { @() })) | Select-Object -Unique
                                $nfr = @($bf.nfr + @(if ($match.nfr) { $match.nfr } else { @() })) | Select-Object -Unique
                                $kpis = @($bf.kpis + @(if ($match.kpis) { $match.kpis } else { @() })) | Select-Object -Unique
                                $enriched += [pscustomobject]@{
                                    name = $bf.name
                                    scope = $bf.scope
                                    description = $desc
                                    acceptance = @($acc)
                                    acceptance_done = (@($acc)).Count
                                    acceptance_total = (@($acc)).Count
                                    stories = @($stories)
                                    nfr = @($nfr)
                                    kpis = @($kpis)
                                }
                            } else {
                                $enriched += $bf
                            }
                        }
                        $state.prd_model = @{ features = @($enriched) }
                    }
                }
                if (Test-Path $tmpJson) { Remove-Item -LiteralPath $tmpJson -Force -ErrorAction SilentlyContinue }
            }
        } catch { Write-Host "  AI enrichment skipped: $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  Using existing PRD model from state" -ForegroundColor Gray
    }

    # IA model: require explicit IA inputs or successful AI extraction. Do not create placeholders.
    # Rebuild if ia_model doesn't exist OR if IA files have changed
    $needsRebuild = $false
    if (-not ($state.ContainsKey('ia_model') -and $state.ia_model)) {
        $needsRebuild = $true
    } elseif ($state.ContainsKey('project_model') -and $state.project_model -and $state.project_model.meta -and $state.project_model.meta.ia_hash) {
        if ($state.project_model.meta.ia_hash -ne $currentHash.ia_hash) {
            $needsRebuild = $true
        }
    } else {
        $needsRebuild = $true
    }

    if ($needsRebuild) {
        # Try AI extraction first
        $iaDir = Join-Path $ProjectPath 'ia'
        $useAI = $false
        $iaModel = $null

        if (Test-Path $iaDir) {
            $provider = Get-EnvOrNull 'FORGE_AI_PROVIDER'
            $hasApiKey = $false
            if ($provider -match '^openai') {
                $hasApiKey = [bool](Get-EnvOrNull 'OPENAI_API_KEY')
            } elseif ($provider -match '^anthropic') {
                $hasApiKey = [bool](Get-EnvOrNull 'ANTHROPIC_API_KEY')
            }

            if ($hasApiKey) {
                try {
                    Write-Host "  Using AI to extract IA model..." -ForegroundColor Cyan
                    $aiResult = Invoke-ForgeIAExtract -ProjectPath $ProjectPath

                    # Convert AI result to hashtable
                    $iaModel = @{
                        routes = @($aiResult.routes)
                        modals = @($aiResult.modals)
                        out_of_scope = @($aiResult.out_of_scope)
                        primary_nav = @($aiResult.primary_nav)
                        components_by_route = @{}
                        entities_by_route = @{}
                        flows = @()
                        purpose_map = @{}
                    }

                    # Convert components_by_route
                    if ($aiResult.components_by_route) {
                        foreach ($prop in $aiResult.components_by_route.PSObject.Properties) {
                            $iaModel.components_by_route[$prop.Name] = @($prop.Value)
                        }
                    }

                    # Convert entities_by_route
                    if ($aiResult.entities_by_route) {
                        foreach ($prop in $aiResult.entities_by_route.PSObject.Properties) {
                            $iaModel.entities_by_route[$prop.Name] = @($prop.Value)
                        }
                    }

                    # Convert flows to hashtable array
                    if ($aiResult.flows) {
                        foreach ($f in $aiResult.flows) {
                            $iaModel.flows += @{
                                name = if ($f.name) { $f.name } else { '' }
                                purpose = if ($f.purpose) { $f.purpose } else { '' }
                                goal = if ($f.PSObject.Properties['goal']) { $f.goal } else { '' }
                                steps = if ($f.steps) { @($f.steps) } else { @() }
                                entry = if ($f.entry) { $f.entry } else { 'N/A' }
                                success = if ($f.success) { $f.success } else { '' }
                                errors = if ($f.errors) { @($f.errors) } else { @() }
                            }
                        }
                    }

                    # Convert purpose_map
                    if ($aiResult.PSObject.Properties['purpose_map'] -and $aiResult.purpose_map) {
                        foreach ($prop in $aiResult.purpose_map.PSObject.Properties) {
                            $iaModel.purpose_map[$prop.Name] = $prop.Value
                        }
                    }

                    $useAI = $true
                    $iaModel.extraction_method = 'AI'
                    $iaModel.extraction_timestamp = (Get-Date).ToString('s')
                    Write-Host "  AI extraction successful" -ForegroundColor Green
                } catch {
                    Write-Host "  AI extraction failed: $($_.Exception.Message)" -ForegroundColor Yellow
                    Write-Host "  Falling back to heuristic parsing..." -ForegroundColor Yellow
                }
            }
        }

        # Heuristic parsing only if IA content exists; do not create defaults
        if (-not $useAI) {
        $sitemapText = Get-IASectionText -ProjectPath $ProjectPath -Section 'sitemap'
        $componentsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'components'
        $entitiesText = Get-IASectionText -ProjectPath $ProjectPath -Section 'entities'
        $navigationText = Get-IASectionText -ProjectPath $ProjectPath -Section 'navigation'
        $flowsText = Get-IASectionText -ProjectPath $ProjectPath -Section 'flows'

        if (-not $sitemapText -and -not $componentsText -and -not $entitiesText -and -not $navigationText -and -not $flowsText) {
            Write-Host "  No IA content found; skipping IA model build" -ForegroundColor Yellow
        } else {
            Write-Host "  Building IA model from existing IA files..." -ForegroundColor Cyan
            $smap = Parse-SitemapSection -SitemapText $sitemapText
            # Components mapping
            $routes = @($smap.Routes)
        $purposeMap = @{}; if ($smap.PurposeMap) { $purposeMap = $smap.PurposeMap }
        $compByRoute = @{}; foreach($r in $routes){ $compByRoute[$r]=@() }
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
                    $compByRoute[$route] = $items
                }
            }
            for($i=0;$i -lt $cl.Count;$i++){
                $t = $cl[$i].Trim()
                if ($t -match '^(?<route>/[A-Za-z0-9][A-Za-z0-9/_:\-]*)\s*:\s*(?<items>.+)$'){
                    $route = $matches['route']
                    $items = @($matches['items'].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                    if (-not $compByRoute.ContainsKey($route) -or ($compByRoute[$route].Count -eq 0)){
                        $compByRoute[$route] = $items
                    } else {
                        $compByRoute[$route] = @($compByRoute[$route] + $items | Select-Object -Unique)
                    }
                }
            }
        }
        # Entities - lenient semantic parser for multiple formats
        $entByRoute = @{}; foreach($r in $routes){ $entByRoute[$r]=@() }
        if ($entitiesText) {
            $lines = $entitiesText -split "`n"
            $currentEntity = $null
            $inEntityBlock = $false

            foreach($ln in $lines){
                $t = $ln.Trim()
                if (-not $t -or $t -match '^#') { continue }  # Skip empty/headers

                # Match entity declarations with multiple format variations
                # Matches: "Entity: Name", "Model: Name", "Data Entity: Name", "Domain Object: Name", etc.
                $entityPattern = '(?i)^(?:Entity|Model|Data\s+(?:Entity|Model|Object)|Domain\s+(?:Entity|Model|Object)|Resource)\s*:?\s*(.+?)(?:\s*\(|$)'
                if ($t -match $entityPattern){
                    $currentEntity = $matches[1].Trim()
                    $inEntityBlock = $true
                    continue
                }

                # Match route references with multiple label variations
                # Matches: "Used On:", "Routes:", "Screens:", "Pages:", "Views:", "Found On:", "Used In:", etc.
                $routeRefPattern = '(?i)^(?:Used\s+(?:On|In)|(?:Found|Seen)\s+(?:On|In)|Routes?|Screens?|Pages?|Views?|Paths?)\s*:\s*(.+)$'
                if ($currentEntity -and $t -match $routeRefPattern){
                    $routesList = $matches[1]
                    # Extract ALL route patterns from the line
                    foreach($m in [regex]::Matches($routesList,'/[A-Za-z0-9][A-Za-z0-9/_:\-]*')){
                        $route = $m.Value
                        if (-not $entByRoute.ContainsKey($route)){ $entByRoute[$route] = @() }
                        if (-not ($entByRoute[$route] -contains $currentEntity)) {
                            $entByRoute[$route] += $currentEntity
                        }
                    }
                    continue
                }

                # If line starts with "Fields:", "Relationships:", we're still in entity block
                if ($t -match '(?i)^(?:Fields?|Relationships?|Constraints?|Validations?)\s*:') {
                    $inEntityBlock = $true
                    continue
                }

                # Empty line or new section resets entity
                if ($t -match '^-{3,}' -or ($inEntityBlock -and -not $t)) {
                    $currentEntity = $null
                    $inEntityBlock = $false
                }
            }
        }
        # Flows - lenient semantic parser for multiple formats
        $flows = @()
        if ($flowsText) {
            $lines = $flowsText -split "`n"; $current = $null
            foreach($ln in $lines){
                $t = $ln.Trim()
                if (-not $t -or $t -match '^#') { continue }  # Skip empty/headers

                # Match flow/journey/process headers with multiple format variations
                # Formats supported:
                # - "Workout Tracking Flow" (standalone with keyword)
                # - "Flow: Name", "Primary Flow: Name", "1. Flow Name" (labeled)
                # - "User Journey: Name", "Process: Name", "Workflow: Name" (alternative keywords)

                # Pattern 1: Standalone headers ending with flow/journey/process (case-insensitive)
                if ($t -match '(?i)^([A-Z][A-Za-z\s]+(?:Flow|Journey|Process|Workflow|Path))s?$'){
                    if ($current -ne $null) { $flows += ,$current; $current = $null }
                    $current = [pscustomobject]@{ name=$matches[1].Trim(); purpose=''; goal=''; steps=@(); entry='N/A'; success=''; errors=@() }
                    continue
                }

                # Pattern 2: Labeled format with priority/numbering and keyword variations
                $flowKeywords = 'Flow|User\s+Flow|Journey|User\s+Journey|Process|Workflow|Path|Feature|Use\s+Case'
                $flowPrefixes = 'Primary|Secondary|Tertiary|Quaternary|Main|Alternative|Happy\s+Path|Error\s+Path'
                if ($t -match "(?i)^(?:\d+\.\s*)?(?:$flowPrefixes)?\s*(?:$flowKeywords)\s*:\s*(.+)$"){
                    if ($current -ne $null) { $flows += ,$current; $current = $null }
                    $raw = $matches[1].Trim()
                    # Extract name and purpose from " - " separator
                    $name=$raw; $purpose=''
                    if ($raw -match '^(.*?)\s+-\s+(.*)$'){ $name=$matches[1].Trim(); $purpose=$matches[2].Trim() }
                    $current = [pscustomobject]@{ name=$name; purpose=$purpose; goal=''; steps=@(); entry='N/A'; success=''; errors=@() }
                    continue
                }

                if ($current -ne $null) {
                    # Goal/Purpose field
                    if ($t -match '(?i)^(?:Goal|Purpose)\s*:\s*(.+)$'){
                        $val = $matches[1].Trim()
                        if (-not $current.goal) { $current.goal = $val }
                        if (-not $current.purpose) { $current.purpose = $val }
                        continue
                    }

                    # Steps field - extract ALL routes from the line
                    if ($t -match '(?i)^Steps\s*:\s*(.+)$'){
                        $seg = $matches[1]
                        $routesIn = @()
                        # Extract all /route patterns
                        foreach($m in [regex]::Matches($seg,'/[A-Za-z0-9][A-Za-z0-9/_\-:]*')){ $routesIn += $m.Value }
                        # If no routes found, try splitting by delimiters
                        if ($routesIn.Count -eq 0){
                            $parts = $seg -split '\?|->|→|›|»|,' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                            foreach($p in $parts){ if ($p -match '^/[A-Za-z0-9]'){ $routesIn += $p } }
                        }
                        if ($routesIn.Count -gt 0){
                            $current.steps = @($routesIn)
                            $current.entry = $routesIn[0]
                        }
                        continue
                    }

                    # Success/outcome field
                    if ($t -match '(?i)^(?:Success|Outcome|Result)\s*:\s*(.+)$'){
                        $current.success = $matches[1].Trim()
                        continue
                    }

                    # Error/failure field
                    if ($t -match '(?i)^(?:Errors?|Failures?|Edge\s+Cases?)\s*:\s*(.+)$'){
                        $current.errors += $matches[1].Trim()
                        continue
                    }
                }
            }
            if ($current -ne $null) { $flows += ,$current }
        }

        # Convert flows to array of hashtables for JSON serialization
        $flowsArray = @()
        foreach ($f in $flows) {
            $flowsArray += @{
                name = $f.name
                purpose = $f.purpose
                goal = $f.goal
                steps = @($f.steps)
                entry = $f.entry
                success = $f.success
                errors = @($f.errors)
            }
        }

            $iaModel = @{
                routes = @($routes); modals = @($smap.Modals); out_of_scope = @($smap.OutOfScope);
                primary_nav = @(); components_by_route = $compByRoute; entities_by_route = $entByRoute; flows = $flowsArray;
                purpose_map = $purposeMap;
                extraction_method = 'Heuristic';
                extraction_timestamp = (Get-Date).ToString('s')
            }
        Write-Host "  IA model built: $($routes.Count) routes, $($flowsArray.Count) flows extracted" -ForegroundColor Green
        }
        }

        # Store the IA model (either from AI or heuristic)
        $state.ia_model = $iaModel
    } else {
        Write-Host "  Using existing IA model from state (no changes detected)" -ForegroundColor Gray
    }

    # Build derived links (project_model) only if IA model exists
    if (-not ($state.ContainsKey('ia_model') -and $state.ia_model -and $state.ia_model.routes -and $state.ia_model.routes.Count -gt 0)) {
        Write-Host "  IA model not present; skipping project model linking" -ForegroundColor Yellow
        Set-ProjectState -ProjectPath $ProjectPath -State $state
        return
    }

    Write-Host "  Building project model (linking PRD features to IA routes)..." -ForegroundColor Cyan
    function Tokens([string]$s){ if(-not $s){ return @() }; return (($s.ToLower() -replace '[^a-z0-9 ]','').Split(' ') | Where-Object { $_.Length -ge 4 }) }
    function RoutesForToken([string]$tok){ switch -Regex ($tok){ 'workout|session|set' { '/workout' } 'template|assign|plan' { '/templates' } 'insight|trend|correl' { '/insights' } 'dash|home' { '/dashboard' } 'journal|habit' { '/journal' } 'progress|photo|metric' { '/progress' } 'export' { '/export' } 'exercise' { '/exercises' } default { $null } } }

    $feature_to_routes = @{}
    $route_to_features = @{}
    foreach($r in $state.ia_model.routes){ $route_to_features[$r] = @() }
    foreach($f in $state.prd_model.features){
        $hints = @()
        foreach($t in (Tokens ($f.name + ' ' + $f.description))){ $h = RoutesForToken $t; if ($h) { $hints += $h } }
        $hints = $hints | Select-Object -Unique
        $routesPick = @()
        if ($state.ia_model.flows -and $state.ia_model.flows.Count -gt 0){
            foreach($fl in $state.ia_model.flows){
                # Handle both hashtable and PSCustomObject flows
                $flowSteps = if ($fl -is [hashtable] -and $fl.ContainsKey('steps')) { $fl['steps'] } elseif ($fl.PSObject.Properties['steps']) { $fl.steps } else { @() }
                foreach($st in $flowSteps){
                    # Ensure $st is a string
                    $stepStr = if ($st -is [string]) { $st } else { [string]$st }
                    if ($stepStr -and $hints | Where-Object { $stepStr.StartsWith($_) }){ $routesPick += $stepStr }
                }
            }
        }
        if ($routesPick.Count -eq 0){ $routesPick = $hints }
        if ($routesPick.Count -eq 0 -and $state.ia_model.routes.Count -gt 0){ $routesPick += $state.ia_model.routes[0] }
        $feature_to_routes[$f.name] = @($routesPick | Select-Object -Unique)
        foreach($rr in $feature_to_routes[$f.name]){ if (-not $route_to_features.ContainsKey($rr)) { $route_to_features[$rr] = @() }; $route_to_features[$rr] = @($route_to_features[$rr] + $f.name | Select-Object -Unique) }
    }

    $flow_to_routes = @{}
    if ($state.ia_model.flows -and $state.ia_model.flows.Count -gt 0) {
        foreach($fl in $state.ia_model.flows){
            if ($fl -and $fl.name) {
                $rt = @()
                # Handle both hashtable and PSCustomObject flows
                $flowSteps = if ($fl -is [hashtable] -and $fl.ContainsKey('steps')) { $fl['steps'] } elseif ($fl.PSObject.Properties['steps']) { $fl.steps } else { @() }
                if ($flowSteps -and $flowSteps.Count -gt 0){ $rt = @($flowSteps) }
                elseif ($fl.entry -and $fl.entry -ne 'N/A'){ $rt = @($fl.entry) }
                elseif ($fl['entry'] -and $fl['entry'] -ne 'N/A'){ $rt = @($fl['entry']) }
                $flow_to_routes[$fl.name] = @($rt)
            }
        }
    }

    $issues = @{}
    if ($state.ContainsKey('semantic_analysis') -and $state.semantic_analysis){
        # Ensure issues is a hashtable, not PSCustomObject
        if ($state.semantic_analysis -is [PSCustomObject]) {
            foreach ($prop in $state.semantic_analysis.PSObject.Properties) {
                $issues[$prop.Name] = $prop.Value
            }
        } else {
            $issues = $state.semantic_analysis
        }
    }

    $meta = Get-ProjectSourcesHash -ProjectPath $ProjectPath
    $meta['built_at'] = (Get-Date).ToString('s')

    $state.project_model = @{ feature_to_routes = $feature_to_routes; route_to_features = $route_to_features; flow_to_routes = $flow_to_routes; issues = $issues; meta = $meta }

    # Summary of extraction methods used
    $prdMethod = if ($state.prd_model.PSObject.Properties['extraction_method'] -and $state.prd_model.extraction_method) { $state.prd_model.extraction_method } else { 'Heuristic' }
    $iaMethod = if ($state.ia_model.extraction_method) { $state.ia_model.extraction_method } else { 'Unknown' }
    Write-Host "  Project model complete - PRD: $prdMethod | IA: $iaMethod" -ForegroundColor Green

    Set-ProjectState -ProjectPath $ProjectPath -State $state
}
