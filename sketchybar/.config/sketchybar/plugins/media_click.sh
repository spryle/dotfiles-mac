#!/usr/bin/env bash
# Play/pause whichever supported player is currently running (bound to a click
# on the media item).
for a in Spotify Music; do
  osascript -e "if application \"$a\" is running then tell application \"$a\" to playpause" 2>/dev/null
done
