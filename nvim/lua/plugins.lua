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
    -- Fuzzy Finder
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        version = false, -- telescope did only one release, so use HEAD for now
	    dependencies = { 'nvim-lua/plenary.nvim' }
        -- Key bindings in keys.lua
    },
    -- cmp & lsp
    require('lsp'),
    -- treesitter
    require('treesitter'),
    -- Misc
    'christoomey/vim-tmux-navigator', -- Easier Tmux and Vim split navigation
    'Yggdroot/indentLine', -- Vertical lines to visually indicate indentation levels
    'nvim-pack/nvim-spectre', -- Find and replace across files
    {
        'folke/which-key.nvim', -- Show available key bindings
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 600
            require('which-key').setup({})
        end

    },
    'sainnhe/edge', -- Color scheme
    {
        'goolord/alpha-nvim', -- Dashboard on launch
        event = 'VimEnter',
        opts = function()
            local dashboard = require("alpha.themes.dashboard")
            local willow = require("willow");
            local logo = willow.get_logo()
            dashboard.section.header.val = vim.split(logo, "\n")
            dashboard.section.buttons.val = {
                dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
                dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
                dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
                dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
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
        end
    },
    -- silly
    {
        'eandrju/cellular-automaton.nvim', -- For when it all comes tumbling down
        dependencies = {'nvim-treesitter/nvim-treesitter'}
    }
})

