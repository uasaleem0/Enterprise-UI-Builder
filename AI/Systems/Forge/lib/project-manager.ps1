# Forge Project Manager
# Handles safe project deletion with comprehensive guardrails

function Remove-ForgeProject {
    <#
    .SYNOPSIS
    Safely deletes a Forge project with comprehensive validation and guardrails.

    .DESCRIPTION
    Removes a Forge project directory and all associated files after performing:
    - Verification that execution is within a valid project directory
    - Protection of the core Forge system files
    - Dependency scanning to prevent system corruption
    - User confirmation before deletion
    - Backup creation before deletion

    .PARAMETER ProjectPath
    Optional. Path to the project directory to delete. Defaults to current directory.

    .PARAMETER Force
    Skip interactive confirmation prompt (still performs all safety checks)

    .PARAMETER NoBackup
    Skip creating a backup before deletion (not recommended)

    .EXAMPLE
    Remove-ForgeProject
    Deletes the current directory as a Forge project (with confirmation)

    .EXAMPLE
    Remove-ForgeProject -ProjectPath "C:\\Users\\User\\AI\\Projects\\MyProject"
    Deletes the specified project directory

    .EXAMPLE
    Remove-ForgeProject -Force -NoBackup
    Deletes current project without confirmation or backup (use with caution)
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$ProjectPath = (Get-Location).Path,

        [switch]$Force,
        
        [switch]$NoBackup
    )

    # ============================================================================
    # GUARDRAIL 1: Verify and normalize target path
    # ============================================================================

    if (-not $ProjectPath -or [string]::IsNullOrWhiteSpace($ProjectPath)) {
        $ProjectPath = (Get-Location).Path
    }
    try {
        $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
    } catch {
        Write-Error "Invalid project path specified"
        Write-Host "  Path: $ProjectPath" -ForegroundColor Red
        return
    }

    # Determine state file (Forge-managed projects)
    $stateFile = Join-Path $ProjectPath ".forge-prd-state.json"
    $hasState = Test-Path -LiteralPath $stateFile
    $isLegacy = (Test-Path -LiteralPath (Join-Path $ProjectPath 'prd.md')) -or (Test-Path -LiteralPath (Join-Path $ProjectPath '.forge-state.json'))
    if (-not $hasState) {
        # Allow deletion for legacy/unknown projects with extra confirmation
        $projectName = Split-Path -Leaf $ProjectPath
        $createdAt = (Get-Item -LiteralPath $ProjectPath).CreationTime.ToString('yyyy-MM-dd HH:mm:ss')
        $confidence = 0
        $projectState = @{ project_name = $projectName; created_at = $createdAt; confidence = $confidence; mode = if ($isLegacy) { 'legacy' } else { 'unknown' } }

        Write-Warning "Missing .forge-prd-state.json; proceeding in $($projectState.mode) mode."
        if (-not $Force) {
            $resp = Read-Host "Continue deleting '$projectName' without a state file? (yes/no)"
            if ($resp -ne 'yes') { Write-Host 'Deletion cancelled' -ForegroundColor Cyan; return }
        }
    }

    # ============================================================================
    # GUARDRAIL 2: Protect the core Forge system
    # ============================================================================

    $forgeSystemPath = (Resolve-Path -LiteralPath (Split-Path $PSScriptRoot -Parent)).Path
    if ($ProjectPath -eq $forgeSystemPath -or $ProjectPath.StartsWith($forgeSystemPath + "\")) {
        Write-Error "CRITICAL: Cannot delete Forge system directory or its subdirectories"
        Write-Host "  Project Path: $ProjectPath" -ForegroundColor Red
        Write-Host "  Forge System: $forgeSystemPath" -ForegroundColor Red
        return
    }

    # Additional protection: verify expected base path
    if ($ProjectPath -notmatch [regex]::Escape("\AI\Projects\")) {
        Write-Warning "Project path doesn't match expected pattern (*\AI\Projects\*)"
        Write-Host "  Path: $ProjectPath" -ForegroundColor Yellow
        if (-not $Force) {
            $confirm = Read-Host "Continue anyway? (yes/no)"
            if ($confirm -ne "yes") { Write-Host "Deletion cancelled" -ForegroundColor Cyan; return }
        }
    }

    # Absolute safety: never allow deleting system or user-profile roots
    $userProfile = $HOME
    $usersRoot = Split-Path -Parent $userProfile
    $driveRoot = [System.IO.Path]::GetPathRoot($ProjectPath)
    if ($ProjectPath -eq $driveRoot -or $ProjectPath -eq $usersRoot -or $ProjectPath -eq $userProfile) {
        Write-Error "CRITICAL: Refusing to delete unsafe path"
        Write-Host "  Path: $ProjectPath" -ForegroundColor Red
        return
    }

    # ============================================================================
    # GUARDRAIL 3: Load and analyze project state
    # ============================================================================

    if ($hasState) {
        try {
            $projectState = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
            $projectName = $projectState.project_name
            $createdAt = $projectState.created_at
            $confidence = $projectState.confidence
        } catch {
            Write-Error "Failed to read project state file"
            Write-Host "  Error: $_" -ForegroundColor Red
            return
        }
    }

    # ============================================================================
    # GUARDRAIL 4: Scan for system dependencies
    # ============================================================================

    Write-Host "Scanning for system dependencies..." -ForegroundColor Cyan

    $dependencies = @{
        SharedConfigs = @()
        SymbolicLinks = @()
        ExternalReferences = @()
    }

    # Check for symbolic links pointing into the project
    $allSymlinks = Get-ChildItem -Path $forgeSystemPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    foreach ($link in $allSymlinks) {
        try {
            $target = (Get-Item $link.FullName -Force).Target
            if ($target -and $target.StartsWith($ProjectPath, [StringComparison]::OrdinalIgnoreCase)) {
                $dependencies.SymbolicLinks += $link.FullName
            }
        }
        catch {
            # Ignore inaccessible links
        }
    }

    # Check for references in shared config files
    $forgeConfigs = Get-ChildItem -Path $forgeSystemPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
    foreach ($config in $forgeConfigs) {
        try {
            $content = Get-Content $config.FullName -Raw
            if ($content -match [regex]::Escape($ProjectPath)) {
                $dependencies.SharedConfigs += $config.FullName
            }
        }
        catch {
            # Skip files that can't be read
        }
    }

    # Check global state file
    $globalStateFile = Join-Path $HOME ".forge-state.json"
    if (Test-Path $globalStateFile) {
        try {
            $globalState = Get-Content $globalStateFile -Raw
            if ($globalState -match [regex]::Escape($ProjectPath)) {
                $dependencies.ExternalReferences += $globalStateFile
            }
        }
        catch {
            # Skip if can't read
        }
    }

    # Report findings
    $hasDependencies = ($dependencies.SymbolicLinks.Count -gt 0) -or
                       ($dependencies.SharedConfigs.Count -gt 0) -or
                       ($dependencies.ExternalReferences.Count -gt 0)

    if ($hasDependencies) {
        Write-Host "WARNING: Found system dependencies" -ForegroundColor Yellow
        if ($dependencies.SymbolicLinks.Count -gt 0) {
            Write-Host "  Symbolic Links pointing to this project:" -ForegroundColor Yellow
            $dependencies.SymbolicLinks | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
        }
        if ($dependencies.SharedConfigs.Count -gt 0) {
            Write-Host "  Config files referencing this project:" -ForegroundColor Yellow
            $dependencies.SharedConfigs | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
        }
        if ($dependencies.ExternalReferences.Count -gt 0) {
            Write-Host "  External references:" -ForegroundColor Yellow
            $dependencies.ExternalReferences | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
        }
        Write-Host "  These dependencies will need manual cleanup after deletion." -ForegroundColor Yellow
    } else {
        Write-Host "No system dependencies found" -ForegroundColor Green
    }

    # ============================================================================
    # GUARDRAIL 5: Display project information and confirm
    # ============================================================================

    Write-Host "-------------------------------------------------------------" -ForegroundColor Red
    Write-Host "           PROJECT DELETION CONFIRMATION                      " -ForegroundColor Red
    Write-Host "-------------------------------------------------------------" -ForegroundColor Red

    Write-Host "`nProject Details:" -ForegroundColor White
    Write-Host "  Name:       $projectName" -ForegroundColor Cyan
    Write-Host "  Path:       $ProjectPath" -ForegroundColor Cyan
    Write-Host "  Created:    $createdAt" -ForegroundColor Cyan
    Write-Host "  Confidence: $confidence%" -ForegroundColor Cyan

    # Count files and calculate size
    $files = Get-ChildItem -Path $ProjectPath -Recurse -File -ErrorAction SilentlyContinue
    $fileCount = $files.Count
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $sizeInMB = [math]::Round($totalSize / 1MB, 2)

    Write-Host "`nDeletion Impact:" -ForegroundColor White
    Write-Host "  Files:      $fileCount files" -ForegroundColor Yellow
    Write-Host "  Size:       $sizeInMB MB" -ForegroundColor Yellow

    if (-not $NoBackup) { Write-Host "  Backup:     Will be created before deletion" -ForegroundColor Green }
    else { Write-Host "  Backup:     SKIPPED (No backup will be created)" -ForegroundColor Red }

    Write-Host "WARNING: This action cannot be undone!" -ForegroundColor Red

    # Interactive confirmation
    if (-not $Force) {
        Write-Host "`nTo confirm deletion, type the project name exactly: " -NoNewline -ForegroundColor Yellow
        Write-Host "$projectName" -ForegroundColor White
        $confirmation = Read-Host "> "

        if ($confirmation -ne $projectName) {
            Write-Host "`n�?O Deletion cancelled (name mismatch)" -ForegroundColor Cyan
            return
        }

        Write-Host "`nAre you absolutely sure? Type 'DELETE' to confirm: " -NoNewline -ForegroundColor Red
        $finalConfirm = Read-Host "> "

        if ($finalConfirm -ne "DELETE") {
            Write-Host "`n�?O Deletion cancelled" -ForegroundColor Cyan
            return
        }
    }

    # ============================================================================
    # GUARDRAIL 6: Create backup (unless explicitly skipped)
    # ============================================================================

    if (-not $NoBackup) {
        Write-Host "Creating backup..." -ForegroundColor Cyan

        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupDir = Join-Path (Split-Path $forgeSystemPath -Parent) "Forge\.backups"
        $backupPath = Join-Path $backupDir "deleted-project-$projectName-$timestamp"

        try {
            # Ensure backup directory exists
            if (-not (Test-Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }

            # Copy entire project to backup
            Copy-Item -Path $ProjectPath -Destination $backupPath -Recurse -Force

            # Create deletion metadata
            $metadata = @{
                project_name = $projectName
                original_path = $ProjectPath
                deleted_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                deleted_by = $env:USERNAME
                state = $projectState
                dependencies = $dependencies
            }

            $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $backupPath ".deletion-metadata.json")

            Write-Host "Backup created: $backupPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create backup"
            Write-Host "  Error: $_" -ForegroundColor Red
            Write-Host "Deletion aborted for safety" -ForegroundColor Red
            return
        }
    }

    # ============================================================================
    # EXECUTE DELETION
    # ============================================================================

    Write-Host "Deleting project..." -ForegroundColor Red

    try {
        # Double-check we're not deleting Forge system
        if ($ProjectPath -eq $forgeSystemPath) {
            throw "CRITICAL SAFETY CHECK FAILED: Attempted to delete Forge system"
        }

        # If the current shell location is inside the project, move out to avoid lock
        $currentPath = (Get-Location).Path
        $isInside = $currentPath.Equals($ProjectPath, [StringComparison]::OrdinalIgnoreCase) -or $currentPath.StartsWith($ProjectPath + '\\', [StringComparison]::OrdinalIgnoreCase)
        if ($isInside) {
            $safeLocation = Split-Path -Parent $ProjectPath
            if (-not $safeLocation) { $safeLocation = $forgeSystemPath }
            try { Set-Location -LiteralPath $safeLocation } catch { Set-Location -LiteralPath $forgeSystemPath }
        }

        Remove-Item -LiteralPath $ProjectPath -Recurse -Force -ErrorAction Stop

        Write-Host "Project deleted successfully" -ForegroundColor Green
        Write-Host "  Path: $ProjectPath" -ForegroundColor Gray

        if (-not $NoBackup) { Write-Host "Backup location: $backupPath" -ForegroundColor Cyan }

        if ($hasDependencies) { Write-Host "Remember to clean up system dependencies manually" -ForegroundColor Yellow }
    }
    catch {
        Write-Error "Failed to delete project"
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host "Project may be partially deleted. Check backup if needed." -ForegroundColor Yellow
        return
    }
}

# Export function only when running as a module (avoid errors when dot-sourced)
$isModuleContext = $false
try {
    if ($MyInvocation.MyCommand.Module) { $isModuleContext = $true }
} catch { $isModuleContext = $false }
if ($isModuleContext) {
    Export-ModuleMember -Function Remove-ForgeProject
}
