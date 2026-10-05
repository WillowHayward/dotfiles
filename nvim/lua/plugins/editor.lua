-- Finding and moving around: Telescope, Oil, flash, Trouble; and the small editing helpers
-- (mini.*, substitute, Spectre, todo-comments, tmux navigation, Markdown rendering).
return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        version = false, -- telescope did only one release, so use HEAD for now
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>/",
                function()
                    require("whc.project").live_grep()
                end,
                desc = "Find in workspace",
            },
            {
                "<C-t>",
                function()
                    require("whc.project").find_files()
                end,
                desc = "Find workspace files",
            },
            {
                "<leader>*",
                function()
                    require("whc.project").grep_string()
                end,
                desc = "Search current string in workspace",
            },
            {
                "<leader>fP",
                function()
                    require("whc.project").switch()
                end,
                desc = "Switch project (tmux session)",
            },
            {
                "<leader>fb",
                function()
                    require("telescope.builtin").buffers()
                end,
                desc = "Find buffers",
            },
            {
                "<leader>fh",
                function()
                    require("telescope.builtin").help_tags()
                end,
                desc = "Find help tags",
            },
            {
                "<C-r>",
                function()
                    require("telescope.builtin").oldfiles()
                end,
                desc = "Find recent files",
            },
            {
                "<leader>fp",
                function()
                    require("telescope.builtin").planets()
                end,
                desc = "Find planet", -- god this plugin is cute
            },
            {
                "gD",
                function()
                    require("telescope.builtin").lsp_definitions()
                end,
                desc = "Find definition",
            },
            {
                "gr",
                function()
                    require("telescope.builtin").lsp_references()
                end,
                desc = "References",
            },
        },
        opts = function()
            local telescopeConfig = require("telescope.config")
            local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
            -- I want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            -- I don't want to search in the `.git` directory.
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")

            return {
                defaults = {
                    vimgrep_arguments = vimgrep_arguments,
                },
                pickers = {
                    -- Show dotfiles, but not .git directory
                    find_files = {
                        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                    },
                },
            }
        end,
    },
    {
        -- File browser (replaces neo-tree and netrw): edit the directory like a buffer.
        "stevearc/oil.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            default_file_explorer = true,
            view_options = { show_hidden = true },
            float = { padding = 2, max_width = 0.8, max_height = 0.8, border = "rounded" },
        },
        keys = {
            {
                "\\",
                function()
                    require("oil").open_float()
                end,
                desc = "Open file browser",
            },
        },
    },
    {
        "folke/flash.nvim",
        keys = {
            {
                "<leader>s",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash: jump to text",
            },
            {
                "<leader>S",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash: select a Treesitter node",
            },
        },
        opts = {},
    },
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {},
        keys = {
            { "<leader>vv", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace diagnostics" },
            { "<leader>vb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
            { "<leader>vs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
            { "<leader>vr", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP references" },
            { "<leader>vq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
            { "<leader>vl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
        },
    },
    {
        "echasnovski/mini.nvim", -- Small modules: pairs, splitjoin (gS), extra text objects, surround (gz*)
        event = "VeryLazy",
        config = function()
            require("mini.pairs").setup()
            require("mini.splitjoin").setup()
            require("mini.ai").setup()
            -- sa/sd/sr would collide with substitute.nvim's `s` operator, so surround lives under gz.
            require("mini.surround").setup({
                mappings = {
                    add = "gza",
                    delete = "gzd",
                    find = "gzf",
                    find_left = "gzF",
                    highlight = "gzh",
                    replace = "gzr",
                    update_n_lines = "gzn",
                },
            })
        end,
    },
    {
        "gbprod/substitute.nvim", -- Substitute text with text from register
        keys = {
            {
                "s",
                function()
                    require("substitute").operator()
                end,
                desc = "Subsitute text with contents of register",
            },
            {
                "ss",
                function()
                    require("substitute").line()
                end,
                desc = "Subsitute line with contents of register",
            },
            {
                "S",
                function()
                    require("substitute").eol()
                end,
                desc = "Subsitute text until end of line with contents of register",
            },
            {
                "s",
                mode = "x",
                function()
                    require("substitute").visual()
                end,
                desc = "Subsitute selection with contents of register",
            },
        },
        opts = {},
    },
    {
        "nvim-pack/nvim-spectre", -- Find and replace across files
        keys = {
            {
                "<leader>%",
                function()
                    require("spectre").open()
                end,
                desc = "Open Spectre",
            },
        },
    },
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
        keys = {
            {
                "]t",
                function()
                    require("todo-comments").jump_next()
                end,
                desc = "Next TODO",
            },
            {
                "[t",
                function()
                    require("todo-comments").jump_prev()
                end,
                desc = "Previous TODO",
            },
            { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Search project TODOs" },
        },
    },
    {
        "MeanderingProgrammer/render-markdown.nvim", -- Render Markdown in the buffer
        ft = "markdown",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        opts = {},
    },
    "christoomey/vim-tmux-navigator", -- Easier Tmux and Vim split navigation
}
