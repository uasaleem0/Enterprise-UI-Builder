# Forge v1.0 - Testing Instructions

## Prerequisites

1. **Windows PowerShell 5.1+** or **PowerShell Core 7+**
2. **Git** installed and in PATH
3. **GitHub CLI** (`gh`) installed and authenticated
   ```bash
   choco install gh
   gh auth login
   ```

---

## Installation Test

### Step 1: Add Forge to PATH

**Option A: Temporary (Current Session)**
```powershell
$env:Path += ";C:\Users\User\AI\Systems\Forge\scripts"
```

**Option B: Permanent (PowerShell Profile)**
```powershell
# Open profile
notepad $PROFILE

# Add this line:
Set-Alias forge "C:\Users\User\AI\Systems\Forge\scripts\forge.ps1"

# If using batch file instead:
$env:Path = "$env:Path;C:\Users\User\AI\Systems\Forge\scripts"

# Save and reload:
. $PROFILE
```

### Step 2: Test forge Command

**Using PowerShell Script Directly**:
```powershell
pwsh C:\Users\User\AI\Systems\Forge\scripts\forge.ps1 version
```

**Using Batch Wrapper** (if PowerShell isn't in PATH):
```bash
C:\Users\User\AI\Systems\Forge\scripts\forge.bat version
```

**Using Alias** (after adding to PATH):
```bash
forge version
```

**Expected Output**:
```
╔═══════════════════════════════════════════════════════════╗
║               FORGE v1.0 - AI Dev System                 ║
╚═══════════════════════════════════════════════════════════╝

Forge System v1.0
Location: C:\Users\User\AI\Systems\Forge
```

---

## Command Testing

### Test 1: forge help
```bash
forge help
```

**Expected**: List of all 14 commands with descriptions

**Pass Criteria**: ✅ Shows command list, no errors

---

### Test 2: forge start (Dry Run)
```bash
forge start test-app-1
```

**Expected**:
1. Creates `/c/Users/User/AI/Projects/test-app-1/`
2. Creates empty `prd.md`
3. Shows "Analyst Agent will now ask questions..."

**Pass Criteria**:
- ✅ Project directory created
- ✅ prd.md file exists
- ✅ Shows next steps

**Cleanup**:
```bash
rm -rf /c/Users/User/AI/Projects/test-app-1
```

---

### Test 3: forge import (Dry Run)
```bash
# Create a dummy PRD first
echo "# Test PRD" > /c/Users/User/test-prd.md

# Import it
forge import test-app-2 /c/Users/User/test-prd.md
```

**Expected**:
1. Creates `/c/Users/User/AI/Projects/test-app-2/`
2. Copies test-prd.md to project
3. Shows "Validator Agent will analyze..."

**Pass Criteria**:
- ✅ Project directory created
- ✅ prd.md copied successfully
- ✅ Shows validation message

**Cleanup**:
```bash
rm -rf /c/Users/User/AI/Projects/test-app-2
rm /c/Users/User/test-prd.md
```

---

### Test 4: forge status (No Project)
```bash
cd /c/Users/User
forge status
```

**Expected**: Error message "No project found"

**Pass Criteria**: ✅ Shows helpful error, suggests running from project directory

---

### Test 5: forge setup-repo (Without PRD)
```bash
forge setup-repo test-app-3
```

**Expected**: Error message "Project not found"

**Pass Criteria**: ✅ Shows error, suggests running `forge start` first

---

### Test 6: forge version
```bash
forge version
```

**Expected**: Shows Forge v1.0 banner and location

**Pass Criteria**: ✅ Displays correctly, no errors

---

## Full Workflow Test (End-to-End)

### Scenario: Create Fitness Tracker App

**Step 1: Start Project**
```bash
forge start fitness-tracker-test
```

**Expected**: Project created at `/c/Users/User/AI/Projects/fitness-tracker-test/`

---

**Step 2: Navigate to Project**
```bash
cd /c/Users/User/AI/Projects/fitness-tracker-test
```

---

**Step 3: Check Status (Should be 0%)**
```bash
forge status
```

**Expected**: Shows 0% confidence, all deliverables at 0%

---

**Step 4: Setup GitHub Foundation**
```bash
forge setup-repo fitness-tracker-test
```

**Expected**:
- Copies `.github/` folder with CI/CD workflow
- Copies issue templates
- Copies PR template
- Creates `scratchpads/` directory
- Shows git init commands

**Verify**:
```bash
ls -la
# Should see:
# .github/
# scratchpads/
# prd.md
```

---

**Step 5: Initialize Git**
```bash
git init
git add .
git commit -m "Initial commit from Forge"
```

---

**Step 6: Create GitHub Repo** (Optional - requires gh CLI)
```bash
gh repo create fitness-tracker-test --private --source=. --remote=origin
git push -u origin main
```

---

**Step 7: Generate Issues** (Requires PRD content)
```bash
forge generate-issues
```

**Expected**: Error message "PRD has no features" (since we haven't filled it yet)

**Pass Criteria**: ✅ Shows helpful error

---

**Step 8: Cleanup**
```bash
cd ..
rm -rf fitness-tracker-test
```

---

## Warp Autocomplete Test

### Step 1: Install Warp Completion Spec

```bash
# Create Warp config directory if it doesn't exist
mkdir -p ~/.warp/completion_specs

# Copy completion spec
cp /c/Users/User/AI/Systems/Forge/scripts/warp-completion.ts ~/.warp/completion_specs/forge.ts
```

### Step 2: Restart Warp Terminal

Close and reopen Warp.

### Step 3: Test Autocomplete

Type `forge ` (with space) and press **TAB**.

**Expected**: Shows list of commands with icons and descriptions:
- 🚀 start - Create new project from scratch
- 📥 import - Import existing PRD
- 📊 status - Show confidence & progress
- etc.

**Pass Criteria**: ✅ Autocomplete works, shows all 14 commands

### Step 4: Test Subcommand Autocomplete

Type `forge show ` (with space) and press **TAB**.

**Expected**: Shows options:
- explicit
- implied
- blockers
- deliverables
- all

**Pass Criteria**: ✅ Subcommand autocomplete works

---

## Render Test (Unicode vs ASCII)

### Test Unicode Renderer

```powershell
$env:CLAUDE_CODE = "true"
forge version
```

**Expected**: Unicode box-drawing characters (╔═══╗)

### Test ASCII Renderer

```powershell
$env:CODEX = "true"
forge version
```

**Expected**: ASCII characters (====)

---

## State Management Test

### Test 1: Create State File

```powershell
# Import state manager
. C:\Users\User\AI\Systems\Forge\lib\state-manager.ps1

# Create test project
$testPath = "C:\Users\User\AI\Projects\state-test"
New-Item -ItemType Directory -Path $testPath -Force

# Get initial state
$state = Get-ProjectState -ProjectPath $testPath

# Verify
$state | ConvertTo-Json
```

**Expected**: JSON with confidence: 0, all deliverables at 0

### Test 2: Update Confidence

```powershell
# Update deliverables
$state.deliverables.problem_statement = 100
$state.deliverables.tech_stack = 100

# Calculate new confidence
$confidence = Update-ProjectConfidence -ProjectPath $testPath -Deliverables $state.deliverables

Write-Host "New Confidence: $confidence%"
```

**Expected**: Confidence = 30% (10% + 20%)

### Test 3: Check Blockers

```powershell
$blockers = Test-ValidationBlocks -State $state

$blockers | ConvertTo-Json
```

**Expected**: Shows "low_confidence" and "vague_features" blockers

### Test 4: Get Next Steps

```powershell
$steps = Get-NextSteps -State $state

$steps | ForEach-Object {
    Write-Host "$($_.deliverable): +$($_.impact)% → $($_.new_confidence)%"
}
```

**Expected**: Lists deliverables sorted by impact

**Cleanup**:
```powershell
Remove-Item -Recurse -Force $testPath
```

---

## Integration Test with Claude Code

### Test Manual Workflow

1. Open Claude Code
2. Paste this prompt:
   ```
   Read C:\Users\User\AI\Systems\Forge\forge.md

   I want to create a new project called "test-integration".

   Follow the from-scratch workflow:
   1. Read agents/analyst.md
   2. Ask me the first 3 discovery questions from lib/questions/core-discovery.json
   3. Extract features based on my answers
   4. Calculate confidence using core/validation/confidence-weights.json
   ```

3. Answer the questions
4. Verify Claude follows the workflow correctly

**Pass Criteria**:
- ✅ Claude asks questions in order
- ✅ Claude calculates confidence correctly
- ✅ Claude detects blockers when confidence < 95%

---

## Known Issues / Limitations

### Issue 1: PowerShell Execution Policy
**Symptom**: "forge.ps1 cannot be loaded because running scripts is disabled"

**Fix**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue 2: GitHub CLI Not Found
**Symptom**: "'gh' is not recognized"

**Fix**:
```bash
choco install gh
gh auth login
```

### Issue 3: Warp Autocomplete Not Working
**Symptom**: TAB doesn't show completions

**Fix**:
1. Verify file exists: `~/.warp/completion_specs/forge.ts`
2. Restart Warp completely
3. Check Warp settings for completion enabled

### Issue 4: Unicode Characters Show as Boxes
**Symptom**: ╔═══╗ shows as □□□□

**Fix**:
- Use Windows Terminal (not CMD)
- Or set `$env:CODEX = "true"` to force ASCII mode

---

## Success Criteria Summary

| Test | Pass Criteria |
|------|---------------|
| **Installation** | ✅ forge command accessible |
| **forge version** | ✅ Shows banner, no errors |
| **forge help** | ✅ Lists all 14 commands |
| **forge start** | ✅ Creates project directory + prd.md |
| **forge import** | ✅ Copies PRD to project |
| **forge setup-repo** | ✅ Copies GitHub templates |
| **forge status** | ✅ Shows confidence breakdown |
| **Warp Autocomplete** | ✅ TAB shows command list |
| **State Management** | ✅ Calculates confidence correctly |
| **Renderers** | ✅ Unicode in Claude Code, ASCII in Codex |
| **Claude Integration** | ✅ Follows workflows from forge.md |

---

## Next Steps After Testing

1. **Fix any failing tests**
2. **Document workarounds** for known issues
3. **Create sample project** to demonstrate full workflow
4. **Record demo video** showing end-to-end usage
5. **Write tutorial** for first-time users

---

**Generated by Forge v1.0**
**Test Document Version**: 1.0
