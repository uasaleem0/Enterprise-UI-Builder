<#
.SYNOPSIS
    Displays a holistic, formatted report of the IA Entity Relationship Diagram.
.DESCRIPTION
    Reads the project state file and generates a comprehensive, human-readable
    ASCII report for the Information Architecture ERD.
.PARAMETER ProjectPath
    Path to the project directory containing .forge-prd-state.json
.EXAMPLE
    forge ia-erd-report
#>
param([string]$ProjectPath = '.')

. "$PSScriptRoot/../lib/state-manager.ps1"
. "$PSScriptRoot/../lib/ia-data-helpers.ps1"

# --- Helper Functions ---
function Write-BoxedLine {
    param([string]$Text, [int]$Width = 68)
    $padding = $Width - $Text.Length
    if ($padding -lt 0) { $padding = 0 }
    Write-Host ("| $Text" + (' ' * $padding) + " |")
}

function Write-Separator {
    param([string]$Char = '-', [int]$Width = 70)
    Write-Host ($Char * $Width)
}

# --- Load State ---
$ErrorActionPreference = 'Stop'
try {
    $ProjectPath = Resolve-Path $ProjectPath
    $state = Get-ProjectState -ProjectPath $ProjectPath
} catch {
    Write-Host "ERROR: Could not read project state." -ForegroundColor Red
    exit 1
}

if (-not $state.ia_model -or -not $state.ia_model.entities_by_route) {
    Write-Host "No Entities found. Run 'forge import-ia' first." -ForegroundColor Yellow
    exit 0
}

# --- Data Preparation with Foundational Helpers ---
$projectName = if ($state.project_name) { $state.project_name } else { Split-Path -Leaf $ProjectPath }
$extractionMethod = if ($state.ia_model.extraction_method) { $state.ia_model.extraction_method } else { 'Unknown' }
$timestamp = if ($state.ia_model.extraction_timestamp) {
    [DateTime]::Parse($state.ia_model.extraction_timestamp).ToString('yyyy-MM-dd HH:mm:ss')
} else { 'N/A' }

# Get unique entities using helper to filter hashtables
$allEntities = New-Object System.Collections.Generic.HashSet[string]
if ($state.ia_model.entities_by_route -is [hashtable]) {
    foreach ($page in $state.ia_model.entities_by_route.Keys) {
        $entities = Get-RouteEntities -EntitiesByRoute $state.ia_model.entities_by_route -Route $page
        foreach ($entity in $entities) {
            $allEntities.Add($entity) | Out-Null
        }
    }
}
$entityCount = $allEntities.Count
$sortedEntities = $allEntities | Sort-Object

# Parse entity schemas from IA source file if available
$entitySchemas = @{}
$iaSourcePath = Join-Path $ProjectPath "ia_source.txt"
if (-not (Test-Path $iaSourcePath)) {
    $iaSourcePath = "C:\Users\User\Desktop\IronSense-IA.txt"
}

if (Test-Path $iaSourcePath) {
    $iaLines = Get-Content $iaSourcePath
    $inEntitiesSection = $false
    $currentEntity = $null

    foreach ($line in $iaLines) {
        if ($line -match '^---DATA_ENTITIES---') {
            $inEntitiesSection = $true
            continue
        }
        elseif ($line -match '^---') {
            $inEntitiesSection = $false
            continue
        }

        if ($inEntitiesSection) {
            if ($line -match '^Entity:\s*([^\(]+)') {
                $currentEntity = $matches[1].Trim()
                $entitySchemas[$currentEntity] = @{
                    Fields = @()
                    Relationships = @()
                    UsedOn = @()
                }
            }
            elseif ($currentEntity -and $line -match '^Fields:\s*(.+)$') {
                $entitySchemas[$currentEntity].Fields = $matches[1].Trim() -split ',\s*'
            }
            elseif ($currentEntity -and $line -match '^Relationships:\s*(.+)$') {
                $entitySchemas[$currentEntity].Relationships += $matches[1].Trim()
            }
            elseif ($currentEntity -and $line -match '^Used On:\s*(.+)$') {
                $entitySchemas[$currentEntity].UsedOn = $matches[1].Trim() -split ',\s*'
            }
        }
    }
}

