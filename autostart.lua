-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Load hyprpm plugins (scrolloverview, etc.) at startup. hyprpm marks plugins
-- as "enabled" but they are only injected into Hyprland by `hyprpm reload`,
-- which must run after the compositor is up. Without this, a reboot leaves the
-- plugins unloaded and their config keys report "unknown config key".
-- The trailing `hyprctl reload` re-runs plugins.lua so plugins.gated config
-- (guarded on hl.plugin.<name>) is applied once the plugin is loaded.
--
-- Instead of a fixed `sleep 2` (which races on slow/cold boots), poll until the
-- Hyprland socket answers `hyprctl ping`, then reload. Bounded attempts so a
-- broken session can't hang the autostart forever. Runs via `exec_cmd` (a child
-- shell), never during config parse, so no IPC re-entrancy deadlock.
hl.on("hyprland.start", function()
  hl.exec_cmd([[
for i in $(seq 1 50); do
  if hyprctl ping >/dev/null 2>&1; then break; fi
  sleep 0.2
done
hyprpm reload && hyprctl reload
]])
end)
