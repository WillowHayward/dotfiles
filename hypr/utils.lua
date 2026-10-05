local superKey = require("constants").keys.super

-- Binding helpers. Every bind carries a description (shown by `just keybinds` through
-- `hyprctl binds -j`):  bindSuper("Close window", hl.dsp.window.close(), "Q")
-- A trailing table is passed through as bind options, e.g. { locked = true }.
local function parse(...)
    local args = { ... }
    local options = {}
    if type(args[#args]) == "table" then
        for key, value in pairs(table.remove(args)) do
            options[key] = value
        end
    end
    return table.concat(args, " + "), options
end

local function bind(prefix, description, action, ...)
    local keys, options = parse(...)
    if type(action) == "string" then
        action = hl.dsp.exec_cmd(action)
    end
    options.description = description
    hl.bind(prefix .. keys, action, options)
end

local function bindSuper(description, action, ...)
    bind(superKey .. " + ", description, action, ...)
end

local function bindStandard(description, action, ...)
    bind("", description, action, ...)
end

-- Native pixels and output-name selection for mixed-scale monitors (see flameshot.md).
-- mode "clipboard" copies the capture; "file" saves it under ~/Pictures/Screenshots.
local function takeScreenshot(mode)
    hl.exec_cmd('"$HOME/.config/hypr/flameshot.sh" ' .. (mode or "clipboard"))
end

return {
    bindSuper = bindSuper,
    bindStandard = bindStandard,
    takeScreenshot = takeScreenshot,
}
