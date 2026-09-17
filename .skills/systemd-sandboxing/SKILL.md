---
name: systemd-sandboxing
description: >-
  Procedures for hardening systemd services with isolation directives, filesystem protections, and capability restrictions.
---

# Systemd Sandboxing

## Overview
This skill outlines how to configure systemd drop-in hardening units to isolate services from unauthorized access to the host filesystem, home directories, and system capabilities.

## Hardening Drop-in Structure
Drop-ins are placed in `/etc/systemd/system/<unit>.service.d/hardened.conf`.

## Standard Hardening Directives
* `ProtectSystem=strict` mounts `/usr`, `/boot`, and `/etc` as read-only for the service process.
* `ProtectHome=yes` renders `/root`, `/home`, and `/run/user` inaccessible or read-only.
* `NoNewPrivileges=yes` prevents processes from gaining new privileges via setuid/setgid binaries.
* `PrivateTmp=yes` gives the process an isolated `/tmp` and `/var/tmp` namespace.
* `PrivateDevices=yes` restricts access to physical hardware devices.
* `ProtectKernelTunables=yes` prevents modifying `/proc/sys` or `/sys` variables.
* `ProtectKernelModules=yes` blocks kernel module loading.
* `ProtectControlGroups=yes` mounts `/sys/fs/cgroup` read-only.
* `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6` limits network sockets.
* `RestrictRealtime=yes` prevents realtime scheduling requests.
* `RestrictNamespaces=yes` prevents unprivileged namespace creation.
* `LockPersonality=yes` prevents changing process execution domain.
* `MemoryDenyWriteExecute=yes` blocks writable and executable memory page allocations.

## Application and Verification
1. Place drop-in at `/etc/systemd/system/<unit>.service.d/hardened.conf`.
2. Reload systemd manager with `systemctl daemon-reload`.
3. Restart unit with `systemctl restart <unit>.service`.
4. Inspect security score with `systemd-analyze security <unit>.service`.
