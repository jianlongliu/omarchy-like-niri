-- Personal window rules. Mirrors default.hypr.windows.
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Glassy/blurred nautilus so it matches the Omarchy liquid-glass surfaces.
-- Global decoration.blur is already enabled; lowering opacity lets the blur show through.
-- float = true: nautilus opens as a floating window (file managers feel better floating).
o.window("org.gnome.Nautilus", { float = true, opacity = "0.88 0.82" })
o.window("org.gnome.Loupe", { opacity = "0.88 0.82" })

-- Don't lock the screen while Zen Browser is open (watching bilibili etc., windowed or fullscreen).
o.window("zen", { idle_inhibit = "always", opacity = "0.92 0.88" })
