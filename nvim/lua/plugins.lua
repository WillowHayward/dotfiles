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

vim.g.leaderkey = " "
require("lazy").setup({
    -- Set up Neovim LSP
    'neovim/nvim-lspconfig',
    'jose-elias-alvarez/null-ls.nvim',
    'nvim-lua/plenary.nvim',
    'jose-elias-alvarez/nvim-lsp-ts-utils',

    -- Code Completion
  
    -- Misc
    'christoomey/vim-tmux-navigator', -- Easier Tmux and Vim split navigation
    'Yggdroot/indentLine', -- Vertical lines to visually indicate indentation levels
    'sainnhe/edge' -- Color scheme
})


