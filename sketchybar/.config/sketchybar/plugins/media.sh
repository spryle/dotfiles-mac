#!/usr/bin/env bash
# Now-playing for Spotify / Apple Music via AppleScript (no external deps, and
# no private MediaRemote API which Apple restricted in recent macOS). Hides the
# item when nothing is playing/paused. The `is running` guard avoids launching
# either app just to poll it.
source "$(dirname "$0")/../colors.sh"

APP=""; STATE=""
for a in "Spotify" "Music"; do
  st="$(osascript -e "if application \"$a\" is running then tell application \"$a\" to player state as string" 2>/dev/null)"
  if [ "$st" = "playing" ] || [ "$st" = "paused" ]; then APP="$a"; STATE="$st"; break; fi
done

if [ -z "$APP" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TRACK="$(osascript -e "tell application \"$APP\" to (get name of current track) & \" – \" & (get artist of current track)" 2>/dev/null)"
if [ -z "$TRACK" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if [ "$STATE" = "playing" ]; then ICON="󰐊"; else ICON="󰏤"; fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$GREEN" label="$TRACK"
