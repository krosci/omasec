# AGENTS

## Project

omasec is an Arch Linux hardening and theming setup for omarchy. It configures the Yaru icon theme, installs security tooling (ufw, audit, apparmor, fail2ban, clamav, usbguard), hardens kernel/sysctl/PAM/SSH, installs micro as the default editor, and assigns each omarchy theme its own folder color via a hook.

## What to do

Run `make setup` as root to execute the full pipeline. Run `make verify` after to check everything landed. Use `make hook` to install the folder-color hook for the current user, and `make icons` to apply the correct folder color for the active theme. Edit `hooks/theme-set.d/folder-color` to change theme-to-color mappings. Edit `scripts/setup.sh` for system-level changes.

## What not to do

Do not use `|| true` to silence failures. Use `|| warn "message"` for non-critical steps that are allowed to fail. Do not add comments to the Makefile or to hook scripts. Do not hardcode paths to /home/kairosci in new scripts — use variables derived from /home/* or $HOME. Do not add systemd-run or background execution — everything runs live in the foreground. Do not leave broken pacman entries or unhandled errors in scripts/setup.sh.
