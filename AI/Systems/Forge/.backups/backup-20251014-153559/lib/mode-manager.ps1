# Forge Mode Manager
# Enforces prod vs dev mode boundaries

function Get-ForgeMode {
    if ($env:FORGE_MODE -eq "dev") {
        return "dev"
    }
    return "prod"
}

function Assert-DevMode {
    param([string]$Operation)

    if ((Get-ForgeMode) -ne "dev") {
        Write-Host ""
        Write-Host "[ERROR] Operation '$Operation' requires DEV mode" -ForegroundColor Red
        Write-Host "[INFO] Enable with: " -NoNewline -ForegroundColor Yellow
        Write-Host "`$env:FORGE_MODE = 'dev'" -ForegroundColor White
        Write-Host "[INFO] Or use: " -NoNewline -ForegroundColor Yellow
        Write-Host "forge mode dev" -ForegroundColor White
        Write-Host ""
        throw "Dev mode required"
    }
}

function Test-SystemFile {
    param([string]$FilePath)

    $systemPaths = @(
        "scripts\",
        "lib\",
        "core\",
        "config\",
        "templates\"
    )

    $forgeRoot = Split-Path -Parent $PSScriptRoot
    $relativePath = $FilePath -replace [regex]::Escape($forgeRoot), ""

    foreach ($path in $systemPaths) {
        if ($relativePath -like "*$path*") {
            return $true
        }
    }

    return $false
}

function Assert-FileAccess {
    param(
        [string]$FilePath,
        [string]$Operation = "modify"
    )

    if ((Get-ForgeMode) -eq "dev") {
        return  # Dev mode has full access
    }

    if (Test-SystemFile -FilePath $FilePath) {
        Write-Host ""
        Write-Host "[ERROR] Cannot $Operation system file in PROD mode" -ForegroundColor Red
        Write-Host "[FILE] $FilePath" -ForegroundColor Gray
        Write-Host "[INFO] System files are read-only in production" -ForegroundColor Yellow
        Write-Host "[INFO] Switch to dev mode to modify: " -NoNewline -ForegroundColor Yellow
        Write-Host "`$env:FORGE_MODE = 'dev'" -ForegroundColor White
        Write-Host ""
        throw "System file modification blocked"
    }
}

function Get-ModeIndicator {
    $mode = Get-ForgeMode
    if ($mode -eq "dev") {
        return "[DEV MODE]"
    }
    return ""
}

function Show-ModeInfo {
    $mode = Get-ForgeMode

    Write-Host ""
    Write-Host "Current Mode: " -NoNewline
    if ($mode -eq "dev") {
        Write-Host "DEVELOPMENT" -ForegroundColor Yellow
        Write-Host "  - Full system access" -ForegroundColor Gray
        Write-Host "  - Can modify Forge source files" -ForegroundColor Gray
        Write-Host "  - Can run dev-* commands" -ForegroundColor Gray
        Write-Host "  - Changes logged to .forge-dev-log.json" -ForegroundColor Gray
    } else {
        Write-Host "PRODUCTION" -ForegroundColor Green
        Write-Host "  - Project files only (prd.md, code, etc.)" -ForegroundColor Gray
        Write-Host "  - System files are read-only" -ForegroundColor Gray
        Write-Host "  - Standard forge commands available" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Switch modes: forge mode [prod|dev]" -ForegroundColor Cyan
    Write-Host ""
}

function Set-ForgeMode {
    param([string]$TargetMode)

    if ($TargetMode -ne "prod" -and $TargetMode -ne "dev") {
        Write-Host "[ERROR] Invalid mode. Use 'prod' or 'dev'" -ForegroundColor Red
        return
    }

    $env:FORGE_MODE = $TargetMode

    Write-Host ""
    if ($TargetMode -eq "dev") {
        Write-Host "[OK] Switched to DEVELOPMENT mode" -ForegroundColor Yellow
        Write-Host "[WARN] You can now modify system files. Be careful!" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Switched to PRODUCTION mode" -ForegroundColor Green
        Write-Host "[INFO] System files are now protected" -ForegroundColor Gray
    }
    Write-Host ""
}

function Write-DevLog {
    param(
        [string]$Operation,
        [string]$File,
        [string]$Description
    )

    if ((Get-ForgeMode) -ne "dev") {
        return  # Only log in dev mode
    }

    $forgeRoot = Split-Path -Parent $PSScriptRoot
    $logPath = Join-Path $forgeRoot ".forge-dev-log.json"

    $entry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        operation = $Operation
        file = $File
        description = $Description
        ai = if ($env:FORGE_AI) { $env:FORGE_AI } else { "Unknown" }
    }

    $log = @()
    if (Test-Path $logPath) {
        $existing = Get-Content $logPath -Raw | ConvertFrom-Json
        # Convert PSCustomObject to array
        if ($existing -is [array]) {
            $log = @($existing)
        } else {
            $log = @($existing)
        }
    }

    $log += $entry

    # Always output as array, even for single item
    if ($log.Count -eq 1) {
        @($log) | ConvertTo-Json -Depth 10 | Set-Content $logPath
    } else {
        $log | ConvertTo-Json -Depth 10 | Set-Content $logPath
    }
}
