-- Plugins
-- lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
require("lazy").setup({
	-- My Plugins
	--{
	--"WillowHayward/nx-cli.nvim",
	--dev = true,
	--config = function()
	--require("nx-cli").setup({})
	--end,
	--},
	-- cmp & lsp & dap
	require("lsp"),
	-- treesitter
	require("treesitter"),
	-- UI
	-- Project management
	--{
		--"coffebar/neovim-project",
		--opts = {
			--projects = { -- define project roots
				--"~/projects/*",
				--"~/docker/*",
				--"~/dotfiles",
				--"~/monoverse/",
				--"~/monolith", -- work
				--"~/new/monolith-hub-services", -- work. Also rename this directory
			--},
		--},
		--init = function()
			---- enable saving the state of plugins in the session
			--vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
		--end,
		--dependencies = {
			--{ "nvim-lua/plenary.nvim" },
			--{ "nvim-telescope/telescope.nvim", tag = "0.1.4" },
			--{ "Shatur/neovim-session-manager" },
		--},
		--lazy = false,
		--priority = 100,
	--},
	--{
		--"folke/noice.nvim",
		--event = "VeryLazy",
		--opts = function()
			--require("noice").setup({
				--cmdline = {
					--conceal = false, -- Stops from trying to search cmdline input in buffer
				--},
				--lsp = {
					---- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					--override = {
						--["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						--["vim.lsp.util.stylize_markdown"] = true,
						--["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
					--},
				--},
				---- you can enable a preset for easier configuration
				--presets = {
					--bottom_search = true, -- use a classic bottom cmdline for search
					--command_palette = true, -- position the cmdline and popupmenu together
					--long_message_to_split = true, -- long messages will be sent to a split
					--inc_rename = false, -- enables an input dialog for inc-rename.nvim
					--lsp_doc_border = false, -- add a border to hover docs and signature help
				--},
			--})
		--end,
		--dependencies = {
			---- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			--"MunifTanjim/nui.nvim",
			---- OPTIONAL:
			----   `nvim-notify` is only needed, if you want to use the notification view.
			----   If not available, we use `mini` as the fallback
			--"rcarriga/nvim-notify",
			--"hrsh7th/nvim-cmp",
		--},
	--},
	-- Fuzzy Finder
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		version = false, -- telescope did only one release, so use HEAD for now
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = function()
			local telescopeConfig = require("telescope.config")
			local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
			-- I want to search in hidden/dot files.
			table.insert(vimgrep_arguments, "--hidden")
			-- I don't want to search in the `.git` directory.
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!**/.git/*")

			return {
				defaults = {
					vimgrep_arguments = vimgrep_arguments,
				},
				pickers = {
					-- Show dotfiles, but not .git directory
					find_files = {
						find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
					},
				},
			}
		end,
	},
	-- File system
	{
		"nvim-neo-tree/neo-tree.nvim",
		cmd = "Neotree",
		branch = "v2.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		init = function()
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1
			vim.g.neo_tree_remove_legacy_commands = 1
		end,
		opts = {
			filesystem = {
				filtered_items = {
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
		},
	},
	-- Status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"AndreM222/copilot-lualine",
		},
		event = "VeryLazy",
		config = function()
			local config = require("lualine").get_config()
			config.sections.lualine_x = {
				{
					"copilot",
					show_colors = true,
				},
				"encoding",
				"fileformat",
				"filetype",
			}
			require("lualine").setup(config)
		end,
	},
	-- Git
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			current_line_blame_opts = {
				virt_text_pos = "right_align",
				delay = 0,
			},
		},
		config = function(_, opts)
			require("gitsigns").setup(opts)
		end,
	},
	"kdheepak/lazygit.nvim",
	-- Litee
	{
		"ldelossa/litee.nvim",
		dependencies = {
			"ldelossa/litee-symboltree.nvim",
		},
		config = function()
			require("litee.lib").setup({})
			require("litee.symboltree").setup({})
		end,
	},
	-- Misc
	"christoomey/vim-tmux-navigator", -- Easier Tmux and Vim split navigation
	"Yggdroot/indentLine", -- Vertical lines to visually indicate indentation levels
	"David-Kunz/jester", -- Run Jest tests
	"nvim-pack/nvim-spectre", -- Find and replace across files
	{
		"folke/todo-comments.nvim", -- Todo
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("todo-comments").setup()
		end,
	},
	-- {
	-- 'numToStr/Comment.nvim', -- Manipulate comments
	-- config = function()
	-- require('Comment').setup()
	-- end
	-- },
	{
		"gbprod/substitute.nvim", -- Substitute text with text from register
		config = function()
			require("substitute").setup({})
		end,
	},
	{
		"folke/which-key.nvim", -- Show available key bindings
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 600
			require("which-key").setup({})
		end,
	},
	"sainnhe/edge", -- Color scheme
	{
		"goolord/alpha-nvim", -- Dashboard on launch
		event = "VimEnter",
		opts = function()
			local dashboard = require("alpha.themes.dashboard")
			local willow = require("willow")
			local logo = willow.get_logo()
			dashboard.section.header.val = vim.split(logo, "\n")
			dashboard.section.buttons.val = {
				dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
				dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
				dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
				dashboard.button("/", " " .. " Find text", ":Telescope live_grep <CR>"),
				dashboard.button("p", " " .. " Recent Projects", ":Telescope neovim-project history <CR>"),
				dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
				dashboard.button("q", " " .. " Quit", ":qa<CR>"),
			}
			dashboard.section.footer.opts.hl = "Type"
			dashboard.section.header.opts.hl = "AlphaHeader"
			dashboard.section.buttons.opts.hl = "AlphaButtons"
			dashboard.opts.layout[1].val = 8
			dashboard.section.footer.val = willow.get_slogan()
			return dashboard
		end,
		config = function(_, dashboard)
			require("alpha").setup(dashboard.opts)
		end,
	},
	-- silly
	{
		"eandrju/cellular-automaton.nvim", -- For when it all comes tumbling down
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
})
