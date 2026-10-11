#!/bin/sh
# Open / close the settings panel (bind it, e.g. SUPER+ALT+S). Needs the bar running.
dir="$(cd "$(dirname "$0")" && pwd)"
quickshell ipc --path "$dir/shell.qml" call settings toggle 2>/dev/null \
    || quickshell -p "$dir/shell.qml" ipc call settings toggle
