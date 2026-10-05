-- Shared RPC endpoint for external editors (including Godot).
-- The default lives in the per-user runtime directory (falling back to Neovim's
-- state directory) rather than world-writable /tmp, where another local user
-- could pre-create the path or connect to the socket. bin/godot-editor must
-- resolve the same default.
local M = {}
local function default_pipepath()
	local directory = vim.env.XDG_RUNTIME_DIR
	if not directory or directory == "" then
		directory = vim.fn.stdpath("state")
		vim.fn.mkdir(directory, "p", "0o700")
	end
	return directory .. "/nvim-editor.pipe"
end
local pipepath = vim.env.NVIM_EDITOR_SOCKET or default_pipepath()
local listening = false
if vim.uv.fs_stat(pipepath) then
	local ok, channel = pcall(vim.fn.sockconnect, "pipe", pipepath, { rpc = true })
	listening = ok and channel > 0
	if listening then
		vim.fn.chanclose(channel)
	else
		vim.uv.fs_unlink(pipepath)
	end
end
if not listening then
	vim.fn.serverstart(pipepath)
end

-- Accept structured arguments instead of interpolating file names into Ex commands.
function M.open(args)
	local bufnr = vim.fn.bufadd(args[1])
	vim.fn.bufload(bufnr)
	vim.api.nvim_set_current_buf(bufnr)
	local row = math.max(1, math.min(tonumber(args[2]) or 1, vim.api.nvim_buf_line_count(bufnr)))
	local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
	local col = math.max(0, math.min((tonumber(args[3]) or 1) - 1, #line))
	vim.api.nvim_win_set_cursor(0, { row, col })
	vim.cmd("normal! zz")
	return true
end
return M
