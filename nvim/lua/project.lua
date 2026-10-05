local M = {}

local function metadata()
	local script = (vim.env.WHC_DOTFILES_DIR or (vim.env.HOME .. "/dotfiles")) .. "/walker/tmux-projects.py"
	local result = vim.system({ "python3", script, "roots", vim.fn.getcwd() }, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("Cannot load .whc workspace roots: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
		return { root = vim.fn.getcwd(), search_dirs = { "." } }
	end
	local ok, value = pcall(vim.json.decode, result.stdout)
	if not ok or type(value) ~= "table" then
		vim.notify("Invalid project metadata response", vim.log.levels.WARN)
		return { root = vim.fn.getcwd(), search_dirs = { "." } }
	end
	return value
end

local function workspace_options()
	local project = metadata()
	return { cwd = project.root, search_dirs = project.search_dirs }
end

function M.find_files()
	require("telescope.builtin").find_files(workspace_options())
end

function M.live_grep()
	require("telescope.builtin").live_grep(workspace_options())
end

function M.grep_string()
	require("telescope.builtin").grep_string(workspace_options())
end

return M
