#!/bin/bash
set -euo pipefail

log "Installing brave-origin"
if ! pacman -Q brave-origin-bin &>/dev/null; then
    aur_verified_install brave-origin-bin || err "brave-origin installation failed"
fi

log "Setting default browser to brave-origin"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    sudo -u "$_user" omarchy default browser brave-origin 2>/dev/null || warn "omarchy default browser skipped for $_user"
done
omarchy default browser brave-origin 2>/dev/null || warn "omarchy default browser skipped"

log "Installing micro editor"
if ! pacman -Q micro &>/dev/null; then
    pacman -S --noconfirm --needed micro
fi

log "Setting default editor to micro"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'micro\n' > "$user_home/.local/state/omarchy/defaults/editor"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "chown state failed for $_user"
done

log "Installing totem (GNOME Videos)"
if ! pacman -Q totem &>/dev/null; then
    pacman -S --noconfirm --needed totem
fi

log "Setting default media player to totem"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'totem\n' > "$user_home/.local/state/omarchy/defaults/media-player"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "chown state failed for $_user"
done
