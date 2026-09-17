# omasec

Arch Linux security hardening, debloat, and theming pipeline for Omarchy.

## Overview
omasec automates system-level security hardening, deployment of security tooling, unneeded package debloating, and desktop theming integrations for Omarchy.

## Repository Structure
* `scripts/`: System setup, verification, and launch execution scripts.
* `hooks/`: Omarchy hook extensions for theme and folder color integration.
* `zedconf/`: Configuration files for the Zed code editor.
* `.skills/`: Operational skill runbooks for workspace workflows.
* `Makefile`: Workflow automation entrypoints.
* `AGENTS.md`: Agent specifications and repository knowledge base.
* `README.md`: Project documentation.

## Quick Start

### Run Full Setup
Execute the complete security hardening and provisioning pipeline as root:
`make setup`

### Verify System State
Run the verification suite to assert that all security settings, services, and kernel parameters are correctly applied:
`make verify`

### Desktop Theming
Install and trigger the per-theme folder color hook for the current user:
`make hook`
`make icons`

## Hardening Features

### Firewall
UFW configured with default deny incoming, strict egress policies, and container bridge rules.

### Kernel Hardening
ASLR, ptrace restriction, dmesg restriction, disabled unprivileged eBPF and io_uring, sync-only SysRq, and IPv6 router advertisement rejection.

### Authentication and PAM
faillock lockout protection enforcing 5 attempts per 900 seconds, strict pwquality rules, access list controls, and disabled core dumps.

### SSH Hardening
Root login disabled, password authentication disabled, strict modern ciphers, and systemd service sandboxing.

### Sandboxing and MAC
AppArmor enforcement profiles for sshd, useradd, curl, and wget.

### System Services
Strict filesystem protections on sshd, unneeded services disabled, LLMNR and mDNS disabled, and NetworkManager preserved without interference.

### Desktop Cleanup
Removal of default Omarchy webapp shortcuts and restoration of the Yaru icon theme with per-theme folder color synchronization.

### Security Tooling
Integrated auditd, fail2ban, usbguard, clamav, lynis, and rkhunter with weekly automated audits.
