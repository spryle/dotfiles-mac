#!/usr/bin/env bash
# CPU load %, coloured when hot.
source "$(dirname "$0")/../colors.sh"
# Sum per-process %CPU via ps (~25ms) rather than top (~900ms of mostly sys time).
CPU="$(ps -A -o %cpu | awk -v n="$(sysctl -n hw.ncpu)" 'NR>1 {s+=$1} END {c=int(s/n); if (c>100) c=100; print c}')"
[ -z "$CPU" ] && CPU=0

if   [ "$CPU" -ge 80 ]; then COLOR=$RED
elif [ "$CPU" -ge 50 ]; then COLOR=$YELLOW
else COLOR=$GREEN; fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${CPU}%"
