-- AeroSpace layout guard (dotfiles-mac)
--
-- Problem: when an external display is unplugged, macOS dumps every window that
-- was on it onto the built-in screen and AeroSpace re-detects them. Apps with an
-- on-window-detected rule snap back to their home workspace; everything else
-- lands on whichever workspace is focused. Upstream: nikitabobko/AeroSpace#1216.
--
-- Fix: keep a rolling snapshot of window-id -> workspace, and after the display
-- layout settles, move any window that strayed back to where it was. Plugging a
-- monitor in is a no-op (workspaces move between monitors, windows don't change
-- workspace), so the restore only ever touches windows that actually jumped.
--
-- Also keeps AeroSpace's CLI socket alive: macOS sweeps /tmp files untouched for
-- 3 days, and once the socket is gone the `aerospace` CLI (and so this guard,
-- and SketchyBar's workspace dots) can't talk to the running daemon. Touching
-- it periodically prevents the sweep. Restart AeroSpace if it's already gone.
--
-- Hammerspoon console shows a log line per restore; "hs.reload()" reloads.

local M = {}

local AEROSPACE  = "/opt/homebrew/bin/aerospace"
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
local SOCKET     = "/tmp/bobko.aerospace-" .. (os.getenv("USER") or "") .. ".sock"

local SNAPSHOT_INTERVAL   = 10         -- seconds; a window moved < this long before
                                       -- an unplug may be put back where it was
local SETTLE_DELAY        = 4          -- seconds of screen-event quiet before restoring
local SOCKET_TOUCH_PERIOD = 6 * 3600   -- well inside macOS's 3-day /tmp sweep

local snapshot  = nil    -- { [window-id (string)] = workspace (string) }
local restoring = false  -- suppress snapshots while displays are in flux
local settle    = nil    -- pending hs.timer for the debounced restore

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Run an aerospace CLI command; returns stdout or nil if the daemon is unreachable.
local function aero(args)
  local out, ok = hs.execute(AEROSPACE .. " " .. args .. " 2>/dev/null")
  if not ok then return nil end
  return out
end

-- Current window-id -> workspace map across all monitors/workspaces.
local function windowMap()
  local out = aero("list-windows --all --format '%{window-id}|%{workspace}'")
  if not out then return nil end
  local map, n = {}, 0
  for line in out:gmatch("[^\n]+") do
    local id, ws = line:match("^(%d+)|(.+)$")
    if id and ws then map[id] = trim(ws); n = n + 1 end
  end
  return map, n
end

local function takeSnapshot()
  if restoring then return end
  local map, n = windowMap()
  if map and n > 0 then snapshot = map end
end

local function restore()
  settle = nil
  local ok, err = pcall(function()
    if not snapshot then return end
    local now = windowMap()
    if not now then
      print("aerospace_guard: daemon unreachable, skipping restore (socket swept? restart AeroSpace)")
      return
    end
    local moved = 0
    for id, ws in pairs(now) do
      local want = snapshot[id]
      if want and want ~= ws then
        if aero(string.format("move-node-to-workspace --window-id %s '%s'", id, want)) then
          moved = moved + 1
        end
      end
    end
    if moved > 0 then
      print(string.format("aerospace_guard: restored %d window(s) after display change", moved))
      hs.execute(SKETCHYBAR .. " --trigger aerospace_workspace_change 2>/dev/null")
    end
  end)
  restoring = false
  if not ok then print("aerospace_guard: restore failed: " .. tostring(err)) end
end

-- Display layout changed (plug/unplug/resolution). Events come in bursts, so
-- debounce and only restore once things have been quiet for SETTLE_DELAY.
local function onScreensChanged()
  restoring = true
  if settle then settle:stop() end
  settle = hs.timer.doAfter(SETTLE_DELAY, restore)
end

local function touchSocket()
  if hs.fs.attributes(SOCKET) then hs.fs.touch(SOCKET) end
end

-- Keep references on the module table so the timers/watcher aren't GC'd.
M.screenWatcher  = hs.screen.watcher.new(onScreensChanged):start()
M.snapshotTimer  = hs.timer.doEvery(SNAPSHOT_INTERVAL, takeSnapshot):start()
M.socketTimer    = hs.timer.doEvery(SOCKET_TOUCH_PERIOD, touchSocket):start()
M.takeSnapshot   = takeSnapshot
M.restore        = restore

touchSocket()
takeSnapshot()

return M
