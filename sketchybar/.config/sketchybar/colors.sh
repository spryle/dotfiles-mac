#!/usr/bin/env bash
# Shared Catppuccin Mocha palette + font, sourced by sketchybarrc AND every
# plugin. This indirection matters: the SketchyBar daemon spawns plugin scripts
# with its own (brew-service) environment, so variables merely `export`ed in
# sketchybarrc do NOT reach the plugins — colours set inside a plugin would come
# out as 0x0 (invisible). Sourcing this file in each plugin fixes that.

# ---- Catppuccin Mocha palette (0xAARRGGBB) ----------------------------------
export BG=0xee1e1e2e        # base @ ~93% alpha
export ITEM_BG=0xff313244   # surface0
export ACCENT=0xffcba6f7    # mauve
export FG=0xffcdd6f4        # text
export MUTED=0xff9399b2     # overlay2
export RED=0xfff38ba8
export GREEN=0xffa6e3a1
export YELLOW=0xfff9e2af
export PEACH=0xfffab387
export BLUE=0xff89b4fa
export DARK=0xff1e1e2e       # for glyphs sitting on an accent-filled pill

# ---- Font -------------------------------------------------------------------
# Family name as macOS registers the Homebrew nerd-font cask (NOT "...Nerd
# Font"). Verify with: system_profiler SPFontsDataType | grep JetBrains
export FONT="JetBrainsMono NF"
