#!/usr/bin/env bash
set -euo pipefail

# Bootstrap dotfiles-mac on a fresh machine. Idempotent — safe to re-run.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(aerospace sketchybar borders wezterm starship wallpapers)

log() { echo "[install] $*"; }

# --- Homebrew ----------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
    echo "[install] Homebrew is required. Install it from https://brew.sh and re-run." >&2
    exit 1
fi

# Taps for third-party formulae/casks (borders, aerospace).
log "tapping + trusting third-party taps"
brew tap FelixKratz/formulae >/dev/null 2>&1 || true
brew tap nikitabobko/tap     >/dev/null 2>&1 || true
brew trust FelixKratz/formulae nikitabobko/tap >/dev/null 2>&1 || true
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1   # fallback if `brew trust` is unavailable

# --- Dependencies ------------------------------------------------------------
FORMULAE=(stow sketchybar starship borders)
CASKS=(aerospace wezterm font-jetbrains-mono-nerd-font font-hack-nerd-font)

for f in "${FORMULAE[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
        log "formula $f already installed"
    else
        log "installing formula $f"
        brew install "$f"
    fi
done

for c in "${CASKS[@]}"; do
    if brew list --cask "$c" >/dev/null 2>&1; then
        log "cask $c already installed"
    else
        log "installing cask $c"
        # --adopt takes ownership of an app already present outside Homebrew
        # (e.g. WezTerm installed manually) instead of erroring on it.
        brew install --cask --adopt "$c"
    fi
done

# --- Executable bits ---------------------------------------------------------
log "ensuring scripts are executable"
chmod +x "$DOTFILES_DIR"/sketchybar/.config/sketchybar/sketchybarrc \
         "$DOTFILES_DIR"/sketchybar/.config/sketchybar/plugins/*.sh \
         "$DOTFILES_DIR"/borders/.config/borders/bordersrc

# --- Stow --------------------------------------------------------------------
cd "$DOTFILES_DIR"
log "stowing packages into $HOME: ${PACKAGES[*]}"
stow --target="$HOME" --restow "${PACKAGES[@]}"

# --- Shell: starship prompt --------------------------------------------------
ZSHRC_MARKER='# starship prompt (dotfiles-mac)'
ZSHRC_BLOCK='# starship prompt (dotfiles-mac)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi'
if ! grep -qF "$ZSHRC_MARKER" "$HOME/.zshrc" 2>/dev/null; then
    log "adding starship init to ~/.zshrc"
    printf '\n%s\n' "$ZSHRC_BLOCK" >> "$HOME/.zshrc"
fi

# --- macOS tweaks ------------------------------------------------------------
# Auto-hide the native menu bar so SketchyBar is the only top bar (Omarchy look).
# `defaults write _HIHideMenuBar` alone only applies at next login (WindowServer
# reads it then), which leaves a reserved gap above SketchyBar until you restart.
# The System Events `autohide menu bar` property applies it live, so do both.
log "auto-hiding the native macOS menu bar"
defaults write NSGlobalDomain _HIHideMenuBar -bool true
osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' 2>/dev/null \
    || log "could not toggle menu-bar auto-hide automatically — set it in System Settings > Control Center > Menu Bar"
killall SystemUIServer 2>/dev/null || true

# Dark appearance so native UI (notifications, menus, sheets) matches the
# Catppuccin Mocha theme. System notifications can't be themed further than this.
log "enabling Dark mode"
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null \
    || log "could not enable Dark mode automatically — set it in System Settings > Appearance"

# Hide all desktop icons for a clean wallpaper (Omarchy/Hyprland look). Files are
# not moved or deleted — they stay in ~/Desktop, reachable via Finder. Reverse
# with: defaults write com.apple.finder CreateDesktop true && killall Finder
log "hiding desktop icons"
defaults write com.apple.finder CreateDesktop false
killall Finder 2>/dev/null || true

# --- Input & UX defaults -----------------------------------------------------
# Keyboard: fast key repeat and, crucially, ApplePressAndHoldEnabled=false so
# holding a key REPEATS it (vim/navigation) instead of popping the accent menu.
# (KeyRepeat/InitialKeyRepeat fully apply to apps launched after next login.)
log "tuning keyboard repeat"
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write -g ApplePressAndHoldEnabled -bool false

# Dock: reveal instantly (it's auto-hidden for the clean look).
log "speeding up the Dock"
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
killall Dock 2>/dev/null || true

# Screenshots: save to ~/Pictures/Screenshots instead of the (now hidden) Desktop.
log "redirecting screenshots to ~/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
killall SystemUIServer 2>/dev/null || true

# Finder: path/status bars, list view, search the current folder, show
# extensions and dotfiles (dev-friendly).
log "applying Finder tweaks"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder 2>/dev/null || true

# --- Wallpaper ---------------------------------------------------------------
# Set the Omarchy wallpaper across every desktop/space. Points at the stowed
# copy in ~/.config so the path is stable regardless of where this repo lives.
# (First run may prompt to allow Terminal to control System Events.)
WALLPAPER="$HOME/.config/wallpapers/legacy-mountains.png"
if [ -f "$WALLPAPER" ]; then
    log "setting desktop wallpaper"
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER\"" 2>/dev/null \
        || log "could not set wallpaper automatically — set it manually in System Settings > Wallpaper"
fi

# --- Raycast hotkey ----------------------------------------------------------
# Set Raycast's global hotkey to Option+Space (keycode 49). Raycast writes this
# key back on quit, so set it while it's not running, then it sticks. Only do
# this if Raycast is installed; skip otherwise.
if [ -d "/Applications/Raycast.app" ]; then
    log "setting Raycast hotkey to Option+Space"
    osascript -e 'quit app "Raycast"' 2>/dev/null || true
    sleep 1
    defaults write com.raycast.macos raycastGlobalHotkey "Option-49"
    open -a Raycast 2>/dev/null || true
fi

# --- Services ----------------------------------------------------------------
log "starting sketchybar service"
brew services restart sketchybar >/dev/null 2>&1 || brew services start sketchybar

log "launching AeroSpace (starts borders + feeds sketchybar)"
open -a AeroSpace || true

# --- Next steps --------------------------------------------------------------
cat <<'EOF'

[install] Done. Remaining manual steps (macOS won't let scripts do these):

  1. Grant AeroSpace Accessibility permission:
       System Settings -> Privacy & Security -> Accessibility -> enable AeroSpace
     (AeroSpace's window manager won't run until this is granted.)

  2. (Optional) Raycast Catppuccin Mocha theme — needs Raycast Pro to activate:
       https://themes.ray.so?version=1&name=Catppuccin%20Mocha&colors=%231e1e2e,%231e1e2e,%23cdd6f4,%236c7086,%237f849c,%23f38ba8,%23fab387,%23f9e2af,%23a6e3a1,%2389b4fa,%23b4befe,%23cba6f7&appearance=dark

  3. Open a new terminal tab to pick up the starship prompt.

EOF
