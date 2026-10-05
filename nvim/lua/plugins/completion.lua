-- Completion: blink.cmp with Copilot suggestions as one of its sources. Agentic AI (chat,
-- edits) is Sidekick's job (plugins/ai.lua); Copilot here only completes.
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        opts = {
            suggestion = { enabled = false }, -- blink shows them
            panel = { enabled = false },
            filetypes = { markdown = true, help = true },
        },
    },
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "rafamadriz/friendly-snippets",
            "fang2hou/blink-copilot",
        },
        opts = {
            keymap = {
                preset = "none",
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<C-p>"] = { "scroll_documentation_up", "fallback" },
                ["<C-n>"] = { "scroll_documentation_down", "fallback" },
                ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide", "fallback" },
            },
            appearance = { nerd_font_variant = "mono" },
            completion = {
                -- Like the old cmp setup: the first item is selected, Enter accepts it, nothing is inserted early.
                list = { selection = { preselect = true, auto_insert = false } },
                menu = { draw = { treesitter = { "lsp" } } },
                documentation = { auto_show = true, auto_show_delay_ms = 300 },
            },
            signature = { enabled = true },
            sources = {
                default = { "lsp", "path", "snippets", "buffer", "copilot" },
                per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
                providers = {
                    copilot = { name = "copilot", module = "blink-copilot", score_offset = 100, async = true },
                    lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
                },
            },
        },
    },
}
