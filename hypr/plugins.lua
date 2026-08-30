-- Third-party Hyprland plugin config (no Omarchy default counterpart).
-- ScrollOverview (yayuuu/hyprland-scroll-overview): niri-style scroll overview.
--
-- Guard on hl.plugin.scrolloverview so the config is only submitted once the
-- plugin is actually injected (via `hyprpm reload`, see autostart.lua). At the
-- first config parse the plugin isn't loaded yet, so hl.plugin.scrolloverview is
-- nil and we skip — otherwise Hyprland logs "unknown config key".
if hl.plugin.scrolloverview ~= nil then
  hl.config({
    plugin = {
      scrolloverview = {
        gesture_distance = 300,
        scale = 0.8,
        workspace_gap = 100,
        layout = "vertical",
        wallpaper = 2,
        blur = true,
        shadow = { enabled = true, range = 50 },
      },
    },
  })
end
