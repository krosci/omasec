# omasec

Comprehensive Arch Linux security hardening, debloat, and theming pipeline for Omarchy.

## Overview

`omasec` automates system-level security hardening, deployment of security tooling, unneeded package debloating, and desktop theming integrations for Omarchy.

## Repository Structure

```
omasec/
├── scripts/              # Setup, verification, and launch execution scripts
│   ├── setup.sh          # Full system hardening & configuration pipeline (run as root)
│   ├── verify.sh         # Automated security and system health assertion suite
│   ├── run-setup.sh      # Setup runner with stdout logging
│   └── launch.sh         # Interactive terminal launcher
├── hooks/                # Omarchy hook extensions
│   └── theme-set.d/      # Theme hooks (e.g. per-theme Tela folder colors)
├── zedconf/              # Pure code Zed editor setup for Omarchy
├── Makefile              # Project workflow targets
├── AGENTS.md             # Guidelines for autonomous coding agents
└── README.md             # Project documentation
```

## Quick Start

### 1. Run Full Setup
Execute the complete security hardening and provisioning pipeline as root:
```bash
make setup
```

### 2. Verify System State
Run the verification suite to assert that all security settings, services, and kernel parameters are correctly applied:
```bash
make verify
```

### 3. Desktop Theming
Install and trigger the per-theme folder color hook for the current user:
```bash
make hook
make icons
```

## Security & Hardening Features

| Component | Protection Mechanism |
|---|---|
| **Firewall** | UFW with default deny incoming, strict egress policies, and Docker bridge rules |
| **Kernel Hardening** | ASLR, ptrace restriction, dmesg restriction, disabled unprivileged BPF & io_uring, sync-only SysRq (16), IPv6 RA drop |
| **Authentication & PAM** | faillock lockout protection (5 attempts / 900s), strict pwquality rules, access.conf ACLs |
| **SSH** | Root login disabled, password auth disabled, strict modern ciphers (ChaCha20, AES-GCM), client hardening drop-in |
| **Sandboxing & MAC** | AppArmor enforcement profiles for `sshd`, `useradd`, `curl`, and `wget` |
| **System Services** | `sshd` systemd drop-in (`ProtectSystem=strict`, `ProtectHome=yes`, `NoNewPrivileges=yes`), NetworkManager left unmodified (no `conf.d/security.conf` overrides), LLMNR/mDNS disabled |
| **Desktop Cleanup** | Removes shipped omarchy webapp shortcuts (Discord, WhatsApp, YouTube, X, Google apps, HEY, Zoom) and restores the Yaru icon theme |
| **Security Stack** | Pre-configured `auditd`, `fail2ban`, `usbguard`, `clamav`, `lynis`, and `rkhunter` with weekly automated audits |
| **Hardware & TPM** | Automatic optimization of TPM NvPCR allocation to prevent NV index space exhaustion |
| **Storage & Memory** | `nosuid,nodev,noexec` tmpfs mountings on `/tmp` and `/var/tmp`, `/run/shm` protections, strict umask `077` |
