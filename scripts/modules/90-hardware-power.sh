#!/bin/bash
set -euo pipefail

log "Enforcing battery charge threshold policy"
mkdir -p /etc/omasec
chmod 755 /etc/omasec 2>/dev/null || warn "/etc/omasec chmod skipped"
cat > /etc/omasec/power.conf << 'POWER'
BATTERY_CHARGE_LIMIT=75
POWER
chmod 644 /etc/omasec/power.conf

cat > /etc/udev/rules.d/98-battery-charge-threshold.rules << 'UDEV'
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_control_end_threshold}="75"
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_stop_threshold}=="?*", ATTR{charge_stop_threshold}="75"
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_end_threshold}=="?*", ATTR{charge_end_threshold}="75"
UDEV
chmod 644 /etc/udev/rules.d/98-battery-charge-threshold.rules
udevadm control --reload-rules 2>/dev/null || warn "udevadm reload-rules skipped"
udevadm trigger --subsystem-match=power_supply 2>/dev/null || warn "udevadm trigger power_supply skipped"

mkdir -p /etc/tmpfiles.d
cat > /etc/tmpfiles.d/battery-charge-threshold.conf << 'TMPFILES'
w- /sys/class/power_supply/BAT*/charge_control_end_threshold - - - - 75
w- /sys/class/power_supply/BAT*/charge_stop_threshold - - - - 75
w- /sys/class/power_supply/BAT*/charge_end_threshold - - - - 75
w- /sys/class/power_supply/BATT*/charge_control_end_threshold - - - - 75
TMPFILES
chmod 644 /etc/tmpfiles.d/battery-charge-threshold.conf
systemd-tmpfiles --create /etc/tmpfiles.d/battery-charge-threshold.conf 2>/dev/null || warn "systemd-tmpfiles create skipped"

cat > /etc/systemd/system/battery-charge-threshold.service << 'SERVICE'
[Unit]
Description=Universal Battery Charge Threshold Policy
After=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'LIMIT=75; [ -f /etc/omasec/power.conf ] && . /etc/omasec/power.conf; for f in /sys/class/power_supply/BAT*/charge_control_end_threshold /sys/class/power_supply/BAT*/charge_stop_threshold /sys/class/power_supply/BAT*/charge_end_threshold /sys/class/power_supply/BATT*/charge_control_end_threshold; do [ -w "$f" ] && echo "$LIMIT" > "$f" 2>/dev/null || :; done; exit 0'

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
SERVICE
chmod 644 /etc/systemd/system/battery-charge-threshold.service
systemctl daemon-reload 2>/dev/null || warn "systemctl daemon-reload skipped"
systemctl enable battery-charge-threshold.service 2>/dev/null || warn "battery-charge-threshold enable skipped"
systemctl start battery-charge-threshold.service 2>/dev/null || warn "battery-charge-threshold start skipped"

for node in /sys/class/power_supply/BAT*/charge_control_end_threshold \
            /sys/class/power_supply/BAT*/charge_stop_threshold \
            /sys/class/power_supply/BAT*/charge_end_threshold \
            /sys/class/power_supply/BATT*/charge_control_end_threshold; do
    if [[ -w "$node" ]]; then
        echo 75 > "$node" 2>/dev/null || warn "Failed to write charge limit to $node"
    fi
done

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
