#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "PAM Policies & Authentication Controls"

assert_file_exists "faillock.conf exists" "/etc/security/faillock.conf"
assert_file_contains "faillock deny threshold configured" "/etc/security/faillock.conf" "deny[[:space:]]*=[[:space:]]*5"
assert_file_contains "faillock unlock_time configured" "/etc/security/faillock.conf" "unlock_time[[:space:]]*=[[:space:]]*900"

assert_file_exists "pwquality.conf exists" "/etc/security/pwquality.conf"
assert_file_contains "pwquality minlen set" "/etc/security/pwquality.conf" "minlen[[:space:]]*=[[:space:]]*14"
assert_file_contains "pwquality minclass set" "/etc/security/pwquality.conf" "minclass[[:space:]]*=[[:space:]]*4"

assert_file_exists "access.conf exists" "/etc/security/access.conf"
assert_file_contains "access.conf allows root" "/etc/security/access.conf" "\+:root:LOCAL"
assert_file_contains "access.conf allows wheel" "/etc/security/access.conf" "\+:wheel:LOCAL"
assert_file_contains "access.conf default deny" "/etc/security/access.conf" "\-:ALL:ALL"

test_summary
