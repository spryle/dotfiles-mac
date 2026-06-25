#!/usr/bin/env bash
# Shows a "RESIZE" pill while AeroSpace is in resize mode, hidden otherwise.
# $MODE comes from the aerospace_mode_change trigger (see aerospace.toml).
source "$(dirname "$0")/../colors.sh"

if [ "$MODE" = "resize" ]; then
  sketchybar --set "$NAME" drawing=on label="RESIZE"
else
  sketchybar --set "$NAME" drawing=off
fi
