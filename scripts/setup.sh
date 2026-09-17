#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG="${OMASEC_LOG:-$PROJECT_DIR/setup.log}"
if [[ "${OMASEC_LOG_STDOUT:-0}" -eq 0 ]]; then
    exec > >(tee -a "$LOG") 2>&1
fi
umask 077

set -euo pipefail

log() { echo "$1"; }
warn() { echo "warning: $1"; }
err() { echo "error: $1"; exit 1; }

[[ $EUID -eq 0 ]] || err "Root required"

log "Syncing package databases"
pacman -Sy --noconfirm

log "Fixing broken pacman entries"
for pkg_dir in /var/lib/pacman/local/*/; do
    [[ -f "$pkg_dir/desc" ]] || { warn "Removing broken entry: $pkg_dir"; rm -rf "$pkg_dir"; }
done

PRIMARY_USER="${SUDO_USER:-}"
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(getent group wheel | cut -d: -f4 | cut -d, -f1)
fi
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(basename "$(find /home -mindepth 1 -maxdepth 1 -type d 2>/dev/null | tail -1)")
fi
id "$PRIMARY_USER" &>/dev/null || err "Cannot determine primary user"

aur_verified_install() {
    local pkg="$1" tmp f
    [[ -n "$pkg" ]] || err "AUR install requested with empty package name"
    [[ "$pkg" =~ ^[a-zA-Z0-9._-]+$ ]] || err "Invalid AUR package name: $pkg"
    pacman -S --noconfirm --needed base-devel git wget
    tmp=$(mktemp -d)
    chmod 700 "$tmp"
    chown "$PRIMARY_USER":"$PRIMARY_USER" "$tmp"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp' && git clone --quiet --depth 1 https://aur.archlinux.org/$pkg.git src && cd src && \
         { grep -q '^validpgpkeys=' PKGBUILD || \
           { grep -qE '^(sha256sums|sha512sums|b2sums|sha256sums_x86_64)=' PKGBUILD && ! grep -q 'SKIP' PKGBUILD && \
             grep -qE '^# Maintainer: [^< ]+ <[^ ]+@[^ ]+>' PKGBUILD; }; }" || \
        err "AUR package '$pkg' has no verified integrity (needs validpgpkeys, or full sha256sums from a named maintainer); refusing to install"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp/src' && makepkg --noconfirm" || {
        rm -rf "$tmp"
        err "AUR package '$pkg' failed source verification during build; refusing to install"
    }
    f=$(find "$tmp/src" -name '*.pkg.tar.*' -type f 2>/dev/null | head -1)
    [[ -n "$f" ]] || { rm -rf "$tmp"; err "AUR package '$pkg' produced no artifact after verified build"; }
    pacman -U --noconfirm "$f"
    rm -rf "$tmp"
}

DEBLOAT=(
    kdenlive
    obs-studio
    obsidian
    libreoffice-fresh
    chromium
    neovim
    omarchy-nvim
    mpv
)

log "Debloating"
INSTALLED_DEBLOAT=()
for pkg in "${DEBLOAT[@]}"; do
    pacman -Q "$pkg" &>/dev/null && INSTALLED_DEBLOAT+=("$pkg")
done
if [[ ${#INSTALLED_DEBLOAT[@]} -gt 0 ]]; then
    pacman -Rns --noconfirm "${INSTALLED_DEBLOAT[@]}" 2>/dev/null || \
    pacman -Rdd --noconfirm "${INSTALLED_DEBLOAT[@]}" 2>/dev/null || \
    warn "Some packages could not be removed"
fi

log "Fixing base package manifest"
BASE_MANIFEST=/usr/share/omarchy/install/omarchy-base.packages
if [[ -w "$BASE_MANIFEST" ]]; then
    for pkg in "${DEBLOAT[@]}"; do
        sed -i "/^${pkg}$/d" "$BASE_MANIFEST"
    done
fi

log "Pinning debloat in pacman.conf so it never returns"
mkdir -p /etc/pacman.d/omasec
chmod 755 /etc/pacman.d/omasec 2>/dev/null || warn "pacman omasec dir chmod skipped"
IGNORE_STR=$(paste -sd ' ' <(printf '%s\n' "${DEBLOAT[@]}"))
printf '%s\n' "${DEBLOAT[@]}" > /etc/pacman.d/omasec/ignore-pkgs.list
chmod 644 /etc/pacman.d/omasec/ignore-pkgs.list 2>/dev/null || warn "ignore-pkgs.list chmod skipped"
if grep -q '^IgnorePkg' /etc/pacman.conf; then
    sed -i "s|^IgnorePkg.*|IgnorePkg = $IGNORE_STR|" /etc/pacman.conf
else
    sed -i "/^\[options\]/a IgnorePkg = $IGNORE_STR" /etc/pacman.conf
fi

log "Cleaning up nonexistent foot application entry"
if ! pacman -Q foot &>/dev/null && ! command -v foot &>/dev/null; then
    for u_home in /home/*; do
        [[ -d "$u_home" ]] || continue
        rm -f "$u_home/.local/share/applications/foot.desktop" 2>/dev/null || warn "foot desktop remove skipped for $u_home"
        rm -f "$u_home/.local/share/applications/footclient.desktop" 2>/dev/null || warn "footclient desktop remove skipped for $u_home"
        rm -f "$u_home/.local/share/applications/foot-server.desktop" 2>/dev/null || warn "foot-server desktop remove skipped for $u_home"
    done
fi

log "Removing default webapps"
for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
    rm -f "/usr/share/omarchy/applications/$webapp.desktop"
done
if [[ -d /usr/share/omarchy/applications ]]; then
    app_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /usr/share/omarchy/applications 2>/dev/null) || warn "No webapps found in /usr/share/omarchy/applications"
    if [[ -n "$app_matches" ]]; then
        while IFS= read -r app_file; do
            [[ -f "$app_file" ]] && rm -f "$app_file"
        done <<< "$app_matches"
    fi
fi
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
        rm -f "$u_home/.local/share/applications/$webapp.desktop"
    done
    if [[ -d "$u_home/.local/share/applications" ]]; then
        user_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' "$u_home/.local/share/applications" 2>/dev/null) || warn "No webapps found for $u_home"
        if [[ -n "$user_matches" ]]; then
            while IFS= read -r app_file; do
                [[ -f "$app_file" ]] && rm -f "$app_file"
            done <<< "$user_matches"
        fi
    fi
done

log "Installing brave-origin"
if ! pacman -Q brave-origin-bin &>/dev/null; then
    aur_verified_install brave-origin-bin || err "brave-origin installation failed"
fi

log "Setting default browser to brave-origin"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    sudo -u "$_user" omarchy default browser brave-origin 2>/dev/null || warn "omarchy default browser skipped for $_user"
done
omarchy default browser brave-origin 2>/dev/null || warn "omarchy default browser skipped"

log "Installing micro editor"
if ! pacman -Q micro &>/dev/null; then
    pacman -S --noconfirm --needed micro
fi

log "Setting default editor to micro"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'micro\n' > "$user_home/.local/state/omarchy/defaults/editor"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "chown state failed for $_user"
done

log "Installing totem (GNOME Videos)"
if ! pacman -Q totem &>/dev/null; then
    pacman -S --noconfirm --needed totem
fi

log "Setting default media player to totem"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'totem\n' > "$user_home/.local/state/omarchy/defaults/media-player"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "chown state failed for $_user"
done


log "Restoring Yaru icon theme for every user"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _uid=$(id -u "$_user" 2>/dev/null) || continue
    for theme_dir in /usr/share/omarchy/themes/*/; do
        slug=$(basename "$theme_dir")
        override="$user_home/.config/omarchy/themes/$slug/icons.theme"
        if [[ -f "$override" ]] && grep -q 'Tela' "$override" 2>/dev/null; then
            rm -f "$override" || warn "removing Tela override failed for $slug/$_user"
        fi
    done
    _theme_name=$(cat "$user_home/.local/state/omarchy/current/theme.name" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    _yaru_variant=$(
        case "$_theme_name" in
            catppuccin)        echo "Yaru-blue-dark" ;;
            catppuccin-latte)  echo "Yaru-blue" ;;
            tokyo-night)       echo "Yaru-purple-dark" ;;
            nord)              echo "Yaru-blue-dark" ;;
            gruvbox)           echo "Yaru-wartybrown-dark" ;;
            everforest)        echo "Yaru-olive-dark" ;;
            kanagawa)          echo "Yaru-red-dark" ;;
            miasma)            echo "Yaru-dark" ;;
            hackerman)         echo "Yaru-olive-dark" ;;
            ethereal)          echo "Yaru-purple-dark" ;;
            lumon)             echo "Yaru-blue-dark" ;;
            ristretto)         echo "Yaru-red-dark" ;;
            osaka-jade)        echo "Yaru-prussiangreen-dark" ;;
            solitude)          echo "Yaru-dark" ;;
            retro-82)          echo "Yaru-yellow-dark" ;;
            rose-pine)         echo "Yaru-magenta-dark" ;;
            white)             echo "Yaru" ;;
            flexoki-light)     echo "Yaru-yellow" ;;
            last-horizon)      echo "Yaru-dark" ;;
            lupine)            echo "Yaru-purple-dark" ;;
            matte-black)       echo "Yaru-wartybrown-dark" ;;
            vantablack)        echo "Yaru-dark" ;;
            *)                 echo "Yaru-dark" ;;
        esac
    )
    if [[ -e "/run/user/$_uid/bus" ]]; then
        sudo -u "$_user" \
            XDG_RUNTIME_DIR="/run/user/$_uid" \
            gsettings set org.gnome.desktop.interface icon-theme "$_yaru_variant" 2>/dev/null || warn "gsettings icon-theme skipped for $_user"
    fi
