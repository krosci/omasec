#!/bin/bash
set -euo pipefail

DEBLOAT=(
    kdenlive
    obs-studio
    obsidian
    libreoffice-fresh
    chromium
    neovim
    omarchy-nvim
    mpv
)

log "Debloating"
INSTALLED_DEBLOAT=()
for pkg in "${DEBLOAT[@]}"; do
    pacman -Q "$pkg" &>/dev/null && INSTALLED_DEBLOAT+=("$pkg")
done
if [[ ${#INSTALLED_DEBLOAT[@]} -gt 0 ]]; then
    pacman -Rns --noconfirm "${INSTALLED_DEBLOAT[@]}" 2>/dev/null || \
    pacman -Rdd --noconfirm "${INSTALLED_DEBLOAT[@]}" 2>/dev/null || \
    warn "Some packages could not be removed"
fi

log "Fixing base package manifest"
BASE_MANIFEST=/usr/share/omarchy/install/omarchy-base.packages
if [[ -w "$BASE_MANIFEST" ]]; then
    for pkg in "${DEBLOAT[@]}"; do
        sed -i "/^${pkg}$/d" "$BASE_MANIFEST"
    done
fi

log "Pinning debloat in pacman.conf so it never returns"
mkdir -p /etc/pacman.d/omasec
chmod 755 /etc/pacman.d/omasec 2>/dev/null || warn "pacman omasec dir chmod skipped"
IGNORE_STR=$(paste -sd ' ' <(printf '%s\n' "${DEBLOAT[@]}"))
printf '%s\n' "${DEBLOAT[@]}" > /etc/pacman.d/omasec/ignore-pkgs.list
chmod 644 /etc/pacman.d/omasec/ignore-pkgs.list 2>/dev/null || warn "ignore-pkgs.list chmod skipped"
if grep -q '^IgnorePkg' /etc/pacman.conf; then
    sed -i "s|^IgnorePkg.*|IgnorePkg = $IGNORE_STR|" /etc/pacman.conf
else
    sed -i "/^\[options\]/a IgnorePkg = $IGNORE_STR" /etc/pacman.conf
fi

log "Cleaning up nonexistent foot application entry"
if ! pacman -Q foot &>/dev/null && ! command -v foot &>/dev/null; then
    for u_home in /home/*; do
        [[ -d "$u_home" ]] || continue
        rm -f "$u_home/.local/share/applications/foot.desktop" 2>/dev/null || warn "foot desktop remove skipped for $u_home"
        rm -f "$u_home/.local/share/applications/footclient.desktop" 2>/dev/null || warn "footclient desktop remove skipped for $u_home"
        rm -f "$u_home/.local/share/applications/foot-server.desktop" 2>/dev/null || warn "foot-server desktop remove skipped for $u_home"
    done
fi

log "Removing default webapps"
for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
    rm -f "/usr/share/omarchy/applications/$webapp.desktop"
done
if [[ -d /usr/share/omarchy/applications ]]; then
    app_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /usr/share/omarchy/applications 2>/dev/null) || warn "No webapps found in /usr/share/omarchy/applications"
    if [[ -n "$app_matches" ]]; then
        while IFS= read -r app_file; do
            [[ -f "$app_file" ]] && rm -f "$app_file"
        done <<< "$app_matches"
    fi
fi
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
        rm -f "$u_home/.local/share/applications/$webapp.desktop"
    done
    if [[ -d "$u_home/.local/share/applications" ]]; then
        user_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' "$u_home/.local/share/applications" 2>/dev/null) || warn "No webapps found for $u_home"
        if [[ -n "$user_matches" ]]; then
            while IFS= read -r app_file; do
                [[ -f "$app_file" ]] && rm -f "$app_file"
            done <<< "$user_matches"
        fi
    fi
done
