<#
 .SYNOPSIS
     Change Applicator for PRD and IA Evolution
 .DESCRIPTION
     Applies analyzed changes to PRD and IA documents
     Orchestrates document updates and validates results
#>

. "$PSScriptRoot\document-editor.ps1"
. "$PSScriptRoot\state-manager.ps1"

function Apply-EvolveChanges {
    <#
    .SYNOPSIS
    Applies analyzed changes to PRD and IA files

    .PARAMETER ProjectPath
    Path to project directory

    .PARAMETER Analysis
    Analysis result from Get-ChangeImpact or Invoke-ForgeEvolveAnalysis

    .PARAMETER CreateBackup
    Create backup before applying changes (default: true)

    .OUTPUTS
    Hashtable containing application results
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$true)]
        [hashtable]$Analysis,

        [Parameter(Mandatory=$false)]
        [bool]$CreateBackup = $true
    )

    $results = @{
        prd_modified = $false
        ia_modified = $false
        files_changed = @()
        errors = @()
        backup_path = $null
    }

    # Create backup if requested
    if ($CreateBackup) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupDir = Join-Path $ProjectPath ".forge-backups"
            if (-not (Test-Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }

            $backupPath = Join-Path $backupDir "backup-evolve-$timestamp"
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null

            $prdPath = Join-Path $ProjectPath 'prd.md'
            if (Test-Path $prdPath) {
                Copy-Item -Path $prdPath -Destination (Join-Path $backupPath 'prd.md') -Force
            }

            $iaDir = Join-Path $ProjectPath 'ia'
            if (Test-Path $iaDir) {
                Copy-Item -Path $iaDir -Destination (Join-Path $backupPath 'ia') -Recurse -Force
            }

            $results.backup_path = $backupPath
        } catch {
            $results.errors += "Backup failed: $($_.Exception.Message)"
            return $results
        }
    }

    # Apply PRD changes
    if ($Analysis.prd_changes) {
        try {
            $prdModified = Apply-PRDChanges -ProjectPath $ProjectPath -Changes $Analysis.prd_changes
            if ($prdModified) {
                $results.prd_modified = $true
                $results.files_changed += 'prd.md'
            }
        } catch {
            $results.errors += "PRD update failed: $($_.Exception.Message)"
        }
    }

    # Apply IA changes
    if ($Analysis.ia_changes) {
        try {
            $iaFiles = Apply-IAChanges -ProjectPath $ProjectPath -Changes $Analysis.ia_changes
            if ($iaFiles.Count -gt 0) {
                $results.ia_modified = $true
                $results.files_changed += $iaFiles
            }
        } catch {
            $results.errors += "IA update failed: $($_.Exception.Message)"
        }
    }

    return $results
}

function Apply-PRDChanges {
    param(
        [string]$ProjectPath,
        [hashtable]$Changes
    )

    $prdPath = Join-Path $ProjectPath 'prd.md'
    if (-not (Test-Path $prdPath)) {
        throw "PRD not found: $prdPath"
    }

    $anyChanges = $false

    # Add features
    if ($Changes.features_add -and $Changes.features_add.Count -gt 0) {
        foreach ($feature in $Changes.features_add) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'features' -Operation 'add' -Data $feature
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to add feature '$($feature.name)': $($_.Exception.Message)"
            }
        }
    }

    # Modify features
    if ($Changes.features_modify -and $Changes.features_modify.Count -gt 0) {
        foreach ($feature in $Changes.features_modify) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'features' -Operation 'modify' -Data $feature
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to modify feature '$($feature.name)': $($_.Exception.Message)"
            }
        }
    }

    # Remove features
    if ($Changes.features_remove -and $Changes.features_remove.Count -gt 0) {
        foreach ($feature in $Changes.features_remove) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'features' -Operation 'remove' -Data $feature
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to remove feature '$($feature.name)': $($_.Exception.Message)"
            }
        }
    }

    # Add scope items
    if ($Changes.scope_add -and $Changes.scope_add.Count -gt 0) {
        foreach ($item in $Changes.scope_add) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'scope' -Operation 'add' -Data $item
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to add scope item '$($item.name)': $($_.Exception.Message)"
            }
        }

    # Modify scope items (change priority)
    if ($Changes.scope_modify -and $Changes.scope_modify.Count -gt 0) {
        foreach ($item in $Changes.scope_modify) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'scope' -Operation 'modify' -Data $item
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to modify scope for '$($item.name)': $($_.Exception.Message)"
            }
        }
    }
    }

    # Modify scope items (change priority)
    if ($Changes.nfr_add -and $Changes.nfr_add.Count -gt 0) {
        foreach ($nfr in $Changes.nfr_add) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'nfr' -Operation 'add' -Data $nfr
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to add NFR: $($_.Exception.Message)"
            }
        }
    }

    # Add KPIs
    if ($Changes.kpis_add -and $Changes.kpis_add.Count -gt 0) {
        foreach ($kpi in $Changes.kpis_add) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'kpis' -Operation 'add' -Data $kpi
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to add KPI: $($_.Exception.Message)"
            }
        }
    }

    # Add user stories
    if ($Changes.user_stories_add -and $Changes.user_stories_add.Count -gt 0) {
        foreach ($story in $Changes.user_stories_add) {
            try {
                $modified = Update-PRDSection -PrdPath $prdPath -Section 'user_stories' -Operation 'add' -Data $story
                if ($modified) { $anyChanges = $true }
            } catch {
                Write-Warning "Failed to add user story: $($_.Exception.Message)"
            }
        }
    }

    return $anyChanges
}

