#Requires -Version 5.1
<#
.SYNOPSIS
    GSD with Design -- Overlay Installer for Windows
.DESCRIPTION
    Installs design-layer files on top of an existing GSD (Get Shit Done)
    installation. Supports both global (~\.claude) and local (.\.claude)
    install targets with interactive selection when multiple are found.
.NOTES
    PowerShell 5.1+ (ships with Windows 10/11)
    Run with: powershell -ExecutionPolicy Bypass -File install.ps1
#>

# --- 1. Execution Policy Handling ---
try {
    if ((Get-ExecutionPolicy -Scope Process) -eq 'Restricted') {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    }
} catch {
    Write-Host "ERROR: Cannot set execution policy." -ForegroundColor Red
    Write-Host "Run with: powershell -ExecutionPolicy Bypass -File install.ps1" -ForegroundColor Yellow
    exit 1
}

# --- 2. Banner ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GSD with Design -- Overlay Installer  " -ForegroundColor Cyan
Write-Host "  v1.0.0 (PowerShell)                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- 3. Helper: Get-DesignFileHash ---
function Get-DesignFileHash {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
}

# --- 4. Source Directory Detection ---
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$SourceCheck1 = Join-Path $ScriptDir ".claude\commands\gsd\design-thinking.md"
$SourceCheck2 = Join-Path $ScriptDir "workflows\design\ui-design.md"

if (-not (Test-Path $SourceCheck1) -or -not (Test-Path $SourceCheck2)) {
    Write-Host "ERROR: Run this script from the gsd-with-design repository root." -ForegroundColor Red
    Write-Host "Expected files not found:" -ForegroundColor Red
    if (-not (Test-Path $SourceCheck1)) { Write-Host "  - .claude\commands\gsd\design-thinking.md" -ForegroundColor Red }
    if (-not (Test-Path $SourceCheck2)) { Write-Host "  - workflows\design\ui-design.md" -ForegroundColor Red }
    exit 1
}

Write-Host "Source directory: $ScriptDir" -ForegroundColor Gray

# --- 5. GSD Installation Detection (R6.5) ---
$RuntimeDirs = @(".claude", ".config\opencode", ".opencode", ".gemini")
$Installations = @()

# Check local installations
foreach ($dir in $RuntimeDirs) {
    $localPath = Join-Path $ScriptDir $dir
    $versionFile = Join-Path $localPath "get-shit-done\VERSION"
    if (Test-Path $versionFile) {
        $Installations += [PSCustomObject]@{
            Type = "local"
            Path = $localPath
            Version = (Get-Content $versionFile -Raw).Trim()
            RuntimeDir = $dir
        }
    }
}

# Check global installations
foreach ($dir in $RuntimeDirs) {
    $globalPath = Join-Path $HOME $dir
    $versionFile = Join-Path $globalPath "get-shit-done\VERSION"
    if (Test-Path $versionFile) {
        $Installations += [PSCustomObject]@{
            Type = "global"
            Path = $globalPath
            Version = (Get-Content $versionFile -Raw).Trim()
            RuntimeDir = $dir
        }
    }
}

if ($Installations.Count -eq 0) {
    Write-Host "ERROR: No GSD installation found." -ForegroundColor Red
    Write-Host "Install GSD first: npx get-shit-done-cc@latest" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Searched locations:" -ForegroundColor Gray
    foreach ($dir in $RuntimeDirs) {
        Write-Host "  Local:  .\$dir\get-shit-done\VERSION" -ForegroundColor Gray
        Write-Host "  Global: $HOME\$dir\get-shit-done\VERSION" -ForegroundColor Gray
    }
    exit 1
}

$SelectedInstall = $null

