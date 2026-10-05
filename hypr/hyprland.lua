-- Hyprland configuration (Lua). This file only wires the modules together:
--   constants, utils, device   shared helpers; device settings come from devices/<WHC_DEVICE>.lua
--   styling, titlebars, input  look, window bars, keyboard/pointer
--   keybinds, workspaces, multimedia   binds (all described, see `just keybinds`)
--   rules                      window rules; local.lua (untracked) holds personal ones
-- Docs: https://wiki.hypr.land/Configuring/Start/

-- Monitors: a catch-all default, overridden by HyprMon's generated hyprmon.lua at the end.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

require("startup")

-- Environment variables, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

require("styling")
require("titlebars")
require("input")
require("keybinds")
require("workspaces")
require("multimedia")
require("rules")

-- Untracked personal rules, if present; a real error in the file is shown, a missing file is not.
local ok, err = pcall(require, "local")
if not ok and not tostring(err):find("module 'local' not found", 1, true) then
    hl.notification.create({ text = "hypr/local.lua: " .. tostring(err), timeout = 8000 })
end

-- hyprmon: managed monitor profile include
require("hyprmon")
