-- Function to set keymaps
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

-- Add tabs
set_keymap("n", "<leader>t", "<cmd>tabnew | Alpha<CR>", "Open new tab onto home screen")
set_keymap("n", "<leader>T", "<cmd>-tabnew | Alpha<CR>", "Open new tab before current onto home screen")

-- Saving and Quitting
set_keymap("n", "<leader>w", "<cmd>w<CR>", "Write buffer")
set_keymap("n", "<leader>W", "<cmd>wa<CR>", "Write all")
set_keymap("n", "<leader>q", "<cmd>q<CR>", "Close buffer")
set_keymap("n", "<leader>Q", "<cmd>qa<CR>", "Close all")
set_keymap("n", "<leader>x", "<cmd>x<CR>", "Write & close buffer")
set_keymap("n", "<leader>X", "<cmd>xa<CR>", "Write & close all")
-- Spectre (find and replace across multiple files)
set_keymap("n", "<leader>%", require("spectre").open, "Open Spectre")

-- Subsitute (replace text with text from register)
local substitute = require("substitute")
local function sub(yank, command)
	command = substitute[command]
	return function()
		command({ yank_substituted_text = yank })
	end
end

set_keymap("n", "s", substitute.operator, "Subsitute text with contents of register")
set_keymap("n", "ss", substitute.line, "Subsitute line with contents of register")
set_keymap("n", "S", substitute.eol, "Subsitute text until end of line with contents of register")
set_keymap("x", "s", substitute.visual, "Subsitute selection with contents of register")

-- substitute + yank BUG: Not currently working
set_keymap(
    "n",
    "<leader>s",
    sub(true, "operator"),
    "[Broken]Subsitute text with contents of register and yank deleted text"
)
set_keymap(
    "n",
    "<leader>ss",
    sub(true, "line"),
    "[Broken]Subsitute line with contents of register and yank deleted text"
)
set_keymap(
    "n",
    "<leader>S",
    sub(true, "eol"),
    "[Broken]Subsitute text until end of line with contents of register and yank deleted text"
)
set_keymap(
    "x",
    "<leader>s",
    sub(true, "visual"),
    "[Broken]Subsitute selection with contents of register and yank deleted text"
)

-- cellular automation (silly)
set_keymap("n", "<leader>!", "<cmd>CellularAutomaton make_it_rain<CR>", "Destroy it all")

-- Mason
set_keymap("n", "<leader>cm", "<cmd>Mason<cr>", "Mason")

-- Todo-comments
local todo = require("todo-comments")
set_keymap("n", "]t", todo.jump_next, "Next TODO")
set_keymap("n", "[t", todo.jump_prev, "Previous TODO")
set_keymap("n", "<leader>ft", "<cmd>TodoTelescope<CR>", "Search project TODOs")

-- Lazy
set_keymap("n", "<leader>l", "<cmd>Lazy<cr>", "Lazy")

-- Telescope
local telescope = require("telescope.builtin")
set_keymap("n", "<leader>/", telescope.live_grep, "Find in files")
set_keymap("n", "<leader>ff", telescope.find_files, "Find files")
set_keymap("n", "<leader>fb", telescope.buffers, "Find buffers")
set_keymap("n", "<leader>fh", telescope.help_tags, "Find help tags")
set_keymap("n", "<leader>fr", telescope.oldfiles, "Find recent files")
set_keymap("n", "<leader>fp", telescope.planets, "Find planet") -- god this plugin is cute

-- Neo-Tree
set_keymap("n", "\\", "<cmd>Neotree float reveal <CR>", "Open file browser")

-- Git
set_keymap("n", "<leader>gb", telescope.git_branches, "Find git branch")
set_keymap("n", "<leader>gf", telescope.git_files, "git ls-files")
set_keymap("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame <CR>", "Toggle line blame")
set_keymap("n", "<leader>gg", "<cmd>LazyGit <CR>", "Open LazyGit")

