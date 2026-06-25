#!/usr/bin/env bash
# Volume with speaker icon; $INFO is the volume % on volume_change events.
source "$(dirname "$0")/../colors.sh"
if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)')"
fi

# Note: local var must NOT be named MUTED — that's the palette colour from
# colors.sh; clobbering it would set icon.color to "true"/"false" (→ 0x0).
IS_MUTED="$(osascript -e 'output muted of (get volume settings)')"
if [ "$IS_MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
  ICON="󰖁"; COLOR=$MUTED
else
  case "$VOLUME" in
    [6-9][0-9]|100) ICON="󰕾" ;;
    [3-5][0-9])     ICON="󰖀" ;;
    *)              ICON="󰕿" ;;
  esac
  COLOR=$PEACH
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOLUME}%"
