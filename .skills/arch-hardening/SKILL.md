---
name: arch-hardening
description: >-
  Procedures for managing Arch Linux kernel sysctl hardening, UFW firewall configuration, PAM authentication limits, and tmpfs mount security.
---

# Arch Linux Hardening

## Overview
This skill provides instructions for applying and maintaining kernel parameters, firewall rules, memory protections, and PAM authentication policies on Arch Linux systems running Omarchy.

## Kernel Hardening Parameters
All kernel sysctl parameters are defined in `/etc/sysctl.d/99-security.conf`.

### Memory and Process Restrictions
* `kernel.randomize_va_space = 2` enables full Address Space Layout Randomization.
* `kernel.kptr_restrict = 2` hides kernel pointers from unprivileged users.
* `kernel.dmesg_restrict = 1` restricts dmesg buffer access to root.
* `kernel.perf_event_paranoid = 3` disables unprivileged performance event monitoring.
* `kernel.unprivileged_bpf_disabled = 1` disables unprivileged eBPF execution.
* `kernel.yama.ptrace_scope = 1` restricts ptrace debugging to parent processes.
* `kernel.sysrq = 16` limits SysRq to sync operations only.

### Filesystem Protection
* `fs.suid_dumpable = 0` prevents core dumps from setuid programs.
* `fs.protected_hardlinks = 1` prevents unprivileged hardlink creation attacks.
* `fs.protected_symlinks = 1` prevents unprivileged symlink follow attacks.
* `fs.protected_fifos = 2` restricts FIFO creation in world-writable sticky directories.
* `fs.protected_regular = 2` restricts regular file creation in world-writable sticky directories.

### Network Stack Protections
* `net.ipv4.conf.all.rp_filter = 1` enables reverse path filtering for anti-spoofing.
* `net.ipv4.conf.all.accept_redirects = 0` disables ICMP redirect acceptance.
* `net.ipv4.conf.all.send_redirects = 0` disables sending ICMP redirects.
* `net.ipv4.conf.all.accept_source_route = 0` disables source-routed packets.
* `net.ipv4.icmp_echo_ignore_broadcasts = 1` disables response to ICMP broadcast requests.
* `net.ipv4.tcp_syncookies = 1` enables TCP SYN cookies protection against SYN floods.
* `net.ipv4.tcp_rfc1337 = 1` protects against TCP TIME-WAIT assassination hazards.

## Firewall Configuration
UFW is configured with default deny incoming and allow outgoing policies.

### Firewall Procedures
1. Verify status using `ufw status verbose`.
2. Ensure `ufw.service` is enabled at boot via `systemctl is-enabled ufw.service`.
3. Check rules in `/etc/ufw/user.rules` and `/etc/ufw/after.rules`.

## PAM and Authentication
1. `/etc/security/faillock.conf` enforces lockout after 5 consecutive failed attempts for 900 seconds.
2. `/etc/security/pwquality.conf` enforces password complexity requirements.
3. `/etc/security/access.conf` restricts access lists.
4. `/etc/security/limits.d/99-no-core.conf` disables core dumps globally.
