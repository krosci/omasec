#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_DIR/scripts/modules"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Modular Pipeline Architecture & Integrity"

EXPECTED_MODULES=(
    "00-env.sh"
    "10-debloat.sh"
    "20-defaults.sh"
    "30-theming.sh"
    "40-firewall.sh"
    "50-kernel.sh"
    "60-auth.sh"
    "70-ssh.sh"
    "80-services.sh"
    "85-security-stack.sh"
    "90-hardware-power.sh"
    "95-maintenance.sh"
)

for m in "${EXPECTED_MODULES[@]}"; do
    mpath="$MODULES_DIR/$m"
    assert_file_exists "module $m exists" "$mpath"
    assert_file_executable "module $m is executable" "$mpath"
    assert_file_contains "module $m has strict mode" "$mpath" "set -euo pipefail"
    assert_file_contains "setup.sh references module $m" "$PROJECT_DIR/scripts/setup.sh" "$m"
done

assert_file_contains "00-env defines aur_verified_install" "$MODULES_DIR/00-env.sh" "aur_verified_install\(\)"
assert_file_contains "10-debloat defines DEBLOAT array" "$MODULES_DIR/10-debloat.sh" "DEBLOAT=\("
assert_file_contains "85-security-stack defines SECURITY_PKGS array" "$MODULES_DIR/85-security-stack.sh" "SECURITY_PKGS=\("
assert_file_contains "setup.sh checks EUID root requirement" "$PROJECT_DIR/scripts/setup.sh" "EUID -eq 0"

test_summary
