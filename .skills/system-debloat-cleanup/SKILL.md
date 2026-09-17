---
name: system-debloat-cleanup
description: >-
  Procedures for removing default Omarchy web application shortcuts, package cleanup, and pacman configuration pinning.
---

# System Debloat Cleanup

## Overview
This skill outlines how to remove default web application launchers, uninstall unwanted packages, and prevent their automatic reinstallation on Arch Linux Omarchy installations.

## Desktop Launcher Cleanup
Web application desktop shortcuts installed under `/usr/share/omarchy/applications` and user desktop menus are cleaned by removing launcher definitions for Basecamp, Google Contacts, Google Maps, Google Messages, Google Photos, Discord, HEY, WhatsApp, X, YouTube, and Zoom.

## Package Removal and Replacement
Unneeded software packages including Chromium, Neovim, omarchy-nvim, MPV, Kdenlive, OBS Studio, LibreOffice, and Obsidian are cleanly removed from the package database. Lightweight native defaults including Brave Origin, Micro, Totem, Yaru icon theme, Nautilus, Herdr, and Gum are retained and configured.

## Pacman Persistence
To ensure removed packages are not pulled back into the system during subsequent system upgrades, package names are listed inside `/etc/pacman.d/omasec/ignore-pkgs.list` and pinned directly into `/etc/pacman.conf` within the `IgnorePkg` directive.