done

log "Installing per-theme folder color hook"
HOOK_SRC="$PROJECT_DIR/hooks/theme-set.d/folder-color"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _hook_dir="$user_home/.config/omarchy/hooks/theme-set.d"
    mkdir -p "$_hook_dir"
    cp "$HOOK_SRC" "$_hook_dir/folder-color"
    chmod +x "$_hook_dir/folder-color"
    chown -R "$_user":"$_user" "$_hook_dir"
    sudo -u "$_user" bash "$_hook_dir/folder-color" 2>/dev/null || warn "folder-color hook run failed for $_user"
done

log "Configuring firewall"
if ! pacman -Q ufw &>/dev/null; then
    pacman -S --noconfirm --needed ufw
fi
ufw --force reset 2>/dev/null || warn "ufw reset skipped"
ufw default deny incoming
ufw default allow outgoing
ufw allow 53317/udp
ufw allow 53317/tcp
ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns'

ufw --force enable || warn "ufw already active"
systemctl enable ufw.service || warn "ufw service already enabled"

if command -v ufw-docker &>/dev/null; then
    ufw-docker install 2>/dev/null || warn "ufw-docker install skipped"
fi

log "Hardening kernel"
cat > /etc/sysctl.d/99-security.conf << 'SYSCTL'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 1
kernel.core_uses_pid = 1
kernel.sysrq = 16
kernel.io_uring_disabled = 2
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.file-max = 2000000
fs.inotify.max_user_watches = 524288
vm.mmap_rnd_bits = 28
vm.mmap_rnd_compat_bits = 14
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.ip_forward = 0
net.core.bpf_jit_harden = 2
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
SYSCTL
sysctl --system || warn "Some sysctl keys failed to apply"

