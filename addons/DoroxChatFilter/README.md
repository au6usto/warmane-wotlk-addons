# DoroxChatFilter

A World of Warcraft 3.3.5a (WotLK) addon that filters and highlights raid recruitment messages in chat.

## Features

- **Smart LFM Detection**: Filters messages containing "LFM", "Looking For", or "Need More"
- **Raid Highlighting**: Color-codes raid names (ICC, RS, VOA) in orange
- **Size/Mode Highlighting**: Highlights raid sizes (10/25) and modes (Normal/Heroic) in yellow
- **Role Detection**: Detects when groups need RDPS, Casters, or "All DPS" (highlighted in cyan)
- **Compound Pattern Support**: Recognizes combined formats like "ICC10H", "RS25NM", etc.
- **Personal Alerts**: Get notified when your name or custom keywords are mentioned in raid/party chat
- **Lockout Awareness**: Automatically hides raids you're already saved to
- **Raid Config Ignore**: Permanently ignore specific raid configurations (e.g., ICC25)
- **Exclusion Keywords**: Filter out unwanted messages (e.g., "REP FARM")
- **Hyperlink Safe**: Preserves achievement and item links while highlighting keywords
- **Sound Notifications**: Plays distinct sounds for raid matches and personal alerts

## Installation

1. Download and extract to your `Interface/AddOns` folder
2. Ensure the folder is named `DoroxChatFilter`
3. Restart WoW or reload UI (`/reload`)

## Commands

| Command | Description |
|---------|-------------|
| `/dcf help` | Show all commands |
| `/dcf toggle` | Enable/disable addon |
| `/dcf sound` | Toggle sound notifications |
| `/dcf filter` | Toggle show only matching messages |
| `/dcf lockout` | Toggle lockout awareness |
| `/dcf colors` | Show current color settings |
| `/dcf color <category> <hex>` | Set color (raids/size/role/personal) |
| `/dcf addraid <keyword>` | Add raid keyword |
| `/dcf addrole <keyword>` | Add role keyword |
| `/dcf addpersonal <keyword>` | Add personal alert keyword |
| `/dcf addexclude <keyword>` | Add exclusion keyword |
| `/dcf ignore <raid><size>` | Ignore a raid config (e.g., ICC25) |
| `/dcf unignore <raid><size>` | Stop ignoring a raid config |
| `/dcf list` | List all keywords |
| `/dcf test` | Test with sample messages |
| `/dcf reset` | Reset to defaults |
| `/dcf status` | Show current settings |

## Default Keywords

- **Raids**: ICC, RS, VOA, ICECROWN, RUBY SANCTUM, VAULT, HALION, TORAVON, LK, LICH KING
- **Sizes**: 10, 25, 10N, 25N, 10H, 25H, NORMAL, HEROIC, ST, SERVER TIME
- **Roles**: RDPS, CDPS, CASTER, RANGED, CLOTH, SPELLCASTER, DPS, ALL, ANY
- **Exclusions**: REP FARM, REPFARM, REPUTATION FARM

## Color Coding

| Category | Default Color | Hex |
|----------|--------------|-----|
| Raids | Orange | FF6600 |
| Size/Mode | Yellow | FFFF00 |
| Role | Cyan | 00FFFF |
| Personal | Magenta | FF00FF |

## Version

1.1.0

## Author

Dorox @ Lordaeron

## License

Free to use and modify.
