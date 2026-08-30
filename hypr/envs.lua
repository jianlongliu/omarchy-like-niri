-- Environment variables and XWayland rendering behavior.
-- Mirrors default.hypr.envs (fcitx5 overrides omarchy's stale fcitx4 defaults).

-- Input method: fcitx5.
hl.env("GTK_IM_MODULE", "fcitx5")
hl.env("QT_IM_MODULE", "fcitx5")
hl.env("XMODIFIERS", "@im=fcitx5")
hl.env("SDL_IM_MODULE", "fcitx5")
hl.env("GLFW_IM_MODULE", "ibus")

-- gum confirm 选中项用独立文字色，避免默认主题下透明+模糊看不清 Yes/No 选中哪个。
hl.env("GUM_CONFIRM_SELECTED_FOREGROUND", "#a6e3a1")

-- Render XWayland apps at native resolution (scale 1) and let each app scale
-- itself via DPI, so they stay crisp under fractional 1.6 scaling instead of being
-- bitmap-upscaled. This mirrors niri/xwayland-satellite's "force_unscaled" behavior.
-- Pair with Xft.dpi (~154) so X11 apps that don't read DPI still size correctly.
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})
