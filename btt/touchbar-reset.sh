#!/usr/bin/env bash
# Reset a wedged Touch Bar (frozen workspace pills, dead brightness/volume).
#
# macOS's Touch Bar agents occasionally hang after days of uptime and
# sleep/wake cycles — a long-standing macOS bug, not something this setup
# causes or can prevent. Restarting BTT doesn't help because BTT only draws
# on top of these agents. This makes recovery one command, escalating
# through the layers:
#
#   touchbar-reset.sh          restart ControlStrip (user-level; fixes the
#                              brightness/volume strip — usually enough)
#   touchbar-reset.sh --full   also restart TouchBarServer (root-owned, so
#                              sudo prompts) — rebuilds the whole bar,
#                              including BTT's workspace pills
#
# Both agents respawn automatically within a couple of seconds. If the pills
# stay blank after a full reset, BTT auto-hid its bar (it does this when the
# bar is briefly empty): restart BetterTouchTool to re-assert it.

set -euo pipefail

echo "[touchbar-reset] restarting ControlStrip"
killall ControlStrip 2>/dev/null || true

if [ "${1:-}" = "--full" ]; then
    echo "[touchbar-reset] restarting TouchBarServer (needs sudo)"
    sudo pkill TouchBarServer
fi

echo "[touchbar-reset] done — the Touch Bar should redraw within a few seconds"
