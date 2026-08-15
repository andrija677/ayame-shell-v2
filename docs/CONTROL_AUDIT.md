# Ayame V2 control audit

Every visible interactive control must either perform its real action or be
rendered as capability information, never as a pretend button.

| Surface | Control | Backend |
| --- | --- | --- |
| Top bar | Workspaces | Hyprland Lua dispatcher |
| Top bar | Workspaces/window title | Hyprland workspaces and active toplevel |
| Top bar | Clock/status hub | Live time, weather, NetworkManager, PipeWire, BlueZ, UPower |
| Top bar | System tray | StatusNotifier items, menus, activation, and scrolling |
| Dock | Launcher, AI, Settings | Shared V2 overlay controller |
| Dock | Pinned/running apps | DesktopEntries and Hyprland toplevels |
| Dock | Left/right click | Launch/focus/minimize and pin/unpin |
| Launcher | Search/launch | DesktopEntries |
| Launcher | Add an app | Integrated executable scanner and desktop registration |
| Launcher | Remove added app | Right-click and desktop entry removal |
| Launcher | Power | Confirmed loginctl/systemctl/Hyprland actions |
| Control center | Media | MPRIS |
| Control center | Audio/output picker | PipeWire default sink and available sinks |
| Control center | Brightness/backlight | brightnessctl with capability detection |
| Control center | Network/Wi-Fi manager | NetworkManager, saved/open/PSK connections |
| Control center | Bluetooth manager | BlueZ scan, pair, connect, disconnect, and forget |
| Control center | Night light/focus | hyprsunset user service and persistent DND |
| Control center | Keep awake/gaming mode | Idle inhibitor and guarded Hyprland effect profile |
| Control center | Power profile/battery | power-profiles-daemon and UPower |
| Utilities | Keybinds/screenshot | Live reference and capture-pill reveal |
| Utilities | Clipboard | Local cliphist history, copy, delete, clear, and password exclusion |
| Utilities | Displays | Hyprland mode/scale inventory and safe next-login persistence |
| Utilities | Power | Confirmed loginctl/systemctl/Hyprland actions |
| Notifications | History/dismiss/clear/actions | Freedesktop notification server in V2 live mode |
| Settings | Wallpaper/palette/mode/glass | Hyprpaper/swww, Matugen, app color scheme, V2-scoped blur rule |
| Settings | Bar/dock/modules/motion | Live runtime visibility, layout, tray, density, and motion settings |
| Settings | Notifications/clipboard/weather | Notification ownership guard, DND, history, Open-Meteo search |
| Settings | Night light/idle | Capability-guarded hyprsunset and hypridle user services |
| Settings | Diagnostics/updates | Dependency report, notification test, and remote check |
| Settings | AI provider/personality/keys | Persistent configuration and Secret Service key storage/test |
| AI | Send/stop/new chat | Streaming Gemini, OpenAI, or Ollama bridge |
| Capture pill | Drag/unsnap/snap/tuck/mode/capture/record | Layer shell, grim, native area selector, wl-copy, wf-recorder |

The V2 notification server is enabled only by `ayame-v2-runtime`; preview and
smoke-test instances leave it disabled so they cannot conflict with Ayame V1.
Persistent night-light, idle, blur, and clipboard services are likewise restored
only by the live V2 runtime, never merely by opening the design preview.
The guarded session script restores V1 automatically if V2 fails to remain
active after startup.
