-- Formatting (conform) and linting (nvim-lint). One formatter per language; where a language
-- server formats well (Rust), conform falls back to it. Tools are installed by Mason (plugins/lsp.lua).
local features = require("whc.profile").features

local formatters = {
    lua = { "stylua" },
    python = { "ruff_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    toml = { "taplo" },
}
for _, filetype in ipairs({
    "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte",
    "json", "jsonc", "yaml", "markdown", "css", "html",
}) do
    formatters[filetype] = { "prettier" }
end
if features.godot then
    formatters.gdscript = { "gdformat" }
end

local linters = {
    sh = { "shellcheck" },
    bash = { "shellcheck" },
    yaml = { "yamllint" },
}
if features.godot then
    linters.gdscript = { "gdlint" }
end

return {
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = "ConformInfo",
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                desc = "Code formatting",
            },
        },
        opts = {
            formatters_by_ft = formatters,
            format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
        },
    },
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = linters
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("WhcLint", { clear = true }),
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },
}
