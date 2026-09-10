-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- Thicker window borders (default is 2).
hl.config({
  general = {
    border_size = 5,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 10,

    blur = {
      enabled = true,
      size = 8,
      passes = 5,
      -- 关掉 xray：模糊取背后真实内容(含窗口)，不再只糊壁纸。
      -- 代价是浮动层模糊开销略高，6950 XT 无压力。
      xray = false,
      vibrancy = 0.5,
      brightness = 1.05,
      contrast = 0.95,
      input_methods = true,
    },
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- Smooth niri-like workspace transition when switching via SUPER+scroll or keys.
-- (Omarchy's default disables the `workspaces` animation, so switching is a hard cut.)
-- Vertical slide to match niri's vertical workspace stack.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })

-- Smooth fade when switching focus between windows on the SAME workspace
-- (e.g. Super+Shift+scroll app switching). Omarchy defaults this OFF, so
-- in-workspace focus changes were a hard cut. NOTE: this is global — it also
-- fades focus switches via Super+arrows etc.
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 5, bezier = "easeOutQuint" })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- BEGIN charlieras262.omablur
hl.config({
  decoration = {
    rounding = 20,
    blur = {
      enabled = true,
      size = 11,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
    },
  },
})
-- END charlieras262.omablur
