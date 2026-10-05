local workspaceUtils = require("workspace_utils")
local normalizeWorkspace = workspaceUtils.normalizeWorkspace
local focusAbsoluteWorkspace = workspaceUtils.focusAbsoluteWorkspace

-- General rules
local defaultRules = {}
local function registerMonitorDefault(monitor)
	if monitor.is_mirror then
		return
	end
	if not defaultRules[monitor.name] then
		defaultRules[monitor.name] = hl.workspace_rule({
			workspace = tostring(normalizeWorkspace(1, monitor)),
			monitor = monitor.name,
			default = true,
		})
	end
end

local function applyMonitorDefault(monitor, preserveCurrent)
	if monitor.is_mirror then
		return
	end
	registerMonitorDefault(monitor)
	local first = normalizeWorkspace(1, monitor)
	local current = monitor.active_workspace
	if preserveCurrent and current and current.id >= first and current.id < first + 10 then
		return
	end
	-- Use dispatchers so the workspace is created if it does not exist yet.
	local focused = hl.get_active_monitor()
	if hl.get_workspace(first) then
		hl.dispatch(hl.dsp.workspace.move({ workspace = first, monitor = monitor.name }))
	end
	hl.dispatch(hl.dsp.focus({ monitor = monitor.name }))
	hl.dispatch(focusAbsoluteWorkspace(first))
	if focused and focused.name ~= monitor.name then
		hl.dispatch(hl.dsp.focus({ monitor = focused.name }))
	end
end

-- Register rules on reload; monitor objects may not exist during initial parsing.
for _, monitor in ipairs(hl.get_monitors()) do
	registerMonitorDefault(monitor)
end
hl.on("monitor.added", function(monitor)
	applyMonitorDefault(monitor, false)
end)
hl.on("hyprland.start", function()
	for _, monitor in ipairs(hl.get_monitors()) do
		applyMonitorDefault(monitor, false)
	end
end)
hl.on("config.reloaded", function()
	for _, monitor in ipairs(hl.get_monitors()) do
		applyMonitorDefault(monitor, true)
	end
end)

-- Route the portrait game preview to DVI-I-1; retain Super + G access.
hl.workspace_rule({
	workspace = "special:game",
	monitor = "eDP-1",
})
hl.window_rule({
	name = "godot-game-workspace",
	match = { class = "^Farm The Revolution$" },
	workspace = "special:game",
	monitor = "eDP-1",
	float = true,
	size = { 360, 640 },
	center = true,
})

-- Stop flameshot from moving windows
hl.window_rule({
	name = "flameshot-screen-isolation",
	match = { class = "flameshot" },
	float = true,
	pin = true,
	no_anim = true,
	border_size = 0,
	rounding = 0,
	-- Fixed: Singular field name and space-separated string value
	suppress_event = "fullscreen maximize activate",
	move = "0 0",
})
