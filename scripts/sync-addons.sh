#!/bin/bash
#
# Addon Sync Script
# Manages addons between this repo and the WoW client
#
# Set WOW_ADDONS environment variable to override auto-detection:
#   export WOW_ADDONS="/path/to/WoW/Interface/AddOns"
#

# Don't use set -e because ((var++)) returns 1 when var is 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ADDONS="$REPO_DIR/addons"

# Auto-detect WoW AddOns path if not set
if [ -z "$WOW_ADDONS" ]; then
    # Try common Bottles/Flatpak path
    BOTTLES_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"
    if [ -d "$BOTTLES_BASE" ]; then
        # Find first bottle with WoW
        for bottle in "$BOTTLES_BASE"/*; do
            if [ -d "$bottle/drive_c" ]; then
                # Check for WoW in common locations
                for wow_path in "warmane" "World of Warcraft" "WoW"; do
                    if [ -d "$bottle/drive_c/$wow_path/Interface/AddOns" ]; then
                        WOW_ADDONS="$bottle/drive_c/$wow_path/Interface/AddOns"
                        break 2
                    fi
                done
            fi
        done
    fi

    # Try native Wine path
    if [ -z "$WOW_ADDONS" ] && [ -d "$HOME/.wine/drive_c" ]; then
        for wow_path in "World of Warcraft" "WoW" "warmane"; do
            if [ -d "$HOME/.wine/drive_c/$wow_path/Interface/AddOns" ]; then
                WOW_ADDONS="$HOME/.wine/drive_c/$wow_path/Interface/AddOns"
                break
            fi
        done
    fi
fi

if [ -z "$WOW_ADDONS" ]; then
    echo "ERROR: Could not find WoW AddOns folder!"
    echo "Please set the WOW_ADDONS environment variable:"
    echo "  export WOW_ADDONS=\"/path/to/WoW/Interface/AddOns\""
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Addons to skip (Blizzard defaults)
is_blizzard_addon() {
    [[ "$1" == Blizzard_* ]]
}

print_usage() {
    echo "Usage: $0 [import|status|link]"
    echo ""
    echo "Commands:"
    echo "  import  - Copy all addons from WoW to repo and create symlinks"
    echo "  status  - Show current addon sync status"
    echo "  link    - Create symlinks for addons already in repo"
    echo ""
    echo "Environment variables:"
    echo "  WOW_ADDONS  - Path to WoW Interface/AddOns folder"
    echo ""
    echo "Current paths:"
    echo "  Repo:  $REPO_ADDONS"
    echo "  WoW:   $WOW_ADDONS"
}

do_status() {
    echo -e "${YELLOW}Addon Sync Status${NC}"
    echo "=================="
    echo ""
    echo -e "Repo addons:  $REPO_ADDONS"
    echo -e "WoW addons:   $WOW_ADDONS"
    echo ""

    local in_repo=0
    local symlinked=0
    local not_synced=0

    echo -e "${CYAN}Addons in repo:${NC}"
    for addon in "$REPO_ADDONS"/*; do
        if [ -d "$addon" ]; then
            name=$(basename "$addon")
            ((in_repo++))
            if [ -L "$WOW_ADDONS/$name" ]; then
                echo -e "  ${GREEN}[LINKED]${NC} $name"
                ((symlinked++))
            else
                echo -e "  ${RED}[NOT LINKED]${NC} $name"
            fi
        fi
    done

    echo ""
    echo -e "${CYAN}Addons in WoW not in repo:${NC}"
    for addon in "$WOW_ADDONS"/*; do
        if [ -d "$addon" ] && [ ! -L "$addon" ]; then
            name=$(basename "$addon")
            if is_blizzard_addon "$name"; then
                continue
            fi
            if [ ! -d "$REPO_ADDONS/$name" ]; then
                echo -e "  ${YELLOW}[NOT SYNCED]${NC} $name"
                ((not_synced++))
            fi
        fi
    done

    echo ""
    echo "Summary: $in_repo in repo, $symlinked linked, $not_synced not synced"
}

do_import() {
    echo -e "${YELLOW}Importing addons from WoW to repo...${NC}"
    echo ""

    if [ ! -d "$WOW_ADDONS" ]; then
        echo -e "${RED}Error: WoW AddOns folder not found${NC}"
        exit 1
    fi

    mkdir -p "$REPO_ADDONS"

    local imported=0
    local skipped=0
    local linked=0

    for addon in "$WOW_ADDONS"/*; do
        if [ ! -d "$addon" ]; then
            continue
        fi

        name=$(basename "$addon")

        # Skip Blizzard addons
        if is_blizzard_addon "$name"; then
            continue
        fi

        # Skip if already a symlink
        if [ -L "$addon" ]; then
            echo -e "  ${CYAN}[SKIP]${NC} $name (already symlinked)"
            ((skipped++))
            continue
        fi

        # Skip LICENSE file
        if [ "$name" = "LICENSE" ]; then
            continue
        fi

        echo -e "  ${GREEN}[IMPORT]${NC} $name"

        # Copy to repo if not exists
        if [ ! -d "$REPO_ADDONS/$name" ]; then
            cp -r "$addon" "$REPO_ADDONS/"
            ((imported++))
        fi

        # Remove original and create symlink
        rm -rf "$addon"
        ln -s "$REPO_ADDONS/$name" "$addon"
        ((linked++))
    done

    echo ""
    echo -e "${GREEN}Done!${NC} Imported: $imported, Linked: $linked, Skipped: $skipped"
    echo ""
    echo "Next steps:"
    echo "  1. Review: git status"
    echo "  2. Commit: git add addons/ && git commit -m 'Add all addons'"
}

do_link() {
    echo -e "${YELLOW}Creating symlinks for repo addons...${NC}"
    echo ""

    local linked=0
    local skipped=0

    for addon in "$REPO_ADDONS"/*; do
        if [ ! -d "$addon" ]; then
            continue
        fi

        name=$(basename "$addon")

        if [ -L "$WOW_ADDONS/$name" ]; then
            echo -e "  ${CYAN}[SKIP]${NC} $name (already linked)"
            ((skipped++))
        elif [ -d "$WOW_ADDONS/$name" ]; then
            echo -e "  ${YELLOW}[REPLACE]${NC} $name (removing existing folder)"
            rm -rf "$WOW_ADDONS/$name"
            ln -s "$addon" "$WOW_ADDONS/$name"
            ((linked++))
        else
            echo -e "  ${GREEN}[LINK]${NC} $name"
            ln -s "$addon" "$WOW_ADDONS/$name"
            ((linked++))
        fi
    done

    echo ""
    echo -e "${GREEN}Done!${NC} Linked: $linked, Skipped: $skipped"
}

# Main
case "${1:-}" in
    import)
        do_import
        ;;
    status)
        do_status
        ;;
    link)
        do_link
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
