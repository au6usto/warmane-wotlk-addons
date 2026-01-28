# WeakAuras Configuration

This folder contains WeakAuras configurations for WotLK 3.3.5a.

## Structure

```
weakauras/
├── saved-variables/     # Raw WeakAuras.lua from WoW client
│   └── WeakAuras.lua    # Full configuration (auto-synced)
└── exports/             # Exported WA strings (shareable)
    ├── wa_warlock_buffs.txt
    ├── wa_warlock_debuffs.txt
    ├── wa_warlock_utils.txt
    └── Warlock_wotlk.txt
```

## Syncing with WoW Client

Use the sync script to keep your in-game WeakAuras in sync with this repo:

```bash
# Check sync status
./scripts/sync-weakauras.sh status

# Save in-game changes to repo (after editing WAs in-game)
./scripts/sync-weakauras.sh pull

# Restore repo config to game (fresh install or corrupted config)
./scripts/sync-weakauras.sh push
```

**Important**: Close WoW before syncing! WeakAuras saves on logout.

## Workflow

### After editing WeakAuras in-game:
1. Log out of WoW (saves WeakAuras)
2. Run `./scripts/sync-weakauras.sh pull`
3. Review: `git diff config/weakauras/`
4. Commit: `git add config/weakauras/ && git commit -m "Update WeakAuras"`

### After fresh WoW install:
1. Run `./scripts/sync-weakauras.sh push`
2. Start WoW - your WeakAuras will be restored

## Exported Strings

The `exports/` folder contains WeakAuras export strings that can be imported directly in-game:

1. Open WeakAuras in-game (`/wa`)
2. Click "Import"
3. Paste the contents of a `.txt` file
4. Click "Import"

### Available Exports

| File | Description |
|------|-------------|
| `wa_warlock_buffs.txt` | Warlock buff tracking auras |
| `wa_warlock_debuffs.txt` | Warlock debuff tracking on target |
| `wa_warlock_utils.txt` | Utility auras (shard count, etc.) |
| `Warlock_wotlk.txt` | Legacy warlock auras |

## Notes

- The `saved-variables/WeakAuras.lua` contains ALL your auras including imported ones
- Export strings are more portable for sharing individual aura groups
- Always backup before pushing to avoid losing in-game changes
