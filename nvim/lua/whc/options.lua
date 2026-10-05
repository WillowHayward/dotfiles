vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.colorcolumn = "101"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.mouse = ""
vim.opt.termguicolors = true

-- Spell checking (toggle with :set spell): a tracked word list for names the dictionary lacks.
-- Nvim fetches the en dictionary on first use; `zg` adds a word to spell/en.utf-8.add.
vim.opt.spelllang = "en_au"
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("WhcSpell", { clear = true }),
    pattern = { "markdown", "text", "gitcommit" },
    callback = function()
        vim.opt_local.spell = true
    end,
})
