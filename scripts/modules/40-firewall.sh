#!/bin/bash
set -euo pipefail

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
