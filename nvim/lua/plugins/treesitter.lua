-- Treesitter (main branch): parsers install asynchronously and need the tree-sitter CLI and a
-- C compiler (`just setup` provides both). Highlighting starts for every filetype that has a parser.
local features = require("whc.profile").features

local languages = {
    "bash", "c", "css", "diff", "dockerfile", "gitcommit", "gitignore", "html", "javascript", "json",
    "lua", "markdown", "markdown_inline", "python", "query", "regex", "rust", "svelte", "toml",
    "tsx", "typescript", "vim", "vimdoc", "yaml",
}
if features.godot then
    vim.list_extend(languages, { "gdscript", "gdshader" })
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install(languages)
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("WhcTreesitter", { clear = true }),
                callback = function(args)
                    local language = vim.treesitter.language.get_lang(args.match)
                    -- No parser yet (first-time installs are asynchronous) is not an error.
                    if language then
                        pcall(vim.treesitter.start, args.buf, language)
                    end
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        lazy = true,
    },
}
