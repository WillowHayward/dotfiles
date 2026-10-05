-- Tests: neotest with a Jest adapter, and rustaceanvim (rust-analyzer, debugging and the
-- cargo test runner through its neotest adapter).
--
-- To add a framework: add its adapter plugin to neotest's `dependencies`, then append
-- `require("neotest-<name>")({ ...options... })` to `adapters` (see the neotest-jest entry).
local function neotest()
    return require("neotest")
end

return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-jest",
            "mrcjkb/rustaceanvim",
        },
        keys = {
            {
                "<leader>nn",
                function()
                    neotest().run.run()
                end,
                desc = "Run nearest test",
            },
            {
                "<leader>nf",
                function()
                    neotest().run.run(vim.fn.expand("%"))
                end,
                desc = "Run tests in file",
            },
            {
                "<leader>nl",
                function()
                    neotest().run.run_last()
                end,
                desc = "Re-run last test",
            },
            {
                "<leader>nd",
                function()
                    neotest().run.run({ strategy = "dap" })
                end,
                desc = "Debug nearest test",
            },
            {
                "<leader>nS",
                function()
                    neotest().run.stop()
                end,
                desc = "Stop test run",
            },
            {
                "<leader>ns",
                function()
                    neotest().summary.toggle()
                end,
                desc = "Test summary",
            },
            {
                "<leader>no",
                function()
                    neotest().output.open({ enter = true })
                end,
                desc = "Test output",
            },
            {
                "<leader>nO",
                function()
                    neotest().output_panel.toggle()
                end,
                desc = "Test output panel",
            },
        },
        config = function()
            neotest().setup({
                adapters = {
                    require("neotest-jest")({
                        jestCommand = "npx jest",
                        cwd = function()
                            return vim.fn.getcwd()
                        end,
                    }),
                    require("rustaceanvim.neotest"),
                },
            })
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^6",
        lazy = false, -- It lazy-loads itself for Rust filetypes.
    },
}
