<#
.SYNOPSIS
    Verifies Forge installation and dependencies
.DESCRIPTION
    Checks that all required tools and configurations are properly installed
    and ready for use with the Forge system.
#>

param(
    [switch]$Verbose,
    [switch]$Fix
)

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              FORGE INSTALLATION VERIFICATION                  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()
$success = 0
$total = 0

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FixCommand = "",
        [string]$Required = "required"
    )

    $script:total++
    Write-Host "[$script:total] Testing: $Name..." -NoNewline

    try {
        $result = & $Test
        if ($result) {
            Write-Host " ✅" -ForegroundColor Green
            if ($Verbose) {
                Write-Host "    $result" -ForegroundColor Gray
            }
            $script:success++
            return $true
        } else {
            if ($Required -eq "required") {
                Write-Host " ❌ FAILED" -ForegroundColor Red
                $script:issues += "$Name is missing"
            } else {
                Write-Host " ⚠️  WARNING" -ForegroundColor Yellow
                $script:warnings += "$Name is not configured (optional)"
            }
            if ($FixCommand) {
                Write-Host "    Fix: $FixCommand" -ForegroundColor Gray
            }
            return $false
        }
    } catch {
        Write-Host " ❌ ERROR" -ForegroundColor Red
        $script:issues += "$Name check failed: $_"
        return $false
    }
}

# =============================================================================
# CORE DEPENDENCIES
# =============================================================================

Test-Requirement -Name "PowerShell Version" -Test {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        return "PowerShell $($PSVersionTable.PSVersion)"
    }
    return $null
} -FixCommand "Update PowerShell to v5.1 or higher"

Test-Requirement -Name "Git" -Test {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        return (git --version)
    }
    return $null
} -FixCommand "choco install git -y"

Test-Requirement -Name "GitHub CLI (gh)" -Test {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        return (gh --version | Select-Object -First 1)
    }
    return $null
} -FixCommand "choco install gh -y"

Test-Requirement -Name "Node.js" -Test {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        return "Node $(node --version)"
    }
    return $null
} -FixCommand "choco install nodejs --version=22.18.0 -y"

Test-Requirement -Name "npm" -Test {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        return "npm v$(npm --version)"
    }
    return $null
} -FixCommand "Install Node.js (includes npm)"

# =============================================================================
# AI CLI TOOLS
# =============================================================================

Test-Requirement -Name "Claude Code CLI" -Test {
    if (Get-Command claude-code -ErrorAction SilentlyContinue) {
        return "Installed"
    }
    return $null
} -FixCommand "npm install -g @anthropic-ai/claude-code@2.0.31" -Required "optional"

Test-Requirement -Name "OpenAI Codex CLI" -Test {
    if (Get-Command codex -ErrorAction SilentlyContinue) {
        return "Installed"
    }
    return $null
} -FixCommand "npm install -g @openai/codex@0.34.0" -Required "optional"

Test-Requirement -Name "Gemini CLI" -Test {
    if (Get-Command gemini -ErrorAction SilentlyContinue) {
        return "Installed"
    }
    return $null
} -FixCommand "npm install -g @google/gemini-cli@0.11.3" -Required "optional"

# =============================================================================
# FORGE SYSTEM
# =============================================================================

$forgeRoot = Split-Path -Parent $PSScriptRoot
$forgeMd = Join-Path $forgeRoot "forge.md"

Test-Requirement -Name "Forge System Files" -Test {
    if (Test-Path $forgeMd) {
        return "Found at: $forgeRoot"
    }
    return $null
} -FixCommand "Clone AI workspace with Forge system"

Test-Requirement -Name "Forge Scripts" -Test {
    $forgeScript = Join-Path $PSScriptRoot "forge.ps1"
    if (Test-Path $forgeScript) {
        return "forge.ps1 found"
    }
    return $null
} -FixCommand "Ensure Forge scripts are in: $PSScriptRoot"

Test-Requirement -Name "Forge Alias in Profile" -Test {
    if (Test-Path $PROFILE) {
        $profileContent = Get-Content $PROFILE -Raw
        if ($profileContent -match "forge") {
            return "Configured in $PROFILE"
        }
    }
    return $null
} -FixCommand "Add: Set-Alias forge '$PSScriptRoot\forge.ps1' to $PROFILE" -Required "optional"

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

Test-Requirement -Name "OPENAI_API_KEY" -Test {
    if ($env:OPENAI_API_KEY) {
        $masked = $env:OPENAI_API_KEY.Substring(0, [Math]::Min(8, $env:OPENAI_API_KEY.Length)) + "..."
        return "Set ($masked)"
    }
    return $null
} -FixCommand "`$env:OPENAI_API_KEY = 'your-key'" -Required "required"

Test-Requirement -Name "ANTHROPIC_API_KEY" -Test {
    if ($env:ANTHROPIC_API_KEY) {
        $masked = $env:ANTHROPIC_API_KEY.Substring(0, [Math]::Min(8, $env:ANTHROPIC_API_KEY.Length)) + "..."
        return "Set ($masked)"
    }
    return $null
} -FixCommand "`$env:ANTHROPIC_API_KEY = 'your-key'" -Required "optional"

Test-Requirement -Name "GitHub Authentication" -Test {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in") {
            return "Authenticated"
        }
    }
    return $null
} -FixCommand "gh auth login" -Required "optional"

# =============================================================================
# PROJECT DIRECTORY
# =============================================================================

$projectDir = "C:\Users\$env:USERNAME\AI\Projects"

Test-Requirement -Name "Project Directory" -Test {
    if (Test-Path $projectDir) {
        $count = (Get-ChildItem $projectDir -Directory -ErrorAction SilentlyContinue).Count
        return "Found with $count projects"
    }
    return $null
} -FixCommand "mkdir '$projectDir'" -Required "optional"

# =============================================================================
# SUMMARY
# =============================================================================

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Passed: $success / $total" -ForegroundColor Green

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "❌ Issues: $($issues.Count)" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "   - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Run setup-forge.ps1 to install missing dependencies" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ""
    Write-Host "🎉 All critical checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready to use Forge! Try:" -ForegroundColor Cyan
    Write-Host "   forge version" -ForegroundColor Gray
    Write-Host "   forge start my-app" -ForegroundColor Gray
    Write-Host ""
    exit 0
}