# --- Report Generation ---
Write-Host ""
Write-Host ""
Write-Separator '='
Write-Host ""
Write-Host "                  ENTITY RELATIONSHIP DIAGRAM"
Write-Host "                         $projectName"
Write-Host ""
Write-Separator '='
Write-Host ""
Write-Host "  Extraction Method: $extractionMethod"
Write-Host "  Last Parsed: $timestamp"
Write-Host "  Total Entities: $entityCount"
Write-Host ""
Write-Host ""

# Entity Grid Diagram
Write-Separator '='
Write-Host "               ENTITY RELATIONSHIP MAP (All Entities)"
Write-Separator '='
Write-Host ""
Write-Host ""

# Display entities in 3-column grid
$sortedEntities = $allEntities | Sort-Object
$col = 0
$maxCols = 3
$boxWidth = 20
$currentRow = @()

foreach ($entity in $sortedEntities) {
    $currentRow += $entity
    $col++

    if ($col -ge $maxCols -or $entity -eq $sortedEntities[-1]) {
        # Draw top border
        Write-Host -NoNewline "     "
        foreach ($ent in $currentRow) {
            Write-Host -NoNewline "+$('-' * $boxWidth)+     "
        }
        Write-Host ""

        # Draw entity names
        Write-Host -NoNewline "     "
        foreach ($ent in $currentRow) {
            $padding = $boxWidth - $ent.Length - 2
            if ($padding -lt 0) { $padding = 0 }
            Write-Host -NoNewline "| $ent$(' ' * $padding) |     "
        }
        Write-Host ""

        # Draw separator
        Write-Host -NoNewline "     "
        foreach ($ent in $currentRow) {
            Write-Host -NoNewline "|$('-' * $boxWidth)|     "
        }
        Write-Host ""

        # Draw fields (show all fields, up to 7)
        $maxFieldLines = 7
        for ($fieldLine = 0; $fieldLine -lt $maxFieldLines; $fieldLine++) {
            Write-Host -NoNewline "     "
            foreach ($ent in $currentRow) {
                if ($entitySchemas.ContainsKey($ent) -and $entitySchemas[$ent].Fields.Count -gt 0) {
                    if ($fieldLine -lt $entitySchemas[$ent].Fields.Count) {
                        $field = $entitySchemas[$ent].Fields[$fieldLine].Trim()
                        # Truncate if too long
                        if ($field.Length -gt ($boxWidth - 4)) {
                            $field = $field.Substring(0, $boxWidth - 7) + "..."
                        }
                        $fieldPadding = $boxWidth - $field.Length - 2
                        if ($fieldPadding -lt 0) { $fieldPadding = 0 }

                        if ($field -match '^id\b') {
                            Write-Host -NoNewline "| $field (PK)$(' ' * ($fieldPadding - 5)) |     "
                        } else {
                            Write-Host -NoNewline "| $field$(' ' * $fieldPadding) |     "
                        }
                    } else {
                        Write-Host -NoNewline "|$(' ' * $boxWidth)|     "
                    }
                } else {
                    # Fallback if no schema
                    if ($fieldLine -eq 0) {
                        Write-Host -NoNewline "| id (PK)$(' ' * ($boxWidth - 8)) |     "
                    } else {
                        Write-Host -NoNewline "|$(' ' * $boxWidth)|     "
                    }
                }
            }
            Write-Host ""
        }

        # Draw bottom border
        Write-Host -NoNewline "     "
        foreach ($ent in $currentRow) {
            Write-Host -NoNewline "+$('-' * $boxWidth)+     "
        }
        Write-Host ""
        Write-Host ""

        $col = 0
        $currentRow = @()
    }
}

Write-Host ""
Write-Host ""

# Relationship Notes
Write-Separator '-'
Write-Host "  RELATIONSHIPS"
Write-Separator '-'
Write-Host ""
Write-Host "  Note: Explicit relationship parsing is a future enhancement"
Write-Host "  Relationships are currently inferred from entity co-location on routes"
Write-Host ""
Write-Host ""

# Entity Details
Write-Separator '='
Write-Host "                         ENTITY CATALOG"
Write-Separator '='
Write-Host ""

