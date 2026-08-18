#!/usr/bin/env bash
set -euo pipefail

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell-v2"
assume_yes=false
install_dependencies=true
update_only=false
check_only=false
migrate_existing=true

for argument in "$@"; do
    case "$argument" in
        --yes) assume_yes=true ;;
        --no-install-deps) install_dependencies=false ;;
        --update) update_only=true; assume_yes=true ;;
        --check) check_only=true; install_dependencies=false ;;
        --no-migrate-v1) migrate_existing=false ;;
        --prefix=*) prefix="${argument#*=}" ;;
        *) printf 'Unknown option: %s\n' "$argument" >&2; exit 2 ;;
    esac
done

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
bin_path="$bin_dir/ayame-shell-v2"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
hypr_main="$hypr_dir/hyprland.lua"
hypr_fragment="$hypr_dir/ayame-shell-v2.lua"
v1_fragment="$hypr_dir/ayame-shell.lua"
systemd_dir="$config_home/systemd/user"
shell_service="$systemd_dir/ayame-shell-v2.service"
wallpaper_service="$systemd_dir/ayame-v2-wallpaper.service"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell-v2"
rollback_dir="$state_dir/rollback"
timestamp="$(date +%Y%m%d-%H%M%S)"
data_dir="$prefix/data"

os_id=unknown
os_like=""
os_name="Unknown Linux"
if [[ -r /etc/os-release ]]; then
    source /etc/os-release
    os_id="${ID:-unknown}"
    os_like="${ID_LIKE:-}"
    os_name="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
fi
package_family=unknown
case " $os_id $os_like " in
    *" arch "*) package_family=arch ;;
    *" debian "*|*" ubuntu "*) package_family=debian ;;
esac

required=(qs Hyprland hyprctl hyprlock hyprpaper grim slurp wf-recorder
    wl-copy wl-paste cliphist kitty matugen rofi rofimoji curl pw-dump nmcli
    notify-send python3 jq)
declare -A command_packages=(
    [qs]=quickshell [Hyprland]=hyprland [hyprctl]=hyprland
    [hyprlock]=hyprlock [hyprpaper]=hyprpaper [grim]=grim [slurp]=slurp
    [wf-recorder]=wf-recorder [wl-copy]=wl-clipboard [wl-paste]=wl-clipboard
    [cliphist]=cliphist [kitty]=kitty [matugen]=matugen [rofi]=rofi
    [rofimoji]=rofimoji [curl]=curl
    [pw-dump]=pipewire [nmcli]=networkmanager [notify-send]=libnotify
    [python3]=python [jq]=jq
)
if [[ "$package_family" == debian ]]; then
    command_packages[pw-dump]=pipewire-bin
    command_packages[nmcli]=network-manager
    command_packages[notify-send]=libnotify-bin
    command_packages[python3]=python3
fi

missing=()
for command_name in "${required[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done

hyprland_line="$(Hyprland --version 2>/dev/null | head -n 1 || true)"
hyprland_compatible=false
if [[ "$hyprland_line" =~ Hyprland[[:space:]]+([0-9]+)\.([0-9]+) ]] \
        && ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 55)); then
    hyprland_compatible=true
fi

v1_detected=false
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell" \
        || -f "$v1_fragment" || -f "$systemd_dir/ayame-shell.service" ]]; then
    v1_detected=true
fi

