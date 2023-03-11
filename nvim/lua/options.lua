vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.colorcolumn = '101'

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- indentLine settings
vim.g.indentLine_setColors = 0

vim.g.netrw_banner = 0

-- color scheme
vim.opt.termguicolors = true
vim.g.edge_style = 'aura'
vim.g.edge_better_performance = 1
vim.cmd[[colorscheme edge]]
