#!/usr/bin/env bash
# Day HH:MM — matches the Omarchy waybar clock format.
sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"
