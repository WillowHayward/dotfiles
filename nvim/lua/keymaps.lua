-- Indenting a visual selection remains in visual mode afterwards
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")

-- provide hjkl movements in Insert mode via the <Alt> modifier key
vim.keymap.set("i", "<A-h>", "<C-o>h")
vim.keymap.set("i", "<A-j>", "<C-o>j")
vim.keymap.set("i", "<A-k>", "<C-o>k")
vim.keymap.set("i", "<A-l>", "<C-o>l")

-- Alt-jk in normal mode centres screen
vim.keymap.set("n", "<A-j>", "zzj")
vim.keymap.set("n", "<A-k>", "zzk")

-- Spectre (find and replace across multiple files)
vim.keymap.set("n", "<leader>%", require("spectre").open, { desc = "Open Spectre" })

-- cellular automation (silly)
vim.keymap.set("n", "<leader>q", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = "Destroy it all" })

-- Mason
vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })

-- Lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Find in files" })
vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>r", builtin.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>p", builtin.planets, { desc = "Find planet" }) -- god this plugin is cute

-- Git
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Find git branch" })
vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "git ls-files" })
vim.keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame <CR>", { desc = "Toggle line blame" })
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit <CR>", { desc = "Open LazyGit" })

-- Telescope lsp
vim.keymap.set("n", "<leader>cd", builtin.lsp_definitions, { desc = "Find definition" })
vim.keymap.set("n", "<leader>ct", builtin.lsp_type_definitions, { desc = "Find type definition" })

-- cmp keybinds in lsp.lua

-- LSP
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>cc", vim.lsp.buf.hover, { desc = "Code hover" })
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "Code formatting" })
vim.keymap.set("n", "<leader>n", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>N", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })

-- TypeScript
vim.keymap.set("n", "<leader>ci", "<cmd>TypescriptOrganizeImports<CR>", { desc = "Organise TypeScript imports" })
