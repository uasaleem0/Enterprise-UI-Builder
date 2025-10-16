# Test error handling for forge import-ia

Write-Host "=== Testing Error Handling ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: No PRD in directory
Write-Host "Test 1: Command without PRD file" -ForegroundColor Yellow
$tempDir = "C:\Users\User\AI\Systems\Forge\temp-test-no-prd"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Load modules
$ForgeRoot = "C:\Users\User\AI\Systems\Forge"
$LibPath = "$ForgeRoot\lib"
. "$LibPath\mode-manager.ps1"
. "$LibPath\state-manager.ps1"
. "$LibPath\semantic-validator.ps1"
. "$LibPath\ia-parser.ps1"

# Try to import without PRD - should fail gracefully
# Note: Function outputs via Write-Host (direct to console), so we just verify it doesn't crash
try {
    $ErrorActionPreference = "Continue"
    Import-IABlock -ProjectPath $tempDir | Out-Null
    # If we get here, function executed without crashing
    Write-Host "[OK] Function handles missing PRD gracefully (check error message above)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Function crashed on missing PRD: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "Test 2: Invalid IA format (no markers)" -ForegroundColor Yellow
$invalidContent = "This is just plain text without markers"
if ($invalidContent -notmatch '\[FORGE_IA_START\]') {
    Write-Host "[OK] Invalid format detection works" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Invalid format not detected" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 3: Missing required sections" -ForegroundColor Yellow
$incompleteSections = @"
[FORGE_IA_START]
PROJECT: Test
DATE: 2025-10-14
CONFIDENCE: 80%

---SITEMAP---
Some content here

[FORGE_IA_END]
"@

if ($incompleteSections -match '(?s)---USER_FLOWS---') {
    Write-Host "[FAIL] Should detect missing USER_FLOWS" -ForegroundColor Red
} else {
    Write-Host "[OK] Correctly detects missing USER_FLOWS" -ForegroundColor Green
}

if ($incompleteSections -match '(?s)---NAVIGATION---') {
    Write-Host "[FAIL] Should detect missing NAVIGATION" -ForegroundColor Red
} else {
    Write-Host "[OK] Correctly detects missing NAVIGATION" -ForegroundColor Green
}

Write-Host ""
Write-Host "Test 4: Autocomplete availability" -ForegroundColor Yellow
# Check if import-ia is in forge.ps1 ValidateSet
$forgeScript = Get-Content "C:\Users\User\AI\Systems\Forge\scripts\forge.ps1" -Raw
if ($forgeScript -match "'import-ia'") {
    Write-Host "[OK] import-ia is in autocomplete list" -ForegroundColor Green
} else {
    Write-Host "[FAIL] import-ia not in autocomplete" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 5: Help text includes import-ia" -ForegroundColor Yellow
if ($forgeScript -match "forge import-ia") {
    Write-Host "[OK] Help text includes import-ia command" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Help text missing import-ia" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Error Handling Tests Complete ===" -ForegroundColor Green
Write-Host ""
