-- Shared RPC endpoint for external editors (including Godot).
local M = {}
local pipepath = vim.env.NVIM_EDITOR_SOCKET or "/tmp/server.pipe"
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
