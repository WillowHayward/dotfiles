-- Machine profile (home, work or remote) and the optional features it enables.
-- WHC_PROFILE is exported by zsh from /etc/environment; read the file directly
-- when Neovim is started from something that did not go through zsh.
local M = {}

local function read_profile()
	local name = vim.env.WHC_PROFILE
	if name and name ~= "" then
		return name
	end
	local ok, lines = pcall(vim.fn.readfile, "/etc/environment")
	if not ok then
		return nil
	end
	for _, line in ipairs(lines) do
		name = line:match('^%s*WHC_PROFILE%s*=%s*"?([%w_-]+)"?') or name
	end
	return name
end

M.name = read_profile() or "home"
M.features = {
	godot = M.name == "home", -- Game development happens on the home machine only.
	ai = M.name ~= "remote", -- Sidekick/Codex; the remote profile uses plain Vim anyway.
}

return M
