-- Look and feel: colour scheme, status line, key hints, and the Snacks utilities
-- (indent guides, the picker Sidekick uses, file rename).
local features = require("whc.profile").features

return {
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("dracula")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "AndreM222/copilot-lualine",
        },
        event = "VeryLazy",
        config = function()
            local config = require("lualine").get_config()
            config.sections.lualine_x = {
                { "copilot", show_colors = true },
                "encoding",
                "fileformat",
                "filetype",
            }
            require("lualine").setup(config)
        end,
    },
    {
        "folke/which-key.nvim", -- Show available key bindings
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 600
        end,
        opts = function()
            local spec = {
                { "<leader>d", group = "Debug", mode = { "n", "x" } },
                { "<leader>n", group = "Test" },
                { "<leader>v", group = "Trouble" },
                { "<leader>g", group = "Git" },
                { "<leader>c", group = "Code" },
                { "<leader>f", group = "Find" },
            }
            if features.ai then
                table.insert(spec, { "<leader>a", group = "AI", mode = { "n", "x" } })
            end
            if features.godot then
                table.insert(spec, { "<leader>o", group = "Godot" })
            end
            return { spec = spec }
        end,
    },
    {
        -- Always loaded: indent guides, and the picker/rename helpers other plugins use.
        "folke/snacks.nvim",
        lazy = false,
        priority = 900,
        opts = {
            indent = { enabled = true },
            picker = { enabled = true },
            rename = { enabled = true },
        },
        keys = {
            {
                "<leader>R",
                function()
                    Snacks.rename.rename_file()
                end,
                desc = "Rename file",
            },
        },
    },
    { "nvim-tree/nvim-web-devicons", lazy = true },
}
