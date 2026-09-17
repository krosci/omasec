---
name: security-audit-tooling
description: >-
  Procedures for managing auditd rules, fail2ban jails, USBGuard policies, ClamAV virus scanning, and Lynis security scans.
---

# Security Audit Tooling

## Overview
This skill outlines how to maintain and verify host-based intrusion detection, device authorization, malware scanning, and security audit systems.

## Security Components

### Auditd
1. Configuration resides in `/etc/audit/auditd.conf` and rules in `/etc/audit/rules.d/`.
2. Inspect audit events using `ausearch` and `aureport`.
3. Check daemon status with `systemctl status auditd.service`.

### Fail2ban
1. Configuration resides in `/etc/fail2ban/jail.local`.
2. Inspect active jails using `fail2ban-client status`.
3. Check banned IPs using `fail2ban-client status sshd`.

### USBGuard
1. Policy resides in `/etc/usbguard/rules.conf`.
2. Block unauthorized USB devices while permitting existing authorized peripherals.
3. Query connected devices using `usbguard list-devices`.

### ClamAV
1. Freshclam database updates are managed via `freshclam.service`.
2. ClamAV daemon is managed via `clamav-daemon.service`.
3. Run on-demand scan using `clamscan -r -i /home`.

### Lynis and Rkhunter Audits
1. Automated weekly audit script is placed in `/etc/cron.weekly/security-audit.sh`.
2. Run manual Lynis system scan using `lynis audit system`.
3. Run manual rootkit check using `rkhunter --check --sk`.
