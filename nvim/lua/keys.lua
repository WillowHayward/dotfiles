-- Indenting a visual selection remains in visual mode afterwards
vim.keymap.set('v', '>', '>gv');
vim.keymap.set('v', '<', '<gv');

-- provide hjkl movements in Insert mode via the <Alt> modifier key
vim.keymap.set('i', '<A-h>', '<C-o>h');
vim.keymap.set('i', '<A-j>', '<C-o>j');
vim.keymap.set('i', '<A-k>', '<C-o>k');
vim.keymap.set('i', '<A-l>', '<C-o>l');

-- Alt-jk in normal mode centres screen
vim.keymap.set('n', '<A-j>', 'zzj');
vim.keymap.set('n', '<A-k>', 'zzk');

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>/', builtin.live_grep)
vim.keymap.set('n', '<leader>f', builtin.find_files)
vim.keymap.set('n', '<leader>b', builtin.git_branches)
vim.keymap.set('n', '<leader>p', builtin.planets) -- god this plugin is cute
-- TODO: LSP Integration https://github.com/nvim-telescope/telescope.nvim#neovim-lsp-pickers
