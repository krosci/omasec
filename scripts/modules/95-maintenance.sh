#!/bin/bash
set -euo pipefail

log "Configuring pacman security"
mkdir -p /etc/pacman.d/hooks
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
        [[ -d "$u_home" ]] || continue
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

log "Cleaning orphaned packages"
orphans=$(pacman -Qdtq 2>/dev/null) || warn "no orphans found"
[[ -n "$orphans" ]] && pacman -Rns --noconfirm $orphans 2>/dev/null || warn "orphan cleanup skipped"

log "Clearing package cache"
yes | pacman -Scc 2>/dev/null || warn "package cache clear skipped"
