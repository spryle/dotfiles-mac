# dotfiles-mac

macOS counterpart to my [Omarchy dotfiles](https://github.com/spryle/dotfiles) —
getting as close to the Hyprland/Linux ricing experience as macOS allows.

## Stack

| Linux (Omarchy) | macOS equivalent | Package dir |
|---|---|---|
| Hyprland (WM) | **AeroSpace** (tiling WM, no SIP changes) | `aerospace/` |
| Waybar | **SketchyBar** | `sketchybar/` |
| Hyprland borders | **JankyBorders** | `borders/` |
| Alacritty / terminal | **WezTerm** | `wezterm/` |
| walker / launcher | **Raycast** (`Option+Space`, set in-app) | — |
| wallpaper | `legacy-mountains.png` (set by install) | `wallpapers/` |
| (Touch Bar) | **BetterTouchTool** — live tappable workspaces | `btt/` |
| libinput scroll | **LinearMouse** — mouse scroll speed/direction | `linearmouse/` |
| wl-clipboard / cliphist | **Karabiner** F-keys + **Raycast** clipboard history | `karabiner/` |
| xkill / `hyprctl kill` | **Hammerspoon** — click-to-kill (F16) | `hammerspoon/` |
| starship prompt | **starship** | `starship/` |

Theme: **Catppuccin Mocha**. Font: **JetBrainsMono Nerd Font**.
Raycast theme: Catppuccin Mocha via https://themes.ray.so (needs Raycast Pro).

## Install

```sh
git clone <this-repo> ~/sz/dotfiles-mac && cd ~/sz/dotfiles-mac
./install.sh
```

`install.sh` (idempotent) installs all deps via Homebrew, stows the packages,
wires starship into `~/.zshrc`, and starts the services. Then grant AeroSpace
Accessibility permission when prompted — see the script's closing notes.

AeroSpace auto-starts JankyBorders and notifies SketchyBar of workspace changes.

<details><summary>Manual install (what install.sh does)</summary>

```sh
brew install stow sketchybar borders starship
brew install --cask aerospace wezterm linearmouse karabiner-elements hammerspoon font-jetbrains-mono-nerd-font font-hack-nerd-font
mkdir -p ~/.hammerspoon   # so stow links init.lua, not the whole dir
stow -t ~ aerospace sketchybar borders wezterm starship wallpapers linearmouse hammerspoon
# Karabiner rewrites its own config, so it's copied (not stowed):
cp karabiner/.config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
brew services start sketchybar && open -a AeroSpace
osascript -e 'tell application "System Events" to tell every desktop to set picture to "'"$HOME"'/.config/wallpapers/legacy-mountains.png"'
```
</details>

## Keybindings (AeroSpace)

Modifier is **Alt (Option)** — Cmd collides with macOS app shortcuts.

| Keys | Action |
|---|---|
| `Alt+Enter` | WezTerm |
| `Alt+b` / `Alt+n` / `Alt+c` / `Alt+m` | Launch/focus Chrome / VS Code / Slack / Music |
| `Alt+h/j/k/l` *or* `Alt+←/↓/↑/→` | Focus left/down/up/right |
| `Alt+Shift+h/j/k/l` *or* `Alt+Shift+←/↓/↑/→` | Move window |
| `Alt+1`…`0` | Switch to workspace 1–10 |
| `Alt+Shift+1`…`0` | Move window to workspace |
| numpad `1`…`0` | Switch to workspace 1–10 (bare keys; `0`→10) |
| `Shift`+numpad `1`…`0` | Move window to workspace |
| `Ctrl+Alt+←/→` *or* `Ctrl+Alt+h/l` | Previous / next workspace (wraps) |
| `Alt+f` | Fullscreen |
| `Alt+e` | Toggle split orientation |
| `Alt+Shift+Space` | Toggle float |
| `Alt+w` | Close window |
| `Alt+r` | Resize mode (h/j/k/l, esc to exit) |
| `Alt+Shift+c` | Reload AeroSpace config |
| `Alt+Tab` | Last workspace |

Apps auto-route to workspaces on launch (WezTerm→1, Docker→6, Claude→8,
Slack→9, Chrome→10) and all but Docker also auto-start via
`after-startup-command`; Zoom floats. VS Code is deliberately *not* routed —
its "Reload Window" recreates the window and re-fires the rule, yanking it back.
Edit/remove the `[[on-window-detected]]` blocks in `aerospace.toml` to change.

## Tuning

- **Bar overlaps windows / gap at top:** adjust `gaps.outer.top` in
  `aerospace/.config/aerospace/aerospace.toml`.
- **Switch WM modifier to Cmd:** find/replace `alt-` → `cmd-` in the same file.
- **Menu bar:** for the cleanest look, enable *System Settings → Control Center →
  Automatically hide and show the menu bar*.
- **SketchyBar shows percentages but no icons:** the font family name is wrong.
  Plugins reference `JetBrainsMono NF` (verify the real name with
  `system_profiler SPFontsDataType | grep JetBrains`). The palette/font live in
  `sketchybar/.config/sketchybar/colors.sh`, which every plugin sources — colours
  set inside a plugin are invisible (`0x0`) unless that file is sourced, because
  the SketchyBar daemon doesn't inherit `export`s from `sketchybarrc`.
- **Workspace dots:** the bar shows only workspaces that are focused or contain
  windows; empty ones are hidden (Hyprland-style). Logic in
  `sketchybar/.config/sketchybar/plugins/aerospace.sh`.
- **Raycast hotkey:** install sets it to `Option+Space`
  (`defaults write com.raycast.macos raycastGlobalHotkey "Option-49"`). If it
  reverts, set it in Raycast → Settings → General → Raycast Hotkey.
- **Wallpaper:** `wallpapers/.config/wallpapers/legacy-mountains.png`. Re-apply
  with the `osascript` line in the manual-install block above.
- **Screen saver:** install mirrors the wallpaper into the screen saver by
  copying the `Desktop` image config into the `Idle` slots of macOS's wallpaper
  store (`~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`),
  then `killall WallpaperAgent idleassetsd`. No still-image screen saver is
  exposed via `defaults`/`osascript` on Sonoma+, hence the store edit. A `.bak`
  is left next to the store; revert by restoring it and restarting the agent.
- **Bar modules:** left = workspaces · focused app · resize-mode pill · now
  playing; centre = clock; right = cpu · volume · battery · wifi. The `media`
  item only appears while Spotify/Music is playing (AppleScript, no extra deps);
  `wifi` shows the SSID, or the IP as a fallback. Add Bluetooth by installing
  `blueutil` and adding a plugin on the same pattern.
- **Wi-Fi shows IP instead of SSID:** modern macOS redacts the SSID from every
  CLI tool unless the caller has Location Services entitlement (a daemon-spawned
  plugin can't). Fix: make a Shortcut named **`CurrentWiFi`** whose only action is
  *Get Network Details → Network Name of Wi-Fi*, run it once to grant the location
  prompt, and `wifi.sh` will pick it up (it calls `shortcuts run "CurrentWiFi"`).
  Without the shortcut it falls back to the IP.
- **Touch Bar (BetterTouchTool):** on Touch Bar Macs, BTT shows tappable
  workspace pills 1–10 (active = mauve Catppuccin pill; tap to jump) in the app
  region, with the macOS Control Strip (brightness/volume) on the right. Built by
  `btt/touchbar-workspaces.py` via BTT's AppleScript API (idempotent — re-run to
  refresh; safe alongside your other BTT triggers). `install.sh` gates this on
  `pgrep TouchBarServer`, sets Touch Bar mode `appWithControlStrip`, and hides the
  app-region close button (`BTTHideTouchBarXButton`). BTT needs Accessibility
  permission + a (paid) license. Notes: SF-symbol/custom-font icons don't render
  on the bar, and BTT has no flexible spacer, so the system controls come from the
  native Control Strip rather than custom widgets. Adjust pill width via
  `BTTTouchBarButtonWidth` in the script.
- **Mouse (LinearMouse):** replaces Scroll Reverser. Config is the stowed
  `linearmouse/.config/linearmouse/linearmouse.json`. For mice it sets a fixed
  scroll `distance` (10 lines — kills macOS scroll acceleration so the wheel
  isn't sluggish), reversed vertical scroll (traditional wheel direction), and
  smoothed `easeInOut` scrolling (absorbs stray encoder ticks on cheap wheels).
  The trackpad is untouched (keeps macOS natural scrolling). LinearMouse reloads
  the file live, so tune `distance` up/down and feel it immediately. **Manual
  step:** grant LinearMouse **Accessibility** permission or scrolling does
  nothing. Note: editing settings in LinearMouse's *UI* can break the stow
  symlink (it rewrites the file) — prefer editing the repo file, then re-stow.
- **Copy / paste (Karabiner F-keys + Raycast):** macOS already shares one
  pasteboard across all apps, so the fix is consistent *keys*, not clipboard
  bridging. Karabiner maps `F13`→Copy (⌘C), `F14`→Paste (⌘V), and `F15`→Raycast
  Clipboard History (via a deeplink `shell_command`, so no manual Raycast hotkey
  needed). `F16` is left unmapped here — it passes through to Hammerspoon for
  click-to-kill (see below). The config is **copied,
  not stowed** (`karabiner.json` is rewritten by Karabiner on load, which would
  clobber a symlink) — the repo file is source of truth; `install.sh` re-copies
  it (backing up any existing one). **Manual steps (macOS won't script these):**
  1. *Launch Karabiner-Elements once* — the driver toggle below doesn't exist
     until the app requests it on first launch.
  2. Approve its driver: **System Settings → General → Login Items & Extensions
     → Driver Extensions → enable Karabiner-VirtualHIDDevice** (or click *Allow*
     on the "System Extension Blocked" prompt / the banner in Privacy &
     Security). Verify with `systemextensionsctl list` → `[activated enabled]`.
  3. Grant **Input Monitoring** to Karabiner (System Settings → Privacy &
     Security → Input Monitoring). The remaps do nothing until both are granted.
- **Click-to-kill (Hammerspoon):** the macOS analog of `xkill` / `hyprctl kill`.
  Press **`F16`** → a red banner appears → click any window to **force-quit**
  (`SIGKILL`) its app; `Esc` cancels. Config is the stowed
  `hammerspoon/.hammerspoon/init.lua` (Hammerspoon doesn't rewrite it, so stow is
  safe). F16 is bound bare and left unmapped in Karabiner so it reaches
  Hammerspoon. To soften it to a graceful quit, swap `app:kill9()` for
  `app:kill()` in the init.lua; change the trigger via `KILL_HOTKEY_KEY`.
  **Manual step:** grant Hammerspoon **Accessibility** permission (it needs it to
  read window frames and tap the click) or kill mode does nothing.
- **macOS defaults:** `install.sh` also tunes key repeat (+ disables
  press-and-hold so keys repeat for vim), makes the Dock reveal instantly,
  redirects screenshots to `~/Pictures/Screenshots` (the Desktop is hidden), and
  applies Finder tweaks + Dark mode. Key-repeat changes fully apply to apps
  launched after the next login.
