local language_servers = {
	"stylua",
	"lua-language-server",
	"shellcheck",
    -- "beautysh", -- TODO
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
	-- Github Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = {
			"zbirenbaum/copilot.lua",
		},
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim" },
		},
		opts = {
			debug = true, -- Enable debugging
			window = {
				layout = "float", -- Set layout to float
				title = "GitHub Copilot", -- Set title
				width = 0.8,
				height = 0.8,
			},
			submit_prompt = {
				normal = "<CR>",
				insert = "<CR><CR>",
			},
		},
	},
	-- autocompletion
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		dependencies = {
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",

			-- New and experimental begin
			"hrsh7th/cmp-cmdline",
			-- New and experimental end
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"zbirenbaum/copilot-cmp",
			"onsails/lspkind.nvim",
		},
		opts = function(_, opts)
			local cmp = require("cmp")
			local lspkind = require("lspkind")
			return {
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						max_width = 100,
						symbol_map = { Copilot = "" },
					}),
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
					{ name = "copilot" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "nvim_lsp" },
					{ name = "vsnip" },
					{ name = "buffer" },
					{ name = "path" },
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.exact, -- Prioritize exact matches over copilot suggestions
						-- require("copilot_cmp.comparators").prioritize,
						cmp.config.compare.offset,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
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
				gdscript = {},
                -- beautysh = {}
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
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local dap = require("dap")
			dap.adapters.godot = {
				type = "server",
				host = "127.0.0.1",
				port = 6006,
			}
			dap.configurations.gdscript = {
				{
					type = "godot",
					request = "launch",
					name = "Launch scene",
					project = "${workspaceFolder}",
					launch_scene = true,
				},
			}
		end,
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
}
