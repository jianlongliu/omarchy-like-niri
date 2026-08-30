-- Window and layer rules for the Omarchy Quickshell surfaces. The shell-wide
-- bar / menu / popouts are layer-shell. Mirrors default.hypr.apps.omarchy-shell.
-- NOTE: ~/.config/hypr/apps/ is NOT auto-required by Omarchy; it's loaded from
-- hyprland.lua (require "hypr.apps.omarchy-shell").

-- Liquid glass blur for the shell layers.
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$" }, blur = true, blur_popups = true, ignore_alpha = 0.5 })
-- Full-screen transparent overlays: blur only the toast/card pixels.
hl.layer_rule({ match = { namespace = "^(omarchy-notifications|omarchy-osd)$" }, blur = true, ignore_alpha = 0.5 })
-- Workspace overview: full-screen glass scrim behind the workspace grid.
hl.layer_rule({ match = { namespace = "omarchy-workspace-overview" }, blur = true, ignore_alpha = 0.5 })
-- Full-screen scrim + centered card: blur only the card (threshold sits between scrim and card alpha).
hl.layer_rule({ match = { namespace = "omarchy-polkit" }, blur = true, ignore_alpha = 0.75 })
hl.layer_rule({ match = { namespace = "omarchy-reminders" }, blur = true, ignore_alpha = 0.5 })
-- Omarchy Find overlay: full-screen scrim + centered card, same shape as polkit/menu.
hl.layer_rule({ match = { namespace = "omarchy-find" }, blur = true, ignore_alpha = 0.5 })
-- Lock screen: full-screen blur is the intended lock look.
hl.layer_rule({ match = { namespace = "omarchy-lock-preview" }, blur = true })
-- Omasnap capture overlay: no animation, excluded from screen share.
hl.layer_rule({ match = { namespace = "^omasnap$" }, no_anim = true, animation = "none", no_screen_share = true })
