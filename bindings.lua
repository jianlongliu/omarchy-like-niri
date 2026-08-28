-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
-- Replace the default PRINT screenshot with omasnap (added by Ante).
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot", "omasnap")
o.bind("SUPER + E", nil, "/home/jianlongliu/.local/bin/nautilus")
o.bind("SUPER + GRAVE", "Workspace overview", "omarchy-shell shell toggle io.github.sirmenef.workspace-overview '{}'")
-- ScrollOverview: niri-style workspace overview on SUPER+TAB (frees the default
-- "Next workspace" binding for this). Must use the Lua API, not the
-- scrolloverview:overview dispatcher string — that path silently no-ops.
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", function()
  hl.plugin.scrolloverview.overview("toggle all")
end, { description = "Scroll overview" })
-- Dank Material Shell-style workspace switching on SUPER+PageUp/PageDown.
o.bind("SUPER + PAGE_UP", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + PAGE_DOWN", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
-- Close the focused window: move SUPER+W off to SUPER+Q and ALT+F4.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("ALT + F4", "Close window", hl.dsp.window.close())
-- Switch apps on Alt+scroll. cycle_next (Alt+Tab) is inherently cyclic and
-- ignores cyclic=false; use spatial focus (like SUPER+arrows) instead, which is
-- non-cyclic — it stops when there's no window in that direction. Overrides the
-- default "Next/Previous window in group" mouse binds; group nav stays on SUPER+ALT+TAB.
hl.unbind("SUPER + ALT + mouse_down")
hl.unbind("SUPER + ALT + mouse_up")
o.bind("ALT + mouse_down", "Focus window right", hl.dsp.focus({ direction = "r" }))
o.bind("ALT + mouse_up", "Focus window left", hl.dsp.focus({ direction = "l" }))

-- ==== Bounded dynamic workspaces on SUPER+scroll (niri-style) ====
-- Forward (scroll down): move to the next numbered workspace, creating it if
-- needed, but stop once the focused workspace is empty. This lets you roll
-- 1 -> 2 -> 3 (3 empty) and then halt, instead of creating 4, 5, ... on and on.
-- Backward (scroll up): move to the previous numbered workspace, stopping at 1.
-- Applies to the default Omarchy "Scroll active workspace" mouse binds.

-- Safely read a nested value that may be nil (Hyprland object tables).
local function table_value(value, ...)
  if value == nil then
    return nil
  end

  for _, key in ipairs({ ... }) do
    local ok, item = pcall(function() return value[key] end)
    if ok and item ~= nil then
      return item
    end
  end

  return nil
end

-- Return { id, windows } for the workspace focused on the cursor's monitor.
local function current_workspace()
  local ok, monitor = pcall(function() return hl.get_monitor_at_cursor() end)
  if not ok or not monitor then
    ok, monitor = pcall(function() return hl.get_active_monitor() end)
  end
  if not ok or not monitor then
    return nil
  end

  local active = table_value(monitor, "active_workspace")
  local id = table_value(active, "id")
  if type(id) ~= "number" then
    return nil
  end

  local windows = table_value(active, "windows")
  return { id = id, windows = windows or 0 }
end

local function scroll_next_workspace()
  local current = current_workspace()
  if not current then
    return
  end

  -- Stop at the first empty workspace (e.g. roll to 3, then halt).
  if current.windows == 0 then
    return
  end

  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id + 1) }))
end

local function scroll_prev_workspace()
  local current = current_workspace()
  if not current then
    return
  end

  -- Never go below workspace 1.
  if current.id <= 1 then
    return
  end

  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id - 1) }))
end

-- Replace the default SUPER+scroll workspace bindings with the bounded versions.
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
hl.bind("SUPER + mouse_down", scroll_next_workspace, { description = "Next workspace (create at end, stop at empty)" })
hl.bind("SUPER + mouse_up", scroll_prev_workspace, { description = "Previous workspace" })

-- ==== Bounded dynamic move-window on SUPER+CTRL+Up/Down (niri-style) ====
-- Move the focused window to the adjacent numbered workspace, but stop at the
-- empty boundary: only move when the current workspace has OTHER windows
-- (current.windows > 1). A lone window is left alone, so you can't chain it
-- into 3, 4, 5, ... through freshly-created empty workspaces. Mirrors the
-- scroll bound above (which stops on current-windows == 0).
local function move_next_workspace()
  local current = current_workspace()
  if not current or current.windows == 0 then
    return
  end

  if current.windows > 1 then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id + 1) }))
  end
end

local function move_prev_workspace()
  local current = current_workspace()
  if not current or current.windows == 0 then
    return
  end

  -- Never go below workspace 1 (rule A: no workspace 0 / negatives). The
  -- backward direction is intentionally NOT window-count-bounded so a window
  -- pushed out to a far workspace can always be brought back home.
  if current.id <= 1 then
    return
  end

  hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id - 1) }))
end

hl.unbind("SUPER + CTRL + UP")
hl.unbind("SUPER + CTRL + DOWN")
hl.bind("SUPER + CTRL + UP", move_prev_workspace, { description = "Move window to previous workspace (stop at empty)" })
hl.bind("SUPER + CTRL + DOWN", move_next_workspace, { description = "Move window to next workspace (stop at empty)" })

-- Omarchy Find file search overlay
o.bind("ALT + SPACE", "Find files & folders", "omarchy-shell shell toggle jesseburlamaque.omarchy-find")
