local language_servers = {
    "stylua",
    "shellcheck",
    "shfmt",
    "flake8",
    "typescript-language-server",
    "tsserver"
}

-- TODO Leftover imports from last config, investigate
    -- 'nvim-lua/plenary.nvim',
    -- 'jose-elias-alvarez/nvim-lsp-ts-utils',

return {
    -- autocompletion
    {
        "hrsh7th/nvim-cmp",
        version = false, -- last release is way too old
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path"
        },
        opts = function()
            local cmp = require('cmp')
            return {
                completion = {
                    completeopt = "menu,menuone,noinsert",
                },
                mapping = {
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
                    ['<S-Tab>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 's' })
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'path' }
                }
            }
        end
    },
    -- lsp
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
            { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
            "mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
    },
    
  -- formatters
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason.nvim" },
        opts = function()
            local nls = require("null-ls")
            return {
            sources = {
                -- nls.builtins.formatting.prettierd,
                nls.builtins.formatting.stylua,
                nls.builtins.diagnostics.flake8,
            },
        }
        end,
    },
    {
        "williamboman/mason-lspconfig",
        dependencies = {
            "williamboman/mason.nvim"
        },
        cmd = "Mason",
        opts = {
            ensure_installed = language_servers
        },
        ---@param opts MasonSettings | {ensure_installed: string[]}
        config = function(plugin, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            for _, tool in ipairs(opts.ensure_installed) do
                local p = mr.get_package(tool)
                if not p:is_installed() then
                    p:install()
                end
            end
        end,
    },
    {
        "jose-elias-alvarez/typescript.nvim",
        config = function()
            require("typescript").setup({})
        end
    }
}

