<#
.SYNOPSIS
    Sync WoW addons between this repository and the WoW client on Windows.

.DESCRIPTION
    Creates symlinks or copies addons from the repo to the WoW AddOns folder.

.PARAMETER Action
    The action to perform: link, copy, or status

.PARAMETER WowPath
    Custom WoW installation path (optional)

.EXAMPLE
    .\sync-addons.ps1 -Action link
    .\sync-addons.ps1 -Action copy -WowPath "D:\Games\WoW"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("link", "copy", "status")]
    [string]$Action,

    [string]$WowPath = $env:WOW_PATH
)

# Default paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$RepoAddons = Join-Path $RepoDir "addons"

# Try common WoW paths if not specified
if (-not $WowPath) {
    $CommonPaths = @(
        "C:\World of Warcraft",
        "C:\Program Files\World of Warcraft",
        "C:\Program Files (x86)\World of Warcraft",
        "D:\World of Warcraft",
        "D:\Games\World of Warcraft",
        "C:\Games\World of Warcraft"
    )

    foreach ($path in $CommonPaths) {
        if (Test-Path $path) {
            $WowPath = $path
            break
        }
    }
}

if (-not $WowPath -or -not (Test-Path $WowPath)) {
    Write-Host "ERROR: WoW installation not found!" -ForegroundColor Red
    Write-Host "Please set the WOW_PATH environment variable or use -WowPath parameter"
    Write-Host "Example: .\sync-addons.ps1 -Action link -WowPath 'D:\Games\WoW'"
    exit 1
}

$WowAddons = Join-Path $WowPath "Interface\AddOns"

# Ensure AddOns folder exists
if (-not (Test-Path $WowAddons)) {
    New-Item -ItemType Directory -Path $WowAddons -Force | Out-Null
}

function Get-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Status {
    Write-Host "Addon Sync Status" -ForegroundColor Yellow
    Write-Host "=================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Repository: $RepoAddons"
    Write-Host "WoW AddOns: $WowAddons"
    Write-Host ""

    $inRepo = 0
    $linked = 0
    $copied = 0
    $missing = 0

    Write-Host "Addons in repo:" -ForegroundColor Cyan
    Get-ChildItem -Path $RepoAddons -Directory | ForEach-Object {
        $name = $_.Name
        $wowAddon = Join-Path $WowAddons $name
        $inRepo++

        if (Test-Path $wowAddon) {
            $item = Get-Item $wowAddon -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                Write-Host "  [LINKED] $name" -ForegroundColor Green
                $linked++
            } else {
                Write-Host "  [COPIED] $name" -ForegroundColor Blue
                $copied++
            }
        } else {
            Write-Host "  [MISSING] $name" -ForegroundColor Red
            $missing++
        }
    }

    Write-Host ""
    Write-Host "Summary: $inRepo in repo, $linked linked, $copied copied, $missing missing"
}

function New-AddonLinks {
    if (-not (Get-IsAdmin)) {
        Write-Host "WARNING: Not running as Administrator!" -ForegroundColor Yellow
        Write-Host "Symlinks require Administrator privileges."
        Write-Host "Run PowerShell as Administrator, or use '-Action copy' instead."
        Write-Host ""
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne 'y') {
            exit 1
        }
    }

    Write-Host "Creating symlinks from repo to WoW..." -ForegroundColor Yellow
    Write-Host ""

    $linked = 0
    $skipped = 0
    $errors = 0

    Get-ChildItem -Path $RepoAddons -Directory | ForEach-Object {
        $name = $_.Name
        $source = $_.FullName
        $target = Join-Path $WowAddons $name

        if (Test-Path $target) {
            $item = Get-Item $target -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                Write-Host "  [SKIP] $name (already linked)" -ForegroundColor Cyan
                $skipped++
                return
            } else {
                Write-Host "  [REPLACE] $name" -ForegroundColor Yellow
                Remove-Item $target -Recurse -Force
            }
        }

        try {
            # Create symbolic link
            $null = New-Item -ItemType SymbolicLink -Path $target -Target $source -Force
            Write-Host "  [LINK] $name" -ForegroundColor Green
            $linked++
        } catch {
            Write-Host "  [ERROR] $name - $_" -ForegroundColor Red
            $errors++
        }
    }

    Write-Host ""
    Write-Host "Done! Linked: $linked, Skipped: $skipped, Errors: $errors" -ForegroundColor Green
}

function Copy-Addons {
    Write-Host "Copying addons from repo to WoW..." -ForegroundColor Yellow
    Write-Host ""

    $copied = 0
    $skipped = 0

    Get-ChildItem -Path $RepoAddons -Directory | ForEach-Object {
        $name = $_.Name
        $source = $_.FullName
        $target = Join-Path $WowAddons $name

        Write-Host "  [COPY] $name" -ForegroundColor Green

        if (Test-Path $target) {
            Remove-Item $target -Recurse -Force
        }

        Copy-Item -Path $source -Destination $target -Recurse -Force
        $copied++
    }

    Write-Host ""
    Write-Host "Done! Copied: $copied addons" -ForegroundColor Green
}

# Main
switch ($Action) {
    "link" { New-AddonLinks }
    "copy" { Copy-Addons }
    "status" { Show-Status }
}
