# Bottles Setup for Warmane WoW

This guide explains how to recreate the Bottles configuration for running Warmane WoW on Linux.

## Prerequisites

- [Bottles](https://usebottles.com/) installed (Flatpak recommended)
- Warmane WoW client downloaded from [warmane.com](https://www.warmane.com/)
- GPU drivers with Vulkan support

## Quick Setup

### 1. Install Bottles

```bash
# Flatpak (recommended)
flatpak install flathub com.usebottles.bottles

# Or via your distro's package manager
```

### 2. Create the Bottle

1. Open Bottles
2. Click **"Create new Bottle"**
3. Configure:
   - **Name**: `Warmane`
   - **Environment**: `Gaming`
   - **Runner**: `soda-9.0-1` (or latest soda/wine-ge)
4. Click **Create**

### 3. Install Dependencies

Go to **Dependencies** tab and install:

| Dependency | Purpose |
|------------|---------|
| `d3dx9` | DirectX 9 runtime |
| `d3dx11` | DirectX 11 runtime |
| `d3dcompiler_43` | Shader compiler |
| `d3dcompiler_47` | Shader compiler |
| `devenum` | Device enumeration |
| `quartz` | DirectShow |
| `mono` | .NET runtime |
| `gecko` | HTML rendering |
| `arial32` | Arial font |
| `times32` | Times New Roman font |
| `courie32` | Courier font |
| `msls31` | Line services |

### 4. Configure Settings

Go to **Settings** tab:

**Graphics:**
- DXVK: `Enabled` (dxvk-2.7.1 or latest)
- VKD3D: `Enabled` (vkd3d-proton-2.14.1 or latest)
- Renderer: `Vulkan`
- Discrete GPU: `Enabled`

**Performance:**
- Gamemode: `Enabled`
- Sync: `Fsync`
- Vmtouch: `Enabled`

**Other:**
- Mouse Warp: `Enabled`

### 5. Install WoW Client

1. Download Warmane client from warmane.com
2. Extract to the bottle's `drive_c` folder:
   ```
   ~/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/drive_c/warmane/
   ```
3. Structure should be:
   ```
   drive_c/
   └── warmane/
       ├── Wow.exe
       ├── Data/
       ├── Interface/
       └── WTF/
   ```

### 6. Add WoW as External Program

1. Go to **Programs** tab
2. Click **Add Program**
3. Navigate to `drive_c/warmane/Wow.exe`
4. Name it: `Warmane WoW`

### 7. Restore Addons and Config

```bash
# Clone this repo
git clone https://github.com/au6usto/warmane-wotlk-addons.git
cd warmane-wotlk-addons

# Symlink addons to WoW
WOW_ADDONS="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/drive_c/warmane/Interface/AddOns"

ln -s "$(pwd)/addons/DoroxChatFilter" "$WOW_ADDONS/"
ln -s "$(pwd)/addons/DoroxLootTracker" "$WOW_ADDONS/"
ln -s "$(pwd)/addons/Quartz" "$WOW_ADDONS/"

# Restore WeakAuras config
./scripts/sync-weakauras.sh push
```

## Bottle Paths Reference

| Description | Path |
|-------------|------|
| Bottle root | `~/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/` |
| Wine prefix | `~/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/` |
| WoW client | `drive_c/warmane/` |
| Addons | `drive_c/warmane/Interface/AddOns/` |
| SavedVariables | `drive_c/warmane/WTF/Account/<ACCOUNT>/SavedVariables/` |
| Config | `bottle.yml` |

## Configuration Reference

See [bottle.yml](bottle.yml) for the complete configuration reference including:
- Runner version
- DXVK/VKD3D versions
- All dependencies
- Parameters

## Troubleshooting

### Game won't start
- Verify all dependencies are installed
- Try a different runner (wine-ge, proton-ge)
- Check Bottles logs for errors

### Poor performance
- Enable Gamemode and Fsync
- Verify discrete GPU is selected
- Try DXVK instead of WineD3D

### Audio issues
- Install `pulseaudio` or `pipewire` dependencies
- Check audio device in Wine config

### Font issues
- Install arial32, times32, courie32 dependencies
- Install corefonts if available

## Backup

To backup your complete bottle (including WoW client):
```bash
# This will be large (20GB+)
tar -czvf warmane-bottle-backup.tar.gz \
  ~/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/
```

To backup just the config (recommended):
```bash
cp ~/.var/app/com.usebottles.bottles/data/bottles/bottles/Warmane/bottle.yml ./
```
