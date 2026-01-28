# Windows Setup Guide

This guide explains how to sync your addons and WeakAuras configuration to a Windows WoW client.

## Prerequisites

- Git for Windows: https://git-scm.com/download/win
- Warmane WoW client installed

## Quick Setup

### 1. Clone the Repository

Open **Git Bash** or **PowerShell** and run:

```powershell
cd C:\
git clone https://github.com/au6usto/warmane-wotlk-addons.git
```

This creates `C:\warmane-wotlk-addons\`

### 2. Run the Sync Script

**Option A: PowerShell (Recommended)**

1. Open PowerShell **as Administrator** (required for symlinks)
2. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   C:\warmane-wotlk-addons\config\windows\sync-addons.ps1 -Action link
   ```

**Option B: Command Prompt (Admin)**

1. Open Command Prompt **as Administrator**
2. Run:
   ```cmd
   C:\warmane-wotlk-addons\config\windows\sync-addons.bat link
   ```

### 3. Sync WeakAuras

```powershell
C:\warmane-wotlk-addons\config\windows\sync-weakauras.ps1 -Action push
```

## Script Commands

### Addon Sync (`sync-addons.ps1` / `sync-addons.bat`)

| Command | Description |
|---------|-------------|
| `link` | Create symlinks from repo to WoW AddOns folder |
| `copy` | Copy addons (no symlinks, for non-admin users) |
| `status` | Show sync status |

### WeakAuras Sync (`sync-weakauras.ps1`)

| Command | Description |
|---------|-------------|
| `push` | Copy WeakAuras from repo to WoW (restore) |
| `pull` | Copy WeakAuras from WoW to repo (backup) |
| `status` | Show sync status |

## Default Paths

The scripts assume these default paths:

| Item | Path |
|------|------|
| Repository | `C:\warmane-wotlk-addons\` |
| WoW Client | `C:\World of Warcraft\` |
| AddOns | `C:\World of Warcraft\Interface\AddOns\` |
| SavedVariables | `C:\World of Warcraft\WTF\Account\<ACCOUNT>\SavedVariables\` |

### Custom WoW Path

If your WoW is installed elsewhere, set the path:

**PowerShell:**
```powershell
$env:WOW_PATH = "D:\Games\WoW"
.\sync-addons.ps1 -Action link
```

**Or edit the script** and change the `$WOW_PATH` variable.

## Symlinks vs Copy

### Symlinks (Recommended)
- Changes in repo are instantly reflected in game
- Requires **Administrator** privileges
- Uses Windows symbolic links (`mklink /D`)

### Copy Mode
- No admin required
- Must re-run script after pulling git updates
- Uses regular file copy

## Workflow

### After Pulling Updates

```powershell
cd C:\warmane-wotlk-addons
git pull

# If using symlinks - nothing else needed!

# If using copy mode:
.\config\windows\sync-addons.ps1 -Action copy
.\config\windows\sync-weakauras.ps1 -Action push
```

### After Editing WeakAuras In-Game

```powershell
# Close WoW first!
cd C:\warmane-wotlk-addons
.\config\windows\sync-weakauras.ps1 -Action pull
git add config/weakauras/
git commit -m "Update WeakAuras"
git push
```

## Troubleshooting

### "Symlink privilege not held"
- Run PowerShell/CMD as Administrator
- Or use `-Action copy` instead of `-Action link`

### "Access denied"
- Close WoW before syncing
- Run as Administrator

### "WoW path not found"
- Edit the script to set your custom WoW installation path
- Or set `$env:WOW_PATH` environment variable

### Addons not showing in-game
1. Check that addons are in the correct folder
2. Make sure addon folders aren't nested (e.g., `AddOns\DBM-Core\DBM-Core\` is wrong)
3. Verify the `.toc` file matches WoW version (30300 for WotLK)

## Manual Setup (No Scripts)

If scripts don't work, you can manually copy:

1. Copy all folders from `C:\warmane-wotlk-addons\addons\*` to `C:\World of Warcraft\Interface\AddOns\`
2. Copy `C:\warmane-wotlk-addons\config\weakauras\saved-variables\WeakAuras.lua` to `C:\World of Warcraft\WTF\Account\<YOUR_ACCOUNT>\SavedVariables\`

Replace `<YOUR_ACCOUNT>` with your WoW account folder name.
