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

-- Spectre (find and replace across multiple files)
vim.keymap.set('n', '<leader>%', require('spectre').open, { desc = 'Open Spectre' })

-- cellular automation (silly)
vim.keymap.set('n', '<leader>q', '<cmd>CellularAutomaton make_it_rain<CR>', { desc = 'Destroy it all' })

-- Mason
vim.keymap.set('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>/', builtin.live_grep, { desc = 'Find in files' })
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>b', builtin.git_branches, { desc = 'Find git branch' })
vim.keymap.set('n', '<leader>p', builtin.planets, { desc = 'Find planet' }) -- god this plugin is cute
-- TODO: LSP Integration https://github.com/nvim-telescope/telescope.nvim#neovim-lsp-pickers
-- cmp keybinds in lsp.lua

-- LSP

local on_attach = function(client, bufnr)
    vim.cmd("command! LspDef lua vim.lsp.buf.definition()")
    vim.cmd("command! LspFormatting lua vim.lsp.buf.formatting()")
    vim.cmd("command! LspCodeAction lua vim.lsp.buf.code_action()")
    vim.cmd("command! LspHover lua vim.lsp.buf.hover()")
    vim.cmd("command! LspRename lua vim.lsp.buf.rename()")
    vim.cmd("command! LspRefs lua vim.lsp.buf.references()")
    vim.cmd("command! LspTypeDef lua vim.lsp.buf.type_definition()")
    vim.cmd("command! LspImplementation lua vim.lsp.buf.implementation()")
    vim.cmd("command! LspDiagPrev lua vim.lsp.diagnostic.goto_prev()")
    vim.cmd("command! LspDiagNext lua vim.lsp.diagnostic.goto_next()")
    vim.cmd("command! LspDiagLine lua vim.lsp.diagnostic.show_line_diagnostics()")
    vim.cmd("command! LspSignatureHelp lua vim.lsp.buf.signature_help()")    buf_map(bufnr, "n", "gd", ":LspDef<CR>")
    buf_map(bufnr, "n", "gr", ":LspRename<CR>")
    buf_map(bufnr, "n", "gy", ":LspTypeDef<CR>")
    buf_map(bufnr, "n", "K", ":LspHover<CR>")
    buf_map(bufnr, "n", "[a", ":LspDiagPrev<CR>")
    buf_map(bufnr, "n", "]a", ":LspDiagNext<CR>")
    buf_map(bufnr, "n", "ga", ":LspCodeAction<CR>")
    buf_map(bufnr, "n", "<Leader>a", ":LspDiagLine<CR>")
    buf_map(bufnr, "i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>")    
	if client.resolved_capabilities.document_formatting then
        vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
    end
        buf_map(bufnr, "n", "gs", ":TSLspOrganize<CR>")
        buf_map(bufnr, "n", "gi", ":TSLspRenameFile<CR>")
        buf_map(bufnr, "n", "go", ":TSLspImportAll<CR>")        
end
