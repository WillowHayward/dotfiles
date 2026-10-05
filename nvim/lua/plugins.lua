-- Plugins
-- lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	-- A new machine has no GitHub SSH key yet, so keep the SSH URL rewrite in ~/.gitconfig
	-- out of this first session (lazy.nvim clones every plugin over https). Only this
	-- Neovim process and its children are affected; later sessions use the normal config.
	vim.env.GIT_CONFIG_GLOBAL = "/dev/null"
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
local features = require("profile").features

require("lazy").setup({
	-- My Plugins
	--{
	--"WillowHayward/nx-cli.nvim",
	--dev = true,
	--config = function()
	--require("nx-cli").setup({})
	--end,
	--},
	-- cmp & lsp
	require("lsp"),
	require("debugging"),
	-- AI CLI
	features.ai and require("ai") or {},
	-- treesitter
	require("treesitter"),
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
	-- SOPS: transparently decrypt on open, re-encrypt on save
	{
		"trixnz/sops.nvim",
		lazy = false,
		opts = {},
	},
	-- GitHub
	{
		"pwntester/octo.nvim",
		cmd = "Octo", -- Needs the gh CLI; do not load it (and fail) until it is used.
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("octo").setup({
				mappings_disable_default = false,
			})
		end,
	},
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
	"nvim-pack/nvim-spectre", -- Find and replace across files
	{
		"folke/todo-comments.nvim", -- Todo
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("todo-comments").setup()
		end,
	},
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
	"Mofiqul/dracula.nvim", -- Theme
	-- Taskwarrior
	{
		"ribelo/taskwarrior.nvim",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	-- Godot
	features.godot and require("godot") or {},
})
