local language_servers = {
    "stylua",
    "lua-language-server",
    "shellcheck",
    "shfmt",
    "flake8",
    "typescript-language-server",
    "tailwindcss-language-server",
    "svelte-language-server",
    "eslint-lsp",
    "prettier",
    "docker-compose-language-service",
    "dockerfile-language-server",
    "gdtoolkit",
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
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-vsnip",
            "hrsh7th/vim-vsnip",
            "hrsh7th/cmp-nvim-lsp-signature-help",
        },
        opts = function(_, opts)
            local cmp = require("cmp")
            return {
                completion = {
                    completeopt = "menu,menuone,noinsert",
                },
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)
                    end,
                },
                mapping = {
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "s" }),
                    ["<C-p>"] = cmp.mapping(cmp.mapping.scroll_docs(-3)),
                    ["<C-n>"] = cmp.mapping(cmp.mapping.scroll_docs(3)),
                },
                sources = {
                    { name = "nvim_lsp_signature_help" },
                    { name = "nvim_lsp" },
                    { name = "vsnip" },
                    { name = "buffer" },
                    { name = "path" },
                },
            }
        end,
    },
    -- lsp
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            {
                "folke/neoconf.nvim",
                cmd = "Neoconf",
                config = true,
            },
            { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
            "mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "jose-elias-alvarez/typescript.nvim", -- TypeScript
            "ray-x/lsp_signature.nvim",
            {
                "j-hui/fidget.nvim",
                opts = { tag = "legacy" }, -- Show LSP progress
            },
        },
        opts = {
            servers = {
                tailwindcss = {},
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = {
                                checkThirdParty = false,
                            },
                        },
                    },
                },
            },
            setup = {
                tsserver = function(_, opts)
                    require("typescript").setup({ server = opts })
                    return true
                end,
            },
        },
        config = function(_, opts)
            -- This is mostly lifted from LazyVim
            local mlsp = require("mason-lspconfig")
            local available = mlsp.get_available_servers()

            local ensure_installed = {} ---@type string[]
            local servers = opts.servers
            local capabilities =
                require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
            local function setup(server)
                local server_opts = vim.tbl_deep_extend("force", {
                    capabilities = vim.deepcopy(capabilities),
                }, servers[server] or {})

                if opts.setup[server] then
                    if opts.setup[server](server, server_opts) then
                        return
                    end
                elseif opts.setup["*"] then
                    if opts.setup["*"](server, server_opts) then
                        return
                    end
                end
                require("lspconfig")[server].setup(server_opts)
            end
            for server, server_opts in pairs(servers) do
                if server_opts then
                    server_opts = server_opts == true and {} or server_opts
                    -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
                    if server_opts.mason == false or not vim.tbl_contains(available, server) then
                        setup(server)
                    else
                        ensure_installed[#ensure_installed + 1] = server
                    end
                end
            end

            require("mason-lspconfig").setup({ ensure_installed = ensure_installed })
            require("mason-lspconfig").setup_handlers({ setup })
            --require("lsp_signature").setup({}) -- TODO: Not super thrilled with the defaults, look into later
            -- Consider "Issafalcon/lsp-overloads.nvim",
            -- Format on save
            vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])
        end,
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
    --- DAP
    {
        "mfussenegger/nvim-dap",
    },
    --- Jest tests
    {
        "David-Kunz/jester",
    },
    --- lsp-management
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {
            ensure_installed = language_servers,
        },
        ---@param opts MasonSettings | {ensure_installed: string[]}
        config = function(plugin, opts)
            require("mason").setup()
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
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = { "mason.nvim", "mfussenegger/nvim-dap" },
    },
}
