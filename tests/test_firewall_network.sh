#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Firewall, Network & SSH Security"

assert_true "UFW service is enabled" "systemctl is-enabled ufw.service &>/dev/null"
if sudo -n ufw status &>/dev/null; then
    assert_true "UFW is active" "sudo -n ufw status | grep -q 'Status: active'"
    assert_true "UFW default deny incoming" "sudo -n ufw status verbose | grep -q 'Default: deny (incoming)'"
    assert_true "UFW default allow outgoing" "sudo -n ufw status verbose | grep -q 'allow (outgoing)'"
fi

assert_false "NetworkManager configuration unmolested" "[[ -f /etc/NetworkManager/conf.d/security.conf ]]"
assert_true "Loopback network interface up" "ip link show lo 2>/dev/null | grep -q 'state UP\|state UNKNOWN'"
assert_warn "DNS resolution functional" "getent hosts archlinux.org &>/dev/null || resolvectl query archlinux.org &>/dev/null"

SSHD_CONF="/etc/ssh/sshd_config.d/hardened.conf"
if [[ -r "$SSHD_CONF" ]]; then
    assert_file_contains "SSH PermitRootLogin disabled" "$SSHD_CONF" "^PermitRootLogin no"
    assert_file_contains "SSH PasswordAuth disabled" "$SSHD_CONF" "^PasswordAuthentication no"
    assert_file_contains "SSH PubkeyAuth enabled" "$SSHD_CONF" "^PubkeyAuthentication yes"
fi

assert_file_exists "SSH systemd sandboxing drop-in exists" "/etc/systemd/system/sshd.service.d/hardened.conf"
if [[ -r "/etc/systemd/system/sshd.service.d/hardened.conf" ]]; then
    assert_file_contains "SSHD ProtectSystem=strict" "/etc/systemd/system/sshd.service.d/hardened.conf" "ProtectSystem=strict"
    assert_file_contains "SSHD ProtectHome=yes" "/etc/systemd/system/sshd.service.d/hardened.conf" "ProtectHome=yes"
    assert_file_contains "SSHD NoNewPrivileges=yes" "/etc/systemd/system/sshd.service.d/hardened.conf" "NoNewPrivileges=yes"
fi

test_summary