function Apply-IAChanges {
    param(
        [string]$ProjectPath,
        [hashtable]$Changes
    )

    $iaDir = Join-Path $ProjectPath 'ia'
    $filesChanged = @()

    # Ensure IA directory exists
    if (-not (Test-Path $iaDir)) {
        New-Item -Path $iaDir -ItemType Directory -Force | Out-Null
    }

    # Add routes
    if ($Changes.routes_add -and $Changes.routes_add.Count -gt 0) {
        $sitemapPath = Join-Path $iaDir 'sitemap.md'

        # Create sitemap if it doesn't exist
        if (-not (Test-Path $sitemapPath)) {
            $initialContent = @"
# Sitemap

## Routes

"@
            Set-Content -Path $sitemapPath -Value $initialContent -Encoding UTF8
        }

        foreach ($route in $Changes.routes_add) {
            try {
                $modified = Update-IASection -IAPath $sitemapPath -Section 'routes' -Operation 'add' -Data $route
                if ($modified -and -not ($filesChanged -contains 'ia/sitemap.md')) {
                    $filesChanged += 'ia/sitemap.md'
                }
            } catch {
                Write-Warning "Failed to add route '$($route.route)': $($_.Exception.Message)"
            }
        }
    }

    # Add modals
    if ($Changes.modals_add -and $Changes.modals_add.Count -gt 0) {
        $sitemapPath = Join-Path $iaDir 'sitemap.md'

        foreach ($modal in $Changes.modals_add) {
            try {
                $modified = Update-IASection -IAPath $sitemapPath -Section 'modals' -Operation 'add' -Data $modal
                if ($modified -and -not ($filesChanged -contains 'ia/sitemap.md')) {
                    $filesChanged += 'ia/sitemap.md'
                }
            } catch {
                Write-Warning "Failed to add modal '$($modal.name)': $($_.Exception.Message)"
            }
        }
    }

    # Add flows
    if ($Changes.flows_add -and $Changes.flows_add.Count -gt 0) {
        $flowsPath = Join-Path $iaDir 'flows.md'

        # Create flows file if it doesn't exist
        if (-not (Test-Path $flowsPath)) {
            $initialContent = @"
# User Flows

"@
            Set-Content -Path $flowsPath -Value $initialContent -Encoding UTF8
        }

        foreach ($flow in $Changes.flows_add) {
            try {
                $modified = Update-IASection -IAPath $flowsPath -Section 'flows' -Operation 'add' -Data $flow
                if ($modified -and -not ($filesChanged -contains 'ia/flows.md')) {
                    $filesChanged += 'ia/flows.md'
                }
            } catch {
                Write-Warning "Failed to add flow '$($flow.name)': $($_.Exception.Message)"
            }
        }
    }

    # Add components
    if ($Changes.components_add -and $Changes.components_add.Count -gt 0) {
        $componentsPath = Join-Path $iaDir 'components.md'

        # Create components file if it doesn't exist
        if (-not (Test-Path $componentsPath)) {
            $initialContent = @"
# Components

"@
            Set-Content -Path $componentsPath -Value $initialContent -Encoding UTF8
        }

        foreach ($comp in $Changes.components_add) {
            try {
                $modified = Update-IASection -IAPath $componentsPath -Section 'components' -Operation 'add' -Data $comp
                if ($modified -and -not ($filesChanged -contains 'ia/components.md')) {
                    $filesChanged += 'ia/components.md'
                }
            } catch {
                Write-Warning "Failed to add components for route '$($comp.route)': $($_.Exception.Message)"
            }
        }
    }

    # Add entities
    if ($Changes.entities_add -and $Changes.entities_add.Count -gt 0) {
        $entitiesPath = Join-Path $iaDir 'entities.md'

        # Create entities file if it doesn't exist
        if (-not (Test-Path $entitiesPath)) {
            $initialContent = @"
# Data Entities

"@
            Set-Content -Path $entitiesPath -Value $initialContent -Encoding UTF8
        }

        foreach ($entity in $Changes.entities_add) {
            try {
                $modified = Update-IASection -IAPath $entitiesPath -Section 'entities' -Operation 'add' -Data $entity
                if ($modified -and -not ($filesChanged -contains 'ia/entities.md')) {
                    $filesChanged += 'ia/entities.md'
                }
            } catch {
                Write-Warning "Failed to add entity '$($entity.name)': $($_.Exception.Message)"
            }
        }
    }

    return $filesChanged
}

function Rollback-EvolveChanges {
    <#
    .SYNOPSIS
    Rolls back changes from a backup

    .PARAMETER ProjectPath
    Path to project directory

    .PARAMETER BackupPath
    Path to backup directory
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )

    if (-not (Test-Path $BackupPath)) {
        throw "Backup not found: $BackupPath"
    }

    $results = @{
        success = $false
        errors = @()
    }

    try {
        # Restore PRD
        $backupPrd = Join-Path $BackupPath 'prd.md'
        if (Test-Path $backupPrd) {
            $targetPrd = Join-Path $ProjectPath 'prd.md'
            Copy-Item -Path $backupPrd -Destination $targetPrd -Force
        }

        # Restore IA
        $backupIA = Join-Path $BackupPath 'ia'
        if (Test-Path $backupIA) {
            $targetIA = Join-Path $ProjectPath 'ia'
            if (Test-Path $targetIA) {
                Remove-Item -Path $targetIA -Recurse -Force
            }
            Copy-Item -Path $backupIA -Destination $targetIA -Recurse -Force
        }

        $results.success = $true
    } catch {
        $results.errors += "Rollback failed: $($_.Exception.Message)"
    }

    return $results
}
