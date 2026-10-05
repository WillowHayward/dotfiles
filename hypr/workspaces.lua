local utils = require("utils")
local bindSuper = utils.bindSuper

local workspaceUtils = require("workspace_utils")
local focusAbsoluteWorkspace = workspaceUtils.focusAbsoluteWorkspace

require("workspace_rules")

bindSuper(focusAbsoluteWorkspace("previous"), "SHIFT", "O")

-- Each monitor owns ten numbered workspaces: 1–10, 11–20, 21–30, ...
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	bindSuper(workspaceUtils.focusMonitorWorkspace(i), key)
	bindSuper(workspaceUtils.moveWindowToMonitorWorkspace(i), "SHIFT", key)
end

bindSuper(function() workspaceUtils.insertWorkspace(1) end, "N")
bindSuper(function() workspaceUtils.insertWorkspace(1, true) end, "SHIFT", "N")
bindSuper(function() workspaceUtils.insertWorkspace(-1) end, "P")
bindSuper(function() workspaceUtils.insertWorkspace(-1, true) end, "SHIFT", "P")

-- Skip empty workspaces within the active monitor's range.
bindSuper(workspaceUtils.focusNextWorkspace, "CONTROL", "L")
bindSuper(workspaceUtils.focusNextWorkspace, "mouse_down")
bindSuper(workspaceUtils.focusPreviousWorkspace, "CONTROL", "H")
bindSuper(workspaceUtils.focusPreviousWorkspace, "mouse_up")

-- Special workspaces
local specialWorkspaces = {
	{ key = "G", name = "game" },
	{ key = "S", name = "scratch" },
	{
		key = "A",
		name = "ai",
		rules = {
            on_created_empty = "[workspace special:ai silent] chatgpt --ozone-platform=wayland",
		},
	},
}
for _, bind in ipairs(specialWorkspaces) do
	local workspaceName = "special:" .. bind.name
	bindSuper(hl.dsp.workspace.toggle_special(bind.name), bind.key)
	bindSuper(hl.dsp.window.move({ workspace = workspaceName }), "SHIFT", bind.key)
	if bind.rules then
		local rule = { workspace = workspaceName }
		for property, value in pairs(bind.rules) do
			rule[property] = value
		end
		hl.workspace_rule(rule)
	end
end
