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
	-- cmp & lsp
	require("lsp"),
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
                    vimgrep_arguments = vimgrep_arguments
                },
                pickers = {
                    -- Show dotfiles, but not .git directory
                    find_files = {
                        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                    }
                }
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
        init = function ()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            vim.g.neo_tree_remove_legacy_commands = 1
        end,
        opts = {
            filesystem = {
                filtered_items = {
                    hide_dotfiles = false,
                    hide_gitignored = false,
                }
            },
        },
    },
	-- Status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			require("lualine").setup({})
		end,
	},
    -- Git
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            current_line_blame_opts = {
                virt_text_pos = "right_align",
                delay = 0
            },
        },
        config = function (_, opts)
            require("gitsigns").setup(opts)
        end
    },
    "kdheepak/lazygit.nvim",
    -- Litee
    {
        'ldelossa/litee.nvim',
        dependencies = {
            'ldelossa/litee-symboltree.nvim'
        },
        config = function ()
            require('litee.lib').setup({})
            require('litee.symboltree').setup({})
        end
    },
	-- Misc
	"christoomey/vim-tmux-navigator", -- Easier Tmux and Vim split navigation
	"Yggdroot/indentLine", -- Vertical lines to visually indicate indentation levels
	"nvim-pack/nvim-spectre", -- Find and replace across files
    {
        "gbprod/substitute.nvim", -- Substitute text with text from register
        config = function()
            require('substitute').setup({})
        end
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
