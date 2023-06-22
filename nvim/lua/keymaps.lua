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

-- Add tabs
vim.keymap.set("n", "<leader>t", "<cmd>tabnew | Alpha<CR>", { desc = "Open new tab onto home screen" })
vim.keymap.set("n", "<leader>T", "<cmd>-tabnew | Alpha<CR>", { desc = "Open new tab before current onto home screen" })

-- Spectre (find and replace across multiple files)
vim.keymap.set("n", "<leader>%", require("spectre").open, { desc = "Open Spectre" })

-- cellular automation (silly)
vim.keymap.set("n", "<leader>q", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = "Destroy it all" })

-- Mason
vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })

-- Lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Telescope
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>/", telescope.live_grep, { desc = "Find in files" })
vim.keymap.set("n", "<leader>f", telescope.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>r", telescope.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>p", telescope.planets, { desc = "Find planet" }) -- god this plugin is cute

-- Neo-Tree
vim.keymap.set("n", "\\", "<cmd>Neotree float reveal <CR>", { desc = "Open file browser" })

-- Git
vim.keymap.set("n", "<leader>gb", telescope.git_branches, { desc = "Find git branch" })
vim.keymap.set("n", "<leader>gf", telescope.git_files, { desc = "git ls-files" })
vim.keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame <CR>", { desc = "Toggle line blame" })
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit <CR>", { desc = "Open LazyGit" })

-- Telescope lsp
vim.keymap.set("n", "gd", telescope.lsp_definitions, { desc = "Find definition" })
vim.keymap.set("n", "gr", telescope.lsp_references, { desc = "References" });
vim.keymap.set("n", "<leader>ct", telescope.lsp_type_definitions, { desc = "Find type definition" })
vim.keymap.set("n", "<leader>*", telescope.grep_string, { desc = "Search current string or selection" })

-- cmp keybinds in lsp.lua

local function diagnostic_goto(next, severity)
    local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
    severity = severity and vim.diagnostic.severity[severity] or nil
    return function()
        go({ severity = severity })
    end
end
-- LSP
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Code hover" })
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "Code formatting" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Previous diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Previous error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARNING"), { desc = "Next warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARNING"), { desc = "Previous warning" })
vim.keymap.set("n", "]h", diagnostic_goto(true, "HINT"), { desc = "Next hint" })
vim.keymap.set("n", "[h", diagnostic_goto(false, "HINT"), { desc = "Previous hint" })
vim.keymap.set("n", "]i", diagnostic_goto(true, "INFO"), { desc = "Next info" })
vim.keymap.set("n", "[i", diagnostic_goto(false, "INFO"), { desc = "Previous info" })
vim.keymap.set("n", "<leader>R", vim.lsp.buf.rename, { desc = "Rename current symbol" });

-- TypeScript
vim.keymap.set("n", "<leader>ci", "<cmd>TypescriptOrganizeImports<CR>", { desc = "Organise TypeScript imports" })
