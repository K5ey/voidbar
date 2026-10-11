pragma Singleton
// Shared, live settings. Everything the bar and the settings panel read comes from here.
// Backed by settings.json next to this file: edit it by hand or use the panel, both reload live.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------- defaults ----------------------------
    readonly property var defaults: ({
        // layout
        position: "top",
        height: 46,
        edgeMargin: 12,
        sideMargin: 20,            // keep equal to GAPS_OUT in hyprland.lua
        reserveSpace: true,        // push windows away from the bar
        exclusiveExtra: 0,
        islandStyle: "islands",    // islands | bar
        islandRadius: 14,
        pillRadius: 10,
        islandPadding: 6,
        itemSpacing: 4,
        primaryOnly: false,        // show the bar on the primary monitor only
        primaryName: "DP-3",       // monitor that gets tray/stats/volume

        // look
        bgColor: "#111318",
        bgOpacity: 0.66,
        borderEnabled: false,
        borderWidth: 1,
        borderColor: "#ffffff",
        borderOpacity: 0.12,
        textColor: "#f2f2f5",
        dimOpacity: 0.6,
        accent: "#ffffff",
        urgentColor: "#ff6b6b",
        warnColor: "#ffb454",
        pywal: false,
        hoverOpacity: 0.15,
        fontFamily: "",            // empty = system default
        fontSize: 13,
        iconFont: "Symbols Nerd Font",
        iconSize: 15,
        animations: true,
        animSpeed: 1.0,

        // modules
        showLauncher: true,
        showWorkspaces: true,
        showTitle: true,
        showTaskbar: true,
        showMedia: true,
        showTray: true,
        showStats: true,
        showBattery: true,
        showVolume: true,
        showClock: true,
        showPower: true,
        showSettingsButton: true,

        // workspaces
        wsCount: 5,
        wsStart: ({}),             // per-monitor first workspace id, e.g. { "DP-3": 1, "HDMI-A-1": 6 }
        wsStyle: "pills",          // pills | dots | numbers
        wsHideEmpty: false,
        wsDotSize: 10,
        wsActiveWidth: 26,
        wsScrollInvert: false,

        // title
        titleMaxWidth: 260,
        titleOnlyFocusedMonitor: true,

        // taskbar
        taskIconSize: 24,
        taskItemWidth: 42,
        taskIndicator: true,
        taskBadge: true,
        taskShowUnpinned: true,
        pinned: ["foot", "org.kde.dolphin", "firefox", "steam", "discord"],

        // media
        mediaMaxWidth: 220,
        mediaShowArtist: true,
        mediaHideWhenPaused: false,

        // tray
        trayIconSize: 18,

        // stats
        statsCpu: true,
        statsGpu: true,
        statsRam: true,
        statsGpuTemp: true,
        statsCpuTemp: false,
        statsDisk: false,
        statsNet: false,
        statsStyle: "labels",      // labels | icons
        statsSpacing: 14,
        statsInterval: 2000,
        statsApp: "btop",

        // battery
        batShowPercent: true,
        batWarnAt: 20,

        // volume
        volStep: 5,
        volMax: 100,
        volShowPercent: true,

        // clock
        clock24: true,
        clockSeconds: false,
        clockShowDate: true,
        clockDateFormat: "ddd d MMM",
        clockBold: true,

        // commands (run through sh -c, ~ and $HOME work)
        terminal: "foot",
        launcherCmd: "wofi --show drun",
        notifCmd: "swaync-client -t -sw",
        lockCmd: "hyprlock",
        mixerCmd: "command -v pwvucontrol >/dev/null && exec pwvucontrol || exec pavucontrol"
    })

    // ---------------------------- state ----------------------------
    property var raw: ({})                                  // what is in settings.json
    readonly property var c: Object.assign({}, defaults, raw)   // effective settings
    readonly property int itemH: Math.max(20, Math.min(40, c.height - 12))   // button height that fits the bar
    property bool open: false                               // settings panel visible
    property string page: "layout"                          // settings panel: current page
    property string query: ""                               // settings panel: search text (lowercase)
    property bool loaded: false

    // animation duration helper: ms(180) -> scaled, or 0 when animations are off
    function ms(base) {
        return c.animations ? Math.round(base * Math.max(0.1, c.animSpeed)) : 0;
    }

    // "#rgb" / "#rrggbb" / "#aarrggbb" + alpha -> color. Never throws.
    function col(hex, alpha) {
        let h = String(hex || "").trim().replace("#", "");
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
        if (h.length === 8) h = h.substring(2);
        if (!/^[0-9a-fA-F]{6}$/.test(h)) h = "ffffff";
        return Qt.rgba(parseInt(h.substring(0, 2), 16) / 255,
                       parseInt(h.substring(2, 4), 16) / 255,
                       parseInt(h.substring(4, 6), 16) / 255,
                       alpha === undefined ? 1 : alpha);
    }

    function validHex(s) {
        return /^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(String(s).trim());
    }

    function normHex(s) {
        let h = String(s).trim().replace("#", "").toLowerCase();
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
        return "#" + h;
    }

    // ---------------------------- editing ----------------------------
    function set(key, value) {
        const n = Object.assign({}, raw);
        // keep the file small: drop keys that equal the default (position stays, position.sh edits it with sed)
        if (key !== "position" && JSON.stringify(defaults[key]) === JSON.stringify(value)) delete n[key];
        else n[key] = value;
        raw = n;
        saveTimer.restart();
    }

    function setMany(obj) {
        const n = Object.assign({}, raw);
        for (const k in obj) {
            if (k !== "position" && JSON.stringify(defaults[k]) === JSON.stringify(obj[k])) delete n[k];
            else n[k] = obj[k];
        }
        raw = n;
        saveTimer.restart();
    }

    function reset() {
        raw = ({});
        saveTimer.restart();
    }

    function resetKeys(keys) {
        const n = Object.assign({}, raw);
        for (let i = 0; i < keys.length; i++) delete n[keys[i]];
        raw = n;
        saveTimer.restart();
    }

    function toggle() { open = !open; }

    signal refocus()    // text fields ask the panel to take keyboard focus back (so Esc keeps closing it)

    // pinned apps helpers
    function addPinned(id) {
        const v = String(id).trim();
        if (!v) return;
        const list = c.pinned.slice();
        for (let i = 0; i < list.length; i++) if (list[i].toLowerCase() === v.toLowerCase()) return;
        list.push(v);
        set("pinned", list);
    }

    function removePinned(i) {
        const list = c.pinned.slice();
        list.splice(i, 1);
        set("pinned", list);
    }

    function movePinned(i, d) {
        const list = c.pinned.slice();
        const j = i + d;
        if (j < 0 || j >= list.length) return;
        const t = list[i]; list[i] = list[j]; list[j] = t;
        set("pinned", list);
    }

    // ---------------------------- presets ----------------------------
    readonly property var presets: [
        { name: "Glass",       bg: "#111318", text: "#f2f2f5", accent: "#ffffff", urgent: "#ff6b6b", op: 0.66 },
        { name: "Midnight",    bg: "#05060a", text: "#e6e9f2", accent: "#7aa2ff", urgent: "#ff6b81", op: 0.82 },
        { name: "Mocha",       bg: "#1e1e2e", text: "#cdd6f4", accent: "#cba6f7", urgent: "#f38ba8", op: 0.80 },
        { name: "Tokyo Night", bg: "#1a1b26", text: "#c0caf5", accent: "#7aa2f7", urgent: "#f7768e", op: 0.80 },
        { name: "Gruvbox",     bg: "#282828", text: "#ebdbb2", accent: "#fabd2f", urgent: "#fb4934", op: 0.85 },
        { name: "Nord",        bg: "#2e3440", text: "#eceff4", accent: "#88c0d0", urgent: "#bf616a", op: 0.82 },
        { name: "Rosé Pine",   bg: "#191724", text: "#e0def4", accent: "#ebbcba", urgent: "#eb6f92", op: 0.82 },
        { name: "Dracula",     bg: "#282a36", text: "#f8f8f2", accent: "#bd93f9", urgent: "#ff5555", op: 0.85 },
        { name: "Everforest",  bg: "#2d353b", text: "#d3c6aa", accent: "#a7c080", urgent: "#e67e80", op: 0.85 },
        { name: "Crimson",     bg: "#12090b", text: "#f5e9ea", accent: "#ff4d5e", urgent: "#ffb454", op: 0.78 },
        { name: "Paper",       bg: "#f4f1ea", text: "#2b2b30", accent: "#3b5bdb", urgent: "#d6336c", op: 0.88 }
    ]

    function applyPreset(p) {
        setMany({ bgColor: p.bg, textColor: p.text, accent: p.accent, urgentColor: p.urgent, bgOpacity: p.op, pywal: false });
    }

    // ---------------------------- persistence ----------------------------
    property string lastWritten: ""

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: {
            // position is always written: position.sh flips it with sed
            const out = Object.assign({ position: defaults.position }, root.raw);
            const t = JSON.stringify(out, null, 2) + "\n";
            root.lastWritten = t;
            file.setText(t);
        }
    }

    FileView {
        id: file
        path: Quickshell.shellDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = text();
            if (t === root.lastWritten) { root.loaded = true; return; }   // our own write
            try {
                const o = JSON.parse(t);
                if (o && typeof o === "object" && !Array.isArray(o)) root.raw = o;
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    // quickshell -p <dir>/shell.qml ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open; }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
