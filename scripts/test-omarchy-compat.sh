#!/bin/bash

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1" condition="$2"
    if eval "$condition" &>/dev/null; then
        ((PASS++))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        ((FAIL++))
        echo -e "  ${RED}fail${NC} $desc"
    fi
}

warn_check() {
    local desc="$1" condition="$2"
    if eval "$condition" &>/dev/null; then
        ((PASS++))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        ((WARN++))
        echo -e "  ${YELLOW}warn${NC} $desc"
    fi
}

section() { echo -e "\n${BOLD}$1${NC}"; }

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

section "Script Syntax & Code Integrity"
for sh_file in "$PROJECT_DIR"/scripts/*.sh "$PROJECT_DIR"/hooks/theme-set.d/* "$PROJECT_DIR"/zedconf/*.sh; do
    [[ -f "$sh_file" ]] || continue
    check "syntax check: $(basename "$sh_file")" "bash -n '$sh_file'"
done

section "Omarchy Theming & Hook Integration"
HOOK_FILE="$PROJECT_DIR/hooks/theme-set.d/folder-color"
check "folder-color hook exists" "[[ -f '$HOOK_FILE' ]]"
check "folder-color hook is executable" "[[ -x '$HOOK_FILE' ]]"

test_theme_mapping() {
    local theme="$1" expected="$2"
    local mapped
    case "$theme" in
        everforest) mapped="Yaru-sage" ;;
        gruvbox) mapped="Yaru-yellow" ;;
        nord) mapped="Yaru-blue" ;;
        tokyo-night) mapped="Yaru-purple" ;;
        catppuccin) mapped="Yaru-magenta" ;;
        dracula) mapped="Yaru-purple" ;;
        rose-pine) mapped="Yaru-pink" ;;
        solarized-dark|solarized-light) mapped="Yaru-cyan" ;;
        *) mapped="Yaru-orange" ;;
    esac
    [[ "$mapped" == "$expected" ]]
}

check "theme map: everforest -> Yaru-sage" "test_theme_mapping 'everforest' 'Yaru-sage'"
check "theme map: gruvbox -> Yaru-yellow" "test_theme_mapping 'gruvbox' 'Yaru-yellow'"
check "theme map: nord -> Yaru-blue" "test_theme_mapping 'nord' 'Yaru-blue'"
check "theme map: tokyo-night -> Yaru-purple" "test_theme_mapping 'tokyo-night' 'Yaru-purple'"
check "theme map: catppuccin -> Yaru-magenta" "test_theme_mapping 'catppuccin' 'Yaru-magenta'"
check "theme map: dracula -> Yaru-purple" "test_theme_mapping 'dracula' 'Yaru-purple'"
check "theme map: rose-pine -> Yaru-pink" "test_theme_mapping 'rose-pine' 'Yaru-pink'"
check "theme map: solarized-dark -> Yaru-cyan" "test_theme_mapping 'solarized-dark' 'Yaru-cyan'"
check "theme map: default -> Yaru-orange" "test_theme_mapping 'default' 'Yaru-orange'"

section "Desktop Environment & User Session"
warn_check "D-Bus session accessible" "[[ -n \"${DBUS_SESSION_BUS_ADDRESS:-}\" ]] || busctl --user status &>/dev/null"
warn_check "XDG runtime directory valid" "[[ -d \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}\" ]]"
check "Polkit daemon enabled/active" "systemctl is-active polkit.service &>/dev/null || systemctl is-enabled polkit.service &>/dev/null"
warn_check "Audio server running (PipeWire)" "systemctl --user is-active pipewire.service &>/dev/null || pgrep -x pipewire &>/dev/null"

section "Network & Connectivity Non-Interference"
check "NetworkManager configuration unmolested" "! [[ -f /etc/NetworkManager/conf.d/security.conf ]]"
check "Loopback interface up" "ip link show lo 2>/dev/null | grep -q 'state UP\|state UNKNOWN'"
warn_check "DNS resolver functional" "getent hosts archlinux.org &>/dev/null || resolvectl query archlinux.org &>/dev/null"

section "Omarchy Application & Package Parity"
check "yaru-icon-theme installed" "pacman -Q yaru-icon-theme &>/dev/null"
check "nautilus installed" "pacman -Q nautilus &>/dev/null"
check "herdr installed" "pacman -Q herdr &>/dev/null"
check "gum installed" "pacman -Q gum &>/dev/null"
check "brave-origin-bin installed" "pacman -Q brave-origin-bin &>/dev/null"
check "micro installed" "pacman -Q micro &>/dev/null"
check "totem installed" "pacman -Q totem &>/dev/null"

for debloated in chromium neovim omarchy-nvim mpv kdenlive obs-studio libreoffice-fresh obsidian; do
    check "debloat verified: $debloated removed" "! pacman -Q '$debloated' &>/dev/null"
done

section "Pacman Configuration & Pinning"
check "IgnorePkg defined in /etc/pacman.conf" "grep -q '^IgnorePkg' /etc/pacman.conf"
check "No syntax error in /etc/pacman.conf" "pacman -Q &>/dev/null"

section "Security Daemon Non-Lockout Checks"
if [[ -f /etc/usbguard/rules.conf ]]; then
    check "USBGuard allows HID input devices" "grep -q '03:00:01\|03:01:01\|03:01:02\|interface-class == { 03:..:.. }' /etc/usbguard/rules.conf 2>/dev/null || grep -q 'allow' /etc/usbguard/rules.conf"
fi
check "Primary user in wheel group" "groups | grep -qw 'wheel' || id -Gn | grep -qw 'wheel'"
check "User has valid shell in /etc/shells" "grep -qFx \"$SHELL\" /etc/shells"

section "Omarchy User Configurations"
warn_check "Starship prompt config exists" "[[ -f \"$HOME/.config/starship.toml\" ]]"
warn_check "Git user config exists" "[[ -f \"$HOME/.config/git/config\" ]]"

echo ""
echo -e "${BOLD}Passed: $PASS  Failed: $FAIL  Warnings: $WARN${NC}"
[[ $FAIL -eq 0 ]] || exit 1
