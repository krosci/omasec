#!/bin/bash

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local desc="$1" condition="$2"
    if eval "$condition" &>/dev/null; then
        ((PASS++))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        ((FAIL++))
        echo -e "  ${RED}fail${NC} $desc"
    fi
}

section() { echo -e "\n${BOLD}$1${NC}"; }

section "Packages"
check "brave-origin installed"          "pacman -Q brave-origin-bin &>/dev/null"
check "chromium removed"                "! pacman -Q chromium &>/dev/null"
check "neovim removed"                  "! pacman -Q neovim &>/dev/null"
check "omarchy-nvim removed"            "! pacman -Q omarchy-nvim &>/dev/null"
check "mpv removed"                     "! pacman -Q mpv &>/dev/null"
check "totem installed"                 "pacman -Q totem &>/dev/null"
check "yaru-icon-theme present"         "pacman -Q yaru-icon-theme &>/dev/null"
check "kdenlive removed"                "! pacman -Q kdenlive &>/dev/null"
check "obs-studio removed"              "! pacman -Q obs-studio &>/dev/null"
check "libreoffice-fresh removed"       "! pacman -Q libreoffice-fresh &>/dev/null"
check "obsidian removed"                "! pacman -Q obsidian &>/dev/null"

section "GUI dependencies"
check "nautilus present"                "pacman -Q nautilus &>/dev/null"
check "herdr present"                   "pacman -Q herdr &>/dev/null"
check "gum present"                     "pacman -Q gum &>/dev/null"

section "Browser & Editor"
check "default browser is brave-origin" "[[ \"\$(omarchy default browser 2>/dev/null)\" == brave-origin ]]"
check "default editor is micro"  "[[ \"\$(cat \$HOME/.local/state/omarchy/defaults/editor 2>/dev/null)\" == micro ]]"



section "Firewall"
if UFW_STATUS=$(sudo -n ufw status 2>/dev/null); then
    check "UFW active"          "echo '$UFW_STATUS' | grep -q 'Status: active'"
    check "deny incoming"       "sudo -n ufw status verbose 2>/dev/null | grep -q 'Default: deny (incoming)'"
    check "allow outgoing"      "sudo -n ufw status verbose 2>/dev/null | grep -q 'allow (outgoing)'"
else
    echo -e "  ${RED}skip${NC} UFW check (requires root)"
fi
check "UFW enabled at boot"     "systemctl is-enabled ufw.service &>/dev/null"

section "Kernel hardening"
for setting in \
    "kernel.randomize_va_space	2" \
    "kernel.kptr_restrict	2" \
    "kernel.dmesg_restrict	1" \
    "kernel.perf_event_paranoid	3" \
    "kernel.unprivileged_bpf_disabled	1" \
    "kernel.yama.ptrace_scope	1" \
    "kernel.sysrq	16" \
    "fs.suid_dumpable	0" \
    "fs.protected_hardlinks	1" \
    "fs.protected_symlinks	1" \
    "fs.protected_fifos	2" \
    "fs.protected_regular	2" \
    "net.ipv4.conf.all.rp_filter	1" \
    "net.ipv4.conf.all.accept_redirects	0" \
    "net.ipv4.conf.all.send_redirects	0" \
    "net.ipv4.conf.all.accept_source_route	0" \
    "net.ipv4.icmp_echo_ignore_broadcasts	1" \
    "net.ipv4.tcp_syncookies	1" \
    "net.ipv4.tcp_rfc1337	1" \
    ; do
    key="${setting%%	*}"
    expected="${setting##*	}"
    check "$key = $expected" "[[ \"\$(cat /proc/sys/\${key//./\/})\" == $expected ]]"
done
check "sysctl config persisted"         "[[ -f /etc/sysctl.d/99-security.conf ]]"
check "core dumps disabled"             "[[ -f /etc/security/limits.d/99-no-core.conf ]]"

section "PAM & authentication"
check "faillock configured"    "[[ -f /etc/security/faillock.conf ]]"
check "pwquality configured"   "[[ -f /etc/security/pwquality.conf ]]"
check "access.conf configured" "[[ -f /etc/security/access.conf ]] && grep -q 'ALL:ALL' /etc/security/access.conf"

section "SSH"
SSHD_DIR="/etc/ssh/sshd_config.d"
if [[ -r "$SSHD_DIR/hardened.conf" ]]; then
    check "hardened config"        "[[ -f $SSHD_DIR/hardened.conf ]]"
    check "PermitRootLogin no"     "grep -q '^PermitRootLogin no' $SSHD_DIR/hardened.conf"
    check "PasswordAuth disabled"  "grep -q '^PasswordAuthentication no' $SSHD_DIR/hardened.conf"
elif sudo -n test -r "$SSHD_DIR/hardened.conf" 2>/dev/null; then
    check "hardened config"        "sudo -n test -f $SSHD_DIR/hardened.conf"
    check "PermitRootLogin no"     "sudo -n grep -q '^PermitRootLogin no' $SSHD_DIR/hardened.conf"
    check "PasswordAuth disabled"  "sudo -n grep -q '^PasswordAuthentication no' $SSHD_DIR/hardened.conf"
