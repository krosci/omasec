#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG="${OMASEC_LOG:-$PROJECT_DIR/setup.log}"

if [[ "${OMASEC_LOG_STDOUT:-0}" -eq 0 ]]; then
    exec > >(tee -a "$LOG") 2>&1
fi
umask 077

set -euo pipefail

log() { echo "$1"; }
warn() { echo "warning: $1"; }
err() { echo "error: $1"; exit 1; }

[[ $EUID -eq 0 ]] || err "Root required"

PRIMARY_USER="${SUDO_USER:-}"
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(getent group wheel | cut -d: -f4 | cut -d, -f1)
fi
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(basename "$(find /home -mindepth 1 -maxdepth 1 -type d 2>/dev/null | tail -1)")
fi
id "$PRIMARY_USER" &>/dev/null || err "Cannot determine primary user"

MODULE_FILES=(
    "$MODULES_DIR/00-env.sh"
    "$MODULES_DIR/10-debloat.sh"
    "$MODULES_DIR/20-defaults.sh"
    "$MODULES_DIR/30-theming.sh"
    "$MODULES_DIR/40-firewall.sh"
    "$MODULES_DIR/50-kernel.sh"
    "$MODULES_DIR/60-auth.sh"
    "$MODULES_DIR/70-ssh.sh"
    "$MODULES_DIR/80-services.sh"
    "$MODULES_DIR/85-security-stack.sh"
    "$MODULES_DIR/90-hardware-power.sh"
    "$MODULES_DIR/95-maintenance.sh"
)

for mod in "${MODULE_FILES[@]}"; do
    [[ -f "$mod" ]] || continue
    mod_name=$(basename "$mod")
    log "--> Executing stage: $mod_name"
    # shellcheck source=/dev/null
    source "$mod"
done

log "Hardening complete. Reboot required."
