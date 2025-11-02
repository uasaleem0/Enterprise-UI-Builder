# AI Workspace Migration Package

**Complete guide for migrating your entire AI development environment to a new PC**

---

## What This Includes

This workspace contains:

- **Forge System**: AI-powered PRD → Production pipeline
- **Multi-AI CLI Setup**: Claude Code, Codex, Gemini, Figma, Canva CLIs
- **Projects**: All your Forge-generated projects
- **Configuration**: Environment variables, aliases, AI configs

---

## Quick Migration (Recommended)

### Prerequisites
- Windows 10/11
- Internet connection
- Administrator access
- GitHub account

### On New PC

**1. Download the setup script:**

```powershell
# Open PowerShell as Administrator
cd $env:USERPROFILE\Downloads

# Download setup script (replace YOUR-USERNAME)
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/YOUR-USERNAME/AI/main/Systems/Forge/scripts/setup-forge.ps1" `
  -OutFile "setup-forge.ps1"
```

**2. Run automated installer:**

```powershell
.\setup-forge.ps1 -GitHubUser "YOUR-USERNAME"
```

**3. Follow prompts:**
- Enter OpenAI API key (required)
- Enter Anthropic API key (optional)
- Enter Google AI API key (optional)
- Wait for installation to complete

**4. Verify:**

```powershell
cd $env:USERPROFILE\AI\Systems\Forge\scripts
.\verify-forge.ps1
```

**5. Test:**

```powershell
forge version
forge start test-migration
```

**Done!** Your entire environment is now migrated.

---

## What Gets Installed

### Package Managers
- Chocolatey (Windows package manager)

### Development Tools
- Git v2.x+
- GitHub CLI (gh)
- Node.js v22.18.0
- npm v11.6.1

### AI CLIs
- Claude Code (`@anthropic-ai/claude-code@2.0.31`)
- OpenAI Codex (`@openai/codex@0.34.0`)
- Google Gemini (`@google/gemini-cli@0.11.3`)
- Canva CLI (`@canva/cli@1.2.0`)
- Figma MCP tools

### Forge System
- Complete Forge framework
- All PowerShell scripts
- Templates and workflows
- IA report generators

### Configuration
- PowerShell profile with aliases
- Environment variables (OPENAI_API_KEY, etc.)
- PATH configuration

---

## Directory Structure After Installation

```
C:\Users\<YourName>\
├── AI\
│   ├── Systems\
│   │   └── Forge\              # Main Forge system
│   │       ├── scripts\        # All Forge commands
│   │       ├── lib\            # Core libraries
│   │       ├── templates\      # PRD/IA templates
│   │       ├── tests\          # Test files
│   │       ├── forge.md        # System documentation
│   │       ├── README.md       # Quick start
│   │       └── SETUP.md        # Installation guide
│   │
│   ├── Projects\               # Your Forge projects
│   │   ├── project-1\
│   │   ├── project-2\
│   │   └── ...
│   │
│   ├── Claude\                 # Claude Code configs
│   ├── Codex\                  # Codex configs
│   ├── Gemini\                 # Gemini configs
│   └── Companies\              # Client work
│
└── .claude\                    # Claude Code global config
    └── CLAUDE.md
```

---

## Migration Checklist

### Before Leaving Old PC

- [ ] Commit all changes: `git add . && git commit -m "Pre-migration"`
- [ ] Push to GitHub: `git push`
- [ ] Export npm packages: `npm list -g --depth=0 > packages.txt`
- [ ] Save API keys to password manager
- [ ] Copy `.claude.json` if customized
- [ ] Copy `.gitconfig` if customized
- [ ] Check for uncommitted projects: `git status` in each project

### On New PC

- [ ] Run `setup-forge.ps1`
- [ ] Enter API keys when prompted
- [ ] Authenticate GitHub CLI: `gh auth login`
- [ ] Run verification: `.\verify-forge.ps1`
- [ ] Test Forge: `forge version`
- [ ] Test project creation: `forge start test`
- [ ] Verify AI CLIs work: `claude-code --version`

---

## Estimated Times

| Task | Time |
|------|------|
| Download setup script | 30 seconds |
| Run automated installer | 15-20 minutes |
| Configure API keys | 2 minutes |
| Verify installation | 1 minute |
| **Total** | **~20 minutes** |

---

## Troubleshooting

### Setup script fails to download

**Manual download:**
1. Go to your GitHub repository
2. Navigate to `Systems/Forge/scripts/setup-forge.ps1`
3. Click "Raw" button
4. Right-click → Save As → `setup-forge.ps1`

### Chocolatey installation blocked

**Install manually:**
- Git: https://git-scm.com/download/win
- GitHub CLI: https://cli.github.com/
- Node.js: https://nodejs.org/ (download v22.18.0 LTS)

### "Cannot run scripts" error

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### API key not working

```powershell
# Verify it's set
$env:OPENAI_API_KEY

# Set manually if needed
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-key", "User")

# Restart PowerShell
```

### Forge command not found

```powershell
# Reload profile
. $PROFILE

# Or restart PowerShell terminal
```

---

## Alternative: Manual Migration

If automated setup fails, see **SETUP.md** for complete manual installation instructions.

---

## Post-Migration

### Recommended Next Steps

1. **Test Forge with a sample project:**
   ```powershell
   forge start sample-app
   ```

2. **Update all tools:**
   ```powershell
   choco upgrade all -y
   npm update -g
   ```

3. **Configure Git:**
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```

4. **Set up GitHub SSH (optional):**
   ```powershell
   ssh-keygen -t ed25519 -C "you@example.com"
   # Add to GitHub: Settings → SSH Keys
   ```

---

## Support Files Included

| File | Purpose |
|------|---------|
| `setup-forge.ps1` | Automated installer |
| `verify-forge.ps1` | Installation verification |
| `.env.template` | Environment variable template |
| `SETUP.md` | Complete setup documentation |
| `MIGRATION-QUICKSTART.md` | 1-page quick reference |

---

## Getting Help

**Documentation:**
- `Systems/Forge/README.md` - Quick start guide
- `Systems/Forge/SETUP.md` - Installation guide
- `Systems/Forge/forge.md` - Complete system documentation

**Verification:**
```powershell
.\verify-forge.ps1 -Verbose
```

**Check logs:**
- PowerShell error messages
- `forge status` output
- GitHub authentication: `gh auth status`

---

## Security Notes

### API Keys
- Never commit API keys to Git
- Store in environment variables only
- Use `.env` files (gitignored) for project-specific keys
- Consider using a password manager

### GitHub Authentication
- Use `gh auth login` for secure authentication
- Consider using SSH keys for repositories
- Personal Access Tokens (PAT) only if needed for automation

---

## Updates

**Keep Forge updated:**
```powershell
cd $env:USERPROFILE\AI
git pull origin main
```

**Update CLIs:**
```powershell
npm update -g @anthropic-ai/claude-code
npm update -g @openai/codex
npm update -g @google/gemini-cli
```

**Update dependencies:**
```powershell
choco upgrade all -y
```

---

## Additional Resources

- **Forge Commands**: `forge help`
- **PRD Workflow**: See `Systems/Forge/forge.md`
- **IA Reports**: See `Systems/Forge/templates/`
- **Examples**: See `Projects/` for sample projects

---

**Ready to migrate? Run `setup-forge.ps1` and you'll be up and running in 20 minutes!**

**Questions?** Check `SETUP.md` troubleshooting section or run `verify-forge.ps1 -Verbose`

---

*Migration package prepared for Forge v1.0*
*Compatible with: Windows 10/11, PowerShell 5.1+*
