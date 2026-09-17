---
name: apparmor-management
description: >-
  Procedures for managing, enforcing, auditing, and troubleshooting AppArmor Mandatory Access Control profiles.
---

# AppArmor Management

## Overview
This skill covers profile lifecycle management, enforcement verification, and log auditing for AppArmor profiles protecting system utilities and services.

## Profile Locations
* Active profiles reside in `/etc/apparmor.d/`.
* Profiles managed in omasec include `sshd`, `useradd`, `curl`, and `wget`.

## Profile Operations

### Check Enforcement Status
1. Check overall status with `aa-status`.
2. Verify specific profile enforcement state in `/sys/kernel/security/apparmor/profiles`.

### Enforce or Complain
1. Put profile in enforce mode with `aa-enforce /etc/apparmor.d/<profile_name>`.
2. Put profile in complain mode with `aa-complain /etc/apparmor.d/<profile_name>`.
3. Reload profiles with `apparmor_parser -r /etc/apparmor.d/<profile_name>`.

### Auditing Denials
1. Review kernel denial messages using `dmesg | grep -i apparmor`.
2. Review audit logs using `ausearch -m avc -ts recent`.
3. Generate profile adjustments if necessary using `aa-logprof`.
