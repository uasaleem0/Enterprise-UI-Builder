# Test Quality Scoring System
# Tests both PRD and IA confidence/quality calculations

$ErrorActionPreference = 'Stop'

$ForgeRoot = "C:\Users\User\AI\Systems\Forge"
. "$ForgeRoot\lib\prd-completeness-validator.ps1"
. "$ForgeRoot\lib\prd-semantic-analyzer.ps1"
. "$ForgeRoot\lib\ia-semantic-analyzer.ps1"

Write-Host ""
Write-Host "=== Testing Quality Scoring System ===" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Helper function
function Test-Assertion {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$FailMessage = ""
    )

    if ($Condition) {
        Write-Host "[PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        if ($FailMessage) {
            Write-Host "       $FailMessage" -ForegroundColor Yellow
        }
        $script:testsFailed++
    }
}

# =============================================================================
# PRD QUALITY SCORING TESTS
# =============================================================================

Write-Host "Testing PRD Quality Score Calculation..." -ForegroundColor Yellow

# Test 1: Empty semantic analysis = 100% quality
$emptyAnalysis = @{
    implied_dependencies = @()
    contradictions = @()
    impossibilities = @()
    vague_features = @()
}
$score = Get-PRDQualityScore -SemanticAnalysis $emptyAnalysis
Test-Assertion "Empty analysis yields 100%" ($score -eq 100)

# Test 2: Single impossibility = -10
$oneImpossibility = @{
    implied_dependencies = @()
    contradictions = @()
    impossibilities = @("Test impossibility")
    vague_features = @()
}
$score = Get-PRDQualityScore -SemanticAnalysis $oneImpossibility
Test-Assertion "One impossibility = 90%" ($score -eq 90)

# Test 3: Mixed issues
$mixedIssues = @{
    implied_dependencies = @("dep1", "dep2")          # -2 each = -4
    contradictions = @("contra1")                      # -5
    impossibilities = @("impos1")                      # -10
    vague_features = @("vague1", "vague2", "vague3")  # -3 each = -9
}
$score = Get-PRDQualityScore -SemanticAnalysis $mixedIssues
$expected = 100 - 4 - 5 - 10 - 9  # = 72
Test-Assertion "Mixed issues calculate correctly" ($score -eq $expected) "Expected $expected, got $score"

# Test 4: Floor at 0%
$manyIssues = @{
    implied_dependencies = @()
    contradictions = @()
    impossibilities = @(1..15)  # -150 points
    vague_features = @()
}
$score = Get-PRDQualityScore -SemanticAnalysis $manyIssues
Test-Assertion "Quality floors at 0%" ($score -eq 0)

# =============================================================================
# IA QUALITY SCORING TESTS
# =============================================================================

Write-Host ""
Write-Host "Testing IA Quality Score Calculation..." -ForegroundColor Yellow

# Test 5: Empty IA analysis = 100%
$emptyIAAnalysis = @{
    vague_flows = @()
    route_contradictions = @()
    impossibilities = @()
    implied_dependencies = @()
    completeness_issues = @()
}
$score = Get-IAQualityScore -SemanticAnalysis $emptyIAAnalysis
Test-Assertion "Empty IA analysis yields 100%" ($score -eq 100)

# Test 6: IA impossibility = -10
$iaImpossibility = @{
    vague_flows = @()
    route_contradictions = @()
    impossibilities = @("Circular flow")
    implied_dependencies = @()
    completeness_issues = @()
}
$score = Get-IAQualityScore -SemanticAnalysis $iaImpossibility
Test-Assertion "IA impossibility = 90%" ($score -eq 90)

# Test 7: Mixed IA issues
$mixedIAIssues = @{
    vague_flows = @([PSCustomObject]@{ Name = "Flow1"; Issues = @("Missing purpose") })      # -3
    route_contradictions = @("Duplicate route")                                               # -5
    impossibilities = @("Orphaned route")                                                     # -10
    implied_dependencies = @("Missing auth flow")                                             # -2
    completeness_issues = @("Route without entity", "Entity without route")                  # -2 each = -4
}
$score = Get-IAQualityScore -SemanticAnalysis $mixedIAIssues
$expected = 100 - 3 - 5 - 10 - 2 - 4  # = 76
Test-Assertion "Mixed IA issues calculate correctly" ($score -eq $expected) "Expected $expected, got $score"

# =============================================================================
# IA COMPLETENESS SCORING TESTS
# =============================================================================

Write-Host ""
Write-Host "Testing IA Completeness Functions..." -ForegroundColor Yellow

# Create test IA directory with sample files
$testIADir = "$ForgeRoot\tests\test-ia-temp"
if (Test-Path $testIADir) { Remove-Item $testIADir -Recurse -Force }
New-Item -ItemType Directory -Path $testIADir -Force | Out-Null