if ($Installations.Count -eq 1) {
    $SelectedInstall = $Installations[0]
    Write-Host "Found GSD installation ($($SelectedInstall.Type)): $($SelectedInstall.Path)" -ForegroundColor Green
    Write-Host "  GSD version: $($SelectedInstall.Version)" -ForegroundColor Gray
} else {
    Write-Host "Multiple GSD installations found:" -ForegroundColor Yellow
    Write-Host ""
    for ($i = 0; $i -lt $Installations.Count; $i++) {
        $inst = $Installations[$i]
        Write-Host "  [$($i + 1)] $($inst.Type): $($inst.Path) (v$($inst.Version))" -ForegroundColor White
    }
    Write-Host ""
    $selection = Read-Host "Select installation [1]"
    if ([string]::IsNullOrWhiteSpace($selection)) { $selection = "1" }

    $index = 0
    if (-not [int]::TryParse($selection, [ref]$index) -or $index -lt 1 -or $index -gt $Installations.Count) {
        Write-Host "ERROR: Invalid selection." -ForegroundColor Red
        exit 1
    }
    $SelectedInstall = $Installations[$index - 1]
    Write-Host "Selected: $($SelectedInstall.Path)" -ForegroundColor Green
}

$InstallDir = $SelectedInstall.Path

# --- 6. Existing Design Installation Check ---
$DesignVersionPath = Join-Path $InstallDir "get-shit-done\design-version.json"

if (Test-Path $DesignVersionPath) {
    Write-Host ""
    Write-Host "Existing design installation detected." -ForegroundColor Yellow

    try {
        $existingVersion = Get-Content $DesignVersionPath -Raw | ConvertFrom-Json
        Write-Host "  Installed version: $($existingVersion.version)" -ForegroundColor Gray
        Write-Host "  Installed at: $($existingVersion.installed_at)" -ForegroundColor Gray

        # Check for customized files
        $customized = @()
        if ($existingVersion.files) {
            $fileProps = $existingVersion.files | Get-Member -MemberType NoteProperty
            foreach ($prop in $fileProps) {
                $relPath = $prop.Name
                $storedHash = $existingVersion.files.$relPath
                $fullPath = Join-Path $InstallDir $relPath
                if (Test-Path $fullPath) {
                    $currentHash = "sha256:" + (Get-DesignFileHash -FilePath $fullPath)
                    if ($currentHash -ne $storedHash) {
                        $customized += $relPath
                    }
                }
            }
        }

        if ($customized.Count -gt 0) {
            Write-Host ""
            Write-Host "Customized design files detected:" -ForegroundColor Yellow
            foreach ($f in $customized) {
                Write-Host "  - $f" -ForegroundColor Yellow
            }
            Write-Host ""
            $backup = Read-Host "Back up customized files before overwriting? [Y/n]"
            if ($backup -ne "n" -and $backup -ne "N") {
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $backupDir = Join-Path $InstallDir "get-shit-done\design-backup-$timestamp"
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                foreach ($f in $customized) {
                    $srcFile = Join-Path $InstallDir $f
                    $destFile = Join-Path $backupDir $f
                    $destDir = Split-Path $destFile -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -Path $srcFile -Destination $destFile -Force
                }
                Write-Host "Backed up to: $backupDir" -ForegroundColor Green
            }
        } else {
            Write-Host "  No customizations detected -- safe to overwrite." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Warning: Could not parse existing design-version.json" -ForegroundColor Yellow
    }
}

# --- 7. Path Rewriting Setup ---
# The patched command shims contain hardcoded developer paths that must be
# replaced with the installing user's actual install directory path.
# GSD @ references use forward slashes even on Windows.
$DevPath = "@~/.claude/"
$InstallDirForward = $InstallDir -replace '\\', '/'
$UserPath = "@$InstallDirForward/"

# --- 8. File Copy ---
Write-Host ""
Write-Host "Installing design files..." -ForegroundColor Cyan

# Create target directories
$DesignWorkflowDir = Join-Path $InstallDir "get-shit-done\workflows\design"
$CommandsDir = Join-Path $InstallDir "commands\gsd"
$WorkflowsDir = Join-Path $InstallDir "get-shit-done\workflows"

New-Item -ItemType Directory -Path $DesignWorkflowDir -Force | Out-Null
New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null
New-Item -ItemType Directory -Path $WorkflowsDir -Force | Out-Null

$InstalledCount = 0

# Design-only command files (no path rewriting needed)
$DesignOnlyCommands = @(
    "design-thinking.md",
    "design-ui.md",
    "design-stack.md"
)

foreach ($file in $DesignOnlyCommands) {
    $src = Join-Path $ScriptDir ".claude\commands\gsd\$file"
    $dest = Join-Path $CommandsDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Force
        $InstalledCount++
        Write-Host "  Copied: commands\gsd\$file" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Source not found: $src" -ForegroundColor Yellow
    }
}

