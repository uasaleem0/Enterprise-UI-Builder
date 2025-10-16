# Forge Mode System

**Version**: 1.1
**Added**: 2025-10-14

---

## Overview

Forge operates in two modes to protect system integrity:

- **PROD** (Production) - Default mode for normal use
- **DEV** (Development) - Enables system modifications

---

## Modes Explained

### Production Mode (Default)

**What You Can Do:**
- Work on project files (prd.md, code, notes)
- Use all standard forge commands
- Create and manage projects
- Run tests, generate issues, deploy

**What You Cannot Do:**
- Edit system files (scripts/, lib/, core/)
- Modify validators or formatters
- Run dev-* commands
- Change Forge behavior

**Purpose**: Prevents accidental system corruption during normal use.

---

### Development Mode

**What You Can Do:**
- Everything from Production mode
- Edit system PowerShell scripts
- Modify validators and workflows
- Run system tests
- Create backups
- Access dev-* commands

**What You Cannot Do:**
- N/A - Full access to all files

**Purpose**: Safe environment for Forge maintenance and enhancement.

---

## Usage

### Check Current Mode

```powershell
forge mode
```

**Output**:
```
Current Mode: PRODUCTION
  - Project files only (prd.md, code, etc.)
  - System files are read-only
  - Standard forge commands available

Switch modes: forge mode [prod|dev]
```

---

### Switch to Dev Mode

```powershell
forge mode dev
```

**Output**:
```
[OK] Switched to DEVELOPMENT mode
[WARN] You can now modify system files. Be careful!
```

The banner will show `[DEV MODE]`:
```
=============================================================
          FORGE v1.0 - AI Dev System [DEV MODE]
=============================================================
```

---

### Switch to Prod Mode

```powershell
forge mode prod
```

**Output**:
```
[OK] Switched to PRODUCTION mode
[INFO] System files are now protected
```

---

## Environment Variable

Modes are controlled via `$env:FORGE_MODE`:

```powershell
# Set manually (session-scoped)
$env:FORGE_MODE = "dev"

# Set permanently (add to $PROFILE)
notepad $PROFILE
# Add: $env:FORGE_MODE = "dev"
```

**Default**: If not set, defaults to `"prod"`

---

## Developer Commands

Only available in DEV mode:

### `forge dev-test`
Run Forge system tests

```powershell
$env:FORGE_MODE = "dev"
forge dev-test
```

### `forge dev-backup`
Create backup of system files

```powershell
forge dev-backup
```

Creates timestamped backup in `.backups/`:
- scripts/
- lib/
- core/

### `forge dev-edit [file]`
Open system file in editor

```powershell
forge dev-edit lib/mode-manager.ps1
```

---

## File Protection

### Protected in PROD Mode

```
Forge/
├── scripts/          ❌ Read-only
├── lib/              ❌ Read-only
├── core/             ❌ Read-only
├── config/           ❌ Read-only
└── templates/        ❌ Read-only
```

### Always Editable

```
Projects/
└── your-project/
    ├── prd.md              ✅ Editable
    ├── .forge-state.json   ✅ Editable
    ├── src/                ✅ Editable
    └── notes/              ✅ Editable
```

---

## Development Log

In DEV mode, all system modifications are logged to:

```
.forge-dev-log.json
```

**Example Entry**:
```json
{
  "timestamp": "2025-10-14 15:30:00",
  "operation": "edit",
  "file": "lib/mode-manager.ps1",
  "description": "Opened system file for editing",
  "ai": "Claude"
}
```

---

## Error Examples

### Attempting Dev Command in PROD Mode

```powershell
forge dev-test
```

**Output**:
```
[ERROR] Operation 'dev-test' requires DEV mode
[INFO] Enable with: $env:FORGE_MODE = 'dev'
[INFO] Or use: forge mode dev
```

### Attempting to Edit System File in PROD Mode

If the mode system detects an attempt to modify protected files:

```
[ERROR] Cannot modify system file in PROD mode
[FILE] C:\Users\User\AI\Systems\Forge\lib\validator.ps1
[INFO] System files are read-only in production
[INFO] Switch to dev mode to modify: $env:FORGE_MODE = 'dev'
```

---

## Best Practices

### For Daily Use
1. **Stay in PROD mode** - Default is safe
2. Only switch to DEV when intentionally modifying Forge
3. Return to PROD after system changes

### For System Development
1. **Create backup first**: `forge dev-backup`
2. Switch to DEV mode: `forge mode dev`
3. Make changes carefully
4. Test thoroughly
5. Return to PROD: `forge mode prod`

### For AI Sessions
- **Claude/Codex/Warp**: Always start in PROD mode
- Only enter DEV mode when explicitly working on Forge system
- Clear indication in banner prevents confusion

---

## Technical Details

### Mode Detection Order
1. Check `$env:FORGE_MODE`
2. If not set, default to `"prod"`

### File Protection Logic
```powershell
Test-SystemFile -FilePath $path
# Returns $true if path contains:
#   - scripts/
#   - lib/
#   - core/
#   - config/
#   - templates/
```

### Assert-DevMode
Called by dev-* commands:
```powershell
Assert-DevMode -Operation "dev-test"
# Throws error if not in DEV mode
```

---

## Migration Notes

**Existing Projects**: Unaffected. Mode system only protects Forge files.

**Existing Scripts**: Continue working. PROD mode doesn't restrict project operations.

**Backward Compatibility**: 100%. All existing workflows work unchanged.

---

## Summary

| Aspect | PROD Mode | DEV Mode |
|--------|-----------|----------|
| Default | ✅ Yes | ❌ No |
| Project files | ✅ Full access | ✅ Full access |
| System files | ❌ Read-only | ✅ Full access |
| forge commands | ✅ All standard | ✅ All + dev-* |
| Banner | Clean | Shows [DEV MODE] |
| Change logging | ❌ No | ✅ Yes (.forge-dev-log.json) |
| Use case | Daily work | System maintenance |

**Rule of thumb**: If you're not modifying Forge itself, stay in PROD mode.