# Test 8: Sitemap with complete routes
$sitemapContent = @"
# Sitemap

## Routes

- /dashboard
  Purpose: Main user dashboard

- /settings
  Purpose: User settings page

- /profile
  Description: User profile view
"@

Set-Content -Path "$testIADir\sitemap.md" -Value $sitemapContent -Encoding UTF8

$score = Measure-SitemapCompleteness -Path "$testIADir\sitemap.md"
Test-Assertion "Sitemap with complete routes > 80%" ($score -gt 80) "Got $score%"

# Test 9: Flows with complete fields
$flowsContent = @"
# User Flows

## Login Flow
Purpose: Authenticate user
Entry: Landing page
Steps: Enter credentials -> Click login -> Redirect
Success: User logged in and redirected to dashboard
Errors: Invalid credentials shown

## Checkout Flow
Purpose: Complete purchase
Entry: Shopping cart
Steps: Review cart -> Enter payment -> Confirm order
Success: Order placed
"@

Set-Content -Path "$testIADir\flows.md" -Value $flowsContent -Encoding UTF8

$score = Measure-FlowsCompleteness -Path "$testIADir\flows.md"
Test-Assertion "Complete flows score > 70%" ($score -gt 70) "Got $score%"

# Test 10: Entities with fields
$entitiesContent = @"
# Data Entities

## User
Fields: id, email, name, created_at

## Workout
Fields: id, user_id, name, date
"@

Set-Content -Path "$testIADir\entities.md" -Value $entitiesContent -Encoding UTF8

$score = Measure-EntitiesCompleteness -Path "$testIADir\entities.md"
Test-Assertion "Entities with fields = 100%" ($score -eq 100) "Got $score%"

# Test 11: Navigation with primary and secondary
$navContent = @"
# Navigation

## Primary Navigation
- Home
- Dashboard
- Settings

## Secondary Navigation
- Help
- Contact
"@

Set-Content -Path "$testIADir\navigation.md" -Value $navContent -Encoding UTF8

$score = Measure-NavigationCompleteness -Path "$testIADir\navigation.md"
Test-Assertion "Navigation with primary + secondary = 100%" ($score -eq 100) "Got $score%"

# Test 12: Full IA completion calculation
$completion = Get-IACompletion -IAPath $testIADir
$overallScore = [Math]::Round((
    ($completion.sitemap_completeness * 0.30) +
    ($completion.flows_completeness * 0.35) +
    ($completion.entities_completeness * 0.20) +
    ($completion.navigation_completeness * 0.15)
), 0)

Test-Assertion "IA overall completion > 80%" ($overallScore -gt 80) "Got $overallScore%"

# Cleanup
Remove-Item $testIADir -Recurse -Force

# =============================================================================
# IA SEMANTIC ANALYSIS TESTS
# =============================================================================

Write-Host ""
Write-Host "Testing IA Semantic Analysis..." -ForegroundColor Yellow

# Create test directory with problematic IA
$testIADir = "$ForgeRoot\tests\test-ia-semantic"
if (Test-Path $testIADir) { Remove-Item $testIADir -Recurse -Force }
New-Item -ItemType Directory -Path $testIADir -Force | Out-Null

# Test 13: Vague flow detection
$vagueFlowsContent = @"
# Flows

## Vague Flow
Steps: Do stuff
"@

Set-Content -Path "$testIADir\flows.md" -Value $vagueFlowsContent -Encoding UTF8
Set-Content -Path "$testIADir\sitemap.md" -Value "" -Encoding UTF8
Set-Content -Path "$testIADir\entities.md" -Value "" -Encoding UTF8
Set-Content -Path "$testIADir\navigation.md" -Value "" -Encoding UTF8

$analysis = Get-IASemanticAnalysis -IAPath $testIADir
Test-Assertion "Detects vague flows" ($analysis.vague_flows.Count -gt 0)

# Test 14: Route contradiction detection
$contradictionSitemap = @"
# Sitemap

- /dashboard
- /dashboard
- /settings
"@

Set-Content -Path "$testIADir\sitemap.md" -Value $contradictionSitemap -Encoding UTF8
Set-Content -Path "$testIADir\flows.md" -Value "" -Encoding UTF8

$analysis = Get-IASemanticAnalysis -IAPath $testIADir
Test-Assertion "Detects duplicate routes" ($analysis.route_contradictions.Count -gt 0)

# Cleanup
Remove-Item $testIADir -Recurse -Force

# =============================================================================
# SUMMARY
# =============================================================================

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "[SUCCESS] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAILURE] Some tests failed" -ForegroundColor Red
    exit 1
}
