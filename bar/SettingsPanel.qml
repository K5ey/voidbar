import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Full-screen click-catcher with the settings card in the middle. One instance, on the focused monitor.
PanelWindow {
    id: win

    property var targetScreen: Quickshell.screens[0]
    property real fade: Settings.open ? 1 : 0
    Behavior on fade { NumberAnimation { duration: Settings.ms(160); easing.type: Easing.OutCubic } }

    screen: targetScreen
    visible: Settings.open || fade > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qsbar-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Settings.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Settings
        function onOpenChanged() {
            if (!Settings.open) return;
            const fm = Hyprland.focusedMonitor;
            if (fm) {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    if (Quickshell.screens[i].name === fm.name) { win.targetScreen = Quickshell.screens[i]; break; }
                }
            }
        }
    }

    // dim a little, but keep the bar visible so changes can be watched live
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.18 * win.fade
        MouseArea { anchors.fill: parent; onClicked: Settings.open = false }
    }

    SettingsView {
        anchors.centerIn: parent
        width: Math.min(960, parent.width - 48)
        height: Math.min(660, parent.height - 48)
        opacity: win.fade
        scale: 0.97 + 0.03 * win.fade
        onCloseRequested: Settings.open = false
        // swallow clicks so they don't hit the click-catcher behind
        MouseArea { anchors.fill: parent; z: -1 }
    }
}
