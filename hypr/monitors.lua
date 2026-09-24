-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- GDK_SCALE removed: native Wayland apps ignore it, and with force_zero_scaling=true
-- XWayland apps render at native resolution and scale themselves via DPI. Setting GDK_SCALE
-- would double-scale XWayland GTK apps.
local omarchy_monitor_scale = 1.6

hl.monitor({
    output = "DP-2",
    mode = "3840x2160@120",
    position = "0x0",
    scale = omarchy_monitor_scale,
    bitdepth = 10,
 -- cm = "srgb",
 -- sdrbrightness = 1.0,
 -- sdrsaturation = 1.0,
 -- sdr_min_luminance = 0.2,
 -- sdr_max_luminance = 400
})

-- Portable BOE 2560x1600, placed to the LEFT of DP-2.
-- Logical width at scale 1.6 is 1600, so it spans -1600..0 and DP-2 keeps 0..2400.
-- Disabled 2026-09-16 (secondary display retired). Kept for reference.
-- hl.monitor({
--     output = "HDMI-A-1",
--     mode = "2560x1600@120",
--     position = "-1600x0",
--     scale = omarchy_monitor_scale,
-- })

-- Pin workspace 6 to the portable display. It is the single workspace used
-- there for video; the SUPER+scroll binds in bindings.lua are scoped to
-- DP-2 only (1..5), so scrolling never drags focus across to this screen.
-- Disabled together with the monitor above (2026-09-16).
-- hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "3840x2160@144", position = "0x0", scale = 2 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
