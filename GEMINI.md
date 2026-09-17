# Agent Guidelines and Codebase Knowledge

## Project Overview
omasec is an Arch Linux security hardening, debloat, and theming automation suite for Omarchy. It manages system-level hardening, security daemon configurations, package debloating, and per-theme desktop folder color integration using pure native Bash automation and standard Unix system utilities.

## Repository Architecture
The repository codebase is organized into distinct functional paths. The provisioning pipeline `scripts/setup.sh` runs as root to apply all system hardening, pacman debloating, and security configurations. The verification runner `scripts/verify.sh` performs automated assertion checks on kernel sysctl parameters, PAM configurations, firewall rules, and active security services. The compatibility suite `scripts/test-omarchy-compat.sh` executes comprehensive non-destructive checks verifying desktop services, D-Bus, PipeWire audio, Polkit, and NetworkManager integrity. Logging is managed by `scripts/run-setup.sh` and interactive execution is supported by `scripts/launch.sh`. Desktop theming integration is implemented in `hooks/theme-set.d/folder-color` which applies Yaru folder icon colors corresponding to Omarchy themes. Editor configurations are located in `zedconf/`. The root `Makefile` provides standard targets for setup, verification, testing, hook installation, and icon updates. Operational runbooks reside in `.skills/`.

## Operational Commands
Workflow targets are exposed through the root Makefile. The `make setup` command invokes `sudo bash scripts/setup.sh` to execute full system hardening. The `make verify` command invokes `bash scripts/verify.sh` to validate applied security assertions. The `make test` command invokes `bash scripts/test-omarchy-compat.sh` to run the Omarchy desktop compatibility test suite. The `make hook` command copies `hooks/theme-set.d/folder-color` into `~/.config/omarchy/hooks/theme-set.d/` with executable permissions. The `make icons` command triggers immediate color synchronization for the active theme. The `make clean` command removes previous setup logs.

## Kernel Hardening Configuration
Kernel sysctl parameters are persisted in `/etc/sysctl.d/99-security.conf`. Memory protections include `kernel.randomize_va_space = 2`, `kernel.kptr_restrict = 2`, `kernel.dmesg_restrict = 1`, `kernel.perf_event_paranoid = 3`, `kernel.unprivileged_bpf_disabled = 1`, `kernel.yama.ptrace_scope = 1`, and `kernel.sysrq = 16`. Filesystem security includes `fs.suid_dumpable = 0`, `fs.protected_hardlinks = 1`, `fs.protected_symlinks = 1`, `fs.protected_fifos = 2`, and `fs.protected_regular = 2`. Network stack hardening includes `net.ipv4.conf.all.rp_filter = 1`, `net.ipv4.conf.all.accept_redirects = 0`, `net.ipv4.conf.all.send_redirects = 0`, `net.ipv4.conf.all.accept_source_route = 0`, `net.ipv4.icmp_echo_ignore_broadcasts = 1`, `net.ipv4.tcp_syncookies = 1`, and `net.ipv4.tcp_rfc1337 = 1`.

## Authentication and PAM Policies
Authentication security is enforced through `/etc/security/faillock.conf` which locks accounts for 900 seconds following 5 consecutive failed attempts. Password complexity rules are enforced in `/etc/security/pwquality.conf`. Access lists are controlled in `/etc/security/access.conf` and core dumps are disabled globally via `/etc/security/limits.d/99-no-core.conf`.

## Firewall and Service Isolation
The UFW firewall operates with default deny incoming and default allow outgoing policies, enabled at boot via `ufw.service`. SSH is hardened in `/etc/ssh/sshd_config.d/hardened.conf` disabling root login and password authentication while enforcing modern ciphers. Sandboxing drop-in `/etc/systemd/system/sshd.service.d/hardened.conf` applies `ProtectSystem=strict`, `ProtectHome=yes`, and `NoNewPrivileges=yes`. Unneeded daemons such as `avahi-daemon.service` and `cups.service` are disabled. Security services including `ufw.service`, `auditd.service`, `fail2ban.service`, and `usbguard.service` are enabled. NetworkManager is preserved without creating conflicting configuration overrides.

## Security Tooling Stack
Host security tools include `lynis` for system audits, `rkhunter` for rootkit scanning, `clamav` for virus scanning, `auditd` for audit logging, `usbguard` for USB authorization, `fail2ban` for intrusion deterrence, and `apparmor` with mandatory access control profiles for `sshd`, `useradd`, `curl`, and `wget`. Automated weekly security audit execution is scheduled in `/etc/cron.weekly/security-audit.sh`.

## Package Debloating and Theming
Debloated packages include `chromium`, `neovim`, `omarchy-nvim`, `mpv`, `kdenlive`, `obs-studio`, `libreoffice-fresh`, and `obsidian`. Retained and provisioned packages include `brave-origin-bin`, `micro`, `totem`, `yaru-icon-theme`, `nautilus`, `herdr`, and `gum`. Debloated packages are persisted inside `IgnorePkg` in `/etc/pacman.conf` to block accidental reinstallation. Default browser is set to `brave-origin` and default editor is set to `micro`. Omarchy theme switching maps `everforest` to `Yaru-sage`, `gruvbox` to `Yaru-yellow`, `nord` to `Yaru-blue`, `tokyo-night` to `Yaru-purple`, `catppuccin` to `Yaru-magenta`, `dracula` to `Yaru-purple`, `rose-pine` to `Yaru-pink`, `solarized-dark` and `solarized-light` to `Yaru-cyan`, and `default` to `Yaru-orange`.

## Commit Conventions
All commit messages must follow the Conventional Commits standard formatted strictly as `<type>: <description>` or `<type>(<scope>): <description>`. The colon `:` following the target type is the only allowed punctuation or symbol. Titles must never contain emojis, exclamation marks, or extra punctuation.

## Scripting Rules and Constraints
Scripts must use strict execution modes `set -euo pipefail` in pure native Bash without Python dependencies. Never use `|| true` to suppress failures; use `|| warn "message"` for non-critical steps that can fail gracefully. Do not add comments to Makefile or hook scripts. Do not hardcode user paths; derive directories from `$HOME` or `/home/*`. All operations must run in the foreground without `systemd-run`. All modifications to `scripts/setup.sh` and `scripts/verify.sh` must remain strictly idempotent.
