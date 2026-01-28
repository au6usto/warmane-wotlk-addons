#!/bin/bash
#
# WeakAuras Sync Script
# Syncs WeakAuras configuration between WoW client and this repository
#
# Set environment variables to override auto-detection:
#   export WOW_SAVED_VARS="/path/to/WTF/Account/ACCOUNTNAME/SavedVariables"
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
REPO_SAVED_VARS="$REPO_DIR/config/weakauras/saved-variables"
REPO_EXPORTS="$REPO_DIR/config/weakauras/exports"

# Auto-detect WoW SavedVariables path if not set
if [ -z "$WOW_SAVED_VARS" ]; then
    # Try common Bottles/Flatpak path
    BOTTLES_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"
    if [ -d "$BOTTLES_BASE" ]; then
        for bottle in "$BOTTLES_BASE"/*; do
            if [ -d "$bottle/drive_c" ]; then
                for wow_path in "warmane" "World of Warcraft" "WoW"; do
                    WTF_PATH="$bottle/drive_c/$wow_path/WTF/Account"
                    if [ -d "$WTF_PATH" ]; then
                        # Find first account folder with SavedVariables
                        for account in "$WTF_PATH"/*; do
                            if [ -d "$account/SavedVariables" ]; then
                                WOW_SAVED_VARS="$account/SavedVariables"
                                break 3
                            fi
                        done
                    fi
                done
            fi
        done
    fi

    # Try native Wine path
    if [ -z "$WOW_SAVED_VARS" ] && [ -d "$HOME/.wine/drive_c" ]; then
        for wow_path in "World of Warcraft" "WoW" "warmane"; do
            WTF_PATH="$HOME/.wine/drive_c/$wow_path/WTF/Account"
            if [ -d "$WTF_PATH" ]; then
                for account in "$WTF_PATH"/*; do
                    if [ -d "$account/SavedVariables" ]; then
                        WOW_SAVED_VARS="$account/SavedVariables"
                        break 2
                    fi
                done
            fi
        done
    fi
fi

if [ -z "$WOW_SAVED_VARS" ]; then
    echo "ERROR: Could not find WoW SavedVariables folder!"
    echo "Please set the WOW_SAVED_VARS environment variable:"
    echo "  export WOW_SAVED_VARS=\"/path/to/WTF/Account/ACCOUNTNAME/SavedVariables\""
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [pull|push|status]"
    echo ""
    echo "Commands:"
    echo "  pull    - Copy WeakAuras from WoW client to repo (backup your in-game config)"
    echo "  push    - Copy WeakAuras from repo to WoW client (restore config to game)"
    echo "  status  - Show sync status and file differences"
    echo ""
    echo "Environment variables:"
    echo "  WOW_SAVED_VARS  - Path to WoW WTF/Account/<NAME>/SavedVariables"
    echo ""
    echo "Current paths:"
    echo "  Repo:  $REPO_SAVED_VARS"
    echo "  WoW:   $WOW_SAVED_VARS"
}

check_wow_running() {
    if pgrep -f "WoW.exe" > /dev/null 2>&1 || pgrep -f "Wow.exe" > /dev/null 2>&1; then
        echo -e "${RED}Warning: WoW appears to be running!${NC}"
        echo "WeakAuras saves on logout. Close WoW first for accurate sync."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

do_pull() {
    echo -e "${YELLOW}Pulling WeakAuras from WoW client to repo...${NC}"
    check_wow_running

    if [[ ! -f "$WOW_SAVED_VARS/WeakAuras.lua" ]]; then
        echo -e "${RED}Error: WeakAuras.lua not found in WoW client${NC}"
        echo "Path checked: $WOW_SAVED_VARS"
        exit 1
    fi

    # Backup existing repo file
    if [[ -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        cp "$REPO_SAVED_VARS/WeakAuras.lua" "$REPO_SAVED_VARS/WeakAuras.lua.bak"
        echo "  Backed up existing repo file to WeakAuras.lua.bak"
    fi

    # Copy from WoW to repo
    mkdir -p "$REPO_SAVED_VARS"
    cp "$WOW_SAVED_VARS/WeakAuras.lua" "$REPO_SAVED_VARS/"
    echo -e "${GREEN}Done! WeakAuras.lua copied to repo${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff config/weakauras/"
    echo "  2. Commit: git add config/weakauras/ && git commit -m 'Update WeakAuras config'"
}

do_push() {
    echo -e "${YELLOW}Pushing WeakAuras from repo to WoW client...${NC}"
    check_wow_running

    if [[ ! -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        echo -e "${RED}Error: WeakAuras.lua not found in repo${NC}"
        exit 1
    fi

    # Backup existing WoW file
    if [[ -f "$WOW_SAVED_VARS/WeakAuras.lua" ]]; then
        cp "$WOW_SAVED_VARS/WeakAuras.lua" "$WOW_SAVED_VARS/WeakAuras.lua.bak"
        echo "  Backed up existing WoW file to WeakAuras.lua.bak"
    fi

    # Copy from repo to WoW
    mkdir -p "$WOW_SAVED_VARS"
    cp "$REPO_SAVED_VARS/WeakAuras.lua" "$WOW_SAVED_VARS/"
    echo -e "${GREEN}Done! WeakAuras.lua copied to WoW client${NC}"
    echo ""
    echo "Start WoW to load the restored WeakAuras configuration."
}

do_status() {
    echo -e "${YELLOW}WeakAuras Sync Status${NC}"
    echo "====================="
    echo ""

    # Check if files exist
    echo "Files:"
    if [[ -f "$WOW_SAVED_VARS/WeakAuras.lua" ]]; then
        WOW_SIZE=$(stat -c%s "$WOW_SAVED_VARS/WeakAuras.lua" 2>/dev/null || stat -f%z "$WOW_SAVED_VARS/WeakAuras.lua")
        WOW_DATE=$(stat -c%y "$WOW_SAVED_VARS/WeakAuras.lua" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" "$WOW_SAVED_VARS/WeakAuras.lua")
        echo -e "  WoW Client:  ${GREEN}Found${NC} (${WOW_SIZE} bytes, $WOW_DATE)"
    else
        echo -e "  WoW Client:  ${RED}Not found${NC}"
        echo "    Path: $WOW_SAVED_VARS"
    fi

    if [[ -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        REPO_SIZE=$(stat -c%s "$REPO_SAVED_VARS/WeakAuras.lua" 2>/dev/null || stat -f%z "$REPO_SAVED_VARS/WeakAuras.lua")
        REPO_DATE=$(stat -c%y "$REPO_SAVED_VARS/WeakAuras.lua" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" "$REPO_SAVED_VARS/WeakAuras.lua")
        echo -e "  Repository:  ${GREEN}Found${NC} (${REPO_SIZE} bytes, $REPO_DATE)"
    else
        echo -e "  Repository:  ${RED}Not found${NC}"
    fi

    echo ""

    # Compare files
    if [[ -f "$WOW_SAVED_VARS/WeakAuras.lua" && -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        if diff -q "$WOW_SAVED_VARS/WeakAuras.lua" "$REPO_SAVED_VARS/WeakAuras.lua" > /dev/null 2>&1; then
            echo -e "Status: ${GREEN}In sync${NC}"
        else
            echo -e "Status: ${YELLOW}Out of sync${NC}"
            echo ""
            echo "Run '$0 pull' to save in-game changes to repo"
            echo "Run '$0 push' to restore repo config to game"
        fi
    fi

    echo ""
    echo "Exported strings in repo:"
    ls -la "$REPO_EXPORTS/" 2>/dev/null | grep -v "^total" | grep -v "^d" || echo "  (none)"
}

# Main
case "${1:-}" in
    pull)
        do_pull
        ;;
    push)
        do_push
        ;;
    status)
        do_status
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