# Patched command shims (need path rewriting)
$PatchedCommands = @(
    "new-project.md",
    "discuss-phase.md",
    "plan-phase.md"
)

foreach ($file in $PatchedCommands) {
    $src = Join-Path $ScriptDir ".claude\commands\gsd\$file"
    $dest = Join-Path $CommandsDir $file
    if (Test-Path $src) {
        $content = Get-Content $src -Raw
        $content = $content -replace [regex]::Escape($DevPath), $UserPath
        Set-Content -Path $dest -Value $content -NoNewline
        $InstalledCount++
        Write-Host "  Patched: commands\gsd\$file" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Source not found: $src" -ForegroundColor Yellow
    }
}

# Update command shim (path rewriting if it exists)
$UpdateSrc = Join-Path $ScriptDir ".claude\commands\gsd\update.md"
if (Test-Path $UpdateSrc) {
    $dest = Join-Path $CommandsDir "update.md"
    $content = Get-Content $UpdateSrc -Raw
    $content = $content -replace [regex]::Escape($DevPath), $UserPath
    Set-Content -Path $dest -Value $content -NoNewline
    $InstalledCount++
    Write-Host "  Patched: commands\gsd\update.md" -ForegroundColor Gray
}

# Design-only workflow files (no path rewriting needed)
$DesignWorkflows = @(
    "motion-design.md",
    "orchestrate-design.md",
    "stack-conventions.md",
    "ui-design.md",
    "ui-detection.md",
    "ux-design.md"
)

foreach ($file in $DesignWorkflows) {
    $src = Join-Path $ScriptDir "workflows\design\$file"
    $dest = Join-Path $DesignWorkflowDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Force
        $InstalledCount++
        Write-Host "  Copied: get-shit-done\workflows\design\$file" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Source not found: $src" -ForegroundColor Yellow
    }
}

# Patched workflow files (need path rewriting)
$PatchedWorkflows = @(
    "new-project.md",
    "discuss-phase.md",
    "plan-phase.md"
)

foreach ($file in $PatchedWorkflows) {
    $src = Join-Path $ScriptDir "workflows\$file"
    $dest = Join-Path $WorkflowsDir $file
    if (Test-Path $src) {
        $content = Get-Content $src -Raw
        $content = $content -replace [regex]::Escape($DevPath), $UserPath
        Set-Content -Path $dest -Value $content -NoNewline
        $InstalledCount++
        Write-Host "  Patched: get-shit-done\workflows\$file" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Source not found: $src" -ForegroundColor Yellow
    }
}

# --- 9. design-version.json Generation ---
Write-Host ""
Write-Host "Generating design-version.json..." -ForegroundColor Cyan

$GsdVersion = "unknown"
$GsdVersionFile = Join-Path $InstallDir "get-shit-done\VERSION"
if (Test-Path $GsdVersionFile) {
    $GsdVersion = (Get-Content $GsdVersionFile -Raw).Trim()
}

# Build file checksums map using ordered dictionary for consistent output
$FilesMap = [ordered]@{}

