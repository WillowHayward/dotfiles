-- Git: hunks and blame (gitsigns), full-screen review and history (diffview), a Magit-style
-- status buffer (neogit), lazygit through Snacks (themed from the colour scheme, opens files in
-- this Neovim; see plugins/ui.lua), GitHub issues/PRs (octo), SOPS files.
-- All keys live under <leader>g.
return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            current_line_blame_opts = {
                virt_text_pos = "right_align",
                delay = 0,
            },
            on_attach = function(buffer)
                local gs = require("gitsigns")
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
                end
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gs.nav_hunk("next")
                    end
                end, "Next hunk")
                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "Previous hunk")
                map("n", "<leader>gs", gs.stage_hunk, "Stage or unstage hunk")
                map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
                map("x", "<leader>gs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage selected lines")
                map("x", "<leader>gr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Reset selected lines")
                map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
                map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
                map("n", "<leader>gp", gs.preview_hunk_inline, "Preview hunk")
                map("n", "<leader>gB", function()
                    gs.blame_line({ full = true })
                end, "Blame line (full)")
                map("n", "<leader>gD", gs.diffthis, "Diff against the index")
                map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
            end,
        },
        keys = {
            { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame <CR>", desc = "Toggle line blame" },
        },
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view: working tree (also the merge tool)" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
            { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Repository history" },
            { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
        },
        opts = {},
    },
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim", "nvim-telescope/telescope.nvim" },
        opts = { integrations = { diffview = true, telescope = true } },
        keys = {
            { "<leader>gn", "<cmd>Neogit<CR>", desc = "Neogit status" },
            { "<leader>gC", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        optional = true,
        keys = {
            {
                "<leader>gb",
                function()
                    require("telescope.builtin").git_branches()
                end,
                desc = "Find git branch",
            },
            {
                "<leader>gf",
                function()
                    require("telescope.builtin").git_files()
                end,
                desc = "git ls-files",
            },
            {
                "<leader>gl",
                function()
                    require("telescope.builtin").git_commits()
                end,
                desc = "Git log",
            },
            {
                "<leader>gz",
                function()
                    require("telescope.builtin").git_stash()
                end,
                desc = "Git stash",
            },
        },
    },
    {
        "pwntester/octo.nvim",
        cmd = "Octo", -- Needs the gh CLI; do not load it (and fail) until it is used.
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = { mappings_disable_default = false },
        keys = {
            { "<leader>fi", "<cmd>Octo issue list<CR>", desc = "Find GitHub issues" },
            { "<leader>gI", "<cmd>Octo issue create<CR>", desc = "Create GitHub issue" },
        },
    },
    {
        -- SOPS: transparently decrypt on open, re-encrypt on save
        "trixnz/sops.nvim",
        lazy = false,
        opts = {},
    },
}
