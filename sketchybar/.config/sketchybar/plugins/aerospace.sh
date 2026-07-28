#!/usr/bin/env bash
# Workspace indicator updater — runs ONCE per event (not once per item).
#
# Three visual states per workspace (Hyprland/Omarchy waybar behaviour):
#   focused          -> solid accent pill, dark glyph
#   occupied (has windows, not focused) -> visible, normal text colour
#   empty + unfocused -> hidden entirely
#
# Subscribed via the hidden `aerospace_listener` item to
# aerospace_workspace_change (instant focus highlight) plus a slow routine
# poll (catches windows opening/closing/moving). All 10 items are updated in
# one batched `sketchybar --set ... --set ...` call: one IPC round-trip, one
# redraw — this is what keeps workspace switching snappy. The old layout
# (each item subscribed with its own script) spawned 10 shells and ~20
# serialized `aerospace` CLI queries per switch, which is where the lag was.
export PATH="/opt/homebrew/bin:$PATH"
source "$(dirname "$0")/../colors.sh"

# FOCUSED_WORKSPACE is set by the trigger; empty on poll/initial load, so fall
# back to querying AeroSpace directly.
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

# Workspaces that currently contain at least one window.
OCCUPIED="$(aerospace list-workspaces --monitor all --empty no)"

args=()
for sid in $(aerospace list-workspaces --all); do
  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set "space.$sid"
      drawing=on
      background.drawing=on
      background.color="$ACCENT"
      icon.color=0xff1e1e2e)
  elif grep -qx "$sid" <<<"$OCCUPIED"; then
    args+=(--set "space.$sid"
      drawing=on
      background.drawing=off
      icon.color="$FG")
  else
    args+=(--set "space.$sid" drawing=off)
  fi
done

sketchybar "${args[@]}"
