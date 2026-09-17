---
name: omarchy-theming
description: >-
  Procedures for managing Omarchy desktop theme hooks, Yaru folder color customization, and icon theme propagation.
---

# Omarchy Theming

## Overview
This skill describes the architecture and execution of theme hooks that automatically map Omarchy desktop themes to corresponding Yaru folder colors.

## Theme Hook Workflow
The theme hook is located at `hooks/theme-set.d/folder-color` and installs to `~/.config/omarchy/hooks/theme-set.d/folder-color`.

## Execution
* Run `make hook` to install the hook to user configuration.
* Run `make icons` to execute the folder color updater for the active theme.

## Theme to Color Mapping
* `everforest` -> `sage`
* `gruvbox` -> `yellow`
* `nord` -> `blue`
* `tokyo-night` -> `purple`
* `catppuccin` -> `magenta`
* `dracula` -> `purple`
* `rose-pine` -> `pink`
* `solarized-dark` / `solarized-light` -> `cyan`
* `default` -> `orange`

## GSettings Integration
The hook applies the icon theme using:
`gsettings set org.gnome.desktop.interface icon-theme "Yaru-<color>"`