# All installed files with their target-relative paths (forward slashes for JSON keys)
$AllTargetFiles = @(
    @{ RelPath = "commands/gsd/design-thinking.md"; FullPath = Join-Path $CommandsDir "design-thinking.md" },
    @{ RelPath = "commands/gsd/design-ui.md"; FullPath = Join-Path $CommandsDir "design-ui.md" },
    @{ RelPath = "commands/gsd/design-stack.md"; FullPath = Join-Path $CommandsDir "design-stack.md" },
    @{ RelPath = "commands/gsd/new-project.md"; FullPath = Join-Path $CommandsDir "new-project.md" },
    @{ RelPath = "commands/gsd/discuss-phase.md"; FullPath = Join-Path $CommandsDir "discuss-phase.md" },
    @{ RelPath = "commands/gsd/plan-phase.md"; FullPath = Join-Path $CommandsDir "plan-phase.md" },
    @{ RelPath = "commands/gsd/update.md"; FullPath = Join-Path $CommandsDir "update.md" },
    @{ RelPath = "get-shit-done/workflows/design/motion-design.md"; FullPath = Join-Path $DesignWorkflowDir "motion-design.md" },
    @{ RelPath = "get-shit-done/workflows/design/orchestrate-design.md"; FullPath = Join-Path $DesignWorkflowDir "orchestrate-design.md" },
    @{ RelPath = "get-shit-done/workflows/design/stack-conventions.md"; FullPath = Join-Path $DesignWorkflowDir "stack-conventions.md" },
    @{ RelPath = "get-shit-done/workflows/design/ui-design.md"; FullPath = Join-Path $DesignWorkflowDir "ui-design.md" },
    @{ RelPath = "get-shit-done/workflows/design/ui-detection.md"; FullPath = Join-Path $DesignWorkflowDir "ui-detection.md" },
    @{ RelPath = "get-shit-done/workflows/design/ux-design.md"; FullPath = Join-Path $DesignWorkflowDir "ux-design.md" },
    @{ RelPath = "get-shit-done/workflows/new-project.md"; FullPath = Join-Path $WorkflowsDir "new-project.md" },
    @{ RelPath = "get-shit-done/workflows/discuss-phase.md"; FullPath = Join-Path $WorkflowsDir "discuss-phase.md" },
    @{ RelPath = "get-shit-done/workflows/plan-phase.md"; FullPath = Join-Path $WorkflowsDir "plan-phase.md" }
)

foreach ($entry in $AllTargetFiles) {
    if (Test-Path $entry.FullPath) {
        $hash = Get-DesignFileHash -FilePath $entry.FullPath
        $FilesMap[$entry.RelPath] = "sha256:$hash"
    }
}

$VersionObj = [PSCustomObject]@{
    version = "1.0.0"
    schema_version = 1
    installed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    gsd_base_version = $GsdVersion
    files = [PSCustomObject]$FilesMap
}

$VersionJson = $VersionObj | ConvertTo-Json -Depth 3
$VersionJsonPath = Join-Path $InstallDir "get-shit-done\design-version.json"
Set-Content -Path $VersionJsonPath -Value $VersionJson -NoNewline

Write-Host "  Written: get-shit-done\design-version.json" -ForegroundColor Gray

# --- 10. Verification and Summary ---
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan

$ExpectedCount = $AllTargetFiles.Count
$VerifiedCount = 0
$MissingFiles = @()

foreach ($entry in $AllTargetFiles) {
    if (Test-Path $entry.FullPath) {
        $VerifiedCount++
    } else {
        $MissingFiles += $entry.RelPath
    }
}

# Also verify design-version.json
if (Test-Path $VersionJsonPath) {
    $VerifiedCount++
} else {
    $MissingFiles += "get-shit-done/design-version.json"
}

Write-Host ""
Write-Host "Installation Summary:" -ForegroundColor Cyan
Write-Host "  Files installed: $InstalledCount" -ForegroundColor White
Write-Host "  Files verified:  $VerifiedCount / $($ExpectedCount + 1)" -ForegroundColor White
Write-Host "  Install target:  $InstallDir" -ForegroundColor White
Write-Host "  GSD version:     $GsdVersion" -ForegroundColor White

if ($MissingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Some files could not be verified:" -ForegroundColor Yellow
    foreach ($f in $MissingFiles) {
        Write-Host "  - $f" -ForegroundColor Yellow
    }
}

# --- 11. Success ---
Write-Host ""
if ($MissingFiles.Count -eq 0) {
    Write-Host "GSD with Design installed successfully!" -ForegroundColor Green
} else {
    Write-Host "GSD with Design installed with warnings." -ForegroundColor Yellow
}
Write-Host "Restart Claude Code to use design commands." -ForegroundColor White
Write-Host ""
