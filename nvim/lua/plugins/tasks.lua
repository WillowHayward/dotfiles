-- Taskwarrior in a buffer (<leader>T).
return {
    "ribelo/taskwarrior.nvim",
    keys = {
        {
            "<leader>T",
            function()
                require("taskwarrior_nvim").browser({ "ready" })
            end,
            desc = "Open taskwarrior list",
        },
    },
    opts = {},
}
