param([string[]]$Args)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\state-manager.ps1"
. "$ForgeRoot\lib\ia-heuristic-parser.ps1"
. "$ForgeRoot\scripts\Format-SitemapReport.ps1"

$CurrentPath = Get-Location
if (-not (Test-Path "$CurrentPath\prd.md")) {
    Write-Host "[ERROR] No project found. Run this from a project directory." -ForegroundColor Red
    exit 1
}

# Parse flags
$width = 78
$noHr = $false
foreach ($a in $Args) {
    if ($a -match '^--width=(\d+)$') { $width = [int]$matches[1]; continue }
    if ($a -eq '--no-hr') { $noHr = $true; continue }
}

$reportData = Parse-IAForSitemapReport -ProjectPath $CurrentPath
$outPath = Join-Path $CurrentPath 'sitemap_report.md'
if ($noHr) {
    Format-SitemapReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -NoHr
} else {
    Format-SitemapReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width
}

# Display report (keep UTF-8 encoding intact for tree characters)
$content = Get-Content -Path $outPath -Raw -Encoding UTF8

Write-Host ""
Write-Host "[FORGE_IA_SITEMAP_REPORT_START]" -ForegroundColor Cyan
Write-Host $content -ForegroundColor White
Write-Host "[FORGE_IA_SITEMAP_REPORT_END]" -ForegroundColor Cyan
Write-Host ""

