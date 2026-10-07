-- Machine profile (home, work, remote or mobile) and the optional features it enables.
-- WHC_PROFILE is exported by zsh from /etc/environment ($PREFIX/etc/environment in
-- Termux); read the file directly when Neovim is started from something that did not go
-- through zsh.
local M = {}

local function read_profile()
    local name = vim.env.WHC_PROFILE
    if name and name ~= "" then
        return name
    end
    local prefix = vim.env.PREFIX
    local termux = vim.env.TERMUX_VERSION or (prefix and prefix:find("/com.termux/", 1, true))
    local ok, lines = pcall(vim.fn.readfile, termux and prefix .. "/etc/environment" or "/etc/environment")
    if not ok then
        return nil
    end
    for _, line in ipairs(lines) do
        name = line:match('^%s*WHC_PROFILE%s*=%s*"?([%w_-]+)"?') or name
    end
    return name
end

M.name = read_profile() or "home"

-- Agentic tools Sidekick offers, first one is the default: Claude and Codex on the
-- personal machines, Copilot on the work machine; none on the phone, which drives the
-- agents running on the workstation instead. (Copilot *completion* is on everywhere.)
local agent_tools = { home = { "codex", "claude" }, work = { "copilot" } }

M.features = {
    godot = M.name == "home", -- Game development happens on the home machine only.
    ai = agent_tools[M.name] ~= nil,
    ai_tools = agent_tools[M.name] or {},
}

return M