if [[ "$check_only" == true ]]; then
    printf 'Ayame Shell V2 compatibility check\n'
    printf '  System:       %s\n' "$os_name"
    printf '  Packages:     %s\n' "$package_family"
    printf '  Hyprland:     %s\n' "${hyprland_line:-missing}"
    printf '  Ayame V1:     %s\n' "$([[ "$v1_detected" == true ]] && printf 'upgrade available' || printf 'not detected')"
    if ((${#missing[@]})); then
        printf '  Missing:      %s\n' "${missing[*]}"
        exit 1
    fi
    [[ "$hyprland_compatible" == true ]] || {
        printf '  Compatibility: Hyprland 0.55 or newer is required\n'
        exit 1
    }
    printf '  Compatibility: ready to install\n'
    exit 0
fi

if ((${#missing[@]})); then
    missing_packages=()
    for command_name in "${missing[@]}"; do
        package_name="${command_packages[$command_name]}"
        [[ " ${missing_packages[*]} " == *" $package_name "* ]] \
            || missing_packages+=("$package_name")
    done
    printf 'Missing commands: %s\n' "${missing[*]}"
    printf 'Required packages: %s\n' "${missing_packages[*]}"
    if [[ "$install_dependencies" != true || "$package_family" == unknown ]]; then
        printf 'Install the missing dependencies, then rerun the installer.\n' >&2
        exit 1
    fi
    answer=n
    if [[ "$assume_yes" == true ]]; then
        answer=y
    else
        read -r -p "Install missing packages now? [y/N] " answer
    fi
    [[ "$answer" =~ ^[Yy]$ ]] || exit 1
    if [[ "$package_family" == arch ]]; then
        sudo pacman -S --needed "${missing_packages[@]}"
    else
        sudo apt-get update
        sudo apt-get install -y "${missing_packages[@]}"
    fi
fi

hyprland_line="$(Hyprland --version 2>/dev/null | head -n 1 || true)"
hyprland_compatible=false
if [[ "$hyprland_line" =~ Hyprland[[:space:]]+([0-9]+)\.([0-9]+) ]] \
        && ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 55)); then
    hyprland_compatible=true
fi
if [[ "$hyprland_compatible" != true ]]; then
    printf 'Ayame V2 requires Hyprland 0.55 or newer. Detected: %s\n' \
        "${hyprland_line:-missing}" >&2
    exit 1
fi

"$source_dir/scripts/check"

printf 'Ayame Shell V2 installer\n'
printf '  Source:       %s\n' "$source_dir"
printf '  Destination:  %s\n' "$prefix"
printf '  Ayame V1:     %s\n' "$([[ "$v1_detected" == true ]] && printf 'detected; kept for rollback' || printf 'not detected')"
if [[ "$assume_yes" != true ]]; then
    read -r -p "Install Ayame Shell V2 as the default shell? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

mkdir -p "$bin_dir" "$hypr_dir" "$systemd_dir" "$state_dir" "$rollback_dir"

if [[ -e "$prefix" ]]; then
    backup="${prefix}.backup-${timestamp}"
    printf 'Backing up the previous V2 installation to %s\n' "$backup"
    mv -- "$prefix" "$backup"
    mkdir -p "$prefix"
    if [[ -d "$backup/data" ]]; then
        cp -a -- "$backup/data" "$prefix/data"
    fi
else
    mkdir -p "$prefix"
fi

for payload in config docs scripts tests README.md install.sh uninstall.sh; do
    cp -a -- "$source_dir/$payload" "$prefix/"
done
chmod +x "$prefix/install.sh" "$prefix/uninstall.sh" "$prefix/scripts/"*
mkdir -p "$data_dir"
chmod 0700 "$data_dir"

if [[ "$migrate_existing" == true ]]; then
    migration_answer=y
    if [[ "$v1_detected" == true && "$assume_yes" != true \
            && ! -f "$data_dir/settings.json" ]]; then
        read -r -p "Migrate compatible Ayame V1 settings into V2? [Y/n] " migration_answer
        migration_answer="${migration_answer:-y}"
    fi
    if [[ "$migration_answer" =~ ^[Yy]$ ]]; then
        "$prefix/scripts/ayame-v2-migrate" --target="$data_dir"
    fi
fi

cat > "$bin_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-run}" in
    update) shift; AYAME_V2_INSTALL_DIR="$prefix" \
        exec "$prefix/scripts/ayame-v2-update" "\$@" ;;
    doctor) shift; exec "$prefix/scripts/ayame-doctor" "\${1:-status}" ;;
    rollback) exec "$prefix/uninstall.sh" --yes --restore-v1 --prefix="$prefix" ;;
    start) exec systemctl --user start ayame-shell-v2.service ;;
    stop) exec systemctl --user stop ayame-shell-v2.service ;;
    restart) exec systemctl --user restart ayame-shell-v2.service ;;
    status) exec systemctl --user --no-pager status ayame-shell-v2.service ;;
    run) shift; exec "$prefix/scripts/ayame-v2-runtime" "\$@" ;;
    *) exec "$prefix/scripts/ayame-v2-runtime" "\$@" ;;
esac
EOF
chmod +x "$bin_path"

cat > "$shell_service" <<EOF
[Unit]
Description=Ayame Shell V2
After=graphical-session.target pipewire.service

[Service]
Type=simple
Environment=AYAME_V2_DATA_DIR=$data_dir
Environment=AYAME_V2_INSTALL_DIR=$prefix
ExecStart=$prefix/scripts/ayame-v2-runtime
KillMode=process
Restart=on-failure
RestartSec=2
TimeoutStopSec=5

[Install]
WantedBy=graphical-session.target
EOF

cat > "$wallpaper_service" <<EOF
[Unit]
Description=Ayame Shell V2 wallpaper service
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=$prefix/scripts/ayame-wallpaper start
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF

cat > "$hypr_fragment" <<EOF
-- Generated by Ayame Shell V2. V1 remains installed for rollback.
local ayame = "$bin_path"
local ipc = "$prefix/scripts/ayame-v2-ipc"
local screenshot = "$prefix/scripts/ayame-screenshot"
local recorder = "$prefix/scripts/ayame-record"

