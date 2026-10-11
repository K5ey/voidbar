#!/bin/sh
# Usage: stats.sh [gpu|nogpu]
# Prints: cpu%|ram GiB|gpu util,gpu temp|cpu temp C|disk %|rx,tx bytes/s|battery %,status
# Empty parts are fine (no nvidia-smi, no battery, ...).
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
sleep 0.4
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat

idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( (u2 + n2 + s2 + i2 + w2 + q2 + sq2 + st2) - (u1 + n1 + s1 + i1 + w1 + q1 + sq1 + st1) ))
if [ "$total" -gt 0 ]; then
    cpu=$(( (100 * (total - idle)) / total ))
else
    cpu=0
fi

mem=$(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{printf "%.1f", (t-a)/1048576}' /proc/meminfo)

gpu=
if [ "$1" != nogpu ]; then
    gpu=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
fi

# CPU temperature: k10temp / coretemp / zenpower first, then thermal_zone0
cputemp=
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|coretemp|zenpower|cpu_thermal)
            t=$(cat "$h/temp1_input" 2>/dev/null) && cputemp=$(( t / 1000 )) && break ;;
    esac
done
if [ -z "$cputemp" ] && [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) && cputemp=$(( t / 1000 ))
fi

disk=$(df -P / 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')

# network: bytes/s of the default interface, from the delta since the last run
net=
iface=$(awk '$2=="00000000"{print $1; exit}' /proc/net/route 2>/dev/null)
if [ -n "$iface" ]; then
    state="${XDG_RUNTIME_DIR:-/tmp}/qsbar-net"
    read -r up _ < /proc/uptime
    cur=$(awk -v i="$iface:" '$1==i{print $2, $10}' /proc/net/dev)
    if [ -n "$cur" ]; then
        if [ -r "$state" ]; then
            net=$(echo "$up $cur" | awk -v prev="$(cat "$state")" '
                BEGIN { split(prev, p, " ") }
                { dt = $1 - p[1]; if (dt > 0) printf "%d,%d", ($2 - p[2]) / dt, ($3 - p[3]) / dt }')
        fi
        echo "$up $cur" > "$state"
    fi
fi

bat=
for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] || continue
    bat="$(cat "$b/capacity"),$(cat "$b/status" 2>/dev/null)"
    break
done

echo "$cpu|$mem|$gpu|$cputemp|$disk|$net|$bat"
