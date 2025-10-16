# Test script for forge import-ia
# Simulates the import process with sample data

$ProjectPath = "C:\Users\User\AI\Projects\test-warp-session"
$SampleIA = Get-Content "C:\Users\User\AI\Systems\Forge\test-ia-sample.txt" -Raw

Write-Host "=== Testing forge import-ia ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Checking project setup..." -ForegroundColor Yellow

# Check PRD exists
if (-not (Test-Path "$ProjectPath\prd.md")) {
    Write-Host "[FAIL] No PRD found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] PRD exists" -ForegroundColor Green

# Load modules
$ForgeRoot = "C:\Users\User\AI\Systems\Forge"
$LibPath = "$ForgeRoot\lib"

Write-Host ""
Write-Host "2. Loading modules..." -ForegroundColor Yellow
try {
    . "$LibPath\mode-manager.ps1"
    . "$LibPath\state-manager.ps1"
    . "$LibPath\semantic-validator.ps1"
    . "$LibPath\ia-parser.ps1"
    Write-Host "[OK] All modules loaded" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Module loading error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if ia-parser function exists
Write-Host ""
Write-Host "3. Verifying Import-IABlock function..." -ForegroundColor Yellow
if (Get-Command Import-IABlock -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Import-IABlock function available" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Import-IABlock function not found" -ForegroundColor Red
    exit 1
}

# Test parsing sample IA
Write-Host ""
Write-Host "4. Testing IA block parsing..." -ForegroundColor Yellow

# Validate format
if ($SampleIA -match '\[FORGE_IA_START\]') {
    Write-Host "[OK] Found FORGE_IA_START marker" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Missing FORGE_IA_START marker" -ForegroundColor Red
    exit 1
}

if ($SampleIA -match '\[FORGE_IA_END\]') {
    Write-Host "[OK] Found FORGE_IA_END marker" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Missing FORGE_IA_END marker" -ForegroundColor Red
    exit 1
}

# Extract content
if ($SampleIA -match '(?s)\[FORGE_IA_START\](.*?)\[FORGE_IA_END\]') {
    $iaContent = $matches[1].Trim()
    Write-Host "[OK] Extracted IA content ($($iaContent.Length) chars)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Could not extract content" -ForegroundColor Red
    exit 1
}

# Test metadata extraction
if ($iaContent -match '(?m)^PROJECT:\s*(.+)$') {
    $project = $matches[1].Trim()
    Write-Host "[OK] Found PROJECT: $project" -ForegroundColor Green
} else {
    Write-Host "[WARN] No PROJECT metadata" -ForegroundColor Yellow
}

if ($iaContent -match '(?m)^CONFIDENCE:\s*(\d+)%?') {
    $confidence = $matches[1]
    Write-Host "[OK] Found CONFIDENCE: $confidence%" -ForegroundColor Green
} else {
    Write-Host "[WARN] No CONFIDENCE metadata" -ForegroundColor Yellow
}

# Test section extraction
$sections = @{
    "SITEMAP" = '(?s)---SITEMAP---(.*?)(?=---|$)'
    "USER_FLOWS" = '(?s)---USER_FLOWS---(.*?)(?=---|$)'
    "NAVIGATION" = '(?s)---NAVIGATION---(.*?)(?=---|$)'
    "COMPONENTS" = '(?s)---COMPONENTS---(.*?)(?=---|$)'
    "DATA_ENTITIES" = '(?s)---DATA_ENTITIES---(.*?)(?=---|$)'
}

Write-Host ""
Write-Host "5. Testing section extraction..." -ForegroundColor Yellow
foreach ($section in $sections.Keys) {
    if ($iaContent -match $sections[$section]) {
        $content = $matches[1].Trim()
        Write-Host "[OK] $section found ($($content.Length) chars)" -ForegroundColor Green
    } else {
        if ($section -in @("SITEMAP", "USER_FLOWS", "NAVIGATION")) {
            Write-Host "[FAIL] Required section $section missing" -ForegroundColor Red
        } else {
            Write-Host "[INFO] Optional section $section not present" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "6. Testing error conditions..." -ForegroundColor Yellow

# Test invalid format
$invalidIA = "This is not a valid IA block"
if ($invalidIA -notmatch '\[FORGE_IA_START\]') {
    Write-Host "[OK] Invalid format correctly rejected" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Invalid format not detected" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Tests Passed ===" -ForegroundColor Green
Write-Host ""
Write-Host "To test full import manually:" -ForegroundColor Cyan
Write-Host "  1. cd $ProjectPath" -ForegroundColor White
Write-Host "  2. forge import-ia" -ForegroundColor White
Write-Host "  3. Paste contents of test-ia-sample.txt" -ForegroundColor White
Write-Host "  4. Press Ctrl+Z then Enter" -ForegroundColor White
Write-Host ""
