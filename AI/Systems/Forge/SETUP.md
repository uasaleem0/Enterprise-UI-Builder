# Forge System - Installation & Migration Guide

Complete guide for setting up Forge on a new PC or migrating your existing setup.

---

## Quick Start (New Installation)

### Option 1: Automated Setup (Recommended)

**Run the setup script as Administrator:**

```powershell
# Navigate to the Forge scripts directory
cd C:\Users\User\AI\Systems\Forge\scripts

# Run the automated installer
.\setup-forge.ps1 -GitHubUser "your-github-username"
```

**What it installs:**
- Chocolatey package manager
- Git + GitHub CLI
- Node.js v22.18.0
- Claude Code, Codex, Gemini CLIs
- Clones your AI workspace
- Configures environment variables
- Sets up PowerShell alias

**Estimated time:** 15-20 minutes

---

### Option 2: Manual Installation

If you prefer manual control or the automated script fails:

#### 1. Install Chocolatey

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 2. Install Core Dependencies

```powershell
choco install git -y
choco install gh -y
choco install nodejs --version=22.18.0 -y
```

#### 3. Install AI CLI Tools

```powershell
npm install -g @anthropic-ai/claude-code@2.0.31
npm install -g @openai/codex@0.34.0
npm install -g @google/gemini-cli@0.11.3
npm install -g @canva/cli@1.2.0
npm install -g figma-mcp@0.1.4
```

#### 4. Clone AI Workspace

```powershell
cd C:\Users\$env:USERNAME
git clone https://github.com/your-username/AI.git
```

#### 5. Configure Environment Variables

```powershell
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-key-here", "User")
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "your-key-here", "User")
```

#### 6. Setup PowerShell Alias

```powershell
# Create or edit your profile
notepad $PROFILE

# Add this line:
Set-Alias forge "C:\Users\$env:USERNAME\AI\Systems\Forge\scripts\forge.ps1"

# Reload profile
. $PROFILE
```

#### 7. Verify Installation

```powershell
cd C:\Users\$env:USERNAME\AI\Systems\Forge\scripts
.\verify-forge.ps1
```

---

## Migrating to a New PC

### Before You Leave the Old PC

#### 1. Push Everything to GitHub

```powershell
cd C:\Users\User\AI
git status
git add .
git commit -m "Backup before migration"
git push
```

#### 2. Export Package List

```powershell
npm list -g --depth=0 > C:\Users\User\Desktop\npm-packages.txt
```

#### 3. Document Custom Settings

- Copy `.claude.json` to cloud storage
- Copy `.gitconfig`
- Export any custom environment variables:

```powershell
Get-ChildItem Env: | Where-Object {
    $_.Name -like "*API*" -or
    $_.Name -like "*FORGE*" -or
    $_.Name -like "*GITHUB*"
} | Format-Table Name, Value > C:\Users\User\Desktop\env-vars.txt
```

#### 4. Backup Any Local-Only Data

```powershell
# Check for uncommitted projects
cd C:\Users\User\AI\Projects
git status

# Backup any .env files or secrets (manually)
```

### On the New PC

#### 1. Run Automated Setup

```powershell
# Download the setup script from GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-username/AI/main/Systems/Forge/scripts/setup-forge.ps1" -OutFile "setup-forge.ps1"

# Run it
.\setup-forge.ps1 -GitHubUser "your-username"
```

#### 2. Verify Everything Works

```powershell
# Test Forge
forge version
forge status

# Test AI CLIs
claude-code --version
codex --version
gemini --version

# Test GitHub auth
gh auth status
```

#### 3. Restore Custom Settings

- Copy `.claude.json` back to `C:\Users\$env:USERNAME\`
- Configure any custom environment variables
- Test with a sample project:

```powershell
forge start test-migration
```

---

## Verification Checklist

After installation, verify each component:

```powershell
# Run automated verification
.\verify-forge.ps1

# Or manually check:
git --version           # Should be 2.x+
gh --version            # Should be latest
node --version          # Should be v22.18.0
npm --version           # Should be 11.x+
forge version           # Should show Forge v1.0

# Check environment
$env:OPENAI_API_KEY     # Should be set
$env:ANTHROPIC_API_KEY  # Optional but recommended

# Test GitHub auth
gh auth status          # Should show "Logged in"

# Test Forge
forge start test-app    # Should start discovery process
```

---

## Troubleshooting

### "forge: command not found"

**Solution:**
```powershell
# Reload PowerShell profile
. $PROFILE

# Or restart PowerShell terminal
```

### "OPENAI_API_KEY not set"

**Solution:**
```powershell
# Set for current session
$env:OPENAI_API_KEY = "your-key-here"

