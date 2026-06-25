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
brew install --cask aerospace wezterm font-jetbrains-mono-nerd-font font-hack-nerd-font
stow -t ~ aerospace sketchybar borders wezterm starship wallpapers
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
| `Ctrl+Alt+←/→` *or* `Ctrl+Alt+h/l` | Previous / next workspace (wraps) |
| `Alt+f` | Fullscreen |
| `Alt+e` | Toggle split orientation |
| `Alt+Shift+Space` | Toggle float |
| `Alt+w` | Close window |
| `Alt+r` | Resize mode (h/j/k/l, esc to exit) |
| `Alt+Shift+c` | Reload AeroSpace config |
| `Alt+Tab` | Last workspace |

Apps auto-route to workspaces on launch (Chrome→1, VS Code→2, Slack→3,
Notion→4, Music→5); Zoom floats. Edit/remove the `[[on-window-detected]]` blocks
in `aerospace.toml` to change this.

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
- **macOS defaults:** `install.sh` also tunes key repeat (+ disables
  press-and-hold so keys repeat for vim), makes the Dock reveal instantly,
  redirects screenshots to `~/Pictures/Screenshots` (the Desktop is hidden), and
  applies Finder tweaks + Dark mode. Key-repeat changes fully apply to apps
  launched after the next login.
