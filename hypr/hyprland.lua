-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")


-- BEGIN firstpick.keybindings capture
local keybindings_editor
local keybindings_editor_path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/omarchy/plugins/firstpick.keybindings/bridge.lua"
local keybindings_editor_file = io.open(keybindings_editor_path, "r")
if keybindings_editor_file then
  keybindings_editor_file:close()
  keybindings_editor = dofile(keybindings_editor_path)
  keybindings_editor.start()
end
-- END firstpick.keybindings capture
-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.envs")
require("hypr.windows")
require("hypr.apps.omarchy-shell")
require("hypr.plugins")

-- Toggle config flags dynamically.
require("default.hypr.toggles")


-- BEGIN firstpick.keybindings apply
if keybindings_editor then keybindings_editor.finish() end
-- END firstpick.keybindings apply
