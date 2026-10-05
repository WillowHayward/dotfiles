-- Agentic AI through Sidekick: Codex and Claude on home, Copilot on work (whc.profile).
-- Copilot *completion* is separate (plugins/completion.lua). Each tool runs through
-- scripts/ai-run.sh so it gets its own shell environment and per-project history.
local profile = require("whc.profile")
local features = profile.features

if not features.ai then
    return {}
end

local function ai()
    return require("whc.ai")
end

local function codex_send(message)
    return function()
        ai().send({ msg = message })
    end
end

local function key(lhs, rhs, desc, mode)
    return { lhs, rhs, desc = desc, mode = mode or "n" }
end

local keys = {
    key("<leader>aa", function()
        ai().toggle()
    end, "Toggle the agent window"),
    key("<leader>aT", function()
        ai().choose()
    end, "Choose the agent tool"),
    key("<leader>ad", function()
        require("sidekick.cli").close({ name = ai().current })
    end, "Detach agent session"),
    key("<leader>as", function()
        require("sidekick.cli").select({ filter = { name = ai().current } })
    end, "Select agent session"),
    key("<leader>ap", function()
        require("sidekick.cli").prompt({
            cb = function(_, text)
                if text then
                    ai().send({ text = text })
                end
            end,
        })
    end, "Choose agent prompt", { "n", "x" }),
    key("<leader>at", codex_send("{this}"), "Send this to the agent", { "n", "x" }),
    key("<leader>af", codex_send("{file}"), "Send file to the agent"),
    key("<leader>av", codex_send("{selection}"), "Send selection to the agent", "x"),
    key("<leader>ae", codex_send("Explain {this}"), "Ask the agent to explain", { "n", "x" }),
    key("<leader>ar", codex_send("Can you review {file} for issues?"), "Ask the agent to review"),
    -- Quick wins: q/Q for the current file, w/W for the whole workspace.
    key(
        "<leader>aq",
        codex_send(
            "Suggest one quick win in {file}: a small, concrete improvement with a clear benefit. Explain what to change and why."
        ),
        "Agent: one quick win in file"
    ),
    key(
        "<leader>aQ",
        codex_send(
            "Suggest ten quick wins in {file}: small, concrete improvements with clear benefits. Rank them by impact versus effort and explain what to change and why."
        ),
        "Agent: ten quick wins in file"
    ),
    key(
        "<leader>aw",
        codex_send(
            "Explore the entire project containing {file} and suggest one quick win across the project: a small, concrete improvement with a clear benefit. Look beyond the current file; identify the relevant files and explain what to change and why."
        ),
        "Agent: one quick win in project"
    ),
    key(
        "<leader>aW",
        codex_send(
            "Explore the entire project containing {file} and suggest ten quick wins across the project: small, concrete improvements with clear benefits. Rank them by impact versus effort, identify the relevant files, and explain what to change and why."
        ),
        "Agent: ten quick wins in project"
    ),
}
-- A second tool gets its own toggle: <leader>ac opens Claude when the profile offers it.
for _, tool in ipairs(features.ai_tools) do
    if tool == "claude" then
        table.insert(
            keys,
            key("<leader>ac", function()
                ai().toggle("claude")
            end, "Toggle the Claude window")
        )
    end
end

return {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    event = vim.env.WHC_PROJECT_ROOT and "VimEnter" or nil,
    keys = keys,
    dependencies = {
        {
            "folke/snacks.nvim",
            opts = { picker = { enabled = true } },
        },
        {
            "nvim-treesitter/nvim-treesitter-textobjects",
            branch = "main",
            dependencies = { "nvim-treesitter/nvim-treesitter" },
        },
    },
    opts = function()
        local dotfiles = vim.env.WHC_DOTFILES_DIR or vim.fn.expand("~/dotfiles")
        local tools = {}
        for _, name in ipairs(features.ai_tools) do
            local executable = vim.fn.exepath(name)
            -- The desktop app bundles Codex, but regular terminals may not have it on PATH.
            if name == "codex" and executable == "" and vim.fn.executable("/usr/lib/chatgpt/resources/codex") == 1 then
                executable = "/usr/lib/chatgpt/resources/codex"
            end
            tools[name] = {
                cmd = { dotfiles .. "/scripts/ai-run.sh", executable ~= "" and executable or name },
                env = { WHC_AI = "true", SHELL = "/bin/bash", TMUX = false, TMUX_PANE = false },
            }
        end
        return {
            -- Next edit suggestions would need Sidekick to drive the Copilot LSP; completion only for now.
            nes = { enabled = false },
            cli = {
                win = {
                    layout = "float",
                    float = { width = 0.8, height = 0.8, border = "rounded" },
                    keys = {
                        hide_ctrl_g = { "<C-g>", "hide", mode = "nt", desc = "Hide AI; keep command running" },
                        hide_alt_q = { "<M-q>", "hide", mode = "nt" },
                        stopinsert = false, -- Avoid the default duplicate Ctrl-Q mapping.
                    },
                },
                mux = { enabled = false },
                tools = tools,
            },
        }
    end,
    config = function(_, opts)
        require("sidekick").setup(opts)
        local root = vim.env.WHC_PROJECT_ROOT
        if not root then
            return
        end
        vim.schedule(function()
            local win = vim.api.nvim_get_current_win()
            local terminal = require("whc.ai").attach(root).terminal
            if terminal and terminal.hide then
                terminal:hide()
            end
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
                vim.cmd.stopinsert()
            end
            -- Sidekick briefly creates a float to start its terminal job.
            -- Repaint after hiding it so startup cannot retain its old grid.
            vim.cmd("redraw!")
        end)
    end,
}
