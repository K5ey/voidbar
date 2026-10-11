#!/bin/sh
# Power menu in wofi. Works with elogind (Artix) or systemd; falls back to plain commands.
choice=$(printf 'Lock\nLogout\nSuspend\nReboot\nShutdown\n' | wofi --dmenu --prompt power 2>/dev/null) || exit 0

case "$choice" in
    Lock)     hyprlock ;;
    Logout)   [ "$(hyprctl dispatch 'hl.dsp.exit()' 2>&1)" = ok ] || hyprctl dispatch exit ;;
    Suspend)  loginctl suspend 2>/dev/null || zzz 2>/dev/null || systemctl suspend ;;
    Reboot)   loginctl reboot 2>/dev/null || reboot ;;
    Shutdown) loginctl poweroff 2>/dev/null || poweroff ;;
esac
