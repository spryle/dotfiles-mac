#!/usr/bin/env bash
# Per-workspace indicator. Arg $1 = this item's workspace id.
#
# Three visual states (Hyprland/Omarchy waybar behaviour):
#   focused          -> solid accent pill, dark glyph
#   occupied (has windows, not focused) -> visible, normal text colour
#   empty + unfocused -> hidden entirely
#
# Runs on the aerospace_workspace_change trigger (instant focus highlight) and
# on a short update_freq poll (catches windows opening/closing/moving).
export PATH="/opt/homebrew/bin:$PATH"
source "$(dirname "$0")/../colors.sh"

SID="$1"

# FOCUSED_WORKSPACE is set by the trigger; empty on poll/initial load, so fall
# back to querying AeroSpace directly.
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

# Workspaces that currently contain at least one window.
OCCUPIED="$(aerospace list-workspaces --monitor all --empty no)"
is_occupied=0
for w in $OCCUPIED; do
  [ "$w" = "$SID" ] && is_occupied=1 && break
done

if [ "$SID" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    background.drawing=on \
    background.color="$ACCENT" \
    icon.color=0xff1e1e2e
elif [ "$is_occupied" = 1 ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    background.drawing=off \
    icon.color="$FG"
else
  sketchybar --set "$NAME" drawing=off
fi
