import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

// One bar per monitor.
//   primary monitor:   launcher, workspaces, title | taskbar | media, tray, stats, battery, volume, clock, settings, power
//   other monitors:    launcher, workspaces        | taskbar | clock
//
// Every option lives in settings.json (see Settings.qml for the list and defaults).
// Change them in the settings panel (gear button / right click on the launcher) or edit the file, it reloads live.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    // ============================ CONFIG ============================
    readonly property var s: Settings.c

    readonly property bool atBottom: s.position === "bottom"
    readonly property int barHeight: s.height > 0 ? s.height : 46
    readonly property int sideMargin: s.sideMargin
    readonly property int edgeMargin: s.edgeMargin
    readonly property string primaryName: s.primaryName
    readonly property string terminal: s.terminal
    readonly property bool usePywal: s.pywal === true      // accent follows ~/.cache/wal/colors.json

    // taskbar: pinned apps (hidden when not installed and not running)
    readonly property var pinned: s.pinned
    // never shown in the taskbar
    readonly property var ignored: ["xwaylandvideobridge", "flameshot", "org.kde.polkit-kde-authentication-agent-1"]

    // first workspace id per monitor, e.g. { "DP-3": 1, "HDMI-A-1": 6 } (set "wsStart" in settings.json).
    // Monitors not listed get consecutive blocks of wsCount workspaces, in screen order.
    readonly property var wsStart: s.wsStart || ({})
    readonly property int wsCount: s.wsCount

    readonly property color cBg: Settings.col(s.bgColor, s.bgOpacity)
    readonly property color cText: Settings.col(s.textColor)
    readonly property color cDim: Settings.col(s.textColor, s.dimOpacity)
    readonly property color cUrgent: Settings.col(s.urgentColor)
    readonly property color cWarn: Settings.col(s.warnColor)
    property color walAccent: "#ffffff"
    property bool walLoaded: false
    readonly property color accent: usePywal && walLoaded ? walAccent : Settings.col(s.accent)
    // readable text colour on top of the accent
    readonly property color onAccent: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.6 ? "#15171c" : "#ffffff"
    // ================================================================

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property var myScreen: modelData
    readonly property var hyprMon: Hyprland.monitorFor(modelData)
    readonly property int screenIndex: {
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++) if (list[i].name === modelData.name) return i;
        return 0;
    }
    readonly property int wsFirst: wsStart[modelData.name] !== undefined ? wsStart[modelData.name] : screenIndex * s.wsCount + 1
    readonly property bool isPrimary: computeIsPrimary()

    visible: !(s.primaryOnly && !isPrimary)

    anchors {
        left: true
        right: true
        top: !atBottom
        bottom: atBottom
    }
    margins {
        left: sideMargin
        right: sideMargin
        top: atBottom ? 0 : edgeMargin
        bottom: atBottom ? edgeMargin : 0
    }
    implicitHeight: barHeight
    exclusiveZone: s.reserveSpace ? barHeight + s.exclusiveExtra : 0
    color: "transparent"
    WlrLayershell.namespace: "qsbar"

    // ============================ HELPERS ============================

    function computeIsPrimary() {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === primaryName)
                return modelData.name === primaryName;
        }
        return modelData === Quickshell.screens[0];
    }

    // run a user command through the shell (so ~ and $HOME work)
    function run(cmd) {
        if (cmd && cmd.trim() !== "")
            Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Hyprland 0.55 with a Lua config wants Lua expressions over IPC; older setups want
    // legacy dispatchers. Try Lua first, fall back to legacy if it didn't answer "ok".
    function hypr(lua, legacy) {
        Quickshell.execDetached(["sh", "-c",
            "out=$(hyprctl dispatch \"$1\" 2>&1); [ \"$out\" = ok ] || hyprctl dispatch \"$2\" >/dev/null 2>&1",
            "sh", lua, legacy]);
    }

    function gotoWs(id) {
        hypr('hl.dsp.focus({ workspace = "' + id + '" })', "workspace " + id);
    }

    function stepWs(sign) {   // sign is "+" or "-"
        hypr('hl.dsp.focus({ workspace = "e' + sign + '1" })', "workspace e" + sign + "1");
    }

    function findWs(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i];
        }
        return null;
    }

    function onThisScreen(t) {
        const sc = t.screens;
        if (!sc || sc.length === 0) return modelData === Quickshell.screens[0];
        for (let i = 0; i < sc.length; i++) {
            if (sc[i] === modelData || sc[i].name === modelData.name) return true;
        }
        return false;
    }

    function idMatches(appId, pin) {
        const a = (appId || "").toLowerCase();
        return a === pin || a.endsWith("." + pin);
    }

    function isIgnored(appId) {
        const a = (appId || "").toLowerCase();
        for (let i = 0; i < ignored.length; i++) {
            if (a === ignored[i].toLowerCase()) return true;
        }
        return false;
    }

    function anyActive(tls) {
        for (let i = 0; i < tls.length; i++) {
            if (tls[i].activated) return true;
        }
        return false;
    }

    function iconFor(m) {
        let name = "";
        if (m.entry && m.entry.icon) name = m.entry.icon;
        else if (m.appId) name = m.appId;
        let p = name ? Quickshell.iconPath(name, true) : "";
        if (!p && m.appId) p = Quickshell.iconPath(String(m.appId).toLowerCase(), true);
        if (!p) p = Quickshell.iconPath("application-x-executable");
        return p;
    }

    function launch(m) {
        if (!m.entry) return;
        try {
            m.entry.execute();
        } catch (e) {
            try { Quickshell.execDetached(m.entry.command); } catch (e2) {}
        }
    }

    function taskClick(m, mouse) {
        const tls = m.toplevels;
        if (mouse.button === Qt.MiddleButton) {          // middle click: close the focused (or first) window
            if (tls.length === 0) return;
            let target = tls[0];
            for (let i = 0; i < tls.length; i++) if (tls[i].activated) target = tls[i];
            target.close();
            return;
        }
        if (mouse.button === Qt.RightButton) {           // right click: new instance
            launch(m);
            return;
        }
        if (tls.length === 0) { launch(m); return; }     // left click: open / focus / cycle windows
        if (tls.length === 1) { tls[0].activate(); return; }
        let cur = -1;
        for (let i = 0; i < tls.length; i++) if (tls[i].activated) cur = i;
        tls[(cur + 1) % tls.length].activate();
    }

    function bumpVolume(delta) {
        const sk = Pipewire.defaultAudioSink;
        if (!sk || !sk.audio) return;
        sk.audio.volume = Math.max(0, Math.min(s.volMax / 100, sk.audio.volume + delta));
    }

    function volGlyph() {
        if (muted || vol <= 0) return "";
        return vol < 0.5 ? "" : "";
    }

    function batGlyph() {
        if (batStatus === "Charging") return "";
        if (batPct <= 10) return "";
        if (batPct <= 35) return "";
        if (batPct <= 60) return "";
        if (batPct <= 85) return "";
        return "";
    }

    function batColor() {
        if (batStatus === "Charging") return accent;
        if (batPct <= s.batWarnAt / 2) return cUrgent;
        if (batPct <= s.batWarnAt) return cWarn;
        return cText;
    }

    function heat(v, warn, urgent) {
        const n = Number(v);
        if (n >= urgent) return cUrgent;
        if (n >= warn) return cWarn;
        return cText;
    }

    function rate(b) {
        const n = Number(b) || 0;
        if (n >= 1048576) return (n / 1048576).toFixed(1) + "M";
        if (n >= 1024) return Math.round(n / 1024) + "K";
        return n + "B";
    }

    // ============================ STATE ============================

    // bumped on window open/close/move so the taskbar re-sorts windows between monitors
    property int tick: 0

    // [{ key, appId, pinned, toplevels: [...], entry: DesktopEntry|null }]
    readonly property var taskEntries: {
        void win.tick;
        const out = [];
        const tls = ToplevelManager.toplevels.values;
        const used = [];

        for (let p = 0; p < pinned.length; p++) {
            const pin = pinned[p].toLowerCase();
            const group = [];
            for (let i = 0; i < tls.length; i++) {
                if (isIgnored(tls[i].appId) || !onThisScreen(tls[i])) continue;
                if (idMatches(tls[i].appId, pin)) {
                    group.push(tls[i]);
                    used[i] = true;
                }
            }
            const de = DesktopEntries.heuristicLookup(pinned[p]);
            if (group.length === 0 && !de) continue;
            out.push({ key: "pin:" + pin, appId: pinned[p], pinned: true, toplevels: group, entry: de });
        }

        if (!s.taskShowUnpinned) return out;

        const index = {};
        for (let i = 0; i < tls.length; i++) {
            if (used[i] || isIgnored(tls[i].appId) || !onThisScreen(tls[i])) continue;
            const id = (tls[i].appId || "?").toLowerCase();
            if (index[id] === undefined) {
                index[id] = out.length;
                out.push({ key: "run:" + id, appId: tls[i].appId, pinned: false, toplevels: [tls[i]],
                           entry: DesktopEntries.heuristicLookup(tls[i].appId) });
            } else {
                out[index[id]].toplevels.push(tls[i]);
            }
        }
        return out;
    }

    // media: the playing player, else the first one
    readonly property var player: {
        const ps = Mpris.players.values;
        let pick = null;
        for (let i = 0; i < ps.length; i++) {
            if (ps[i].isPlaying) return ps[i];
            if (!pick) pick = ps[i];
        }
        return pick;
    }
    readonly property string mediaText: player
        ? ((s.mediaShowArtist && player.trackArtist ? player.trackArtist + " - " : "") + (player.trackTitle || ""))
        : ""
    readonly property bool mediaVisible: s.showMedia && isPrimary && player !== null && mediaText !== ""
        && !(s.mediaHideWhenPaused && !player.isPlaying)

    // audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    // stats (filled by stats.sh on the primary bar)
    property string cpu: "--"
    property string mem: "--"
    property string gpu: "--"
    property string gpuTemp: ""
    property string cpuTemp: ""
    property string disk: "--"
    property string netDown: "0"
    property string netUp: "0"
    property bool batPresent: false
    property int batPct: 100
    property string batStatus: ""

    readonly property bool anyStat: s.statsCpu || s.statsCpuTemp || s.statsGpu || s.statsRam || s.statsDisk || s.statsNet
    readonly property bool showStatsPill: isPrimary && s.showStats && anyStat
    readonly property bool showBatPill: isPrimary && s.showBattery && batPresent
    readonly property bool showVolPill: isPrimary && s.showVolume
    readonly property bool anySystem: showStatsPill || showBatPill || showVolPill

    // ============================ BACKGROUND OBJECTS ============================

    PwObjectTracker {
        objects: win.sink ? [win.sink] : []
    }

    SystemClock {
        id: clock
        precision: win.s.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2")
                win.tick++;
        }
    }

    Process {
        id: statsProc
        command: ["sh", Quickshell.shellDir + "/stats.sh", win.s.statsGpu && win.s.showStats ? "gpu" : "nogpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("|");
                if (p.length < 3) return;
                win.cpu = p[0];
                win.mem = p[1];
                const g = p[2].split(",");
                win.gpu = g[0] ? g[0] : "--";
                win.gpuTemp = g[1] ? g[1] : "";
                win.cpuTemp = p[3] ? p[3] : "";
                win.disk = p[4] ? p[4] : "--";
                const nt = p[5] ? p[5].split(",") : [];
                win.netDown = nt[0] ? nt[0] : "0";
                win.netUp = nt[1] ? nt[1] : "0";
                const b = p[6] ? p[6].split(",") : [];
                win.batPresent = b.length > 0 && b[0] !== "";
                if (win.batPresent) {
                    win.batPct = parseInt(b[0]);
                    win.batStatus = b[1] ? b[1] : "";
                }
            }
        }
    }

    Timer {
        interval: Math.max(750, win.s.statsInterval)
        running: win.isPrimary && (win.s.showStats || win.s.showBattery)
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statsProc.running) statsProc.running = true
    }

    FileView {
        path: win.usePywal ? win.home + "/.cache/wal/colors.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                win.walAccent = c.colors.color4;
                win.walLoaded = true;
            } catch (e) {}
        }
    }

    // ============================ UI ============================

    Item {
        anchors.fill: parent

        // one background behind everything when islandStyle is "bar"
        Rectangle {
            anchors.fill: parent
            visible: win.s.islandStyle === "bar"
            radius: Math.min(win.s.islandRadius, height / 2)
            color: win.cBg
            border.width: win.s.borderEnabled ? win.s.borderWidth : 0
            border.color: Settings.col(win.s.borderColor, win.s.borderOpacity)
        }

        // ---------------------------- LEFT ----------------------------
        Island {
            id: leftIsland
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: win.s.itemSpacing + 2

                Pill {
                    visible: win.s.showLauncher
                    width: 34
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) Settings.toggle();
                        else win.run(win.s.launcherCmd);
                    }
                    Label { icon: true; text: "" }
                }

                Row {
                    id: wsRow
                    visible: win.s.showWorkspaces
                    height: Settings.itemH

                    Repeater {
                        model: win.wsCount
                        delegate: Item {
                            id: wsItem
                            required property int index

                            readonly property int wsId: win.wsFirst + index
                            readonly property var ws: win.findWs(wsId)
                            readonly property bool isActive: ws ? ws.active : false
                            readonly property bool occupied: ws ? ws.toplevels.values.length > 0 : false
                            readonly property bool urgent: ws ? ws.urgent : false

                            readonly property string style: win.s.wsStyle
                            readonly property int dot: win.s.wsDotSize
                            readonly property int numCell: Math.max(22, win.s.fontSize + 10)
                            readonly property int cell: style === "numbers" ? numCell : dot
                            readonly property int activeW: style === "pills" ? Math.max(dot, win.s.wsActiveWidth) : cell

                            visible: !(win.s.wsHideEmpty && !isActive && !occupied && !urgent)
                            width: visible ? (isActive ? activeW : cell) + 8 : 0
                            height: Settings.itemH
                            Behavior on width { NumberAnimation { duration: Settings.ms(220); easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                height: wsItem.style === "numbers" ? Math.min(wsItem.numCell, Settings.itemH) : wsItem.dot
                                radius: wsItem.style === "numbers" ? Math.min(win.s.pillRadius, height / 2) : height / 2
                                color: wsItem.urgent ? win.cUrgent
                                     : wsItem.isActive ? win.accent
                                     : wsItem.style === "numbers" ? "transparent"
                                     : wsItem.occupied ? Settings.col(win.s.textColor, 0.7)
                                     : Settings.col(win.s.textColor, 0.22)
                                Behavior on color { ColorAnimation { duration: Settings.ms(160) } }

                                Text {
                                    visible: wsItem.style === "numbers"
                                    anchors.centerIn: parent
                                    text: wsItem.wsId
                                    font.pixelSize: win.s.fontSize
                                    font.family: win.s.fontFamily !== "" ? win.s.fontFamily : Qt.application.font.family
                                    font.bold: wsItem.isActive
                                    color: wsItem.urgent || wsItem.isActive ? win.onAccent
                                         : wsItem.occupied ? Settings.col(win.s.textColor, 0.85)
                                         : Settings.col(win.s.textColor, 0.35)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: win.gotoWs(wsItem.wsId)
                            }
                        }
                    }

                    WheelHandler {
                        onWheel: event => win.stepWs((event.angleDelta.y > 0) !== win.s.wsScrollInvert ? "-" : "+")
                    }
                }

                Divider { visible: titleText.visible && (win.s.showLauncher || win.s.showWorkspaces) }

                Label {
                    id: titleText
                    visible: win.s.showTitle && text !== ""
                        && (!win.s.titleOnlyFocusedMonitor || (win.hyprMon !== null && win.hyprMon.focused))
                    text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
                    color: win.cDim
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, win.s.titleMaxWidth)
                    rightPadding: 6
                }
            }
        }

        // ---------------------------- CENTER (taskbar) ----------------------------
        Island {
            id: centerIsland
            active: win.s.showTaskbar && win.taskEntries.length > 0
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: win.s.itemSpacing

                Repeater {
                    model: win.taskEntries
                    delegate: Pill {
                        id: task
                        required property var modelData

                        readonly property var tls: modelData.toplevels
                        readonly property bool running: tls.length > 0
                        readonly property bool isFocused: win.anyActive(tls)

                        width: win.s.taskItemWidth
                        highlighted: isFocused
                        onClicked: mouse => win.taskClick(modelData, mouse)

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: win.s.taskIconSize
                            source: win.iconFor(task.modelData)
                            opacity: task.running ? 1.0 : 0.75
                        }

                        overlay: [
                            Rectangle {
                                visible: task.running && win.s.taskIndicator
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                height: 3
                                radius: 1.5
                                width: task.isFocused ? 14 : 5
                                color: task.isFocused ? win.accent : win.cDim
                                Behavior on width { NumberAnimation { duration: Settings.ms(160); easing.type: Easing.OutCubic } }
                            },
                            Text {
                                visible: win.s.taskBadge && task.tls.length > 1
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: 4
                                anchors.topMargin: 1
                                text: task.tls.length
                                color: win.cText
                                font.pixelSize: 10
                                font.bold: true
                            }
                        ]
                    }
                }
            }
        }

        // ---------------------------- RIGHT ----------------------------
        Island {
            id: rightIsland
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: win.s.itemSpacing

                // media: click play/pause, middle next, right previous, wheel prev/next
                Pill {
                    visible: win.mediaVisible
                    onClicked: mouse => {
                        const p = win.player;
                        if (!p) return;
                        if (mouse.button === Qt.MiddleButton) { if (p.canGoNext) p.next(); }
                        else if (mouse.button === Qt.RightButton) { if (p.canGoPrevious) p.previous(); }
                        else if (p.canTogglePlaying) p.togglePlaying();
                    }
                    onWheeled: wheel => {
                        const p = win.player;
                        if (!p) return;
                        if (wheel.angleDelta.y > 0) { if (p.canGoPrevious) p.previous(); }
                        else { if (p.canGoNext) p.next(); }
                    }

                    Row {
                        spacing: 8
                        Label { icon: true; text: win.player && win.player.isPlaying ? "" : ""; font.pixelSize: Math.max(9, Math.round(win.s.iconSize * 0.75)) }
                        Label {
                            text: win.mediaText
                            color: win.cDim
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, win.s.mediaMaxWidth)
                        }
                    }
                }

                // tray
                Repeater {
                    model: win.isPrimary && win.s.showTray ? SystemTray.items : null
                    delegate: Pill {
                        id: tray
                        required property var modelData

                        width: win.s.trayIconSize + 12
                        onClicked: mouse => {
                            const pos = tray.mapToItem(null, 0, 0);
                            if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                            } else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                                modelData.activate();
                            } else if (modelData.hasMenu) {
                                modelData.display(win, Math.round(pos.x), Math.round(pos.y));
                            }
                        }

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: win.s.trayIconSize
                            source: tray.modelData.icon
                        }
                    }
                }

                Divider { visible: (win.mediaVisible || (win.isPrimary && win.s.showTray)) && win.anySystem }

                // stats (click opens the stats app in the terminal)
                Pill {
                    visible: win.showStatsPill
                    onClicked: mouse => win.run(win.terminal + " -e " + win.s.statsApp)

                    Row {
                        spacing: win.s.statsSpacing

                        Stat {
                            visible: win.s.statsCpu
                            label: "CPU"; glyph: ""
                            value: win.cpu + "%"
                            valueColor: win.heat(win.cpu, 70, 90)
                        }
                        Stat {
                            visible: win.s.statsCpuTemp && win.cpuTemp !== ""
                            label: "TMP"; glyph: ""
                            value: win.cpuTemp + "°"
                            valueColor: win.heat(win.cpuTemp, 75, 90)
                        }
                        Stat {
                            visible: win.s.statsGpu
                            label: "GPU"; glyph: ""
                            value: win.gpu + "%" + (win.s.statsGpuTemp && win.gpuTemp !== "" ? "  " + win.gpuTemp + "°" : "")
                            valueColor: win.heat(win.gpu, 80, 95)
                        }
                        Stat {
                            visible: win.s.statsRam
                            label: "RAM"; glyph: ""
                            value: win.mem + "G"
                        }
                        Stat {
                            visible: win.s.statsDisk
                            label: "DSK"; glyph: ""
                            value: win.disk + "%"
                            valueColor: win.heat(win.disk, 85, 95)
                        }
                        Stat {
                            visible: win.s.statsNet
                            label: "NET"; glyph: ""
                            value: "↓" + win.rate(win.netDown) + " ↑" + win.rate(win.netUp)
                        }
                    }
                }

                // battery (only where one exists)
                Pill {
                    visible: win.showBatPill
                    onClicked: mouse => win.run(win.terminal + " -e " + win.s.statsApp)

                    Row {
                        spacing: 8
                        Label { icon: true; text: win.batGlyph(); color: win.batColor() }
                        Label {
                            visible: win.s.batShowPercent
                            text: win.batPct + "%"
                            color: win.batColor()
                        }
                    }
                }

                // volume: click mute, right click mixer, wheel changes volume
                Pill {
                    visible: win.showVolPill
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            win.run(win.s.mixerCmd);
                        } else if (win.sink && win.sink.audio) {
                            win.sink.audio.muted = !win.sink.audio.muted;
                        }
                    }
                    onWheeled: wheel => win.bumpVolume((wheel.angleDelta.y > 0 ? 1 : -1) * win.s.volStep / 100)

                    Row {
                        spacing: 8
                        Label { icon: true; text: win.volGlyph(); color: win.muted ? win.cDim : win.cText }
                        Label {
                            visible: win.s.volShowPercent
                            text: win.muted ? "muted" : Math.round(win.vol * 100) + "%"
                            color: win.muted ? win.cDim : win.cText
                        }
                    }
                }

                Divider { visible: win.s.showClock && win.anySystem }

                // clock: click toggles the notification center
                Pill {
                    visible: win.s.showClock
                    onClicked: mouse => win.run(win.s.notifCmd)

                    Row {
                        spacing: 8
                        Label {
                            visible: win.s.clockShowDate
                            text: Qt.formatDateTime(clock.date, win.s.clockDateFormat)
                            color: win.cDim
                        }
                        Label {
                            text: Qt.formatDateTime(clock.date, win.s.clock24
                                ? (win.s.clockSeconds ? "HH:mm:ss" : "HH:mm")
                                : (win.s.clockSeconds ? "h:mm:ss AP" : "h:mm AP"))
                            font.bold: win.s.clockBold
                        }
                    }
                }

                // settings: opens the settings panel
                Pill {
                    visible: win.isPrimary && win.s.showSettingsButton
                    width: 34
                    highlighted: Settings.open
                    onClicked: mouse => Settings.toggle()
                    Label { icon: true; text: ""; color: win.cDim }
                }

                // power: click lock, right click power menu
                Pill {
                    visible: win.isPrimary && win.s.showPower
                    width: 34
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Quickshell.execDetached(["sh", Quickshell.shellDir + "/power-menu.sh"]);
                        else
                            win.run(win.s.lockCmd);
                    }
                    Label { icon: true; text: "" }
                }
            }
        }
    }
}
