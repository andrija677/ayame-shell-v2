#!/usr/bin/env bash
set -euo pipefail

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell-v2"
assume_yes=false
restore_v1=false
purge_data=false
for argument in "$@"; do
    case "$argument" in
        --yes) assume_yes=true ;;
        --restore-v1) restore_v1=true ;;
        --purge-data) purge_data=true ;;
        --prefix=*) prefix="${argument#*=}" ;;
        *) printf 'Unknown option: %s\n' "$argument" >&2; exit 2 ;;
    esac
done

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_main="$config_home/hypr/hyprland.lua"
hypr_fragment="$config_home/hypr/ayame-shell-v2.lua"
v1_fragment="$config_home/hypr/ayame-shell.lua"
systemd_dir="$config_home/systemd/user"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell-v2"
bin_path="${XDG_BIN_HOME:-$HOME/.local/bin}/ayame-shell-v2"

if [[ "$assume_yes" != true ]]; then
    prompt="Remove Ayame Shell V2"
    [[ "$restore_v1" == true ]] && prompt+=" and restore V1"
    read -r -p "$prompt? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

systemctl --user disable --now ayame-shell-v2.service \
    ayame-v2-wallpaper.service >/dev/null 2>&1 || true
rm -f -- "$systemd_dir/ayame-shell-v2.service" \
    "$systemd_dir/ayame-v2-wallpaper.service"
systemctl --user daemon-reload

if [[ -f "$hypr_main" ]]; then
    temporary="$(mktemp --tmpdir="$(dirname -- "$hypr_main")" .hyprland.XXXXXX)"
    awk -v v2="$hypr_fragment" '
        $0 == "-- Ayame Shell V2" || $0 == "dofile(\"" v2 "\")" { next }
        { print }
    ' "$hypr_main" > "$temporary"
    if [[ "$restore_v1" == true && -f "$v1_fragment" ]] \
            && ! grep -Fq "dofile(\"$v1_fragment\")" "$temporary"; then
        printf '\n-- Ayame Shell\ndofile("%s")\n' "$v1_fragment" >> "$temporary"
    fi
    install -m 0644 "$temporary" "$hypr_main"
    rm -f -- "$temporary"
fi

rm -f -- "$bin_path" "$hypr_fragment"
if [[ "$purge_data" == true ]]; then
    rm -rf -- "$prefix" "$state_dir"
else
    rm -rf -- "$prefix/config" "$prefix/docs" "$prefix/scripts" \
        "$prefix/tests"
    rm -f -- "$prefix/README.md" "$prefix/install.sh" "$prefix/uninstall.sh"
fi

if [[ "$restore_v1" == true && -f "$systemd_dir/ayame-shell.service" ]]; then
    if [[ -f "$state_dir/rollback/v1-shell-enabled" ]]; then
        systemctl --user enable --now ayame-shell.service >/dev/null 2>&1 || true
    else
        systemctl --user start ayame-shell.service >/dev/null 2>&1 || true
    fi
    if [[ -f "$state_dir/rollback/v1-clipboard-enabled" \
            && -f "$systemd_dir/ayame-clipboard.service" ]]; then
        systemctl --user enable --now ayame-clipboard.service >/dev/null 2>&1 || true
    fi
fi

printf 'Ayame Shell V2 was removed.'
[[ "$purge_data" == true ]] || printf ' User data was preserved in %s/data.' "$prefix"
[[ "$restore_v1" == true ]] && printf ' Ayame V1 was restored.'
printf '\n'
