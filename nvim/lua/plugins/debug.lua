-- Debugging: nvim-dap and its UI. Language plugins (Godot, rustaceanvim) supply adapters.
local function dap()
    return require("dap")
end

return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
        },
        keys = {
            {
                "<leader>dt",
                function()
                    dap().toggle_breakpoint()
                end,
                desc = "Toggle debug breakpoint",
            },
            {
                "<leader>dd",
                function()
                    dap().continue({ new = true })
                end,
                desc = "Start new debug session",
            },
            {
                "<leader>dc",
                function()
                    dap().continue()
                end,
                desc = "Continue debug session",
            },
            {
                "<leader>dD",
                function()
                    dap().terminate()
                end,
                desc = "Stop debug session",
            },
            {
                "<leader>ds",
                function()
                    dap().step_over()
                end,
                desc = "Step through code",
            },
            {
                "<leader>dS",
                function()
                    dap().step_back()
                end,
                desc = "Step back through code",
            },
            {
                "<leader>di",
                function()
                    dap().repl.open()
                end,
                desc = "Inspect debug state",
            },
            {
                "<leader>dn",
                function()
                    dap().step_into()
                end,
                desc = "Step into code",
            },
            {
                "<leader>do",
                function()
                    dap().step_out()
                end,
                desc = "Step out of code",
            },
            {
                "<leader>db",
                function()
                    vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
                        if condition and condition ~= "" then
                            dap().set_breakpoint(condition)
                        end
                    end)
                end,
                desc = "Set conditional breakpoint",
            },
            {
                "<leader>dr",
                function()
                    dap().run_last()
                end,
                desc = "Run last debug configuration",
            },
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "Toggle debug UI",
            },
            {
                "<leader>de",
                function()
                    require("dapui").eval()
                end,
                mode = { "n", "x" },
                desc = "Evaluate debug expression",
            },
        },
        config = function()
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup()
            -- godotdev uses this same listener key, so loading it does not duplicate hooks.
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    },
}
