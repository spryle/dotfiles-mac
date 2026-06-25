#!/usr/bin/env bash
# Wi-Fi status: SSID when connected (falls back to IP if macOS redacts the SSID),
# muted icon when offline. Assumes Wi-Fi is en0 (true on every MacBook).
source "$(dirname "$0")/../colors.sh"
export PATH="/opt/homebrew/bin:$PATH"

IP="$(ipconfig getifaddr en0 2>/dev/null)"
SSID="$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/^Current Wi-Fi Network: //')"

if [ -n "$IP" ]; then
  ICON="󰖩"; COLOR=$BLUE
  case "$SSID" in
    *"not associated"*|*"not currently"*|"") LABEL="$IP" ;;
    *) LABEL="$SSID" ;;
  esac
else
  ICON="󰖪"; COLOR=$MUTED; LABEL="off"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
