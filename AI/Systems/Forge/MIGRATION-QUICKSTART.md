# Forge Migration - Quick Reference Card

**1-page guide for migrating Forge to a new PC**

---

## 🚀 On New PC (5 Minutes)

### Step 1: Download & Run Setup Script

```powershell
# Open PowerShell as Administrator
irm https://raw.githubusercontent.com/YOUR-USERNAME/AI/main/Systems/Forge/scripts/setup-forge.ps1 -OutFile setup.ps1

# Run installer
.\setup.ps1 -GitHubUser "YOUR-USERNAME"
```

### Step 2: Enter API Keys When Prompted
- OpenAI API Key (required)
- Anthropic API Key (optional)
- Google AI API Key (optional)

### Step 3: Verify Installation

```powershell
.\AI\Systems\Forge\scripts\verify-forge.ps1
```

### Step 4: Authenticate GitHub

```powershell
gh auth login
```

### Done! Test It

```powershell
forge version
forge start my-first-app
```

---

## 📋 Pre-Migration Checklist (Old PC)

### 1. Commit & Push Everything

```powershell
cd C:\Users\User\AI
git add .
git commit -m "Pre-migration backup"
git push
```

### 2. Export Settings (Save to USB/Cloud)

```powershell
# API keys
Get-ChildItem Env: | Where-Object {$_.Name -like "*API*"} > env-backup.txt

# NPM packages
npm list -g --depth=0 > npm-packages.txt

# Copy these files:
# - .claude.json
# - .gitconfig
```

---

## ⚡ Manual Installation (If Script Fails)

```powershell
# 1. Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# 2. Install dependencies
choco install git gh nodejs --version=22.18.0 -y

# 3. Install AI CLIs
npm i -g @anthropic-ai/claude-code@2.0.31 @openai/codex@0.34.0 @google/gemini-cli@0.11.3

# 4. Clone workspace
git clone https://github.com/YOUR-USERNAME/AI.git C:\Users\$env:USERNAME\AI

# 5. Set API key
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-key", "User")

# 6. Add alias to profile
Add-Content $PROFILE "Set-Alias forge 'C:\Users\$env:USERNAME\AI\Systems\Forge\scripts\forge.ps1'"

# 7. Reload
. $PROFILE
```

---

## 🔧 Common Issues

| Problem | Solution |
|---------|----------|
| "forge not found" | Restart PowerShell or run `. $PROFILE` |
| "API key not set" | `$env:OPENAI_API_KEY = "key"` |
| "Cannot run scripts" | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Choco fails | Install Git/Node manually from websites |
| gh not authenticated | `gh auth login` |

---

## 📦 What Gets Installed

✅ Git + GitHub CLI
✅ Node.js v22.18.0
✅ Claude Code, Codex, Gemini CLIs
✅ Forge system + all scripts
✅ PowerShell alias
✅ Environment variables

**Total install time:** ~15 minutes
**Disk space:** ~2GB

---

## 🎯 Essential Commands

```powershell
forge version              # Check installation
forge start <name>         # Create new project
forge status               # Check project status
forge help                 # Full command list
.\verify-forge.ps1         # Verify installation
```

---

## 📱 Need Help?

**Full docs:** `AI\Systems\Forge\SETUP.md`
**Verify:** `.\verify-forge.ps1 -Verbose`
**Support:** Check SETUP.md troubleshooting section

---

**Print this page and keep it handy during migration!**
