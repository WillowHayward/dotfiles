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
	-- Native pixels and output-name selection for mixed-scale monitors.
	hl.exec_cmd('"$HOME/.config/hypr/flameshot.sh"')
end

return {
	bindSuper = bindSuper,
	bindStandard = bindStandard,
	takeScreenshot = takeScreenshot,
}
