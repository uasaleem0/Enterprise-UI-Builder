<#
 .SYNOPSIS
     Evolve Reporter for displaying analysis and results
 .DESCRIPTION
     Formats and displays analysis reports for evolve-spec changes
#>

function Show-EvolveAnalysisReport {
    <#
    .SYNOPSIS
    Displays a formatted analysis report

    .PARAMETER Analysis
    Analysis result from Get-ChangeImpact or Invoke-ForgeEvolveAnalysis

    .PARAMETER Width
    Report width (default: 78)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Analysis,

        [Parameter(Mandatory=$false)]
        [int]$Width = 78
    )

    $rule = '=' * $Width
    $sep = '-' * $Width

    Write-Host ""
    Write-Host $rule -ForegroundColor Cyan
    Write-Host "CHANGE IMPACT ANALYSIS" -ForegroundColor Cyan
    Write-Host $rule -ForegroundColor Cyan
    Write-Host ""

    # User Request
    if ($Analysis.request) {
        Write-Host "REQUEST:" -ForegroundColor Yellow
        Write-Host "  $($Analysis.request)" -ForegroundColor White
        Write-Host ""
    }

    # Intent
    if ($Analysis.intent) {
        Write-Host "DETECTED INTENT:" -ForegroundColor Yellow
        Write-Host "  Operation: $($Analysis.intent.operation)" -ForegroundColor White
        Write-Host "  Target: $($Analysis.intent.target)" -ForegroundColor White
        if ($Analysis.intent.entity_name) {
            Write-Host "  Entity: $($Analysis.intent.entity_name)" -ForegroundColor White
        }
        Write-Host "  Scope: $($Analysis.intent.scope)" -ForegroundColor White
        Write-Host ""
    }

    # PRD Changes
    if ($Analysis.prd_changes) {
        $hasPRDChanges = $false
        foreach ($key in $Analysis.prd_changes.Keys) {
            if ($Analysis.prd_changes[$key] -and $Analysis.prd_changes[$key].Count -gt 0) {
                $hasPRDChanges = $true
                break
            }
        }

        if ($hasPRDChanges) {
            Write-Host "PRD MODIFICATIONS:" -ForegroundColor Yellow
            Write-Host ""

            if ($Analysis.prd_changes.features_add -and $Analysis.prd_changes.features_add.Count -gt 0) {
                Write-Host "  Features to Add:" -ForegroundColor Cyan
                foreach ($f in $Analysis.prd_changes.features_add) {
                    Write-Host "    + $($f.name) [$($f.scope)]" -ForegroundColor Green
                    if ($f.description) {
                        Write-Host "      $($f.description)" -ForegroundColor Gray
                    }
                }
                Write-Host ""
            }

            if ($Analysis.prd_changes.features_modify -and $Analysis.prd_changes.features_modify.Count -gt 0) {
                Write-Host "  Features to Modify:" -ForegroundColor Cyan
                foreach ($f in $Analysis.prd_changes.features_modify) {
                    Write-Host "    * $($f.name)" -ForegroundColor Yellow
                }
                Write-Host ""
            }

            if ($Analysis.prd_changes.features_remove -and $Analysis.prd_changes.features_remove.Count -gt 0) {
                Write-Host "  Features to Remove:" -ForegroundColor Cyan
                foreach ($f in $Analysis.prd_changes.features_remove) {
                    Write-Host "    - $($f.name)" -ForegroundColor Red
                }
                Write-Host ""
            }

            if ($Analysis.prd_changes.nfr_add -and $Analysis.prd_changes.nfr_add.Count -gt 0) {
                Write-Host "  Non-Functional Requirements to Add:" -ForegroundColor Cyan
                foreach ($nfr in $Analysis.prd_changes.nfr_add) {
                    Write-Host "    + [$($nfr.category)] $($nfr.requirement)" -ForegroundColor Green
                }
                Write-Host ""
            }

            if ($Analysis.prd_changes.kpis_add -and $Analysis.prd_changes.kpis_add.Count -gt 0) {
                Write-Host "  KPIs to Add:" -ForegroundColor Cyan
                foreach ($kpi in $Analysis.prd_changes.kpis_add) {
                    if ($kpi.metric) {
                        Write-Host "    + $($kpi.metric): $($kpi.target)" -ForegroundColor Green
                    } else {
                        Write-Host "    + $($kpi.description)" -ForegroundColor Green
                    }
                }
                Write-Host ""
            }
        }
    }

    # IA Changes
    if ($Analysis.ia_changes) {
        $hasIAChanges = $false
        foreach ($key in $Analysis.ia_changes.Keys) {
            if ($Analysis.ia_changes[$key] -and $Analysis.ia_changes[$key].Count -gt 0) {
                $hasIAChanges = $true
                break
            }
        }

        if ($hasIAChanges) {
            Write-Host "IA MODIFICATIONS:" -ForegroundColor Yellow
            Write-Host ""

            if ($Analysis.ia_changes.routes_add -and $Analysis.ia_changes.routes_add.Count -gt 0) {
                Write-Host "  Routes to Add:" -ForegroundColor Cyan
                foreach ($r in $Analysis.ia_changes.routes_add) {
                    Write-Host "    + $($r.route)" -ForegroundColor Green
                    if ($r.description) {
                        Write-Host "      $($r.description)" -ForegroundColor Gray
                    }
                }
                Write-Host ""
            }

            if ($Analysis.ia_changes.flows_add -and $Analysis.ia_changes.flows_add.Count -gt 0) {
                Write-Host "  User Flows to Add:" -ForegroundColor Cyan
                foreach ($f in $Analysis.ia_changes.flows_add) {
                    Write-Host "    + $($f.name)" -ForegroundColor Green
                    if ($f.steps) {
                        Write-Host "      Steps: $($f.steps -join ' -> ')" -ForegroundColor Gray
                    }
                }
                Write-Host ""
            }

            if ($Analysis.ia_changes.components_add -and $Analysis.ia_changes.components_add.Count -gt 0) {
                Write-Host "  Components to Add:" -ForegroundColor Cyan
                foreach ($c in $Analysis.ia_changes.components_add) {
                    Write-Host "    Route: $($c.route)" -ForegroundColor Cyan
                    foreach ($comp in $c.components) {
                        Write-Host "      + $comp" -ForegroundColor Green
                    }
                }
                Write-Host ""
            }

            if ($Analysis.ia_changes.entities_add -and $Analysis.ia_changes.entities_add.Count -gt 0) {
                Write-Host "  Data Entities to Add:" -ForegroundColor Cyan
                foreach ($e in $Analysis.ia_changes.entities_add) {
                    Write-Host "    + $($e.name)" -ForegroundColor Green
                    if ($e.fields) {
                        Write-Host "      Fields: $($e.fields -join ', ')" -ForegroundColor Gray
                    }
                }
                Write-Host ""
            }
        }
    }

    # Affected Areas
    $hasAffected = ($Analysis.affected_routes -and $Analysis.affected_routes.Count -gt 0) -or
                   ($Analysis.affected_features -and $Analysis.affected_features.Count -gt 0) -or
                   ($Analysis.affected_flows -and $Analysis.affected_flows.Count -gt 0)

    if ($hasAffected) {
        Write-Host "AFFECTED AREAS:" -ForegroundColor Yellow
        if ($Analysis.affected_routes -and $Analysis.affected_routes.Count -gt 0) {
            Write-Host "  Routes: $($Analysis.affected_routes -join ', ')" -ForegroundColor White
        }
        if ($Analysis.affected_features -and $Analysis.affected_features.Count -gt 0) {
            Write-Host "  Features: $($Analysis.affected_features -join ', ')" -ForegroundColor White
        }
        if ($Analysis.affected_flows -and $Analysis.affected_flows.Count -gt 0) {
            Write-Host "  Flows: $($Analysis.affected_flows -join ', ')" -ForegroundColor White
        }
        Write-Host ""
    }

    # Semantic Issues
    if ($Analysis.semantic_issues -and $Analysis.semantic_issues.Count -gt 0) {
        Write-Host "POTENTIAL ISSUES:" -ForegroundColor Red
        foreach ($issue in $Analysis.semantic_issues) {
            Write-Host "  ! $issue" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # Recommendations
    if ($Analysis.recommendations -and $Analysis.recommendations.Count -gt 0) {
        Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
        foreach ($rec in $Analysis.recommendations) {
            Write-Host "  * $rec" -ForegroundColor White
        }
        Write-Host ""
    }

    # Confidence Impact
    if ($Analysis.confidence_impact -ne $null) {
        $impact = $Analysis.confidence_impact
        $color = if ($impact -ge 0) { "Green" } else { "Red" }
        $sign = if ($impact -ge 0) { "+" } else { "" }
        Write-Host "CONFIDENCE IMPACT: $sign$impact%" -ForegroundColor $color
        Write-Host ""
    }

    Write-Host $rule -ForegroundColor Cyan
    Write-Host ""
}

function Show-EvolveResultsReport {
    <#
    .SYNOPSIS
    Displays results after applying changes

    .PARAMETER Results
    Results from Apply-EvolveChanges

    .PARAMETER NewConfidence
    New confidence score after changes

    .PARAMETER Width
    Report width (default: 78)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,

        [Parameter(Mandatory=$false)]
        [double]$NewConfidence,

        [Parameter(Mandatory=$false)]
        [int]$Width = 78
    )

    $rule = '=' * $Width

    Write-Host ""
    Write-Host $rule -ForegroundColor Cyan
    Write-Host "CHANGES APPLIED" -ForegroundColor Cyan
    Write-Host $rule -ForegroundColor Cyan
    Write-Host ""

    if ($Results.files_changed -and $Results.files_changed.Count -gt 0) {
        Write-Host "FILES MODIFIED:" -ForegroundColor Green
        foreach ($file in $Results.files_changed) {
            Write-Host "  * $file" -ForegroundColor White
        }
        Write-Host ""
    }

    if ($Results.backup_path) {
        Write-Host "BACKUP CREATED:" -ForegroundColor Cyan
        Write-Host "  $($Results.backup_path)" -ForegroundColor Gray
        Write-Host ""
    }

    if ($Results.errors -and $Results.errors.Count -gt 0) {
        Write-Host "ERRORS:" -ForegroundColor Red
        foreach ($error in $Results.errors) {
            Write-Host "  ! $error" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    if ($NewConfidence -ne $null) {
        Write-Host "NEW CONFIDENCE SCORE: $NewConfidence%" -ForegroundColor $(
            if ($NewConfidence -ge 95) { "Green" }
            elseif ($NewConfidence -ge 75) { "Yellow" }
            else { "Red" }
        )
        Write-Host ""
    }

    Write-Host $rule -ForegroundColor Cyan
    Write-Host ""
}
