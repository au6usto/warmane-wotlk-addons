#!/bin/bash
#
# WeakAuras Sync Script
# Syncs WeakAuras configuration between WoW client and this repository
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Paths
WOW_WTF="/path/to/WoW/WTF/Account/ACCOUNT/SavedVariables"
REPO_SAVED_VARS="$REPO_DIR/config/weakauras/saved-variables"
REPO_EXPORTS="$REPO_DIR/config/weakauras/exports"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [pull|push|status]"
    echo ""
    echo "Commands:"
    echo "  pull    - Copy WeakAuras from WoW client to repo (backup your in-game config)"
    echo "  push    - Copy WeakAuras from repo to WoW client (restore config to game)"
    echo "  status  - Show sync status and file differences"
    echo ""
    echo "Examples:"
    echo "  $0 pull   # After making changes in-game, save them to repo"
    echo "  $0 push   # Restore repo config to game (after fresh install)"
    echo "  $0 status # Check if files are in sync"
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

    if [[ ! -f "$WOW_WTF/WeakAuras.lua" ]]; then
        echo -e "${RED}Error: WeakAuras.lua not found in WoW client${NC}"
        exit 1
    fi

    # Backup existing repo file
    if [[ -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        cp "$REPO_SAVED_VARS/WeakAuras.lua" "$REPO_SAVED_VARS/WeakAuras.lua.bak"
        echo "  Backed up existing repo file to WeakAuras.lua.bak"
    fi

    # Copy from WoW to repo
    cp "$WOW_WTF/WeakAuras.lua" "$REPO_SAVED_VARS/"
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
    if [[ -f "$WOW_WTF/WeakAuras.lua" ]]; then
        cp "$WOW_WTF/WeakAuras.lua" "$WOW_WTF/WeakAuras.lua.bak"
        echo "  Backed up existing WoW file to WeakAuras.lua.bak"
    fi

    # Copy from repo to WoW
    cp "$REPO_SAVED_VARS/WeakAuras.lua" "$WOW_WTF/"
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
    if [[ -f "$WOW_WTF/WeakAuras.lua" ]]; then
        WOW_SIZE=$(stat -c%s "$WOW_WTF/WeakAuras.lua" 2>/dev/null || stat -f%z "$WOW_WTF/WeakAuras.lua")
        WOW_DATE=$(stat -c%y "$WOW_WTF/WeakAuras.lua" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" "$WOW_WTF/WeakAuras.lua")
        echo -e "  WoW Client:  ${GREEN}Found${NC} (${WOW_SIZE} bytes, $WOW_DATE)"
    else
        echo -e "  WoW Client:  ${RED}Not found${NC}"
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
    if [[ -f "$WOW_WTF/WeakAuras.lua" && -f "$REPO_SAVED_VARS/WeakAuras.lua" ]]; then
        if diff -q "$WOW_WTF/WeakAuras.lua" "$REPO_SAVED_VARS/WeakAuras.lua" > /dev/null 2>&1; then
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
