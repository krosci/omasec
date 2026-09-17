#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Security Tooling, Isolation & Module Blacklists"

for pkg in lynis rkhunter clamav audit usbguard fail2ban apparmor; do
    assert_true "security package $pkg present" "pacman -Q '$pkg' &>/dev/null"
done

assert_file_exists "USB storage blacklist conf exists" "/etc/modprobe.d/disable-usb-storage.conf"
assert_file_exists "Unsafe protocols blacklist conf exists" "/etc/modprobe.d/disable-protocols.conf"
assert_file_exists "FireWire blacklist conf exists" "/etc/modprobe.d/disable-firewire.conf"
assert_file_exists "Legacy filesystems blacklist conf exists" "/etc/modprobe.d/disable-ramfs.conf"

assert_file_exists "Weekly audit cron script exists" "/etc/cron.weekly/security-audit.sh"
assert_file_executable "Weekly audit cron script executable" "/etc/cron.weekly/security-audit.sh"

assert_true "Root directory permissions 700" "[[ \"\$(stat -c %a /root 2>/dev/null)\" == 700 ]]"
assert_true "Shadow file permissions 600" "[[ \"\$(stat -c %a /etc/shadow 2>/dev/null)\" == 600 ]]"
assert_true "GShadow file permissions 600" "[[ \"\$(stat -c %a /etc/gshadow 2>/dev/null)\" == 600 ]]"
assert_true "Passwd file permissions 644" "[[ \"\$(stat -c %a /etc/passwd 2>/dev/null)\" == 644 ]]"
assert_true "Group file permissions 644" "[[ \"\$(stat -c %a /etc/group 2>/dev/null)\" == 644 ]]"

assert_false "Nonexistent TPM verity file absent" "[[ -f /usr/lib/nvpcr/verity.nvpcr ]]"

test_summary
