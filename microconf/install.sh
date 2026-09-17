#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/micro"

mkdir -p "$CONFIG_DIR/colorschemes"

if [[ -f "$CONFIG_DIR/settings.json" ]]; then
    cp "$CONFIG_DIR/settings.json" "$CONFIG_DIR/settings.json.bak-$(date +%s)"
fi
if [[ -f "$CONFIG_DIR/bindings.json" ]]; then
    cp "$CONFIG_DIR/bindings.json" "$CONFIG_DIR/bindings.json.bak-$(date +%s)"
fi

if command -v jq &>/dev/null && [[ -f "$CONFIG_DIR/settings.json" ]] && [[ -s "$CONFIG_DIR/settings.json" ]]; then
    jq -s '.[0] * .[1]' "$CONFIG_DIR/settings.json" "$SCRIPT_DIR/data/settings.json" > "$CONFIG_DIR/settings.json.tmp" 2>/dev/null && \
    mv "$CONFIG_DIR/settings.json.tmp" "$CONFIG_DIR/settings.json" || cp "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
else
    cp "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
fi

if [[ -f "$SCRIPT_DIR/data/bindings.json" ]]; then
    cp "$SCRIPT_DIR/data/bindings.json" "$CONFIG_DIR/bindings.json"
fi

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/micro-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/micro-theme" 2>/dev/null || echo "Theme sync skipped"
fi

echo "Micro configuration installed successfully."
