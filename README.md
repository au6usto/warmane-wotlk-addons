# Warmane WotLK Addons

A complete WoW 3.3.5a addon collection for Warmane private servers, with symlink-based management for easy syncing.

## Addons (46 total)

All addons are stored in this repo and symlinked to the WoW client.

### Custom Addons
- **DoroxChatFilter** - Smart LFM chat filter with raid/role highlighting
- **DoroxLootTracker** - Visual raid loot tracker with priority system

### Raid & Combat
- **DBM** (Deadly Boss Mods) - Boss timers and alerts
- **Details** - Damage/healing meters
- **WeakAuras** - Custom UI alerts and trackers
- **GTFO** - Bad stuff warnings
- **DocsCorporeality** - Halion corporeality tracker

### UI & Quality of Life
- **Bagnon** - All-in-one bag addon
- **Quartz** - Modular cast bars
- **OmniCC** - Cooldown text on buttons
- **TidyPlates** - Customizable nameplates
- **MoveAnything** - Move any UI frame
- **OPie** - Radial action menus
- **Auctionator** - Auction house helper
- **Postal** - Mail enhancement
- **Questie** - Quest helper
- **Scrap** - Auto-sell junk
- **GearScoreLite** - Gear score display
- **ClassLoot** - Loot class recommendations
- **AutoRepair** - Auto repair gear
- **SnowfallKeyPress** - Faster key response

## Configuration

### [WeakAuras](config/weakauras/)

Warlock WeakAuras configuration with sync support:
- Full SavedVariables backup
- Exported WA strings for easy sharing
- Sync script to pull/push between game and repo

```bash
# Check sync status
./scripts/sync-weakauras.sh status

# Save in-game changes to repo
./scripts/sync-weakauras.sh pull

# Restore repo config to game
./scripts/sync-weakauras.sh push
```

### [Bottles Setup](config/bottles/) (Linux)

Complete Bottles configuration to run WoW on Linux:
- Wine runner and DXVK settings
- Required dependencies list
- Step-by-step setup guide
- Performance optimizations (Gamemode, Fsync, Vulkan)

### [Windows Setup](config/windows/)

Scripts and guide for syncing to Windows WoW client:
- PowerShell and batch sync scripts
- Symlink or copy mode support
- WeakAuras sync for Windows

## Installation

### Fresh Install (New Machine)

```bash
# Clone the repo
git clone https://github.com/au6usto/warmane-wotlk-addons.git
cd warmane-wotlk-addons

# Create symlinks from repo to WoW AddOns folder
./scripts/sync-addons.sh link

# Restore WeakAuras config
./scripts/sync-weakauras.sh push
```

### Addon Management

```bash
# Check addon sync status
./scripts/sync-addons.sh status

# Import new addons from WoW to repo (after installing new addon in-game)
./scripts/sync-addons.sh import

# Create symlinks for all repo addons
./scripts/sync-addons.sh link
```

## Compatibility

- **WoW Client**: 3.3.5a (Interface: 30300)
- **Server**: Warmane (Lordaeron, Icecrown, etc.)

## License

Custom addons (DoroxChatFilter, DoroxLootTracker) are free to use and modify.
Quartz is licensed under GPL v2.

## Author

Dorox @ Lordaeron
