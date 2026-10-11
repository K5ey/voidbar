# voidbar

A floating, glassy status bar for [Hyprland](https://hypr.land), written in QML for [Quickshell](https://quickshell.org).
Every option is live-editable from a built-in settings panel (or by hand in `settings.json`), no restart needed.

<!-- TODO: add a screenshot here: ![screenshot](screenshots/bar.png) -->

## Features

- **Islands or solid bar** layout, top or bottom, with adjustable margins, radii, opacity and optional border
- **Per-monitor bars:** the primary monitor gets everything, others get launcher, workspaces, taskbar and clock
- **Workspaces** as pills, dots or numbers; scroll to switch
- **Taskbar** with pinned apps, running indicators and window badges
- **Media** (MPRIS), **system tray**, **volume** (PipeWire), **battery**, **clock**
- **Stats:** CPU, RAM, GPU (nvidia-smi), temps, disk, network; click to open your monitor of choice
- **Settings panel** with search, sliders, colour pickers and toggles
- **Colour presets** (Glass, Mocha, Tokyo Night, Gruvbox, Nord, Dracula, Paper and more) in the settings panel, plus optional **pywal** accent
- Power menu via wofi (lock / logout / suspend / reboot / shutdown)

## Requirements

- Hyprland
- Quickshell (built with the Hyprland, PipeWire, MPRIS and SystemTray modules)
- A [Nerd Font](https://www.nerdfonts.com/) (default: `Symbols Nerd Font`)
- Optional: `wofi` (launcher and power menu), `hyprlock`, `swaync`, `pavucontrol`/`pwvucontrol`, `btop`, `nvidia-smi`, `pywal`

## Install

```sh
git clone https://github.com/K5ey/voidbar ~/.config/hypr/bar
cd ~/.config/hypr/bar
cp settings.example.json settings.json   # your local config, gitignored
quickshell -p shell.qml
```

Autostart it from `hyprland.conf`:

```
exec-once = quickshell -p ~/.config/hypr/bar/shell.qml
```

## Keybinds

The helper scripts are meant to be bound in Hyprland, for example:

```
bind = SUPER ALT, S,   exec, ~/.config/hypr/bar/toggle-settings.sh   # settings panel
bind = SUPER SHIFT, B, exec, ~/.config/hypr/bar/toggle.sh            # bar on/off
bind = SUPER ALT, B,   exec, ~/.config/hypr/bar/position.sh          # flip top/bottom
```

You can also click the gear in the bar, or right-click the launcher button.

## Configuration

Settings live in `settings.json`; anything you leave out falls back to the defaults in
[`Settings.qml`](Settings.qml). The panel writes to the same file. Main groups:

| Group | Examples |
|---|---|
| Layout | `position`, `height`, `islandStyle`, `edgeMargin`, `sideMargin`, `primaryOnly`, `primaryName` |
| Look | `bgColor`, `bgOpacity`, `accent`, `fontFamily`, `animations`, `pywal` |
| Modules | `showLauncher`, `showWorkspaces`, `showTaskbar`, `showMedia`, `showStats`, ... |
| Workspaces | `wsCount`, `wsStyle`, `wsHideEmpty` |
| Taskbar | `pinned`, `taskIconSize`, `taskIndicator` |
| Stats | `statsCpu`, `statsGpu`, `statsNet`, `statsInterval`, `statsApp` |
| Clock | `clock24`, `clockSeconds`, `clockDateFormat` |
| Commands | `terminal`, `launcherCmd`, `notifCmd`, `lockCmd`, `mixerCmd` |

Run `hyprctl monitors` for monitor names. Set `primaryName` to your main monitor's name, and keep `sideMargin` equal to your Hyprland `gaps_out`.

## Multi-monitor workspaces

By default each monitor gets its own block of `wsCount` workspaces in screen order (monitor 1: 1-5, monitor 2: 6-10).
To pin them yourself, add this to `settings.json`:

```json
"wsStart": { "DP-3": 1, "HDMI-A-1": 6 }
```

## License

MIT
