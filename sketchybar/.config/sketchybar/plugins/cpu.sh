#!/usr/bin/env bash
# CPU load %, coloured when hot.
source "$(dirname "$0")/../colors.sh"
CPU="$(top -l 1 -n 0 | awk -F'[ %]+' '/CPU usage/ {print int($3 + $5)}')"
[ -z "$CPU" ] && CPU=0

if   [ "$CPU" -ge 80 ]; then COLOR=$RED
elif [ "$CPU" -ge 50 ]; then COLOR=$YELLOW
else COLOR=$GREEN; fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${CPU}%"
