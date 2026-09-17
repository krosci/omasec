---
name: system-debloat-cleanup
description: >-
  Procedures for removing default Omarchy web application shortcuts, package cleanup, and pacman configuration pinning.
---

# System Debloat Cleanup

## Overview
This skill outlines how to remove default webapp launchers, uninstall bloat packages, and prevent their automatic reinstallation.

## Debloat Procedures

### Desktop Launcher Removal
Remove web application launchers from `/usr/share/omarchy/applications` and user desktop menus:
* Discord
* WhatsApp
* YouTube
* X / Twitter
* Google suite
* HEY
* Zoom

### Package Cleanups
* Unwanted packages removed: `chromium`, `neovim`, `omarchy-nvim`, `mpv`, `kdenlive`, `obs-studio`, `libreoffice-fresh`, `obsidian`.
* Required packages installed: `brave-origin-bin`, `micro`, `totem`, `yaru-icon-theme`, `nautilus`, `herdr`, `gum`.

### Pacman Pinning
* Prevent removed packages from being re-pulled during system updates by appending them to `IgnorePkg` in `/etc/pacman.conf`.
