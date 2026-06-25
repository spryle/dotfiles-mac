#!/usr/bin/env python3
"""Build the BetterTouchTool Touch Bar: live AeroSpace workspaces + native sliders.

BTT stores its config in its own database, not a stowable dotfile, so instead of
a config file this script drives BTT's AppleScript API (`add_new_trigger`) to
build the items reproducibly. It is idempotent: it deletes the items it manages
first (identified by content/type, since BTT doesn't persist custom names), so
re-running just refreshes them and never touches your other BTT triggers.

Layout: workspaces 1-10 only. They're Shell Script Widgets (type 642) whose
script prints "●N" when workspace N is focused, else "N"; BTTTouchBarColorRegex
"●" flips the focused one to a mauve Catppuccin pill. Tapping runs
`aerospace workspace N` (action 206), output silenced so re-tapping the active
one is quiet.

The system controls (brightness/volume/mute) are NOT recreated here — they come
from the macOS Control Strip on the right, which stays visible because install.sh
sets the Touch Bar to "appWithControlStrip" mode (BTT's recommended mode: app
region on the left, real Control Strip on the right).

Requires BTT to be running. NOTE: a full rebuild empties the bar briefly, which
makes BTT auto-hide it (BTTTouchBarVisible→0). install.sh re-asserts visibility
after running this; for a manual run, toggle the BTT Touch Bar back on (or
restart BTT) if it goes blank.
"""
import json
import subprocess

AERO = "/opt/homebrew/bin/aerospace"
WORKSPACES = range(1, 11)

# Types/actions from earlier iterations — matched only so a re-run cleans them
# up during the transition (no longer created).
LEGACY_WIDGET_TYPES = {636, 637}        # native volume/brightness sliders
LEGACY_SYS_ACTIONS = {22, 24, 25, 28, 29}  # emoji brightness/volume/mute buttons

# Catppuccin Mocha, as BTT "R, G, B, A" strings.
SURFACE0 = "49.0, 50.0, 68.0, 255.0"      # #313244 base pill
TEXT     = "205.0, 214.0, 244.0, 255.0"   # #cdd6f4
MAUVE    = "203.0, 166.0, 247.0, 255.0"   # #cba6f7 active pill
BASE     = "30.0, 30.0, 46.0, 255.0"      # #1e1e2e dark text on mauve


def osa(script: str) -> str:
    return subprocess.run(
        ["osascript", "-e", script], capture_output=True, text=True
    ).stdout.strip()


def add_trigger(obj: dict) -> None:
    payload = json.dumps(obj)
    escaped = payload.replace("\\", "\\\\").replace('"', '\\"')
    osa(f'tell application "BetterTouchTool" to add_new_trigger "{escaped}"')


def display_script(n: int) -> str:
    return (
        "export PATH=/opt/homebrew/bin:$PATH\n"
        f'if [ "$(aerospace list-workspaces --focused)" = "{n}" ]; '
        f'then echo "●{n}"; else echo "{n}"; fi\n'
    )


def workspace_widget(n: int) -> dict:
    return {
        "BTTTriggerType": 642,
        "BTTTriggerClass": "BTTTriggerTypeTouchBar",
        "BTTWidgetName": str(n),
        "BTTOrder": n,
        "BTTTriggerConfig": {
            "BTTTouchBarButtonName": str(n),
            "BTTTouchBarShellScriptString": display_script(n),
            "BTTTouchBarScriptUpdateInterval": 1,
            "BTTTouchBarButtonColor": SURFACE0,
            "BTTTouchBarFontColor": TEXT,
            "BTTTouchBarColorRegex": "●",
            "BTTTouchBarAlternateBackgroundColor": MAUVE,
            "BTTTouchBarFontColorAlternate": BASE,
            "BTTTouchBarButtonFontSize": 15,
            "BTTTouchBarFreeSpaceAfterButton": 4,
            "BTTTouchBarButtonCornerRadius": 6,
            # Uniform, slightly wider pills (vs auto-sizing to the digit).
            "BTTTouchBarButtonWidth": 46,
            "BTTTouchBarButtonUseFixedWidth": 1,
            # Show on every app's Touch Bar, even ones with their own bar.
            "BTTTouchBarAlwaysShowButton": 1,
        },
        "BTTActionsToExecute": [{
            "BTTPredefinedActionType": 206,  # Execute Shell Script / Task
            # Silence output so tapping the already-focused workspace is quiet.
            "BTTShellTaskActionScript": f"{AERO} workspace {n} >/dev/null 2>&1",
            "BTTShellTaskActionConfig": "/bin/bash:::-c:::-",
        }],
    }


def is_ours(t: dict) -> bool:
    cfg = t.get("BTTTriggerConfig")
    cfg = cfg if isinstance(cfg, dict) else {}
    script = cfg.get("BTTTouchBarShellScriptString", "")
    ttype = t.get("BTTTriggerType")
    wname = t.get("BTTWidgetName", "") or ""
    return (
        # Workspace widget: identified by its unique display script.
        (ttype == 642 and "aerospace list-workspaces" in script)
        # Legacy slider widgets (clean up on transition).
        or ttype in LEGACY_WIDGET_TYPES
        # Legacy emoji system buttons (clean up on transition).
        or (ttype == 629 and t.get("BTTPredefinedActionType") in LEGACY_SYS_ACTIONS)
        # Legacy "ws-N" named widgets (clean up on transition).
        or wname.startswith("ws-")
    )


def main() -> None:
    existing = json.loads(osa('tell application "BetterTouchTool" to get_triggers') or "[]")
    removed = 0
    for t in existing:
        if is_ours(t) and t.get("BTTUUID"):
            osa(f'tell application "BetterTouchTool" to delete_trigger "{t["BTTUUID"]}"')
            removed += 1

    created = 0
    for n in WORKSPACES:
        add_trigger(workspace_widget(n))
        created += 1

    print(f"[btt] refreshed Touch Bar (removed {removed}, created {created})")


if __name__ == "__main__":
    main()
