pragma Singleton
// Palette of the settings panel (the bar itself uses Settings.c colours).
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: "#15171c"
    readonly property color bg2: "#1b1e25"
    readonly property color bg3: "#262a34"
    readonly property color line: "#1fffffff"
    readonly property color text: "#eceef3"
    readonly property color dim: "#8e93a3"
    readonly property color danger: "#ff6b6b"

    readonly property color accent: Settings.col(Settings.c.accent)
    readonly property real lum: 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b
    readonly property color onAccent: lum > 0.6 ? "#15171c" : "#ffffff"
}
