#!/bin/bash
set -euo pipefail

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
if systemctl list-unit-files auditd.service &>/dev/null; then
    systemctl enable auditd.service || warn "auditd enable skipped"
fi
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