cat > /etc/sysctl.d/99-lockdown.conf << 'LOCKDOWN'
kernel.kexec_load_disabled = 1
LOCKDOWN
sysctl --system >/dev/null 2>&1 || warn "Some sysctl keys failed to apply"

log "Disabling core dumps"
mkdir -p /etc/security/limits.d
chmod 755 /etc/security/limits.d 2>/dev/null || warn "limits.d chmod skipped"
cat > /etc/security/limits.d/99-no-core.conf << 'CORE'
* hard core 0
* soft core 0
CORE
chmod 644 /etc/security/limits.d/99-no-core.conf 2>/dev/null || warn "limits.d no-core chmod skipped"
mkdir -p /etc/systemd/system.conf.d
chmod 755 /etc/systemd/system.conf.d 2>/dev/null || warn "system.conf.d chmod skipped"
printf '[Manager]\nDefaultLimitCORE=0\n' > /etc/systemd/system.conf.d/99-no-core.conf
chmod 644 /etc/systemd/system.conf.d/99-no-core.conf 2>/dev/null || warn "system.conf.d no-core chmod skipped"

log "Hardening PAM"
cat > /etc/security/faillock.conf << 'FAILLOCK'
deny = 5
unlock_time = 900
FAILLOCK
chmod 644 /etc/security/faillock.conf

