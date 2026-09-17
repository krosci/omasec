#!/bin/bash
set -euo pipefail

log "Hardening systemd services"
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

log "Enabling systemd-oomd"
systemctl enable systemd-oomd.service || warn "systemd-oomd enable failed"
systemctl enable systemd-oomd.socket || warn "systemd-oomd socket enable failed"
systemctl start systemd-oomd.socket 2>/dev/null || warn "systemd-oomd socket start skipped"
