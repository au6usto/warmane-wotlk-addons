# DoroxLootTracker

A World of Warcraft 3.3.5a (WotLK) addon that tracks and alerts for desired raid loot drops.

## Features

- **Visual Loot Tracker**: Draggable frame showing all tracked items organized by priority
- **Loot Detection**: Monitors chat and loot windows for tracked items
- **Sound Alerts**: Plays raid warning sound when tracked items drop
- **Chat Alerts**: Announces drops with item priority and slot info
- **Priority System**: Items organized by upgrade priority (1 = highest)
- **Obtained Marking**: Click items to mark as obtained (grayed out)
- **Persistent Settings**: Saves position, visibility, and obtained status

## Installation

1. Download and extract to your `Interface/AddOns` folder
2. Ensure the folder is named `DoroxLootTracker`
3. Restart WoW or reload UI (`/reload`)

## Commands

| Command | Description |
|---------|-------------|
| `/dlt help` | Show all commands |
| `/dlt toggle` | Enable/disable addon |
| `/dlt sound` | Toggle sound alerts |
| `/dlt chat` | Toggle chat alerts |
| `/dlt frame` | Toggle tracker frame |
| `/dlt show` | Show tracker frame |
| `/dlt hide` | Hide tracker frame |
| `/dlt list` | List all tracked items |
| `/dlt obtained <item>` | Toggle item obtained status |
| `/dlt reset` | Reset all settings |
| `/dlt test` | Test alert system |

## Tracked Items

The addon tracks ICC and RS loot organized by equipment slot priority:

| Priority | Slot | Items |
|----------|------|-------|
| 1 | Off-Hand | Sundial of Eternal Dusk, Shadow Silk Spindle, Nightmare Ender |
| 2 | Wrists | Bracers of Fiery Night, The Lady's Brittle Bracers, Bracers of Dark Blessings |
| 3 | Neck | Amulet of the Silent Eulogy, Blood Queen's Crimson Choker |
| 4 | Main Hand | Bloodsurge, Rigormortis, Frozen Bonespike |
| 5 | Trinket | Phylactery of the Nameless Lich |
| 6 | Ring | Ring of Rapid Ascent, Memory of Malygos, Signet of Twilight |
| 7 | Token | Conqueror's Mark of Sanctification |

## Priority Colors

| Priority | Color |
|----------|-------|
| 1 | Red |
| 2 | Orange |
| 3 | Yellow |
| 4 | Green |
| 5 | Cyan |
| 6 | Blue |
| 7 | Purple |

## Usage

1. The tracker frame appears on the right side of the screen by default
2. Drag the frame to reposition it
3. Click items to mark them as obtained
4. Hover over items for detailed tooltips
5. When a tracked item drops, you'll hear an alert and see a message

## Customization

To track different items, edit the `trackedItems` table in `DoroxLootTracker.lua`.

## Version

1.0.0

## Author

Dorox @ Lordaeron

## License

Free to use and modify.
