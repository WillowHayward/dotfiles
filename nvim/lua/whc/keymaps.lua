-- Keymaps that do not belong to a plugin. Plugin keymaps live in lua/plugins/*.lua (lazy `keys`),
-- LSP-independent code actions and diagnostics are here because they use built-ins.

-- Function to set keymaps w/ some logical defaults
local function set_keymap(mode, key, action, desc, opts)
    local defaults = {
        desc = desc or "",
        silent = false,
        expr = false,
        noremap = true,
    }
    local fullOpts = vim.tbl_extend("force", defaults, opts or {})
    vim.keymap.set(mode, key, action, fullOpts)
end

-- Clear search highlighting
set_keymap("n", "<leader><leader>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- Refresh
set_keymap("n", "<leader>e", "<cmd>e<CR>", "Reload buffer")

-- Redo (<C-r> is taken by "open recent file")
set_keymap("n", "U", "<cmd>redo<CR>", "Redo last undone change")

-- Indenting a visual selection remains in visual mode afterwards
set_keymap("v", ">", ">gv")
set_keymap("v", "<", "<gv")

-- provide hjkl movements in Insert mode via the <Alt> modifier key
set_keymap("i", "<A-h>", "<C-o>h")
set_keymap("i", "<A-j>", "<C-o>j")
set_keymap("i", "<A-k>", "<C-o>k")
set_keymap("i", "<A-l>", "<C-o>l")

-- Alt-jk in normal mode centres screen
set_keymap("n", "<A-j>", "zzj")
set_keymap("n", "<A-k>", "zzk")

-- Tabs. gt/gT are disabled to build the <leader> habit; a count repeats the move, wrapping
-- around: 2<leader>h goes two tabs to the left.
set_keymap("n", "<leader>t", "<cmd>tabnew<CR>", "Open new tab")
vim.keymap.set("n", "gt", "<nop>")
vim.keymap.set("n", "gT", "<nop>")
local function tab_step(direction)
    return function()
        local total = vim.fn.tabpagenr("$")
        vim.cmd.tabnext(((vim.fn.tabpagenr() - 1 + direction * vim.v.count1) % total) + 1)
    end
end
set_keymap("n", "<leader>l", tab_step(1), "Next tab (takes a count)")
set_keymap("n", "<leader>h", tab_step(-1), "Previous tab (takes a count)")

-- Saving and Quitting
set_keymap("n", "<leader>w", "<cmd>w<CR>", "Write buffer")
set_keymap("n", "<leader>W", "<cmd>wa<CR>", "Write all")
set_keymap("n", "<leader>q", "<cmd>q<CR>", "Close buffer")
set_keymap("n", "<leader>Q", "<cmd>qa<CR>", "Close all")
set_keymap("n", "<leader>x", "<cmd>x<CR>", "Write & close buffer")
set_keymap("n", "<leader>X", "<cmd>xa<CR>", "Write & close all")

-- Plugin managers
set_keymap("n", "<leader>cm", "<cmd>Mason<cr>", "Mason")
set_keymap("n", "<leader>L", "<cmd>Lazy<cr>", "Lazy")

-- LSP and diagnostics
local function diagnostic_goto(next, severity)
    severity = severity and vim.diagnostic.severity[severity] or nil
    return function()
        vim.diagnostic.jump({ count = next and 1 or -1, severity = severity })
    end
end

-- TODO: Broken, figure it out (only works when there's 1 code action at present - modify to run first if multiple)
-- TODO: Review this, consider making the default ca behaviour
local function code_action_apply()
    vim.lsp.buf.code_action({
        apply = true,
    })
end
set_keymap("n", "<leader>cl", "<cmd>LspInfo<CR>", "Open LspInfo")
set_keymap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
set_keymap("n", "<leader>cA", code_action_apply, "Code action")
set_keymap("n", "K", vim.lsp.buf.hover, "Code hover")
set_keymap("n", "gd", vim.diagnostic.open_float, "Diagnostic hover")
set_keymap("n", "]d", diagnostic_goto(true), "Next diagnostic")
set_keymap("n", "[d", diagnostic_goto(false), "Previous diagnostic")
set_keymap("n", "]e", diagnostic_goto(true, "ERROR"), "Next error")
set_keymap("n", "[e", diagnostic_goto(false, "ERROR"), "Previous error")
set_keymap("n", "]w", diagnostic_goto(true, "WARNING"), "Next warning")
set_keymap("n", "[w", diagnostic_goto(false, "WARNING"), "Previous warning")
set_keymap("n", "]h", diagnostic_goto(true, "HINT"), "Next hint")
set_keymap("n", "[h", diagnostic_goto(false, "HINT"), "Previous hint")
set_keymap("n", "]i", diagnostic_goto(true, "INFO"), "Next info")
set_keymap("n", "[i", diagnostic_goto(false, "INFO"), "Previous info")
set_keymap("n", "<leader>r", vim.lsp.buf.rename, "Rename current symbol")
set_keymap("n", "<leader>cs", vim.lsp.buf.document_symbol, "View document symbols")
set_keymap("n", "<leader>ci", function()
    vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
end, "Organise imports")
