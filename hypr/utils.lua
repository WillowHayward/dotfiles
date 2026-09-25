local superKey = require("constants").keys.super
local function bindSuper(action, ...)
    local keys = table.concat({ ... }, " + ")

    if type(action) == "string" then
        action = hl.dsp.exec_cmd(action)
    end

    hl.bind(superKey .. " + " .. keys, action)
end

local function bindStandard(action, ...)
    local keys = table.concat({ ... }, " + ")
    if type(action) == "string" then
        action = hl.dsp.exec_cmd(action)
    end
    hl.bind(keys, action)
end

local function takeScreenshot()
    local mon = hl.get_active_monitor()
    local n = mon and mon.id or 0
    hl.exec_cmd("flameshot screen --number " .. n .. " -c -e ")
end


return {
    bindSuper = bindSuper,
    bindStandard = bindStandard,
    takeScreenshot = takeScreenshot,
}
