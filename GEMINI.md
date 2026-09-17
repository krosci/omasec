# Agent Guidelines and Codebase Knowledge

## Project Overview
omasec is an Arch Linux security hardening, debloat, and theming automation suite for Omarchy. It manages system-level hardening, security daemon configurations, package debloating, and per-theme desktop folder color integration.

## Repository Architecture
* `scripts/setup.sh` executes the full system hardening, package provisioning, and debloat pipeline as root.
* `scripts/verify.sh` executes automated assertion checks on kernel sysctl parameters, PAM configs, firewall state, packages, and services.
* `scripts/test-omarchy-compat.sh` executes deep compatibility assertions ensuring Omarchy desktop components, hooks, permissions, audio, D-Bus, and network are intact.
* `scripts/run-setup.sh` runs setup with stdout redirection and logging.
* `scripts/launch.sh` launches an interactive terminal execution session.
* `hooks/theme-set.d/folder-color` integrates with Omarchy theme-set events to apply matching Yaru folder colors via gsettings.
* `zedconf/` contains configuration settings, keybindings, and language configurations for the Zed editor.
* `Makefile` exposes standard developer targets: `setup`, `verify`, `test`, `hook`, `icons`, `clean`.
* `.skills/` contains workspace operational skills.

## Operational Commands
* Full setup: `make setup` runs `sudo bash scripts/setup.sh`.
* System verification: `make verify` runs `bash scripts/verify.sh`.
* Compatibility test suite: `make test` runs `bash scripts/test-omarchy-compat.sh`.
* Install user hook: `make hook` copies `hooks/theme-set.d/folder-color` to `~/.config/omarchy/hooks/theme-set.d/`.
* Apply theme icons: `make icons` executes `hooks/theme-set.d/folder-color`.
* Clean logs: `make clean` deletes `setup.log`.

## Security Architecture and Configuration Knowledge

### Kernel Sysctl Parameters
Configured in `/etc/sysctl.d/99-security.conf`:
* `kernel.randomize_va_space = 2`
* `kernel.kptr_restrict = 2`
* `kernel.dmesg_restrict = 1`
* `kernel.perf_event_paranoid = 3`
* `kernel.unprivileged_bpf_disabled = 1`
* `kernel.yama.ptrace_scope = 1`
* `kernel.sysrq = 16`
* `fs.suid_dumpable = 0`
* `fs.protected_hardlinks = 1`
* `fs.protected_symlinks = 1`
* `fs.protected_fifos = 2`
* `fs.protected_regular = 2`
* `net.ipv4.conf.all.rp_filter = 1`
* `net.ipv4.conf.all.accept_redirects = 0`
* `net.ipv4.conf.all.send_redirects = 0`
* `net.ipv4.conf.all.accept_source_route = 0`
* `net.ipv4.icmp_echo_ignore_broadcasts = 1`
* `net.ipv4.tcp_syncookies = 1`
* `net.ipv4.tcp_rfc1337 = 1`

### PAM and Authentication Policies
* `/etc/security/faillock.conf`: 5 failed attempts locks account for 900 seconds.
* `/etc/security/pwquality.conf`: Strict password complexity requirements.
* `/etc/security/access.conf`: Access control list configuration.
* `/etc/security/limits.d/99-no-core.conf`: Core dumps disabled.

### Firewall Configuration
* UFW active with default deny incoming and default allow outgoing.
* Service enabled at boot via `ufw.service`.

### SSH Hardening
* `/etc/ssh/sshd_config.d/hardened.conf` sets `PermitRootLogin no`, `PasswordAuthentication no`, and modern ciphers.
* `/etc/systemd/system/sshd.service.d/hardened.conf` provides service sandboxing (`ProtectSystem=strict`, `ProtectHome=yes`, `NoNewPrivileges=yes`).

### Network and Daemon Hardening
* Disabled services: `avahi-daemon.service`, `cups.service`.
* Enabled services: `bluetooth.service`, `ufw.service`, `auditd.service`, `fail2ban.service`, `usbguard.service`.
* `/etc/systemd/resolved.conf.d/hardened.conf` disables LLMNR and mDNS.
* NetworkManager is preserved without overriding `conf.d/security.conf`.

### Security Tooling Stack
* `lynis`: System auditing.
* `rkhunter`: Rootkit checks.
* `clamav`: Antivirus daemon and scanner.
* `auditd`: Linux auditing framework.
* `usbguard`: USB authorization and policy enforcement.
* `fail2ban`: Log intrusion protection.
* `apparmor`: Mandatory access control profiles for `sshd`, `useradd`, `curl`, `wget`.
* `/etc/cron.weekly/security-audit.sh`: Weekly automated security audit script.

### Package Debloat and Persistence
* Removed packages: `chromium`, `neovim`, `omarchy-nvim`, `mpv`, `kdenlive`, `obs-studio`, `libreoffice-fresh`, `obsidian`.
* Installed packages: `brave-origin-bin`, `micro`, `totem`, `yaru-icon-theme`, `nautilus`, `herdr`, `gum`.
* Removed default webapps: Discord, WhatsApp, YouTube, X, Google apps, HEY, Zoom from `/usr/share/omarchy/applications`.
* `/etc/pacman.conf` includes removed packages in `IgnorePkg` to prevent reinstallation.
* Default browser configured to `brave-origin`. Default editor configured to `micro`.

### Omarchy Theme Mapping
* `everforest` -> `Yaru-sage`
* `gruvbox` -> `Yaru-yellow`
* `nord` -> `Yaru-blue`
* `tokyo-night` -> `Yaru-purple`
* `catppuccin` -> `Yaru-magenta`
* `dracula` -> `Yaru-purple`
* `rose-pine` -> `Yaru-pink`
* `solarized-dark` / `solarized-light` -> `Yaru-cyan`
* `default` -> `Yaru-orange`

## Commit Conventions
* All commit messages must follow Conventional Commits.
* Format: `<type>: <description>` or `<type>(<scope>): <description>`.
* The colon `:` after the target/type is the only allowed punctuation or symbol.
* Do not use emojis, exclamation marks, or symbols in commit titles.

## Scripting Rules and Constraints
* Never use `|| true` to suppress failures. Use `|| warn "message"` for optional non-critical steps.
* Do not add comments to Makefile or hook scripts.
* Do not hardcode user paths such as `/home/kairosci`. Derive paths from `$HOME` or `/home/*`.
* All operations must run in the foreground. Never use `systemd-run` or background execution.
* Ensure all changes in `scripts/setup.sh` and `scripts/verify.sh` remain fully idempotent.
