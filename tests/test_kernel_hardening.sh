#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Kernel Sysctl Hardening & Limits"

assert_file_exists "sysctl 99-security.conf exists" "/etc/sysctl.d/99-security.conf"
assert_file_exists "sysctl 99-lockdown.conf exists" "/etc/sysctl.d/99-lockdown.conf"
assert_file_exists "limits 99-no-core.conf exists" "/etc/security/limits.d/99-no-core.conf"

check_sysctl_live() {
    local key="$1" expected="$2"
    local path="/proc/sys/${key//./\/}"
    [[ -f "$path" ]] || return 0
    local val
    val=$(cat "$path" 2>/dev/null)
    [[ "$val" == "$expected" ]]
}

assert_true "kernel.randomize_va_space = 2" "check_sysctl_live kernel.randomize_va_space 2"
assert_true "kernel.kptr_restrict = 2" "check_sysctl_live kernel.kptr_restrict 2"
assert_true "kernel.dmesg_restrict = 1" "check_sysctl_live kernel.dmesg_restrict 1"
assert_true "kernel.perf_event_paranoid = 3" "check_sysctl_live kernel.perf_event_paranoid 3"
assert_true "kernel.unprivileged_bpf_disabled = 1" "check_sysctl_live kernel.unprivileged_bpf_disabled 1"
assert_true "kernel.yama.ptrace_scope = 1" "check_sysctl_live kernel.yama.ptrace_scope 1"
assert_true "kernel.sysrq = 16" "check_sysctl_live kernel.sysrq 16"

assert_true "fs.suid_dumpable = 0" "check_sysctl_live fs.suid_dumpable 0"
assert_true "fs.protected_hardlinks = 1" "check_sysctl_live fs.protected_hardlinks 1"
assert_true "fs.protected_symlinks = 1" "check_sysctl_live fs.protected_symlinks 1"
assert_true "fs.protected_fifos = 2" "check_sysctl_live fs.protected_fifos 2"
assert_true "fs.protected_regular = 2" "check_sysctl_live fs.protected_regular 2"

assert_true "net.ipv4.conf.all.rp_filter = 1" "check_sysctl_live net.ipv4.conf.all.rp_filter 1"
assert_true "net.ipv4.conf.all.accept_redirects = 0" "check_sysctl_live net.ipv4.conf.all.accept_redirects 0"
assert_true "net.ipv4.conf.all.send_redirects = 0" "check_sysctl_live net.ipv4.conf.all.send_redirects 0"
assert_true "net.ipv4.conf.all.accept_source_route = 0" "check_sysctl_live net.ipv4.conf.all.accept_source_route 0"
assert_true "net.ipv4.icmp_echo_ignore_broadcasts = 1" "check_sysctl_live net.ipv4.icmp_echo_ignore_broadcasts 1"
assert_true "net.ipv4.tcp_syncookies = 1" "check_sysctl_live net.ipv4.tcp_syncookies 1"
assert_true "net.ipv4.tcp_rfc1337 = 1" "check_sysctl_live net.ipv4.tcp_rfc1337 1"

assert_file_contains "limits.d/99-no-core.conf has hard core 0" "/etc/security/limits.d/99-no-core.conf" "hard[[:space:]]+core[[:space:]]+0"
assert_file_contains "limits.d/99-no-core.conf has soft core 0" "/etc/security/limits.d/99-no-core.conf" "soft[[:space:]]+core[[:space:]]+0"

test_summary
