#!/bin/bash
set -euo pipefail

log "Syncing package databases"
pacman -Sy --noconfirm 2>/dev/null || warn "pacman database sync skipped"

log "Fixing broken pacman entries"
for pkg_dir in /var/lib/pacman/local/*/; do
    [[ -d "$pkg_dir" ]] || continue
    [[ -f "$pkg_dir/desc" ]] || { warn "Removing broken entry: $pkg_dir"; rm -rf "$pkg_dir"; }
done

aur_verified_install() {
    local pkg="$1" tmp f
    [[ -n "$pkg" ]] || err "AUR install requested with empty package name"
    [[ "$pkg" =~ ^[a-zA-Z0-9._-]+$ ]] || err "Invalid AUR package name: $pkg"
    pacman -S --noconfirm --needed base-devel git wget
    tmp=$(mktemp -d)
    chmod 700 "$tmp"
    chown "$PRIMARY_USER":"$PRIMARY_USER" "$tmp"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp' && git clone --quiet --depth 1 https://aur.archlinux.org/$pkg.git src && cd src && \
         { grep -q '^validpgpkeys=' PKGBUILD || \
           { grep -qE '^(sha256sums|sha512sums|b2sums|sha256sums_x86_64)=' PKGBUILD && ! grep -q 'SKIP' PKGBUILD && \
             grep -qE '^# Maintainer: [^< ]+ <[^ ]+@[^ ]+>' PKGBUILD; }; }" || \
        err "AUR package '$pkg' has no verified integrity (needs validpgpkeys, or full sha256sums from a named maintainer); refusing to install"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp/src' && makepkg --noconfirm" || {
        rm -rf "$tmp"
        err "AUR package '$pkg' failed source verification during build; refusing to install"
    }
    f=$(find "$tmp/src" -name '*.pkg.tar.*' -type f 2>/dev/null | head -1)
    [[ -n "$f" ]] || { rm -rf "$tmp"; err "AUR package '$pkg' produced no artifact after verified build"; }
    pacman -U --noconfirm "$f"
    rm -rf "$tmp"
}
