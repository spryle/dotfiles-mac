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

  # Each `shortcuts run` costs siriactionsd several seconds of CPU, so only ask
  # on real events (wifi_change, forced) or when the IP changed; the 30s routine
  # tick reuses the cached SSID.
  CACHE="${TMPDIR:-/tmp}/sketchybar_wifi_ssid"
  [ -r "$CACHE" ] && IFS=$'\t' read -r CACHED_IP SSID < "$CACHE"
  if [ "$SENDER" != "routine" ] || [ "$CACHED_IP" != "$IP" ] || [ -z "$SSID" ]; then
    # `shortcuts run` blocks reading an open stdin, hence </dev/null; perl alarm = 15s timeout.
    SSID="$(perl -e 'alarm 15; exec @ARGV' shortcuts run "CurrentWiFi" --output-path - </dev/null 2>/dev/null | tr -d '\n')"
    if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
      SSID="$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/^Current Wi-Fi Network: //')"
    fi
  fi

  # Only a real SSID is cached, so a failed lookup is retried on the next tick.
  case "$SSID" in
    *"not associated"*|*"not currently"*|*redacted*|"") LABEL="$IP"; rm -f "$CACHE" ;;
    *) LABEL="$SSID"; printf '%s\t%s\n' "$IP" "$SSID" > "$CACHE" ;;
  esac
else
  ICON="󰖪"; COLOR=$MUTED; LABEL="off"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