cat > /etc/security/pwquality.conf << 'PWQ'
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 5
minclass = 4
PWQ
chmod 644 /etc/security/pwquality.conf

log "Configuring login access control"
cat > /etc/security/access.conf << 'ACCESS'
+:root:LOCAL
+:root:ALL
+:wheel:LOCAL
+:wheel:ALL
+:sddm:LOCAL
+:sddm:ALL
+:gdm:LOCAL
+:gdm:ALL
+:greetd:LOCAL
+:greetd:ALL
+:lightdm:LOCAL
+:lightdm:ALL
-:ALL:ALL
ACCESS
chmod 644 /etc/security/access.conf

log "Securing SSH"
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/hardened.conf << 'SSH'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 3
MaxSessions 4
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
StrictModes yes
UsePrivilegeSeparation sandbox
AuthenticationMethods publickey
ChrootDirectory none
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
SSH
chmod 600 /etc/ssh/sshd_config.d/hardened.conf

log "Hardening SSH client"
mkdir -p /etc/ssh/ssh_config.d
cat > /etc/ssh/ssh_config.d/hardened.conf << 'SSH_CLIENT'
Host *
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
SSH_CLIENT
chmod 644 /etc/ssh/ssh_config.d/hardened.conf

if systemctl is-active sshd 2>/dev/null | grep -q active; then
    systemctl restart sshd || warn "sshd restart failed"
fi

log "Hardening systemd services"
mkdir -p /etc/systemd/system/sshd.service.d
chmod 755 /etc/systemd/system/sshd.service.d 2>/dev/null || warn "sshd.service.d chmod skipped"
cat > /etc/systemd/system/sshd.service.d/hardened.conf << 'SSHD_SVC'
[Service]
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
RestrictSUIDSGID=yes
ReadWritePaths=/etc/ssh /var/log /var/run/sshd /run/sshd
SSHD_SVC
chmod 644 /etc/systemd/system/sshd.service.d/hardened.conf 2>/dev/null || warn "sshd.service.d hardened.conf chmod skipped"

mkdir -p /etc/systemd/resolved.conf.d
chmod 755 /etc/systemd/resolved.conf.d 2>/dev/null || warn "resolved.conf.d chmod skipped"
cat > /etc/systemd/resolved.conf.d/hardened.conf << 'RESOLVED'
[Resolve]
LLMNR=no
MulticastDNS=no
RESOLVED
chmod 644 /etc/systemd/resolved.conf.d/hardened.conf 2>/dev/null || warn "resolved.conf.d hardened.conf chmod skipped"

mkdir -p /etc/systemd/journald.conf.d
chmod 755 /etc/systemd/journald.conf.d 2>/dev/null || warn "journald.conf.d chmod skipped"
cat > /etc/systemd/journald.conf.d/security.conf << 'JOURNAL'
[Journal]
SystemMaxUse=500M
SystemMaxRetentionSec=30day
Compress=yes
JOURNAL
chmod 644 /etc/systemd/journald.conf.d/security.conf 2>/dev/null || warn "journald.conf.d security.conf chmod skipped"
systemctl restart systemd-journald 2>/dev/null || warn "systemd-journald restart skipped"

log "Disabling unused services"
for svc in avahi-daemon cups cups-browsed; do
    systemctl disable --now "$svc.service" 2>/dev/null || warn "$svc.service not present"
    systemctl disable --now "$svc.socket" 2>/dev/null || warn "$svc.socket not present"
