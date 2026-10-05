local constants = require("constants")
local programs = constants.programs
local utils = require("utils")
local bindSuper = utils.bindSuper
local bindStandard = utils.bindStandard

-- Generic keybinds. For workspace keybinds see workspaces.lua; media keys: multimedia.lua.

bindSuper("Close window", hl.dsp.window.close(), "Q")
bindSuper("Exit Hyprland", 'sh "$HOME/.config/hypr/exit.sh"', "M")
bindSuper("Toggle floating", hl.dsp.window.float({ action = "toggle" }), "V")
bindSuper("Toggle pseudotiling", hl.dsp.window.pseudo(), "ALT", "P")
bindSuper("Toggle split direction", hl.dsp.layout("togglesplit"), "ALT", "J") -- dwindle only

-- Window Navigation
-- Move focus with super + homerow keys (vim style)
local navBinds = {
    { key = "H", dir = "left", name = "left" },
    { key = "J", dir = "down", name = "down" },
    { key = "K", dir = "up", name = "up" },
    { key = "L", dir = "right", name = "right" },
}

for _, bind in ipairs(navBinds) do
    bindSuper("Focus window " .. bind.name, hl.dsp.focus({ direction = bind.dir }), bind.key)
    -- Shift+H/J/K/L moves the window to the adjacent monitor and follows.
    bindSuper("Move window to the monitor " .. bind.name, function()
        local window = hl.get_active_window()
        local monitor = hl.get_monitor(bind.dir:sub(1, 1))
        if not window or not monitor or (window.monitor and window.monitor.id == monitor.id) then
            return
        end
        hl.dispatch(hl.dsp.window.move({ monitor = monitor.name, follow = true }))
    end, "SHIFT", bind.key)
    if bind.key == "J" or bind.key == "K" then
        -- Target the monitor directly, bypassing windows in the same monitor.
        bindSuper(
            "Focus the monitor " .. bind.name,
            hl.dsp.focus({ monitor = bind.dir:sub(1, 1) }),
            "CONTROL",
            bind.key
        )
    end
end

-- Basic Programs
local programsKeybinds = {
    { key = "RETURN", cmd = programs.menu, description = "Launcher (Walker)" },
    { key = "D", cmd = programs.terminal, description = "Terminal" },
    { key = "E", cmd = programs.fileManager, description = "File manager" },
    { key = "W", cmd = programs.webBrowser, description = "Web browser" },
}
for _, value in ipairs(programsKeybinds) do
    bindSuper(value.description, value.cmd, value.key)
end

-- Screenshots: the capture is copied, Shift+Print also saves it to ~/Pictures/Screenshots.
bindStandard("Screenshot to the clipboard", function()
    utils.takeScreenshot("clipboard")
end, "PRINT")
bindStandard("Screenshot to the clipboard and a file", function()
    utils.takeScreenshot("file")
end, "SHIFT", "PRINT")
