#!/bin/bash
set -euo pipefail

log "Restoring Yaru icon theme for every user"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _uid=$(id -u "$_user" 2>/dev/null) || continue
    for theme_dir in /usr/share/omarchy/themes/*/; do
        [[ -d "$theme_dir" ]] || continue
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

log "Installing per-theme hooks (folder color and micro editor)"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _hook_dir="$user_home/.config/omarchy/hooks/theme-set.d"
    mkdir -p "$_hook_dir"
    for hook_file in "$PROJECT_DIR"/hooks/theme-set.d/*; do
        [[ -f "$hook_file" ]] || continue
        hook_name=$(basename "$hook_file")
        cp "$hook_file" "$_hook_dir/$hook_name"
        chmod +x "$_hook_dir/$hook_name"
        sudo -u "$_user" bash "$_hook_dir/$hook_name" 2>/dev/null || warn "$hook_name hook run failed for $_user"
    done
    chown -R "$_user":"$_user" "$_hook_dir"
done
