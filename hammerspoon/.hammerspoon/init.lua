-- Hammerspoon config (dotfiles-mac)
--
-- Click-to-kill: the macOS analog of Linux `xkill` / Hyprland's `hyprctl kill`.
-- Press F16 to enter kill mode (a red banner appears), then click any window to
-- force-quit its app. Esc cancels. Hammerspoon needs Accessibility permission
-- (System Settings -> Privacy & Security -> Accessibility).
--
-- F16 is bound bare (no modifier) and is NOT mapped in Karabiner, so the
-- keypress passes straight through to here. Change the key below to taste.
local KILL_HOTKEY_MODS = {}
local KILL_HOTKEY_KEY  = "f16"

local killMode = { active = false, clickTap = nil, escTap = nil, alertId = nil }

local function endKillMode()
  if killMode.clickTap then killMode.clickTap:stop() end
  if killMode.escTap then killMode.escTap:stop() end
  if killMode.alertId then hs.alert.closeSpecific(killMode.alertId) end
  killMode.clickTap, killMode.escTap, killMode.alertId = nil, nil, nil
  killMode.active = false
end

-- Topmost standard window whose frame contains the given screen point.
local function windowAt(p)
  for _, win in ipairs(hs.window.orderedWindows()) do
    local f = win:frame()
    if win:isStandard()
      and p.x >= f.x and p.x <= f.x + f.w
      and p.y >= f.y and p.y <= f.y + f.h then
      return win
    end
  end
  return nil
end

local function startKillMode()
  if killMode.active then endKillMode(); return end
  killMode.active = true
  killMode.alertId = hs.alert.show(
    "Click a window to KILL it   •   Esc to cancel",
    { textColor = { white = 1 }, fillColor = { red = 0.55, green = 0.1, blue = 0.1, alpha = 0.95 } },
    hs.screen.mainScreen(), 15)

  -- Esc cancels (swallowed so it doesn't reach the focused app).
  killMode.escTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getKeyCode() == hs.keycodes.map["escape"] then endKillMode(); return true end
    return false
  end):start()

  -- Next left click: force-kill the app of the window under the cursor.
  killMode.clickTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function()
    local win = windowAt(hs.mouse.absolutePosition())
    endKillMode()
    if win and win:application() then
      local app = win:application()
      local name = app:name() or "?"
      app:kill9()   -- force kill (SIGKILL); use app:kill() for a graceful quit
      hs.alert.show("Killed: " .. name)
    else
      hs.alert.show("No window under cursor")
    end
    return true   -- swallow the click so it doesn't reach the app
  end):start()
end

hs.hotkey.bind(KILL_HOTKEY_MODS, KILL_HOTKEY_KEY, startKillMode)

-- Focus follows mouse: the Hyprland/Omarchy behavior AeroSpace doesn't provide
-- (it only has the reverse, mouse-follows-focus). Watch mouse movement and,
-- once the pointer settles for FFM_DELAY, focus the window under it. The
-- delayed timer restarts on every move event, so nothing focuses mid-flick and
-- the (relatively expensive) window lookup runs once per pause instead of at
-- 60Hz. hs.window:focus() also raises the window — invisible for tiled
-- windows, and arguably what you want for floating ones.
local FFM_DELAY = 0.05  -- seconds the pointer must rest before focus moves

-- FFM is restricted to terminals only (allowlist). Auto-focusing every window
-- on hover caused problems elsewhere: browser extension popups (1Password,
-- toolbar dropdowns) are non-standard windows, so windowAt() returns the
-- browser window *behind* the popup — focusing it blurs the popup, which
-- dismisses on blur, so it vanished the instant you moved toward it. Other GUI
-- apps had their own hover-focus surprises. Terminals are the only place the
-- Hyprland-style focus-follows-mouse actually earns its keep, so we only act on
-- them; every other app now requires a click to focus (standard macOS).
-- Matched on exact app name (hs.window:application():name()). Add your terminal
-- here if it isn't listed.
local FFM_ONLY_APPS = {
  ["WezTerm"] = true,
  ["iTerm2"] = true,
  ["Terminal"] = true,   -- Apple Terminal
  ["Alacritty"] = true,
  ["kitty"] = true,
  ["Ghostty"] = true,
  ["Hyper"] = true,
  ["Tabby"] = true,
  ["Warp"] = true,
  ["WarpPreview"] = true,
}

local ffmTimer = hs.timer.delayed.new(FFM_DELAY, function()
  if killMode.active then return end
  local win = windowAt(hs.mouse.absolutePosition())
  if not win then return end
  local app = win:application()
  if not (app and FFM_ONLY_APPS[app:name()]) then return end
  local focused = hs.window.focusedWindow()
  if not focused or win:id() ~= focused:id() then
    win:focus()
  end
end)

-- Global (not local) so the tap isn't garbage-collected and silently stopped.
ffmTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
  ffmTimer:start()
  return false
end):start()

hs.alert.show("Hammerspoon: click-to-kill (F16) + focus-follows-mouse ready")
