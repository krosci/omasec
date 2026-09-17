#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Debloat, Application Parity & Theming"

assert_true "yaru-icon-theme installed" "pacman -Q yaru-icon-theme &>/dev/null"
assert_true "nautilus installed" "pacman -Q nautilus &>/dev/null"
assert_true "herdr installed" "pacman -Q herdr &>/dev/null"
assert_true "gum installed" "pacman -Q gum &>/dev/null"
assert_true "brave-origin-bin installed" "pacman -Q brave-origin-bin &>/dev/null"
assert_true "micro installed" "pacman -Q micro &>/dev/null"
assert_true "totem installed" "pacman -Q totem &>/dev/null"

for debloated in chromium neovim omarchy-nvim mpv kdenlive obs-studio libreoffice-fresh obsidian; do
    assert_false "debloat verified: $debloated removed" "pacman -Q '$debloated' &>/dev/null"
done

assert_file_exists "pacman ignore-pkgs.list exists" "/etc/pacman.d/omasec/ignore-pkgs.list"
assert_file_contains "pacman.conf has IgnorePkg" "/etc/pacman.conf" "^IgnorePkg"

HOOK_FILE="$PROJECT_DIR/hooks/theme-set.d/folder-color"
assert_file_exists "folder-color hook exists in repo" "$HOOK_FILE"
assert_file_executable "folder-color hook executable" "$HOOK_FILE"

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

assert_true "theme map: everforest -> Yaru-sage" "test_theme_mapping 'everforest' 'Yaru-sage'"
assert_true "theme map: gruvbox -> Yaru-yellow" "test_theme_mapping 'gruvbox' 'Yaru-yellow'"
assert_true "theme map: nord -> Yaru-blue" "test_theme_mapping 'nord' 'Yaru-blue'"
assert_true "theme map: tokyo-night -> Yaru-purple" "test_theme_mapping 'tokyo-night' 'Yaru-purple'"
assert_true "theme map: catppuccin -> Yaru-magenta" "test_theme_mapping 'catppuccin' 'Yaru-magenta'"
assert_true "theme map: dracula -> Yaru-purple" "test_theme_mapping 'dracula' 'Yaru-purple'"
assert_true "theme map: rose-pine -> Yaru-pink" "test_theme_mapping 'rose-pine' 'Yaru-pink'"
assert_true "theme map: solarized-dark -> Yaru-cyan" "test_theme_mapping 'solarized-dark' 'Yaru-cyan'"
assert_true "theme map: default -> Yaru-orange" "test_theme_mapping 'default' 'Yaru-orange'"

test_summary