else
    echo -e "  ${RED}skip${NC} SSH config (requires root to read)"
fi

section "Services"
check "avahi-daemon disabled"   "! systemctl is-enabled avahi-daemon.service 2>/dev/null | grep -q '^enabled$'"
check "cups disabled"           "! systemctl is-enabled cups.service 2>/dev/null | grep -q '^enabled$'"
check "bluetooth enabled"       "systemctl is-enabled bluetooth.service 2>/dev/null | grep -q '^enabled$'"
check "sshd service hardened"   "[[ -f /etc/systemd/system/sshd.service.d/hardened.conf ]]"
check "NetworkManager not overridden" "! [[ -f /etc/NetworkManager/conf.d/security.conf ]]"
check "resolved LLMNR disabled" "[[ -f /etc/systemd/resolved.conf.d/hardened.conf ]]"

section "Security tooling"
for pkg in lynis rkhunter clamav audit usbguard fail2ban apparmor; do
    check "$pkg present" "pacman -Q $pkg &>/dev/null"
done

section "File permissions"
check "/root 700"       "[[ \"\$(stat -c %a /root)\" == 700 ]]"
check "/etc/shadow 600" "[[ \"\$(stat -c %a /etc/shadow)\" == 600 ]]"
check "/etc/gshadow 600" "[[ \"\$(stat -c %a /etc/gshadow)\" == 600 ]]"
check "/etc/passwd 644" "[[ \"\$(stat -c %a /etc/passwd)\" == 644 ]]"
check "/etc/group 644"  "[[ \"\$(stat -c %a /etc/group)\" == 644 ]]"

section "Module blocking"
check "USB storage blocked"      "[[ -f /etc/modprobe.d/disable-usb-storage.conf ]]"
check "unsafe protocols blocked" "[[ -f /etc/modprobe.d/disable-protocols.conf ]]"
check "FireWire blocked"         "[[ -f /etc/modprobe.d/disable-firewire.conf ]]"
check "legacy filesystems blocked" "[[ -f /etc/modprobe.d/disable-ramfs.conf ]]"

section "System Health & Parity"
check "TPM NvPCR verity removed" "! [[ -f /usr/lib/nvpcr/verity.nvpcr ]]"
check "voxtype daemon inactive if missing" "! systemctl --user is-active voxtype 2>/dev/null | grep -q '^active$'"
check "foot launcher clean when missing" "! command -v foot &>/dev/null && ! [[ -f \$HOME/.local/share/applications/foot.desktop ]]"
check "default webapps removed" "! grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /usr/share/omarchy/applications 2>/dev/null"

section "Hardware & Power Management"
check "power.conf policy exists" "[[ -f /etc/omasec/power.conf ]]"
check "battery charge udev rule exists" "[[ -f /etc/udev/rules.d/98-battery-charge-threshold.rules ]]"
check "battery charge tmpfiles exists" "[[ -f /etc/tmpfiles.d/battery-charge-threshold.conf ]]"
check "battery service enabled" "systemctl is-enabled battery-charge-threshold.service &>/dev/null"
if ls /sys/class/power_supply/BAT*/charge_control_end_threshold &>/dev/null; then
    check "live battery limit is 75%" "grep -qx '75' /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null"
fi

section "Scheduling"
check "weekly security audit" "[[ -f /etc/cron.weekly/security-audit.sh && -x /etc/cron.weekly/security-audit.sh ]]"

section "User configs intact"
check "starship config"  "[[ -f \$HOME/.config/starship.toml ]]"
check "git config"       "[[ -f \$HOME/.config/git/config ]]"
check "lazygit config"   "[[ -f \$HOME/.config/lazygit/config.yml ]]"

section "Debloat persistence"
check "IgnorePkg in pacman.conf" "grep -q '^IgnorePkg' /etc/pacman.conf"
check "icon-theme is Yaru"       "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | grep -q 'Yaru'"
check "no Tela override"         "! grep -rq 'Tela' $HOME/.config/omarchy/themes/ 2>/dev/null"
check "folder-color hook"        "[[ -x $HOME/.config/omarchy/hooks/theme-set.d/folder-color ]]"
check "micro-theme hook"         "[[ -x $HOME/.config/omarchy/hooks/theme-set.d/micro-theme ]]"
check "micro colorscheme exists" "[[ -f $HOME/.config/micro/colorschemes/omarchy.micro ]]"
check "yaru-icon-theme present"  "pacman -Q yaru-icon-theme &>/dev/null"

section "AUR integrity"
check "no unverified AUR" "! grep -q 'aur_install ' '$SCRIPT_DIR/setup.sh'"
check "no yay fallback"   "! grep -q 'yay -S' '$SCRIPT_DIR/setup.sh'"

echo ""
echo -e "${BOLD}Passed: $PASS  Failed: $FAIL${NC}"
[[ $FAIL -eq 0 ]] || exit 1
