import QtQuick
import Quickshell

// The settings UI. Pages, sections and rows are plain data (`schema`), so adding an option is one line.
Rectangle {
    id: root

    signal closeRequested()

    width: 960
    height: 660
    radius: 18
    color: Pal.bg
    border.width: 1
    border.color: "#2effffff"
    clip: true

    // ---------------------------- schema ----------------------------
    readonly property var pages: [
        { id: "layout",     label: "Layout" },
        { id: "appearance", label: "Appearance" },
        { id: "modules",    label: "Modules" },
        { id: "workspaces", label: "Workspaces" },
        { id: "apps",       label: "Taskbar & title" },
        { id: "media",      label: "Media & tray" },
        { id: "system",     label: "System" },
        { id: "clock",      label: "Clock" },
        { id: "behaviour",  label: "Behaviour" }
    ]

    readonly property var screenOpts: {
        const out = [];
        const seen = {};
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const n = Quickshell.screens[i].name;
            out.push([n, n]);
            seen[n] = true;
        }
        const cur = Settings.c.primaryName;
        if (cur && !seen[cur]) out.push([cur + " (offline)", cur]);
        return out;
    }

    readonly property var darkSwatches: ["#000000", "#05060a", "#111318", "#1a1b26", "#1e1e2e", "#282a36", "#2e3440", "#f4f1ea"]
    readonly property var lightSwatches: ["#ffffff", "#f2f2f5", "#e6e9f2", "#cdd6f4", "#ebdbb2", "#d3c6aa", "#2b2b30", "#000000"]
    readonly property var accentSwatches: ["#ffffff", "#7aa2ff", "#cba6f7", "#a6e3a1", "#fab387", "#f38ba8", "#f9e2af", "#94e2d5"]
    readonly property var urgentSwatches: ["#ff6b6b", "#f38ba8", "#ff5555", "#fb4934", "#ff4d5e", "#eb6f92", "#e67e80", "#d6336c"]
    readonly property var warnSwatches: ["#ffb454", "#f9e2af", "#fabd2f", "#e5c07b", "#ff9e64", "#f6c177", "#dbbc7f", "#ffd43b"]

    function tg(k, title, desc, extra) { return Object.assign({ k: k, t: "toggle", title: title, desc: desc || "" }, extra || {}); }
    function sl(k, title, desc, min, max, step, unit, extra) { return Object.assign({ k: k, t: "slider", title: title, desc: desc || "", min: min, max: max, step: step, unit: unit || "" }, extra || {}); }
    function ch(k, title, desc, opts, extra) { return Object.assign({ k: k, t: "choice", title: title, desc: desc || "", opts: opts }, extra || {}); }
    function co(k, title, desc, swatches, extra) { return Object.assign({ k: k, t: "color", title: title, desc: desc || "", swatches: swatches }, extra || {}); }
    function tx(k, title, desc, extra) { return Object.assign({ k: k, t: "text", title: title, desc: desc || "" }, extra || {}); }

    readonly property var schema: [
        // ============ layout ============
        { page: "layout", title: "Position & size", rows: [
            ch("position", "Position", "Top or bottom of the screen. SUPER+ALT+B also flips it.", [["Top", "top"], ["Bottom", "bottom"]]),
            sl("height", "Height", "Bar height in pixels.", 28, 80, 1, " px"),
            sl("edgeMargin", "Edge gap", "Space between the bar and the screen edge.", 0, 40, 1, " px"),
            sl("sideMargin", "Side gap", "Space left and right. Keep it equal to gaps_out in your Hyprland config.", 0, 60, 1, " px"),
            tg("reserveSpace", "Reserve space", "Windows stay out from under the bar. Off = the bar floats over them."),
            sl("exclusiveExtra", "Reserved space tweak", "Nudge the reserved zone if the gap below the bar looks off.", -20, 40, 1, " px", { dep: "reserveSpace" })
        ]},
        { page: "layout", title: "Shape", rows: [
            ch("islandStyle", "Style", "Separate floating islands, or one bar across the whole width.", [["Islands", "islands"], ["One bar", "bar"]]),
            sl("islandRadius", "Island corner radius", "", 0, 30, 1, " px"),
            sl("pillRadius", "Button corner radius", "Hover highlight shape of every button.", 0, 20, 1, " px"),
            sl("islandPadding", "Island padding", "Inner padding of each island.", 0, 16, 1, " px"),
            sl("itemSpacing", "Item spacing", "Gap between buttons.", 0, 16, 1, " px")
        ]},
        { page: "layout", title: "Monitors", rows: [
            ch("primaryName", "Primary monitor", "Gets the tray, stats, battery, volume, media and power button. Others get launcher, workspaces, taskbar and clock.", "screens"),
            tg("primaryOnly", "Primary monitor only", "Don't show the bar on other monitors at all.")
        ]},

        // ============ appearance ============
        { page: "appearance", title: "Theme presets", rows: [
            { t: "presets", title: "Presets", desc: "Sets background, text, accent and urgent colours in one click. Fine-tune below afterwards.", stacked: true }
        ]},
        { page: "appearance", title: "Colours", rows: [
            co("bgColor", "Background", "Island colour.", darkSwatches),
            sl("bgOpacity", "Background opacity", "Lower = more see-through. Blur comes from your Hyprland layer rule for qsbar.", 0, 100, 1, " %", { mul: 100 }),
            co("textColor", "Text", "", lightSwatches),
            sl("dimOpacity", "Dim text", "Opacity of secondary text (window title, date, media).", 20, 100, 1, " %", { mul: 100 }),
            co("accent", "Accent", "Active workspace, focused app, toggles in this panel.", accentSwatches, { depNot: "pywal" }),
            tg("pywal", "Accent from pywal", "Follow color4 in ~/.cache/wal/colors.json."),
            co("urgentColor", "Urgent", "Urgent workspace, low battery, muted states.", urgentSwatches),
            co("warnColor", "Warning", "Hot CPU/GPU, medium battery.", warnSwatches),
            sl("hoverOpacity", "Hover strength", "How strong the button hover highlight is.", 0, 50, 1, " %", { mul: 100 })
        ]},
        { page: "appearance", title: "Border", rows: [
            tg("borderEnabled", "Border", "Thin outline around the islands."),
            sl("borderWidth", "Border width", "", 1, 4, 1, " px", { dep: "borderEnabled" }),
            co("borderColor", "Border colour", "", accentSwatches, { dep: "borderEnabled" }),
            sl("borderOpacity", "Border opacity", "", 0, 100, 1, " %", { mul: 100, dep: "borderEnabled" })
        ]},
        { page: "appearance", title: "Typography", rows: [
            tx("fontFamily", "Font", "Family name, e.g. Inter or JetBrains Mono. Empty = system default."),
            sl("fontSize", "Font size", "", 10, 20, 1, " px"),
            tx("iconFont", "Icon font", "Needs to be a Nerd Font symbols font."),
            sl("iconSize", "Icon size", "Glyph size of launcher, volume, power and media buttons.", 10, 26, 1, " px")
        ]},

        // ============ modules ============
        { page: "modules", title: "Left island", rows: [
            tg("showLauncher", "Launcher button", "Left click opens the launcher. Right click opens these settings."),
            tg("showWorkspaces", "Workspaces", ""),
            tg("showTitle", "Window title", "Title of the focused window.")
        ]},
        { page: "modules", title: "Centre island", rows: [
            tg("showTaskbar", "Taskbar", "Pinned and running apps.")
        ]},
        { page: "modules", title: "Right island", rows: [
            tg("showMedia", "Media", "Current track, only while a player exists."),
            tg("showTray", "System tray", ""),
            tg("showStats", "System stats", "CPU, GPU, RAM and friends."),
            tg("showBattery", "Battery", "Hidden automatically on machines without a battery."),
            tg("showVolume", "Volume", ""),
            tg("showClock", "Clock", ""),
            tg("showPower", "Power button", "Click locks, right click opens the power menu."),
            tg("showSettingsButton", "Settings button", "If you hide this, reopen settings with a right click on the launcher or: toggle-settings.sh")
        ]},

        // ============ workspaces ============
        { page: "workspaces", title: "Workspaces", rows: [
            sl("wsCount", "Count per monitor", "Workspace ids still start at 1 on DP-3 and 6 on HDMI-A-1, keep the count at 5 or lower to avoid overlap.", 1, 10, 1, ""),
            ch("wsStyle", "Style", "", [["Pills", "pills"], ["Dots", "dots"], ["Numbers", "numbers"]]),
            tg("wsHideEmpty", "Hide empty workspaces", "Only show workspaces that have windows, plus the active one."),
            sl("wsDotSize", "Size", "", 6, 24, 1, " px"),
            sl("wsActiveWidth", "Active pill width", "Width of the active workspace (pills style).", 10, 50, 1, " px", { dep: "isPills" }),
            tg("wsScrollInvert", "Invert scroll direction", "Mouse wheel over the workspaces switches workspace.")
        ]},

        // ============ apps ============
        { page: "apps", title: "Taskbar", rows: [
            sl("taskIconSize", "Icon size", "", 14, 40, 1, " px"),
            sl("taskItemWidth", "Button width", "", 28, 70, 1, " px"),
            tg("taskIndicator", "Running indicator", "Small bar under apps that are running."),
            tg("taskBadge", "Window count badge", "Number on apps with several windows."),
            tg("taskShowUnpinned", "Show unpinned apps", "Running apps that aren't pinned."),
            { t: "pinned", title: "Pinned apps", desc: "App ids, in order. Find an id with: hyprctl clients | grep class. Pinned apps that aren't installed or running stay hidden.", stacked: true }
        ]},
        { page: "apps", title: "Window title", rows: [
            sl("titleMaxWidth", "Max width", "Longer titles are cut off with an ellipsis.", 80, 700, 10, " px"),
            tg("titleOnlyFocusedMonitor", "Only on the focused monitor", "")
        ]},

        // ============ media ============
        { page: "media", title: "Media", rows: [
            sl("mediaMaxWidth", "Max width", "", 80, 500, 10, " px"),
            tg("mediaShowArtist", "Show artist", ""),
            tg("mediaHideWhenPaused", "Hide when paused", "")
        ]},
        { page: "media", title: "Tray", rows: [
            sl("trayIconSize", "Icon size", "", 12, 32, 1, " px")
        ]},

        // ============ system ============
        { page: "system", title: "Stats", rows: [
            tg("statsCpu", "CPU usage", ""),
            tg("statsCpuTemp", "CPU temperature", "Reads hwmon / thermal zones."),
            tg("statsGpu", "GPU usage", "NVIDIA only (nvidia-smi)."),
            tg("statsGpuTemp", "GPU temperature", "", { dep: "statsGpu" }),
            tg("statsRam", "RAM used", ""),
            tg("statsDisk", "Disk usage", "Root filesystem."),
            tg("statsNet", "Network speed", "Down / up of the default interface."),
            ch("statsStyle", "Labels", "", [["Text", "labels"], ["Icons", "icons"]]),
            sl("statsSpacing", "Spacing", "", 4, 30, 1, " px"),
            sl("statsInterval", "Refresh interval", "Faster refresh costs a little CPU.", 750, 10000, 250, " ms"),
            tx("statsApp", "Click opens", "Run in your terminal, e.g. btop or htop.", { mono: true })
        ]},
        { page: "system", title: "Battery", rows: [
            tg("batShowPercent", "Show percentage", ""),
            sl("batWarnAt", "Warn below", "Battery turns the warning colour here, urgent at half of it.", 5, 60, 1, " %")
        ]},
        { page: "system", title: "Volume", rows: [
            sl("volStep", "Scroll step", "", 1, 20, 1, " %"),
            sl("volMax", "Maximum", "Above 100% boosts the volume.", 50, 150, 5, " %"),
            tg("volShowPercent", "Show percentage", "")
        ]},

        // ============ clock ============
        { page: "clock", title: "Clock", rows: [
            tg("clock24", "24 hour time", ""),
            tg("clockSeconds", "Show seconds", "Updates every second."),
            tg("clockBold", "Bold time", ""),
            tg("clockShowDate", "Show date", ""),
            tx("clockDateFormat", "Date format", "Qt format: ddd d MMM, dd.MM.yyyy, dddd d MMMM ...", { dep: "clockShowDate", mono: true })
        ]},

        // ============ behaviour ============
        { page: "behaviour", title: "Animation", rows: [
            tg("animations", "Animations", "Workspace pills, hover fades, indicators."),
            sl("animSpeed", "Duration", "Lower is faster.", 0.3, 3, 0.1, "x", { dec: 1, dep: "animations" })
        ]},
        { page: "behaviour", title: "Commands", rows: [
            tx("terminal", "Terminal", "", { mono: true }),
            tx("launcherCmd", "Launcher", "Run by the launcher button.", { mono: true }),
            tx("notifCmd", "Notification centre", "Run by clicking the clock.", { mono: true }),
            tx("lockCmd", "Lock screen", "Run by the power button.", { mono: true }),
            tx("mixerCmd", "Volume mixer", "Run by right clicking the volume.", { mono: true })
        ]},
        { page: "behaviour", title: "Config file", rows: [
            { t: "buttons", title: "settings.json", desc: "Everything here is saved to settings.json next to the bar and reloads live, so you can also edit it by hand or keep it in your dotfiles.", stacked: true }
        ]}
    ]

    function pageKeys(id) {
        const keys = [];
        for (let i = 0; i < schema.length; i++) {
            if (schema[i].page !== id) continue;
            for (let j = 0; j < schema[i].rows.length; j++)
                if (schema[i].rows[j].k) keys.push(schema[i].rows[j].k);
        }
        return keys;
    }

    function pageLabel(id) {
        for (let i = 0; i < pages.length; i++) if (pages[i].id === id) return pages[i].label;
        return "";
    }

    // ---------------------------- layout ----------------------------
    Item {
        id: keyItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()

        Connections {
            target: Settings
            function onRefocus() { keyItem.forceActiveFocus(); }
            function onOpenChanged() { if (Settings.open) keyItem.forceActiveFocus(); }
        }

        // sidebar
        Rectangle {
            id: side
            width: 200
            height: parent.height
            color: Pal.bg2

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Pal.line }

            Column {
                x: 16
                y: 20
                width: parent.width - 32
                spacing: 4

                Text { text: "Bar settings"; color: Pal.text; font.pixelSize: 17; font.bold: true }
                Text { text: "changes apply live"; color: Pal.dim; font.pixelSize: 11; bottomPadding: 12 }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: Pal.bg3
                    border.width: 1
                    border.color: search.activeFocus ? Pal.accent : "transparent"

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 24
                        verticalAlignment: TextInput.AlignVCenter
                        color: Pal.text
                        selectionColor: Pal.accent
                        selectedTextColor: Pal.onAccent
                        font.pixelSize: 12
                        clip: true
                        onTextChanged: Settings.query = text.trim().toLowerCase()
                        Keys.onEscapePressed: event => {
                            if (text !== "") { text = ""; event.accepted = true; }
                            else { focus = false; Settings.refocus(); event.accepted = true; }
                        }
                    }
                    Text {
                        anchors.fill: search
                        verticalAlignment: Text.AlignVCenter
                        visible: search.text === "" && !search.activeFocus
                        text: "Search settings"
                        color: Pal.dim
                        font.pixelSize: 12
                    }
                    Text {
                        visible: search.text !== ""
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: Pal.dim
                        font.pixelSize: 11
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: search.text = "" }
                    }
                }

                Item { width: 1; height: 8 }

                Repeater {
                    model: root.pages
                    delegate: Rectangle {
                        id: nav
                        required property var modelData
                        readonly property bool sel: Settings.query === "" && Settings.page === modelData.id

                        width: parent.width
                        height: 32
                        radius: 8
                        color: sel ? "#1fffffff" : navMa.containsMouse ? "#12ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: Settings.ms(100) } }

                        Rectangle {
                            visible: nav.sel
                            width: 3
                            height: 14
                            radius: 1.5
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            color: Pal.accent
                        }
                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: nav.modelData.label
                            color: nav.sel ? Pal.text : "#b4b8c6"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: navMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { search.text = ""; Settings.page = nav.modelData.id; flick.contentY = 0; }
                        }
                    }
                }
            }
        }

        // content
        Item {
            id: main
            anchors.left: side.right
            anchors.right: parent.right
            height: parent.height

            // header
            Item {
                id: header
                width: parent.width
                height: 62

                Text {
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: Settings.query !== "" ? "Search results" : root.pageLabel(Settings.page)
                    color: Pal.text
                    font.pixelSize: 20
                    font.bold: true
                }
                SButton {
                    visible: Settings.query === ""
                    anchors.right: parent.right
                    anchors.rightMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset page"
                    onClicked: Settings.resetKeys(root.pageKeys(Settings.page))
                }
            }

            Flickable {
                id: flick
                y: header.height
                width: parent.width
                height: parent.height - header.height - footer.height
                contentWidth: width
                contentHeight: col.height + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 4000
                maximumFlickVelocity: 2500

                Column {
                    id: col
                    x: 28
                    width: flick.width - 56
                    spacing: 0

                    Repeater {
                        model: root.schema
                        delegate: SSection {
                            id: sec
                            required property var modelData
                            title: modelData.title
                            page: modelData.page

                            Repeater {
                                model: sec.modelData.rows
                                delegate: SRow {
                                    id: srow
                                    required property var modelData
                                    title: modelData.title
                                    desc: modelData.desc || ""
                                    keywords: modelData.k || ""
                                    stacked: modelData.stacked === true
                                    enabled: {
                                        const d = modelData.dep, n = modelData.depNot;
                                        if (d === "isPills") return Settings.c.wsStyle === "pills";
                                        if (d) return Settings.c[d] === true;
                                        if (n) return Settings.c[n] !== true;
                                        return true;
                                    }

                                    Loader {
                                        sourceComponent: {
                                            switch (srow.modelData.t) {
                                            case "toggle":  return cToggle;
                                            case "slider":  return cSlider;
                                            case "choice":  return cChoice;
                                            case "color":   return cColor;
                                            case "text":    return cText;
                                            case "presets": return cPresets;
                                            case "pinned":  return cPinned;
                                            case "buttons": return cButtons;
                                            }
                                            return null;
                                        }
                                        onLoaded: {
                                            item.row = srow.modelData;
                                            if (srow.stacked) item.fullWidth = Qt.binding(() => srow.width);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // scrollbar
                Rectangle {
                    visible: flick.contentHeight > flick.height
                    x: flick.width - 8
                    y: 4 + (flick.height - 8 - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
                    width: 4
                    height: Math.max(30, (flick.height - 8) * flick.height / flick.contentHeight)
                    radius: 2
                    color: "#33ffffff"
                }
            }

            // footer
            Rectangle {
                id: footer
                anchors.bottom: parent.bottom
                width: parent.width
                height: 54
                color: Pal.bg

                Rectangle { width: parent.width; height: 1; color: Pal.line }

                Text {
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Esc to close"
                    color: Pal.dim
                    font.pixelSize: 11
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    SButton {
                        id: resetAll
                        property bool armed: false
                        text: armed ? "Really reset everything?" : "Reset all"
                        danger: true
                        onClicked: {
                            if (armed) { Settings.reset(); armed = false; }
                            else { armed = true; armTimer.restart(); }
                        }
                        Timer { id: armTimer; interval: 3000; onTriggered: resetAll.armed = false }
                    }
                    SButton { text: "Close"; primary: true; onClicked: root.closeRequested() }
                }
            }
        }
    }

    // ---------------------------- row controls ----------------------------
    Component {
        id: cToggle
        SToggle {
            property var row
            checked: row ? Settings.c[row.k] === true : false
            onToggled: v => Settings.set(row.k, v)
        }
    }

    Component {
        id: cSlider
        SSlider {
            property var row
            readonly property real mul: row && row.mul ? row.mul : 1
            from: row ? row.min : 0
            to: row ? row.max : 1
            stepSize: row ? row.step : 1
            unit: row ? row.unit : ""
            decimals: row && row.dec ? row.dec : 0
            value: row ? Settings.c[row.k] * mul : 0
            onMoved: v => Settings.set(row.k, Number((v / mul).toFixed(4)))
        }
    }

    Component {
        id: cChoice
        SChoice {
            property var row
            model: {
                if (!row) return [];
                const o = row.opts === "screens" ? root.screenOpts : row.opts;
                return o.map(x => ({ label: x[0], value: x[1] }));
            }
            current: row ? Settings.c[row.k] : undefined
            onPicked: v => Settings.set(row.k, v)
        }
    }

    Component {
        id: cColor
        SColor {
            property var row
            swatches: row ? row.swatches : []
            value: row ? String(Settings.c[row.k]) : "#ffffff"
            onPicked: hex => Settings.set(row.k, hex)
        }
    }

    Component {
        id: cText
        STextField {
            property var row
            width: row && row.mono ? 260 : 220
            mono: row ? row.mono === true : false
            value: row ? String(Settings.c[row.k]) : ""
            onCommitted: t => Settings.set(row.k, t)
        }
    }

    Component {
        id: cPresets
        Flow {
            property var row
            property real fullWidth: 400
            width: fullWidth
            spacing: 8

            Repeater {
                model: Settings.presets
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool sel: Settings.c.bgColor === modelData.bg
                        && Settings.c.accent === modelData.accent && Settings.c.textColor === modelData.text

                    width: 134
                    height: 40
                    radius: 10
                    color: Settings.col(modelData.bg, 1)
                    border.width: sel ? 2 : 1
                    border.color: sel ? Settings.col(modelData.accent) : "#33ffffff"
                    scale: prMa.containsMouse ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: Settings.ms(100) } }

                    Rectangle {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 8
                        radius: 4
                        color: Settings.col(pr.modelData.accent)
                    }
                    Rectangle {
                        x: 34
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: Settings.col(pr.modelData.urgent)
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: pr.modelData.name
                        color: Settings.col(pr.modelData.text)
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: prMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.applyPreset(pr.modelData)
                    }
                }
            }
        }
    }

    Component {
        id: cPinned
        Column {
            property var row
            property real fullWidth: 400
            width: fullWidth
            spacing: 6

            Repeater {
                model: Settings.c.pinned
                delegate: Rectangle {
                    id: pin
                    required property int index
                    required property string modelData

                    width: parent.width
                    height: 32
                    radius: 8
                    color: Pal.bg3

                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: pin.modelData
                        color: Pal.text
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: [
                                { g: "↑", d: -1 },
                                { g: "↓", d: 1 },
                                { g: "✕", d: 0 }
                            ]
                            delegate: Rectangle {
                                id: btn
                                required property var modelData
                                width: 24
                                height: 24
                                radius: 6
                                color: bMa.containsMouse ? "#2effffff" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: btn.modelData.g
                                    color: btn.modelData.d === 0 ? Pal.danger : Pal.dim
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: bMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (btn.modelData.d === 0) Settings.removePinned(pin.index);
                                        else Settings.movePinned(pin.index, btn.modelData.d);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 8
                STextField {
                    id: addField
                    width: 260
                    mono: true
                    placeholder: "app id, e.g. org.mozilla.firefox"
                    onCommitted: t => { Settings.addPinned(t); value = ""; }
                }
                SButton {
                    text: "Add"
                    onClicked: { Settings.addPinned(addField.value); }
                }
            }
        }
    }

    Component {
        id: cButtons
        Row {
            property var row
            property real fullWidth: 400
            spacing: 8
            SButton {
                text: "Open settings.json"
                onClicked: Quickshell.execDetached(["sh", "-c", "xdg-open \"$1\"", "sh", Quickshell.shellDir + "/settings.json"])
            }
            SButton {
                text: "Copy path"
                onClicked: Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | { wl-copy 2>/dev/null || xclip -selection clipboard; }", "sh", Quickshell.shellDir + "/settings.json"])
            }
        }
    }
}
