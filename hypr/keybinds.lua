local constants = require("constants")
local programs = constants.programs
local utils = require("utils")
local bindSuper = utils.bindSuper
local bindStandard = utils.bindStandard

-- Generic keybinds. For workspace keybinds see workspaces.lua

bindSuper(hl.dsp.window.close(), "Q")

-- Window Navigation
-- Move focus with super + homerow keys (vim style)
local navBinds = {
	{ key = "H", dir = "left" },
	{ key = "J", dir = "down" },
	{ key = "K", dir = "up" },
	{ key = "L", dir = "right" },
}

for _, bind in ipairs(navBinds) do
	bindSuper(hl.dsp.focus({ direction = bind.dir }), bind.key)
	if bind.key == "H" or bind.key == "L" then
		-- Shift+H/L moves the current window to an adjacent workspace and follows.
		bindSuper(function()
			require("workspace_utils").moveWindowRelativeWorkspace(bind.key == "H" and -1 or 1)
		end, "SHIFT", bind.key)
	else
		-- Shift+J/K moves the window to the monitor below/above and follows.
		bindSuper(function()
			local window = hl.get_active_window()
			local monitor = hl.get_monitor(bind.dir:sub(1, 1))
			if not window or not monitor or (window.monitor and window.monitor.id == monitor.id) then
				return
			end
			hl.dispatch(hl.dsp.window.move({ monitor = monitor.name, follow = true }))
		end, "SHIFT", bind.key)
		-- Target the monitor directly, bypassing windows in the same monitor.
		bindSuper(hl.dsp.focus({ monitor = bind.dir:sub(1, 1) }), "CONTROL", bind.key)
	end
end

-- Basic Programs
local programsKeybinds = {
	{ key = "RETURN", cmd = programs.menu },
	{ key = "D", cmd = programs.terminal },
	{ key = "E", cmd = programs.fileManager },
	{ key = "W", cmd = programs.webBrowser },
	{ key = "PRINT", cmd = utils.takeScreenshot, noSuper = true },
}

for _, value in ipairs(programsKeybinds) do
	if value.noSuper then
		bindStandard(value.cmd, value.key)
	else
		bindSuper(value.cmd, value.key)
	end
end
