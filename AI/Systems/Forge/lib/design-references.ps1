# Forge Design References - Minimal
# Adds a single reference to the living brief with only two fields:
#   - type: website | image (open to other strings later)
#   - value: URL or local file path

function Add-DesignReference {
    param(
        [string]$ProjectPath,
        [string]$Type,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Type) -or [string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "[ERROR] Usage: forge design-ref <type> <url-or-path>" -ForegroundColor Red
        return
    }

    $briefPath = Join-Path $ProjectPath 'design.md'

    if (-not (Test-Path $briefPath)) {
        # Create minimal design.md with structure
        $dateStr = Get-Date -Format 'yyyy-MM-dd'
        $brief = @(
            '# Design Specification'
            ''
            '## 1. Aesthetic Brief'
            ''
            "Date: $dateStr"
            ''
            '## 2. Inspiration & Competitive Analysis'
            ''
            '### 2.1. Inspiration'
        ) -join "`r`n" | Set-Content -Path $briefPath -Encoding UTF8
    } else {
        # Ensure inspiration section exists
        $content = Get-Content -Raw $briefPath
        if ($content -notmatch '(?m)^###\s+2\.1\.\s+Inspiration\s*$') {
            Add-Content -Path $briefPath -Value "`r`n### 2.1. Inspiration"
        }
    }

    $normalizedType = $Type.ToLower()
    $line = "- [$normalizedType] $Value"
    Add-Content -Path $briefPath -Value $line
    Write-Host "[OK] Added reference to design.md" -ForegroundColor Green
}

