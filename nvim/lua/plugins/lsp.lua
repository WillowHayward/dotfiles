-- Language servers (nvim-lspconfig + Mason) and the tools conform/nvim-lint run. Mason installs
-- everything in `packages` once its registry is available; mason-lspconfig then enables each
-- installed server (rust-analyzer is left to rustaceanvim in plugins/test.lua).
local features = require("whc.profile").features

local packages = {
    -- servers
    "lua-language-server",
    "typescript-language-server",
    "tailwindcss-language-server",
    "svelte-language-server",
    "eslint-lsp",
    "docker-compose-language-service",
    "dockerfile-language-server",
    "bash-language-server",
    "json-lsp",
    "yaml-language-server",
    "taplo",
    "marksman",
    "html-lsp",
    "css-lsp",
    "pyright",
    "ruff",
    "rust-analyzer",
    -- formatters and linters
    "stylua",
    "shellcheck",
    "shfmt",
    "prettier",
    "yamllint",
}
if features.godot then
    table.insert(packages, "gdtoolkit") -- gdformat and gdlint
end

-- Settings merged into each server's default config.
local servers = {
    lua_ls = {
        settings = {
            Lua = {
                workspace = { checkThirdParty = false },
            },
        },
    },
}

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
            "mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
            { "j-hui/fidget.nvim", opts = {} }, -- Show LSP progress
        },
        config = function()
            -- Every server gets the completion capabilities; declared servers add their settings.
            vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
            for server, options in pairs(servers) do
                vim.lsp.config(server, options)
            end
            require("mason-lspconfig").setup({ automatic_enable = { exclude = { "rust_analyzer" } } })

            -- Ruff is the linter/formatter; leave hover to pyright.
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("WhcRuff", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.name == "ruff" then
                        client.server_capabilities.hoverProvider = false
                    end
                end,
            })
        end,
    },
    {
        "folke/lazydev.nvim", -- Lua LSP knowledge of the Neovim runtime
        ft = "lua",
        opts = {
            library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
        },
    },
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {},
        config = function(_, opts)
            require("mason").setup(opts)
            local registry = require("mason-registry")
            -- On a fresh machine the registry is empty until it has been fetched, and
            -- registry.get_package throws for every tool until then.
            registry.refresh(function()
                for _, tool in ipairs(packages) do
                    local ok, package = pcall(registry.get_package, tool)
                    if not ok then
                        vim.notify("Mason has no package named " .. tool, vim.log.levels.WARN)
                    elseif not package:is_installed() then
                        package:install()
                    end
                end
            end)
        end,
    },
}