hl.config({
    decoration = { rounding = 14, rounding_power = 2 },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0
    }
})

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE; dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE; systemctl --user stop ayame-shell.service ayame-clipboard.service; systemctl --user restart ayame-v2-wallpaper.service ayame-shell-v2.service")
end)

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(ipc .. " launcher"), { release = true, description = "Open Ayame V2 launcher" })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Open terminal" })
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("kitty"), { description = "Open recovery terminal" })
hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd("rofimoji"), { description = "Open emoji picker" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"), { description = "Lock session" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Toggle fullscreen" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
for workspace = 1, 5 do
    hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }), { description = "Focus workspace " .. workspace })
    hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }), { description = "Move window to workspace " .. workspace })
end
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " desktop 0"), { description = "Capture desktop" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(ipc .. " capture"), { description = "Select an area" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd(screenshot .. " monitor 0 AUTO"), { description = "Capture monitor" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(recorder .. " toggle desktop none AUTO 0"), { description = "Toggle recording" })
EOF

if [[ ! -f "$rollback_dir/hyprland.lua" && -f "$hypr_main" ]]; then
    cp -a -- "$hypr_main" "$rollback_dir/hyprland.lua"
fi
if [[ "$v1_detected" == true ]]; then
    : > "$rollback_dir/upgrade-from-v1"
fi

temporary_hypr="$(mktemp --tmpdir="$hypr_dir" .hyprland.XXXXXX)"
if [[ -f "$hypr_main" ]]; then
    awk -v v1="$v1_fragment" -v v2="$hypr_fragment" '
        $0 == "-- Ayame Shell" || $0 == "-- Ayame Shell V2" { next }
        $0 == "dofile(\"" v1 "\")" || $0 == "dofile(\"" v2 "\")" { next }
        { print }
    ' "$hypr_main" > "$temporary_hypr"
else
    printf '%s\n' '-- Created by Ayame Shell V2.' > "$temporary_hypr"
fi
printf '\n-- Ayame Shell V2\ndofile("%s")\n' "$hypr_fragment" \
    >> "$temporary_hypr"
chmod 0644 "$temporary_hypr"
# Hyprland watches its main configuration file. Replace it atomically so the
# watcher can never observe a short unlink/create gap during installs or updates.
mv -f -- "$temporary_hypr" "$hypr_main"

verification_log="$(mktemp)"
if ! Hyprland --verify-config --config "$hypr_main" \
        > "$verification_log" 2>&1; then
    cat "$verification_log" >&2
    if [[ -f "$rollback_dir/hyprland.lua" ]]; then
        restore_hypr="$(mktemp --tmpdir="$hypr_dir" .hyprland-restore.XXXXXX)"
        cp -- "$rollback_dir/hyprland.lua" "$restore_hypr"
        chmod 0644 "$restore_hypr"
        mv -f -- "$restore_hypr" "$hypr_main"
    fi
    rm -f -- "$verification_log"
    printf 'Hyprland rejected the V2 configuration; the previous file was restored.\n' >&2
    exit 1
fi
rm -f -- "$verification_log"

systemctl --user daemon-reload
systemctl --user enable ayame-shell-v2.service ayame-v2-wallpaper.service >/dev/null
if [[ "$v1_detected" == true ]]; then
    if systemctl --user is-enabled --quiet ayame-shell.service 2>/dev/null; then
        : > "$rollback_dir/v1-shell-enabled"
    fi
    if systemctl --user is-enabled --quiet ayame-clipboard.service 2>/dev/null; then
        : > "$rollback_dir/v1-clipboard-enabled"
    fi
    systemctl --user disable --now ayame-shell.service \
        ayame-clipboard.service >/dev/null 2>&1 || true
else
    systemctl --user stop ayame-shell.service \
        ayame-clipboard.service >/dev/null 2>&1 || true
fi

if [[ -n "${WAYLAND_DISPLAY:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    systemctl --user restart ayame-v2-wallpaper.service
    systemctl --user restart ayame-shell-v2.service
    sleep 2
    if ! systemctl --user is-active --quiet ayame-shell-v2.service; then
        printf 'V2 did not stay running; restoring V1.\n' >&2
        "$prefix/uninstall.sh" --yes --restore-v1 --prefix="$prefix"
        exit 1
    fi
fi

printf '\nAyame Shell V2 is installed as the default shell.\n'
printf '  Update:    %s update\n' "$bin_path"
printf '  Diagnose:  %s doctor\n' "$bin_path"
if [[ "$v1_detected" == true ]]; then
    printf '  Roll back: %s rollback\n' "$bin_path"
fi
if [[ "$update_only" != true ]]; then
    printf 'Log out and back in if this Hyprland session was already running.\n'
fi
