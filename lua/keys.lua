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
