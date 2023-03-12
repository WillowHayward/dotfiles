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
vim.keymap.set('n', '<leader>/', builtin.live_grep, { desc = 'Find in files' })
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>b', builtin.git_branches, { desc = 'Find git branch' })
vim.keymap.set('n', '<leader>p', builtin.planets, { desc = 'Find planet' }) -- god this plugin is cute
-- TODO: LSP Integration https://github.com/nvim-telescope/telescope.nvim#neovim-lsp-pickers

-- Spectre (find and replace across multiple files)
vim.keymap.set('n', '<leader>%', require('spectre').open, { desc = 'Open Spectre' })

-- cellular automation (silly)
vim.keymap.set("n", "<leader>q", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = 'Destroy it all' })
