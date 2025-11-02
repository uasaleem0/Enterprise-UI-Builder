<#
.SYNOPSIS
    Complete Forge System Setup Script for New PC
.DESCRIPTION
    Installs all dependencies needed to run Forge on a fresh Windows PC:
    - Chocolatey package manager
    - Git, GitHub CLI, Node.js
    - Global npm packages (Claude Code, Codex, Gemini CLIs)
    - Clones AI workspace from GitHub
    - Configures environment variables and PATH
    - Sets up Forge alias in PowerShell profile
.NOTES
    Run as Administrator for first-time setup
    Requires internet connection
    Estimated time: 15-20 minutes
#>

param(
    [switch]$SkipChocolatey,
    [switch]$SkipGit,
    [switch]$SkipNode,
    [switch]$SkipCLIs,
    [switch]$SkipClone,
    [string]$GitHubUser = "",
    [string]$InstallPath = "C:\Users\$env:USERNAME\AI"
)

# Banner
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           FORGE SYSTEM - COMPLETE SETUP INSTALLER             ║" -ForegroundColor Cyan
Write-Host "║                     Windows Edition v1.0                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   Some installations may fail. Recommend restarting as Admin." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') { exit }
}

# Progress tracker
$steps = @()
$currentStep = 0

function Add-Step($name) {
    $script:steps += $name
}

function Complete-Step($success = $true) {
    $script:currentStep++
    $status = if ($success) { "✅" } else { "❌" }
    Write-Host "$status Step $currentStep/$($steps.Count) completed" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
    Write-Host ""
}

function Show-Progress($message) {
    Write-Host "[$currentStep/$($steps.Count)] $message" -ForegroundColor Cyan
}

# Define installation steps
Add-Step "Install Chocolatey"
Add-Step "Install Git"
Add-Step "Install GitHub CLI"
Add-Step "Install Node.js"
Add-Step "Install Global NPM Packages"
Add-Step "Clone AI Workspace"
Add-Step "Configure Environment Variables"
Add-Step "Setup PowerShell Profile"
Add-Step "Verify Installation"

Write-Host "📋 Setup will perform $($steps.Count) steps" -ForegroundColor White
Write-Host ""

# ============================================================
# STEP 1: Install Chocolatey
# ============================================================
if (-not $SkipChocolatey) {
    $currentStep++
    Show-Progress "Installing Chocolatey package manager..."

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "   Chocolatey already installed" -ForegroundColor Green
        Complete-Step
    } else {
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            Complete-Step
        } catch {
            Write-Host "   Failed to install Chocolatey: $_" -ForegroundColor Red
            Complete-Step $false
        }
    }
} else {
    $currentStep++
    Write-Host "⏭️  Skipping Chocolatey installation" -ForegroundColor Yellow
}

# ============================================================
# STEP 2: Install Git
# ============================================================
if (-not $SkipGit) {
    $currentStep++
    Show-Progress "Installing Git..."

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        Write-Host "   Git already installed: $gitVersion" -ForegroundColor Green
        Complete-Step
    } else {
        try {
            choco install git -y
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Complete-Step
        } catch {
            Write-Host "   Failed to install Git: $_" -ForegroundColor Red
            Complete-Step $false
        }
    }
} else {
    $currentStep++
    Write-Host "⏭️  Skipping Git installation" -ForegroundColor Yellow
}

# ============================================================
# STEP 3: Install GitHub CLI
# ============================================================
$currentStep++
Show-Progress "Installing GitHub CLI (gh)..."

if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghVersion = gh --version | Select-Object -First 1
    Write-Host "   GitHub CLI already installed: $ghVersion" -ForegroundColor Green
    Complete-Step
} else {
    try {
        choco install gh -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Complete-Step
    } catch {
        Write-Host "   Failed to install GitHub CLI: $_" -ForegroundColor Red
        Complete-Step $false
    }
}

