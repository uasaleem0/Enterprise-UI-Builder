param(
    [string[]]$Args
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ForgeRoot = Split-Path -Parent $ScriptRoot

. "$ForgeRoot\lib\ia-report-parser.ps1"
. "$ForgeRoot\scripts\New-ForgeUserFlowsReport.ps1"

$CurrentPath = Get-Location
if (-not (Test-Path "$CurrentPath\prd.md")) {
    Write-Host "[ERROR] No project found. Run this from a project directory." -ForegroundColor Red
    exit 1
}

# Parse flags
$width = 78
$noFence = $false
$noHr = $false
foreach ($a in $Args) {
    if ($a -match '^--width=(\d+)$') { $width = [int]$matches[1]; continue }
    if ($a -eq '--no-fence') { $noFence = $true; continue }
    if ($a -eq '--no-hr') { $noHr = $true; continue }
}

# Build data and render
$reportData = Parse-IAForUserFlowsReport -ProjectPath $CurrentPath
$outPath = Join-Path $CurrentPath 'flows_report.md'
if ($noFence -and $noHr) {
    New-ForgeUserFlowsReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -NoFence -NoHr
} elseif ($noFence) {
    New-ForgeUserFlowsReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -NoFence
} elseif ($noHr) {
    New-ForgeUserFlowsReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width -NoHr
} else {
    New-ForgeUserFlowsReport -ReportData $reportData -OutputPath $outPath -Plain -Width $width
}

# Print a plain, AI-agnostic view between markers (apply final ASCII fallback)
function To-Ascii([string]$s){ if(-not $s){ return '' }; $s = $s -replace "[\u2018\u2019]","'" -replace "[\u201C\u201D]", '"' -replace "[\u2013\u2014\u2212]", '-' -replace "\u2026", '...' ; $chars=$s.ToCharArray(); for($i=0;$i -lt $chars.Length;$i++){ if([int]$chars[$i] -gt 127){ $chars[$i] = [char]'?' } }; return -join $chars }
$content = Get-Content -Path $outPath -Raw -Encoding UTF8
$content = To-Ascii $content

Write-Host ""; Write-Host "[FORGE_IA_USERFLOWS_REPORT_START]" -ForegroundColor Cyan
Write-Host $content -ForegroundColor White
Write-Host "[FORGE_IA_USERFLOWS_REPORT_END]" -ForegroundColor Cyan; Write-Host ""

