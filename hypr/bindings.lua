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
-- 直连系统 nautilus：原来的 ~/.local/bin/nautilus 包装脚本只为注入
-- GTK_THEME=Catppuccin（写死配色），已废；配色改由 omarchy 主题模板驱动。
o.bind("SUPER + E", nil, "nautilus")
-- SUPER+F → 带任务栏全屏（maximized），覆盖默认的真全屏。
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Maximized (with bar)", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- SUPER+CTRL+F → 真全屏（盖状态栏），覆盖默认的 Tiled full screen。
hl.unbind("SUPER + CTRL + F")
o.bind("SUPER + CTRL + F", "True fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
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
-- Switch apps on Super+Shift+scroll. Moved off Alt+scroll because some video
-- players (esp. in-browser) hijack Alt+wheel as volume. cycle_next is cyclic and
-- ignores cyclic=false, so use spatial focus (like SUPER+arrows), which is
-- non-cyclic — it stops when there's no window in that direction.
hl.unbind("SUPER + SHIFT + mouse_down")
hl.unbind("SUPER + SHIFT + mouse_up")
o.bind("SUPER + SHIFT + mouse_down", "Focus window right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + mouse_up", "Focus window left", hl.dsp.focus({ direction = "l" }))

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

-- Workspace range reserved for the main monitor. The portable display
-- (HDMI-A-1) is pinned to workspace 6 for video, so every scroll/move bind
-- below is scoped to this range and only acts when the cursor is on DP-2.
local MAIN_MONITOR = "DP-2"
local MAIN_WS_MIN, MAIN_WS_MAX = 1, 3

-- Return { id, windows, monitor } for the workspace focused on the cursor's monitor.
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
  return { id = id, windows = windows or 0, monitor = table_value(monitor, "name") }
end

local function scroll_next_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR then
    return
  end

  -- Stop at the first empty workspace (e.g. roll to 3, then halt).
  if current.windows == 0 then
    return
  end

  -- Stay inside the main monitor's range so focus never jumps to the
  -- portable display, which owns workspace 6.
  if current.id >= MAIN_WS_MAX then
    return
  end

  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id + 1) }))
end

local function scroll_prev_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR then
    return
  end

  -- Never go below the first workspace of the range.
  if current.id <= MAIN_WS_MIN then
    return
  end

  -- A workspace above the range (e.g. created with SUPER+7) must not step
  -- down onto the portable display's pinned workspace 6: clamp back into the
  -- range instead, so focus never leaves this monitor.
  local target = math.min(current.id - 1, MAIN_WS_MAX)
  hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
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
  if not current or current.monitor ~= MAIN_MONITOR or current.windows == 0 then
    return
  end

  if current.windows > 1 and current.id < MAIN_WS_MAX then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id + 1) }))
  end
end

local function move_prev_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR or current.windows == 0 then
    return
  end

  -- Never go below the first workspace of the range (rule A: no workspace 0 /
  -- negatives). The backward direction is intentionally NOT window-count-bounded
  -- so a window pushed out to a far workspace can always be brought back home.
  -- Clamped at the top for the same reason as scroll_prev_workspace: stepping
  -- down from an out-of-range workspace would land on the other monitor.
  if current.id <= MAIN_WS_MIN then
    return
  end

  local target = math.min(current.id - 1, MAIN_WS_MAX)
  hl.dispatch(hl.dsp.window.move({ workspace = tostring(target) }))
end

hl.unbind("SUPER + CTRL + UP")
hl.unbind("SUPER + CTRL + DOWN")
hl.bind("SUPER + CTRL + UP", move_prev_workspace, { description = "Move window to previous workspace (stop at empty)" })
hl.bind("SUPER + CTRL + DOWN", move_next_workspace, { description = "Move window to next workspace (stop at empty)" })

-- ==== Spotlight (maajix) 命令面板 ====
-- ALT+SPACE 当前空闲；不用 CTRL+SPACE 是因为与 fcitx5 冲突。
o.bind("ALT + SPACE", "Spotlight", "omarchy-shell shell toggle io.github.maajix.spotlight '{}'")

-- ==== Windows 风格快捷键 ====
-- CTRL+ALT+DELETE → 系统菜单（出厂是 "Close all windows"，见 tiling.lua）。
-- 走 Omarchy 那套：纯 Hyprland 绑定，不去 mask 内核。注意内核 VT 键表里
-- `control alt keycode 111 = Boot`，VT 层不区分图形模式 → 按下会同时给 PID 1 发
-- SIGINT → systemd 的 ctrl-alt-del.target（= reboot.target）→ 机器重启。
hl.unbind("CTRL + ALT + DELETE")
o.bind("CTRL + ALT + DELETE", "System menu", "omarchy-menu toggle system")
-- CTRL+SHIFT+ESCAPE → btop（已开则聚焦旧窗口）。原为此键空闲。
o.bind("CTRL + SHIFT + ESCAPE", "btop", "omarchy-launch-or-focus-tui btop")
-- SUPER+Y → yazi（原为此键空闲；SUPER+SHIFT+Y 仍是 YouTube，未动）。
-- 用 Omarchy 的 TUI 助手：app-id = org.omarchy.yazi，再按一次会聚焦已开的窗口。
-- 注意它不在 system.lua 的浮动名单里，所以是平铺窗口（和 btop 的浮动不同）。
o.bind("SUPER + Y", "Yazi", { tui = "yazi", focus = true })
-- SUPER+Z → Zen 浏览器（原为此键空闲；只有 SUPER+CTRL+Z=Zoom in、
-- SUPER+CTRL+ALT+Z=Reset zoom 占用了 Z，纯 SUPER+Z 无冲突）。
-- 走 Omarchy 通道读 xdg-settings 默认浏览器（本机 = zen.desktop），
-- 换默认浏览器这里自动跟着变，不写死 zen。私密窗口是 SUPER+SHIFT+ALT+B。
o.bind("SUPER + Z", "Browser", { omarchy = "browser" })
-- SUPER+L → 锁屏（出厂是 CTRL+SUPER+L，太长）。SUPER+L 原本是
-- "Toggle workspace layout"（dwindle/滚动布局切换），被这条征用。
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock system", "omarchy-system-lock")
-- 布局切换随后挪到 CTRL+SUPER+L（原来是锁屏），与上面互换。
hl.unbind("SUPER + CTRL + L")
o.bind("SUPER + CTRL + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
