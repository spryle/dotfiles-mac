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
| `Alt+h/j/k/l` *or* `Alt+←/↓/↑/→` | Focus left/down/up/right |
| `Alt+Shift+h/j/k/l` *or* `Alt+Shift+←/↓/↑/→` | Move window |
| `Alt+1`…`0` | Switch to workspace 1–10 |
| `Alt+Shift+1`…`0` | Move window to workspace |
| `Alt+f` | Fullscreen |
| `Alt+e` | Toggle split orientation |
| `Alt+Shift+Space` | Toggle float |
| `Alt+w` | Close window |
| `Alt+r` | Resize mode (h/j/k/l, esc to exit) |
| `Alt+Shift+c` | Reload AeroSpace config |
| `Alt+Tab` | Last workspace |

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