# ============================================================
# STEP 4: Install Node.js
# ============================================================
if (-not $SkipNode) {
    $currentStep++
    Show-Progress "Installing Node.js v22.x..."

    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = node --version
        Write-Host "   Node.js already installed: $nodeVersion" -ForegroundColor Green
        Complete-Step
    } else {
        try {
            choco install nodejs --version=22.18.0 -y
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Complete-Step
        } catch {
            Write-Host "   Failed to install Node.js: $_" -ForegroundColor Red
            Complete-Step $false
        }
    }
} else {
    $currentStep++
    Write-Host "⏭️  Skipping Node.js installation" -ForegroundColor Yellow
}

# ============================================================
# STEP 5: Install Global NPM Packages
# ============================================================
if (-not $SkipCLIs) {
    $currentStep++
    Show-Progress "Installing AI CLI tools (Claude Code, Codex, Gemini, etc.)..."

    $packages = @(
        "@anthropic-ai/claude-code@2.0.31",
        "@openai/codex@0.34.0",
        "@google/gemini-cli@0.11.3",
        "@canva/cli@1.2.0",
        "figma-mcp@0.1.4",
        "figma-developer-mcp@0.5.2",
        "cursor-talk-to-figma-mcp@0.3.3"
    )

    try {
        foreach ($pkg in $packages) {
            Write-Host "   Installing $pkg..." -ForegroundColor Gray
            npm install -g $pkg --silent
        }
        Complete-Step
    } catch {
        Write-Host "   Failed to install some packages: $_" -ForegroundColor Red
        Complete-Step $false
    }
} else {
    $currentStep++
    Write-Host "⏭️  Skipping CLI installations" -ForegroundColor Yellow
}

# ============================================================
# STEP 6: Clone AI Workspace
# ============================================================
if (-not $SkipClone) {
    $currentStep++
    Show-Progress "Cloning AI workspace..."

    if (Test-Path $InstallPath) {
        Write-Host "   AI workspace already exists at: $InstallPath" -ForegroundColor Yellow
        $overwrite = Read-Host "   Overwrite? (y/N)"
        if ($overwrite -eq 'y') {
            Remove-Item -Path $InstallPath -Recurse -Force
        } else {
            Write-Host "   Skipping clone" -ForegroundColor Yellow
            Complete-Step
            $SkipClone = $true
        }
    }

    if (-not $SkipClone) {
        if ($GitHubUser) {
            try {
                Write-Host "   Cloning from GitHub user: $GitHubUser" -ForegroundColor Gray
                git clone "https://github.com/$GitHubUser/AI.git" $InstallPath
                Complete-Step
            } catch {
                Write-Host "   Failed to clone repository: $_" -ForegroundColor Red
                Write-Host "   You can manually clone your AI repository later" -ForegroundColor Yellow
                Complete-Step $false
            }
        } else {
            Write-Host "   ⚠️  No GitHub username provided" -ForegroundColor Yellow
            Write-Host "   You can manually clone your AI repository to: $InstallPath" -ForegroundColor Gray
            Complete-Step $false
        }
    }
} else {
    $currentStep++
    Write-Host "⏭️  Skipping workspace clone" -ForegroundColor Yellow
}

# ============================================================
# STEP 7: Configure Environment Variables
# ============================================================
$currentStep++
Show-Progress "Configuring environment variables..."

Write-Host ""
Write-Host "   📝 Please enter your API keys (press Enter to skip):" -ForegroundColor Cyan
Write-Host ""

# OpenAI API Key
$openaiKey = Read-Host "   OpenAI API Key"
if ($openaiKey) {
    [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $openaiKey, "User")
    Write-Host "   ✅ OPENAI_API_KEY configured" -ForegroundColor Green
}

# Anthropic API Key
$anthropicKey = Read-Host "   Anthropic API Key (for Claude)"
if ($anthropicKey) {
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $anthropicKey, "User")
    Write-Host "   ✅ ANTHROPIC_API_KEY configured" -ForegroundColor Green
}

