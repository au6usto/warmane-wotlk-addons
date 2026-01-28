<#
.SYNOPSIS
    Sync WeakAuras configuration between this repository and the WoW client on Windows.

.DESCRIPTION
    Copies WeakAuras SavedVariables between the repo and WoW's WTF folder.

.PARAMETER Action
    The action to perform: push, pull, or status

.PARAMETER WowPath
    Custom WoW installation path (optional)

.PARAMETER Account
    WoW account name (folder in WTF/Account/)

.EXAMPLE
    .\sync-weakauras.ps1 -Action push
    .\sync-weakauras.ps1 -Action pull -Account "MYACCOUNT"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("push", "pull", "status")]
    [string]$Action,

    [string]$WowPath = $env:WOW_PATH,
    [string]$Account
)

# Default paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$RepoWeakAuras = Join-Path $RepoDir "config\weakauras\saved-variables"

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
    exit 1
}

# Find account folder
$WtfAccount = Join-Path $WowPath "WTF\Account"

if (-not $Account) {
    # Try to find account folder automatically
    if (Test-Path $WtfAccount) {
        $accounts = Get-ChildItem -Path $WtfAccount -Directory | Where-Object { $_.Name -ne "SavedVariables" }
        if ($accounts.Count -eq 1) {
            $Account = $accounts[0].Name
        } elseif ($accounts.Count -gt 1) {
            Write-Host "Multiple accounts found:" -ForegroundColor Yellow
            $accounts | ForEach-Object { Write-Host "  - $($_.Name)" }
            Write-Host ""
            $Account = Read-Host "Enter account name"
        }
    }
}

if (-not $Account) {
    Write-Host "ERROR: Could not determine account folder!" -ForegroundColor Red
    Write-Host "Please specify with -Account parameter"
    exit 1
}

$WowSavedVars = Join-Path $WtfAccount "$Account\SavedVariables"

# Ensure directories exist
if (-not (Test-Path $WowSavedVars)) {
    New-Item -ItemType Directory -Path $WowSavedVars -Force | Out-Null
}

function Get-FileInfo {
    param([string]$Path)

    if (Test-Path $Path) {
        $file = Get-Item $Path
        $size = "{0:N0}" -f $file.Length
        $date = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        return @{
            Exists = $true
            Size = $size
            Date = $date
        }
    }
    return @{ Exists = $false }
}

function Show-Status {
    Write-Host "WeakAuras Sync Status" -ForegroundColor Yellow
    Write-Host "=====================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Repository: $RepoWeakAuras"
    Write-Host "WoW SavedVariables: $WowSavedVars"
    Write-Host "Account: $Account"
    Write-Host ""

    $repoFile = Join-Path $RepoWeakAuras "WeakAuras.lua"
    $wowFile = Join-Path $WowSavedVars "WeakAuras.lua"

    $repoInfo = Get-FileInfo $repoFile
    $wowInfo = Get-FileInfo $wowFile

    Write-Host "Files:" -ForegroundColor Cyan
    if ($repoInfo.Exists) {
        Write-Host "  Repository:  Found ($($repoInfo.Size) bytes, $($repoInfo.Date))" -ForegroundColor Green
    } else {
        Write-Host "  Repository:  Not found" -ForegroundColor Red
    }

    if ($wowInfo.Exists) {
        Write-Host "  WoW Client:  Found ($($wowInfo.Size) bytes, $($wowInfo.Date))" -ForegroundColor Green
    } else {
        Write-Host "  WoW Client:  Not found" -ForegroundColor Red
    }

    Write-Host ""

    if ($repoInfo.Exists -and $wowInfo.Exists) {
        $repoHash = (Get-FileHash $repoFile -Algorithm MD5).Hash
        $wowHash = (Get-FileHash $wowFile -Algorithm MD5).Hash

        if ($repoHash -eq $wowHash) {
            Write-Host "Status: In sync" -ForegroundColor Green
        } else {
            Write-Host "Status: Out of sync" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Run '.\sync-weakauras.ps1 -Action pull' to backup WoW changes to repo"
            Write-Host "Run '.\sync-weakauras.ps1 -Action push' to restore repo config to WoW"
        }
    }
}

function Push-WeakAuras {
    Write-Host "Pushing WeakAuras from repo to WoW..." -ForegroundColor Yellow

    $repoFile = Join-Path $RepoWeakAuras "WeakAuras.lua"

    if (-not (Test-Path $repoFile)) {
        Write-Host "ERROR: WeakAuras.lua not found in repo!" -ForegroundColor Red
        exit 1
    }

    $wowFile = Join-Path $WowSavedVars "WeakAuras.lua"

    # Backup existing
    if (Test-Path $wowFile) {
        $backupFile = Join-Path $WowSavedVars "WeakAuras.lua.bak"
        Copy-Item $wowFile $backupFile -Force
        Write-Host "  Backed up existing file to WeakAuras.lua.bak"
    }

    # Copy from repo to WoW
    Copy-Item $repoFile $wowFile -Force
    Write-Host ""
    Write-Host "Done! WeakAuras.lua copied to WoW" -ForegroundColor Green
    Write-Host "Start WoW to load the restored configuration."
}

function Pull-WeakAuras {
    Write-Host "Pulling WeakAuras from WoW to repo..." -ForegroundColor Yellow

    $wowFile = Join-Path $WowSavedVars "WeakAuras.lua"

    if (-not (Test-Path $wowFile)) {
        Write-Host "ERROR: WeakAuras.lua not found in WoW!" -ForegroundColor Red
        Write-Host "Make sure you've logged into the game at least once."
        exit 1
    }

    $repoFile = Join-Path $RepoWeakAuras "WeakAuras.lua"

    # Backup existing
    if (Test-Path $repoFile) {
        $backupFile = Join-Path $RepoWeakAuras "WeakAuras.lua.bak"
        Copy-Item $repoFile $backupFile -Force
        Write-Host "  Backed up existing repo file to WeakAuras.lua.bak"
    }

    # Copy from WoW to repo
    Copy-Item $wowFile $repoFile -Force
    Write-Host ""
    Write-Host "Done! WeakAuras.lua copied to repo" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review: git diff config/weakauras/"
    Write-Host "  2. Commit: git add config/weakauras/ && git commit -m 'Update WeakAuras'"
}

# Main
switch ($Action) {
    "push" { Push-WeakAuras }
    "pull" { Pull-WeakAuras }
    "status" { Show-Status }
}