foreach ($entity in $allEntities | Sort-Object) {
    Write-Host ""
    Write-Host "+-----------------------------------------------------------------------+"
    Write-Host "|  ENTITY: $entity"
    Write-Host "+-----------------------------------------------------------------------+"
    Write-Host ""

    # Attributes
    if ($entitySchemas.ContainsKey($entity) -and $entitySchemas[$entity].Fields.Count -gt 0) {
        Write-Host "  ATTRIBUTES"
        foreach ($field in $entitySchemas[$entity].Fields) {
            $fieldClean = $field.Trim()
            if ($fieldClean -match '^id\b') {
                Write-Host "     - $fieldClean (PK)"
            } else {
                Write-Host "     - $fieldClean"
            }
        }
        Write-Host ""

        # Relationships
        if ($entitySchemas[$entity].Relationships.Count -gt 0) {
            Write-Host "  RELATIONSHIPS"
            foreach ($rel in $entitySchemas[$entity].Relationships) {
                Write-Host "     - $rel"
            }
            Write-Host ""
        }
    } else {
        Write-Host "  PRIMARY KEY"
        Write-Host "     - id"
        Write-Host ""
        Write-Host "  Note: Detailed attribute parsing coming in future release"
        Write-Host ""
    }

    # Associated Flows
    $associatedFlows = @()
    if ($state.ia_model.flows) {
        foreach ($flow in $state.ia_model.flows) {
            $usesEntity = $false
            $steps = Get-StepsFromValue -Value $flow.steps

            foreach ($step in $steps) {
                $stepEntities = Get-RouteEntities -EntitiesByRoute $state.ia_model.entities_by_route -Route $step
                if ($stepEntities -contains $entity) {
                    $usesEntity = $true
                    break
                }
            }

            if ($usesEntity) {
                $associatedFlows += $flow.name
            }
        }
    }

    if ($associatedFlows.Count -gt 0) {
        Write-Host "  USER FLOWS ($($associatedFlows.Count))"
        foreach ($flow in $associatedFlows) {
            Write-Host "     - $flow"
        }
        Write-Host ""
    }

    # Associated Features
    $associatedFeatures = @()
    if ($state.project_model -and $state.project_model.route_to_features) {
        if ($state.project_model.route_to_features -is [hashtable]) {
            foreach ($route in $state.project_model.route_to_features.Keys) {
                $routeEntities = Get-RouteEntities -EntitiesByRoute $state.ia_model.entities_by_route -Route $route

                if ($routeEntities -contains $entity) {
                    $features = Get-EntitiesFromValue -Value $state.project_model.route_to_features[$route]
                    foreach ($featureName in $features) {
                        if ($featureName -and $associatedFeatures -notcontains $featureName) {
                            $associatedFeatures += $featureName
                        }
                    }
                }
            }
        }
    }

    if ($associatedFeatures.Count -gt 0) {
        $uniqueFeatures = $associatedFeatures | Select-Object -Unique
        Write-Host "  FEATURES ($($uniqueFeatures.Count))"
        foreach ($feature in $uniqueFeatures) {
            Write-Host "     - $feature"
        }
        Write-Host ""
    }

    # Appears on Pages
    $appearsOn = @()
    if ($state.ia_model.entities_by_route -is [hashtable]) {
        foreach ($page in $state.ia_model.entities_by_route.Keys) {
            $pageEntities = Get-RouteEntities -EntitiesByRoute $state.ia_model.entities_by_route -Route $page
            if ($pageEntities -contains $entity) {
                $appearsOn += $page
            }
        }
    }

    if ($appearsOn.Count -gt 0) {
        Write-Host "  ROUTES ($($appearsOn.Count))"
        foreach ($route in ($appearsOn | Sort-Object)) {
            $purpose = ""
            if ($state.ia_model.purpose_map -and $state.ia_model.purpose_map.$route) {
                $purpose = " - " + $state.ia_model.purpose_map.$route
            }
            Write-Host "     - $route$purpose"
        }
        Write-Host ""
    }

    Write-Host "+-----------------------------------------------------------------------+"
}

Write-Host ""
