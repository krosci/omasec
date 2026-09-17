#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEBLOAT_MODULE="$PROJECT_DIR/scripts/modules/10-debloat.sh"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/modules/20-defaults.sh"
THEMING_MODULE="$PROJECT_DIR/scripts/modules/30-theming.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Debloat, Application Parity & Theming"

assert_file_exists "debloat module exists" "$DEBLOAT_MODULE"
assert_file_contains "debloat module defines package removal" "$DEBLOAT_MODULE" "pacman -Rns"
assert_file_contains "debloat module defines IgnorePkg pinning" "$DEBLOAT_MODULE" "IgnorePkg.*IGNORE_STR"

assert_file_exists "defaults module exists" "$DEFAULTS_MODULE"
assert_file_contains "defaults module configures brave-origin" "$DEFAULTS_MODULE" "brave-origin"
assert_file_contains "defaults module configures micro editor" "$DEFAULTS_MODULE" "micro"
assert_file_contains "defaults module configures totem player" "$DEFAULTS_MODULE" "totem"

assert_file_exists "theming module exists" "$THEMING_MODULE"
assert_file_contains "theming module installs hooks" "$THEMING_MODULE" "hooks/theme-set.d"

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]]; then
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
fi

if [[ -f /etc/pacman.d/omasec/ignore-pkgs.list ]]; then
    assert_file_exists "pacman ignore-pkgs.list exists" "/etc/pacman.d/omasec/ignore-pkgs.list"
fi

if [[ -f /etc/pacman.conf ]]; then
    assert_file_contains "pacman.conf has IgnorePkg" "/etc/pacman.conf" "^IgnorePkg"
fi

HOOK_FILE="$PROJECT_DIR/hooks/theme-set.d/folder-color"
assert_file_exists "folder-color hook exists in repo" "$HOOK_FILE"
assert_file_executable "folder-color hook executable" "$HOOK_FILE"

MICRO_HOOK="$PROJECT_DIR/hooks/theme-set.d/micro-theme"
assert_file_exists "micro-theme hook exists in repo" "$MICRO_HOOK"
assert_file_executable "micro-theme hook executable" "$MICRO_HOOK"

assert_file_exists "zedconf install script exists" "$PROJECT_DIR/zedconf/install.sh"
assert_file_exists "microconf install script exists" "$PROJECT_DIR/microconf/install.sh"
assert_file_exists "microconf settings exists" "$PROJECT_DIR/microconf/data/settings.json"
assert_file_exists "microconf bindings exists" "$PROJECT_DIR/microconf/data/bindings.json"

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