-- Telescope lsp
set_keymap("n", "gD", telescope.lsp_definitions, "Find definition")
set_keymap("n", "gr", telescope.lsp_references, "References")
--set_keymap("n", "<leader>ct", telescope.lsp_type_definitions, "Find type definition") -- Deprecated for copilot tests (also I don't think it worked lol)
set_keymap("n", "<leader>*", telescope.grep_string, "Search current string or selection")

-- cmp keybinds in lsp.lua

-- LSP
local function diagnostic_goto(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end

set_keymap("n", "<leader>cl", "<cmd>LspInfo<CR>", "Open LspInfo")
set_keymap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
set_keymap("n", "K", vim.lsp.buf.hover, "Code hover")
set_keymap("n", "gd", vim.diagnostic.open_float, "Diagnostic hover")
set_keymap("n", "<leader>cf", vim.lsp.buf.format, "Code formatting")
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
set_keymap("n", "<leader>R", vim.lsp.buf.rename, "Rename current symbol")

set_keymap("n", "<leader>cs", vim.lsp.buf.document_symbol, "View document symbols")
-- TypeScript
set_keymap("n", "<leader>ci", "<cmd>TypescriptOrganizeImports<CR>", "Organise TypeScript imports")

-- DAP
local dap = require("dap")
set_keymap("n", "<leader>dt", dap.toggle_breakpoint, "Toggle debug breakpoint")
set_keymap("n", "<leader>dd", function()
	dap.continue({ new = true })
end, "Start new debug session")
set_keymap("n", "<leader>dc", dap.continue, "Continue debug session")
set_keymap("n", "<leader>dD", dap.close, "Stop debug session")
set_keymap("n", "<leader>ds", dap.step_over, "Step through code")
set_keymap("n", "<leader>dS", dap.step_back, "Step back through code")
set_keymap("n", "<leader>di", dap.repl.open, "Inspect debug state")


local jester = require("jester")
-- Jest
set_keymap("n", "<leader>ctt", jester.run, "Run Jest test under cursor")
set_keymap("n", "<leader>ctf", jester.run_file, "Run Jest tests in current file")
set_keymap("n", "<leader>ctl", jester.run_last, "Re-run last Jest test")

-- Copilot
--vim.keymap.set("i", "`", 'copilot#Accept("\\<CR>")', {
--expr = true,
--replace_keycodes = false,
--})
--vim.g.copilot_no_tab_map = true
local chat = require("CopilotChat")
local CopilotChatSelect = require("CopilotChat.select")

local function ask_copilot(question, selectionMethod, callback)
    return function()
        chat.ask(question, {
            selection = CopilotChatSelect[selectionMethod],
            callback = callback or function() end,
        })
    end
end

-- Function which uses set_keymap and ask_copilot to create the same keymap for visual and normal mode
local function set_copilot_keymap(key, question, desc, callback)
    set_keymap("n", key, ask_copilot(question, "buffer", callback), desc .. " current buffer")
    set_keymap("v", key, ask_copilot(question, "visual", callback), desc .. " selection")
end

-- TODO: "fix" and "fix diagnostics" - https://github.com/CopilotC-Nvim/CopilotChat.nvim
set_keymap("n", "<leader>cc", "<cmd>CopilotChatOpen<CR>", "Open Copilot chat window")

set_keymap("n", "<leader>gd", "<cmd>CopilotChatCommit<CR>", "Generate a commit message for the current diff")
set_keymap("n", "<leader>gs", "<cmd>CopilotChatCommitStaged<CR>", "Generate a commit message for the staged changes")

-- Explain
set_copilot_keymap("<leader>ce", "Please explain how this code works", "Ask Copilot to explain")

-- TODO: This seems inconsistent
-- Review
set_keymap("n", "<leader>cr", "<cmd>CopilotChatReview<CR>", "Ask copilot to review current buffer")
set_keymap("v", "<leader>cr", "<cmd>CopilotChatReview<CR>", "Ask copilot to review selection")

-- Optimize
set_copilot_keymap(
    "<leader>co",
    "Please optimize this code to improve performance and readablilty",
    "Ask Copilot to optimize"
)

-- Document
set_copilot_keymap("<leader>cd", "Please add documentation comment(s) for this code", "Ask Copilot to document")

-- Generate Tests
set_copilot_keymap("<leader>ct", "Please generate tests for this code", "Ask Copilot to document")
