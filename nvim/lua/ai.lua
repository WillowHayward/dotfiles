-- Sidekick CLI uses Codex; Copilot completion remains configured in lsp.lua.
return {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    event = vim.env.WHC_PROJECT_ROOT and "VimEnter" or nil,
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
        -- The desktop app bundles Codex, but regular terminals may not have it on PATH.
        local codex = vim.fn.exepath("codex")
        if codex == "" and vim.fn.executable("/usr/lib/chatgpt/resources/codex") == 1 then
            codex = "/usr/lib/chatgpt/resources/codex"
        end
        return {
            -- Next edit suggestions require a separate Copilot LSP, not Codex.
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
                tools = {
                    codex = {
                        cmd = {
                            vim.fn.expand((vim.env.WHC_DOTFILES_DIR or "~/dotfiles") .. "/scripts/ai-codex.sh"),
                            codex ~= "" and codex or "codex",
                        },
                        env = { WHC_AI = "true", SHELL = "/bin/bash", TMUX = false, TMUX_PANE = false },
                    },
                },
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
            local terminal = require("ai-context").attach(root).terminal
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
