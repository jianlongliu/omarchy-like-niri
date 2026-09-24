-- Personal window rules. Mirrors default.hypr.windows.
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Glassy/blurred nautilus so it matches the Omarchy liquid-glass surfaces.
-- Global decoration.blur is already enabled; lowering opacity lets the blur show through.
-- float = true: nautilus opens as a floating window (file managers feel better floating).
o.window("org.gnome.Nautilus", { float = true, opacity = "0.88 0.82" })
o.window("org.gnome.Loupe", { opacity = "0.88 0.82" })

-- Don't lock the screen while Zen Browser is open (watching bilibili etc., windowed or fullscreen).
o.window("zen", { idle_inhibit = "always", opacity = "0.92 0.88" })

-- Chromium: work ticketing system (needs a Windows UA). Match the exact class so
-- the "zen" rule above never touches it; keep it from locking too.
o.window("^org\\.chromium\\.Chromium$", { idle_inhibit = "always", opacity = "0.92 0.88" })

-- Glassy flea (Quickshell file manager) so it matches the Omarchy liquid-glass look.
-- Global decoration.blur is enabled; the lowered opacity lets the blur show through.
o.window("com.thisisgm.flea", { opacity = "0.92 0.88" })

-- Discord / QQ / ColaMD: same treatment as Zen above — translucent so the global blur
-- shows through. Electron (Discord, ColaMD) and Qt (QQ) both draw an opaque
-- background, so the app itself can't be made transparent from the outside;
-- whole-window opacity is the only lever. Same value as Zen on purpose: omarchy's
-- default-opacity tag rule (0.985 0.96) is a multiplier, so 0.92/0.88 lands on the
-- identical result.
o.window("discord", { opacity = "0.92 0.88" })
o.window("^QQ$", { opacity = "0.92 0.88" })
o.window("^colamd$", { opacity = "0.92 0.88" })

-- yazi (SUPER+Y) and btop (CTRL+SHIFT+ESCAPE): float, centered, roomy.
-- Omarchy hands btop the "floating-window" tag, whose 875x600 is too cramped for
-- a TUI (btop loses its columns, yazi its preview pane). The tag's rules are
-- applied as *dynamic* rules — after every static rule — so a later plain
-- `size` override loses to them. Hence: opt out of the tag and restate
-- float/center/size here instead of editing the shared tag (dialogs and file
-- pickers reuse it and want the small default).
o.window("^(org\\.omarchy\\.btop|org\\.omarchy\\.yazi)$", {
  tag = "-floating-window",
  float = true,
  center = true,
  size = { 1280, 800 },
})
o.window("org.omarchy.yazi", { opacity = "0.92 0.88"})