done

log "Installing security stack"
SECURITY_PKGS=(
    lynis
    rkhunter
    clamav
    audit
    usbguard
    fail2ban
    apparmor
)
MISSING_PKGS=()
for pkg in "${SECURITY_PKGS[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "Failed to install $pkg"
    else
        warn "Package $pkg not found in repos, skipping"
        MISSING_PKGS+=("$pkg")
    fi
done

log "Configuring audit rules"
mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/hardened.rules << 'AUDIT'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/ufw -p wa -k firewall
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
-a always,exit -F arch=b64 -S execve -C gid!=egid -F egid=0 -k privilege_escalation
-a always,exit -F arch=b32 -S execve -C gid!=egid -F egid=0 -k privilege_escalation
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/sysctl.conf -p wa -k sysctl
-w /etc/modprobe.d -p wa -k modules
-a always,exit -F arch=b64 -S mount -k mount
-a always,exit -F arch=b32 -S mount -k mount
AUDIT
systemctl list-unit-files auditd.service &>/dev/null && systemctl enable auditd.service || warn "auditd enable skipped"
systemctl restart auditd.service 2>/dev/null || warn "auditd restart skipped"
auditctl -R /etc/audit/rules.d/hardened.rules 2>/dev/null || warn "auditctl load skipped"

log "Configuring USBGuard"
if pacman -Q usbguard &>/dev/null; then
    mkdir -p /etc/usbguard
    usbguard generate-policy > /etc/usbguard/rules.conf || warn "usbguard policy generation failed"
    systemctl enable usbguard.service || warn "usbguard enable failed"
fi

log "Configuring ClamAV"
if pacman -Q clamav &>/dev/null; then
    systemctl enable clamav-freshclam.service || warn "clamav-freshclam enable failed"
    systemctl enable clamav-daemon.service || warn "clamav-daemon enable failed"
    freshclam 2>/dev/null || warn "freshclam update skipped"
fi

log "Configuring fail2ban"
if pacman -Q fail2ban &>/dev/null; then
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3
FAIL2BAN
    systemctl enable fail2ban.service || warn "fail2ban enable failed"
fi

log "Enabling AppArmor"
if pacman -Q apparmor &>/dev/null; then
    mkdir -p /etc/apparmor.d

    cat > /etc/apparmor.d/usr.bin.sshd << 'SSHD'
#include <tunables/global>