# Set permanently
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-key", "User")
```

### "Cannot run scripts" (ExecutionPolicy error)

**Solution:**
```powershell
# Allow scripts for current user
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### Chocolatey installation fails

**Solution:**
```powershell
# Ensure you're running as Administrator
# If still fails, install tools manually:
# - Git: https://git-scm.com/download/win
# - GitHub CLI: https://cli.github.com/
# - Node.js: https://nodejs.org/
```

### GitHub CLI not authenticated

**Solution:**
```powershell
gh auth login
# Choose: GitHub.com > HTTPS > Login with browser
```

### Node packages fail to install

**Solution:**
```powershell
# Clear npm cache
npm cache clean --force

# Retry installation
npm install -g @anthropic-ai/claude-code@2.0.31

# If Windows security blocks it, run PowerShell as Administrator
```

---

## Advanced Configuration

### Custom Install Location

```powershell
.\setup-forge.ps1 -InstallPath "D:\MyProjects\AI" -GitHubUser "your-username"
```

### Skip Specific Steps

```powershell
# Skip Chocolatey (if already installed)
.\setup-forge.ps1 -SkipChocolatey

# Skip cloning (if you want to do it manually)
.\setup-forge.ps1 -SkipClone

# Skip all CLI tools (install manually later)
.\setup-forge.ps1 -SkipCLIs
```

### Environment Variables Reference

| Variable | Required | Purpose |
|----------|----------|---------|
| `OPENAI_API_KEY` | Yes | AI features (PRD generation, IA analysis) |
| `ANTHROPIC_API_KEY` | Optional | Claude Code CLI |
| `GOOGLE_AI_API_KEY` | Optional | Gemini CLI |
| `GITHUB_TOKEN` | Optional | GitHub API access (higher rate limits) |
| `FORGE_PROJECT_DIR` | Optional | Custom project storage location |
| `FORGE_AI_DEBUG` | Optional | Enable AI request debugging |

See `.env.template` for complete configuration options.

---

## What Gets Installed

### Package Managers
- **Chocolatey**: Windows package manager for easy software installation

### Version Control
- **Git**: Distributed version control
- **GitHub CLI (gh)**: GitHub integration for repo creation, issues, PRs

### Runtime
- **Node.js v22.18.0**: JavaScript runtime
- **npm v11.6.1**: Package manager (included with Node.js)

### AI CLI Tools
- **Claude Code** (`@anthropic-ai/claude-code@2.0.31`)
- **OpenAI Codex** (`@openai/codex@0.34.0`)
- **Gemini CLI** (`@google/gemini-cli@0.11.3`)
- **Canva CLI** (`@canva/cli@1.2.0`)
- **Figma MCP** (`figma-mcp@0.1.4`, `figma-developer-mcp@0.5.2`, `cursor-talk-to-figma-mcp@0.3.3`)

### Forge System
- Core Forge framework (PowerShell scripts)
- PRD templates and workflows
- IA report generators
- GitHub integration tools

---

## Keeping Forge Updated

### Update Forge System

```powershell
cd C:\Users\$env:USERNAME\AI
git pull origin main
```

### Update CLI Tools

```powershell
npm update -g @anthropic-ai/claude-code
npm update -g @openai/codex
npm update -g @google/gemini-cli
```

### Update Core Dependencies

```powershell
choco upgrade git -y
choco upgrade gh -y
choco upgrade nodejs -y
```

---

## Uninstallation

If you need to remove Forge:

```powershell
# Remove global npm packages
npm uninstall -g @anthropic-ai/claude-code
npm uninstall -g @openai/codex
npm uninstall -g @google/gemini-cli

# Remove AI workspace
Remove-Item -Recurse -Force C:\Users\$env:USERNAME\AI

# Remove PowerShell alias (edit profile and remove forge line)
notepad $PROFILE

# Remove environment variables
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $null, "User")
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
```

---

## Support

For issues or questions:

1. **Check documentation**: `C:\Users\User\AI\Systems\Forge\README.md`
2. **Run verification**: `.\verify-forge.ps1 -Verbose`
3. **Review logs**: Check PowerShell error messages
4. **GitHub Issues**: Report bugs in your repository

---

## Next Steps

After successful installation:

1. **Authenticate GitHub CLI**: `gh auth login`
2. **Test Forge**: `forge version`
3. **Create a test project**: `forge start test-app`
4. **Read full documentation**: `forge help`
5. **Build something amazing!** 🚀

---

**Generated for Forge v1.0**
**Last Updated**: 2025-11-02
