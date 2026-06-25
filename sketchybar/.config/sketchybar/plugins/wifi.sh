#!/usr/bin/env bash
# Wi-Fi status: SSID when connected, IP as fallback, muted icon when offline.
# Assumes Wi-Fi is en0 (true on every MacBook).
#
# Reading the SSID: modern macOS redacts it from every CLI tool (networksetup,
# ipconfig, wdutil) unless the caller holds the Location Services entitlement,
# which a daemon-spawned plugin can't have. The Shortcuts app DOES hold it, so we
# call a one-line shortcut named "CurrentWiFi" (see README for the 30s setup).
# Until that shortcut exists we fall back to networksetup, then to the IP.
source "$(dirname "$0")/../colors.sh"
export PATH="/opt/homebrew/bin:$PATH"

IP="$(ipconfig getifaddr en0 2>/dev/null)"

if [ -n "$IP" ]; then
  ICON="󰖩"; COLOR=$BLUE

  SSID="$(shortcuts run "CurrentWiFi" --output-path - 2>/dev/null | tr -d '\n')"
  if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
    SSID="$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/^Current Wi-Fi Network: //')"
  fi

  case "$SSID" in
    *"not associated"*|*"not currently"*|*redacted*|"") LABEL="$IP" ;;
    *) LABEL="$SSID" ;;
  esac
else
  ICON="󰖪"; COLOR=$MUTED; LABEL="off"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