/usr/bin/sshd {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability dac_override,
  capability dac_read_search,
  capability setuid,
  capability setgid,
  capability net_bind_service,

  /etc/ssh/** r,
  /etc/ssh/sshd_config.d/** r,
  /var/log/* w,
  /var/run/sshd/ rw,
  /run/sshd/ rw,
  /proc/sys/net/ipv4/tcp_max_syn_backlog r,
  /proc/sys/net/core/somaxconn r,
  /dev/log w,
  /run/nscd.pid rw,
  /run/systemd/notify rw,

  deny /home/** w,
  deny /root/** w,
  deny /tmp/** rw,
  deny /var/tmp/** rw,
}
SSHD

    cat > /etc/apparmor.d/usr.bin.useradd << 'USERADD'
#include <tunables/global>

/usr/bin/useradd {
  #include <abstractions/base>

  /etc/passwd rw,
  /etc/shadow rw,
  /etc/group rw,
  /etc/gshadow rw,
  /etc/login.defs r,
  /etc/skel/** r,
  /home/** rw,
  /var/spool/mail/** rw,
}
USERADD

    cat > /etc/apparmor.d/usr.bin.curl << 'CURL'
#include <tunables/global>

/usr/bin/curl {
  #include <abstractions/base>
  #include <abstractions/ssl_certs>

  network inet stream,
  network inet6 stream,
  network unix stream,

  /etc/ssl/** r,
  /etc/ca-certificates/** r,
  /etc/resolv.conf r,
  /etc/hosts r,
  /dev/null rw,
  /dev/urandom r,
  /tmp/** rw,

  deny /etc/shadow r,
  deny /etc/gshadow r,
  deny /etc/sudoers r,
  deny /etc/ssh/sshd_config r,
}
CURL

    cat > /etc/apparmor.d/usr.bin.wget << 'WGET'
#include <tunables/global>

/usr/bin/wget {
  #include <abstractions/base>
  #include <abstractions/ssl_certs>

  network inet stream,
  network inet6 stream,

  /etc/ssl/** r,
  /etc/ca-certificates/** r,
  /etc/resolv.conf r,
  /etc/hosts r,
  /dev/null rw,
  /dev/urandom r,
  /tmp/** rw,

  deny /etc/shadow r,
  deny /etc/gshadow r,
  deny /etc/sudoers r,
  deny /etc/ssh/sshd_config r,
}
WGET

    systemctl enable apparmor.service || warn "apparmor enable failed"
    aa-enforce /usr/bin/sshd 2>/dev/null || warn "aa-enforce sshd skipped"
    aa-enforce /usr/bin/useradd 2>/dev/null || warn "aa-enforce useradd skipped"
    aa-enforce /usr/bin/curl 2>/dev/null || warn "aa-enforce curl skipped"
    aa-enforce /usr/bin/wget 2>/dev/null || warn "aa-enforce wget skipped"
fi

log "Disabling USB storage"
cat > /etc/modprobe.d/disable-usb-storage.conf << 'USB'
install usb-storage /bin/true
blacklist usb-storage
USB

log "Disabling unused protocols"
cat > /etc/modprobe.d/disable-protocols.conf << 'PROTO'
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
PROTO

log "Disabling FireWire"
cat > /etc/modprobe.d/disable-firewire.conf << 'FIREWIRE'
blacklist firewire-core
blacklist firewire-ohci
blacklist firewire-sbp2
FIREWIRE

log "Disabling unused filesystems"
cat > /etc/modprobe.d/disable-ramfs.conf << 'RAMFS'
blacklist cramfs
blacklist freevxfs
blacklist hfs
blacklist hfsplus
blacklist jffs2
blacklist udf
RAMFS

log "Securing file permissions"
chmod 700 /root
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 750 /etc/ssh
chmod 644 /etc/ssh/*.conf 2>/dev/null || warn "ssh conf chmod skipped"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    chmod 750 "$u_home" 2>/dev/null || warn "home dir chmod skipped for $u_home"
    for d in Documents Downloads Desktop; do
        [[ -d "$u_home/$d" ]] && (chmod 750 "$u_home/$d" 2>/dev/null || warn "user dir chmod skipped for $u_home/$d")
    done
done

log "Securing shared memory"
grep -q '^tmpfs /run/shm tmpfs' /etc/fstab || \
    echo "tmpfs /run/shm tmpfs defaults,nosuid,nodev,mode=1777 0 0" >> /etc/fstab

log "Hardening /tmp and /var/tmp"
for mount_point in /tmp /var/tmp; do
    if grep -q "^tmpfs $mount_point tmpfs" /etc/fstab; then
        if grep -q "^tmpfs $mount_point tmpfs.*noexec" /etc/fstab; then
            sed -i "s|^tmpfs $mount_point tmpfs.*|tmpfs $mount_point tmpfs defaults,nosuid,nodev,mode=1777 0 0|" /etc/fstab
        fi
    else
        echo "tmpfs $mount_point tmpfs defaults,nosuid,nodev,mode=1777 0 0" >> /etc/fstab
    fi
done

log "Setting strict umask"
cat > /etc/profile.d/umask.sh << 'UMASK'
umask 077
UMASK
chmod 644 /etc/profile.d/umask.sh
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/99-umask.conf << 'SYSTEMD_UMASK'
[Manager]
UMask=077
SYSTEMD_UMASK

log "Restricting coredump via systemd"
cat > /etc/systemd/coredump.conf << 'COREDUMP'
[Coredump]
Storage=none
ProcessSizeMax=0
COREDUMP
systemctl daemon-reexec 2>/dev/null || warn "daemon-reexec skipped"

log "Ensuring NetworkManager is not overridden"
rm -f /etc/NetworkManager/conf.d/security.conf

log "Configuring pacman security"
cat > /etc/pacman.d/hooks/99-verify-inserted-keyrings.hook << 'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = archlinux-keyring

[Action]
Description = Verifying keyring signatures...
When = PostTransaction
Exec = /usr/bin/pacman-key --verify
HOOK
chmod 644 /etc/pacman.d/hooks/99-verify-inserted-keyrings.hook

log "Scheduling weekly security audit"
mkdir -p /etc/cron.weekly
cat > /etc/cron.weekly/security-audit.sh << 'AUDITEOF'
#!/bin/bash
/usr/bin/lynis --cron system >> /var/log/lynis-audit.log 2>&1
/usr/bin/rkhunter --check --skip-keypress --report-warnings-only >> /var/log/rkhunter-audit.log 2>&1
/usr/bin/freshclam >> /var/log/clamav-update.log 2>&1
AUDITEOF
chmod 755 /etc/cron.weekly/security-audit.sh

log "Configuring log protection"
cat > /etc/logrotate.d/security << 'LOGROTATE'
/var/log/sudo-io/*
{
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s HUP systemd-journald 2>/dev/null
    endscript
}
LOGROTATE

log "Hardening sudo"
mkdir -p /var/log/sudo
cat > /etc/sudoers.d/security << 'SUDO'
Defaults env_reset,timestamp_timeout=5,passwd_timeout=2
Defaults mail_badpass
Defaults use_pty
Defaults log_input,log_output
Defaults iolog_dir=/var/log/sudo
SUDO
visudo -cf /etc/sudoers.d/security >/dev/null 2>&1 || { rm -f /etc/sudoers.d/security; err "sudoers.d/security invalid, rolled back"; }
chmod 440 /etc/sudoers.d/security

echo 'Defaults passwd_tries=3' > /etc/sudoers.d/passwd-tries
chmod 440 /etc/sudoers.d/passwd-tries

log "Optimizing TPM NvPCR allocation"
if [[ -f /usr/lib/nvpcr/verity.nvpcr ]]; then
    rm -f /usr/lib/nvpcr/verity.nvpcr
fi

log "Fixing voxtype daemon crash loop"
if ! command -v voxtype &>/dev/null; then
    for u_home in /home/*; do
        rm -f "$u_home/.config/systemd/user/graphical-session.target.wants/voxtype.service" 2>/dev/null || warn "voxtype user unit cleanup skipped for $u_home"
    done
    systemctl --global disable voxtype.service 2>/dev/null || warn "global voxtype disable skipped"
fi

log "Sanitizing user shell profiles"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    if [[ -f "$u_home/.profile" ]]; then
        sed -i 's|^\. "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|' "$u_home/.profile"
        sed -i 's|^source "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& source "$HOME/.cargo/env"|' "$u_home/.profile"
    fi
    if [[ -f "$u_home/.bash_profile" ]]; then
        sed -i 's|^\. "\$HOME/\.cargo/env"|[[ -f "$HOME/.cargo/env" ]] \&\& . "$HOME/.cargo/env"|' "$u_home/.bash_profile"
        sed -i 's|^source "\$HOME/\.cargo/env"|[[ -f "$HOME/.cargo/env" ]] \&\& source "$HOME/.cargo/env"|' "$u_home/.bash_profile"
    fi
done

log "Enabling systemd-oomd"
systemctl enable systemd-oomd.service || warn "systemd-oomd enable failed"
systemctl enable systemd-oomd.socket || warn "systemd-oomd socket enable failed"
systemctl start systemd-oomd.socket 2>/dev/null || warn "systemd-oomd socket start skipped"

log "Cleaning orphaned packages"
orphans=$(pacman -Qdtq 2>/dev/null) || warn "no orphans found"
[[ -n "$orphans" ]] && pacman -Rns --noconfirm $orphans 2>/dev/null || warn "orphan cleanup skipped"

log "Clearing package cache"
yes | pacman -Scc 2>/dev/null || warn "package cache clear skipped"

log "Hardening complete. Reboot required."
