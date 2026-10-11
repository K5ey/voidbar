//@ pragma UseQApplication
// voidbar: floating glass islands for Hyprland.
// Run:  quickshell -p ~/.config/hypr/bar/shell.qml
// Settings: click the gear (or right-click the launcher button, or run toggle-settings.sh).
// They live in settings.json next to this file; defaults and schema are in Settings.qml / SettingsView.qml.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    SettingsPanel {}
}
