#!/bin/sh
# Flip the bar between top and bottom (SUPER+ALT+B). Edits settings.json in place; the bar reloads live.
f="$(dirname "$0")/settings.json"
[ -f "$f" ] || echo '{ "position": "top" }' > "$f"
if grep -q '"position": *"top"' "$f"; then new=bottom; else new=top; fi
sed "s/\"position\": *\"[a-z]*\"/\"position\": \"$new\"/" "$f" > "$f.tmp" && cat "$f.tmp" > "$f" && rm -f "$f.tmp"
