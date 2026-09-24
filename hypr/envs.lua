-- Environment variables and XWayland rendering behavior.
-- Mirrors default.hypr.envs (fcitx5 overrides omarchy's stale fcitx4 defaults).

-- Input method: fcitx5.
-- GTK_IM_MODULE intentionally NOT set: it routes GTK apps onto fcitx5's in-process
-- GTK im module, which draws the candidate window itself (ClientSideInputPanel)
-- and seams under fractional scaling (1.6x). Unset lets GTK3/GTK4 use the Wayland
-- text-input protocol (both bind zwp_text_input_manager_v3), so fcitx5 draws the
-- popup itself -- seamless.
-- QT_IM_MODULE stays fcitx5: /usr/lib/environment.d/10-omarchy-fcitx.conf sets
-- QT_IM_MODULE=fcitx (the fcitx *4* era name) and environment.d has no way to
-- unset a variable, so dropping ours would just let that value through. It is
-- harmless either way -- libfcitx5platforminputcontextplugin.so registers both
-- the "fcitx" and "fcitx5" keys -- so this line is explicit, not a workaround.
-- Qt stays on the im-module route because no Qt seam has ever been observed
-- (the seam is a GTK4 im-module artifact) and unsetting is not possible anyway.
-- hl.env("GTK_IM_MODULE", "fcitx5")
hl.env("QT_IM_MODULE", "fcitx5")
hl.env("XMODIFIERS", "@im=fcitx5")
-- SDL/GLFW apps don't speak text-input; keep their module route as fallback.
hl.env("SDL_IM_MODULE", "fcitx5")
hl.env("GLFW_IM_MODULE", "ibus")

-- Cursor theme: Bibata Modern Amber (AUR bibata-cursor-theme).
hl.env("XCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("XCURSOR_SIZE", "30")
hl.env("HYPRCURSOR_SIZE", "30")

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