# Google AI API Key
$googleKey = Read-Host "   Google AI API Key (for Gemini)"
if ($googleKey) {
    [System.Environment]::SetEnvironmentVariable("GOOGLE_AI_API_KEY", $googleKey, "User")
    Write-Host "   ✅ GOOGLE_AI_API_KEY configured" -ForegroundColor Green
}

# GitHub Token (optional)
$githubToken = Read-Host "   GitHub Personal Access Token (optional)"
if ($githubToken) {
    [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $githubToken, "User")
    Write-Host "   ✅ GITHUB_TOKEN configured" -ForegroundColor Green
}

Complete-Step

# ============================================================
# STEP 8: Setup PowerShell Profile
# ============================================================
$currentStep++
Show-Progress "Configuring PowerShell profile..."

try {
    # Ensure profile exists
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    }

    # Add Forge alias if not already present
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notmatch "forge") {
        $forgeScriptPath = Join-Path $InstallPath "Systems\Forge\scripts\forge.ps1"

        Add-Content -Path $PROFILE -Value @"

# Forge System Alias
Set-Alias forge "$forgeScriptPath"

# Add Forge to PATH
`$env:Path += ";$InstallPath\Systems\Forge\scripts"
"@
        Write-Host "   ✅ Forge alias added to PowerShell profile" -ForegroundColor Green
    } else {
        Write-Host "   Forge alias already exists in profile" -ForegroundColor Green
    }

    Complete-Step
} catch {
    Write-Host "   Failed to update PowerShell profile: $_" -ForegroundColor Red
    Complete-Step $false
}

# ============================================================
# STEP 9: Verify Installation
# ============================================================
$currentStep++
Show-Progress "Verifying installation..."

Write-Host ""
$verificationResults = @()

# Check Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVer = git --version
    $verificationResults += "✅ Git: $gitVer"
} else {
    $verificationResults += "❌ Git: Not found"
}

# Check GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghVer = (gh --version | Select-Object -First 1)
    $verificationResults += "✅ GitHub CLI: $ghVer"
} else {
    $verificationResults += "❌ GitHub CLI: Not found"
}

# Check Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = node --version
    $npmVer = npm --version
    $verificationResults += "✅ Node.js: $nodeVer"
    $verificationResults += "✅ npm: $npmVer"
} else {
    $verificationResults += "❌ Node.js: Not found"
}

# Check Claude Code
if (Get-Command claude-code -ErrorAction SilentlyContinue) {
    $verificationResults += "✅ Claude Code CLI: Installed"
} else {
    $verificationResults += "⚠️  Claude Code CLI: Not found (may need PATH refresh)"
}

# Check Forge directory
if (Test-Path (Join-Path $InstallPath "Systems\Forge\forge.md")) {
    $verificationResults += "✅ Forge System: Found at $InstallPath"
} else {
    $verificationResults += "❌ Forge System: Not found"
}

# Check API Keys
if ($env:OPENAI_API_KEY) {
    $verificationResults += "✅ OPENAI_API_KEY: Configured"
} else {
    $verificationResults += "⚠️  OPENAI_API_KEY: Not set"
}

foreach ($result in $verificationResults) {
    Write-Host "   $result"
}

Complete-Step

# ============================================================
# FINAL SUMMARY
# ============================================================
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    INSTALLATION COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Restart PowerShell to load the new environment" -ForegroundColor White
Write-Host "2. Authenticate GitHub CLI:" -ForegroundColor White
Write-Host "   gh auth login" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test Forge installation:" -ForegroundColor White
Write-Host "   forge version" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Create your first project:" -ForegroundColor White
Write-Host "   forge start my-app" -ForegroundColor Gray
Write-Host ""

if (-not $env:OPENAI_API_KEY) {
    Write-Host "⚠️  Remember to set OPENAI_API_KEY for AI features:" -ForegroundColor Yellow
    Write-Host "   `$env:OPENAI_API_KEY = 'your-key-here'" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "📖 Documentation: $InstallPath\Systems\Forge\README.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "Happy building! 🚀" -ForegroundColor Green
Write-Host ""
