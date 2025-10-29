$content = Get-Content 'forge-ia-userflows-report.ps1' -Raw
$content = $content -replace 'PSObject\.Properties\.Name -contains', 'ContainsKey'
$content = $content -replace 'entities_by_route\.\$route', 'entities_by_route[$route]'
Set-Content 'forge-ia-userflows-report.ps1' $content
Write-Host "Fixed"
