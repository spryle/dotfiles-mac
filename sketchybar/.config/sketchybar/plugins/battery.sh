#!/usr/bin/env bash
# Battery with Nerd Font icon; colours by level / charging state.
source "$(dirname "$0")/../colors.sh"
PERCENT="$(pmset -g batt | grep -Eo '\d+%' | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

[ -z "$PERCENT" ] && exit 0

if [ -n "$CHARGING" ]; then
  ICON="󰂄"; COLOR=$GREEN
else
  case "${PERCENT}" in
    100|9[0-9]) ICON="󰁹" ;;
    8[0-9]|7[0-9]) ICON="󰂁" ;;
    6[0-9]|5[0-9]) ICON="󰁿" ;;
    4[0-9]|3[0-9]) ICON="󰁽" ;;
    2[0-9]) ICON="󰁻" ;;
    *) ICON="󰁺" ;;
  esac
  if   [ "$PERCENT" -le 10 ]; then COLOR=$RED
  elif [ "$PERCENT" -le 20 ]; then COLOR=$YELLOW
  else COLOR=$FG; fi
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENT}%"
