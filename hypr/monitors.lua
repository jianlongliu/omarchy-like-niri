-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- GDK_SCALE removed: native Wayland apps ignore it, and with force_zero_scaling=true
-- XWayland apps render at native resolution and scale themselves via DPI. Setting GDK_SCALE
-- would double-scale XWayland GTK apps.
local omarchy_monitor_scale = 1.6

hl.monitor({
    output = "DP-2",
    mode = "3840x2160@144",
    position = "auto",
    scale = omarchy_monitor_scale,
    bitdepth = 10,
 -- cm = "srgb",
 -- sdrbrightness = 1.0,
 -- sdrsaturation = 1.0,
 -- sdr_min_luminance = 0.2,
 -- sdr_max_luminance = 400
})

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "3840x2160@144", position = "0x0", scale = 2 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
