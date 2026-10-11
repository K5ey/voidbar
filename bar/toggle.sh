#!/bin/sh
# Toggle the bar on/off (SUPER+SHIFT+B). The [b] trick stops pgrep/pkill matching this script.
if pgrep -f 'quickshell.*[b]ar/shell.qml' >/dev/null; then
    pkill -f 'quickshell.*[b]ar/shell.qml'
else
    quickshell -p "$(dirname "$0")/shell.qml" >/dev/null 2>&1 &
fi
