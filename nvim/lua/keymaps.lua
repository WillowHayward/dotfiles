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

-- Clear notifications
set_keymap("n", "<leader><leader>", "<cmd>Noice dismiss<CR>", "Clear noice notifications") -- TODO: Does double-space scan?

-- Refresh
set_keymap("n", "<leader>e", "<cmd>e<CR>", "Reload buffer")

-- Redo (<C-r> is taken by "open recent file")
set_keymap("n", "U", "<cmd>redo<CR>", "Redo last undone change")

-- Indenting a visual selection remains in visual mode afterwards
set_keymap("v", ">", ">gv")
set_keymap("v", "<", "<gv")

-- Import the 'comment' module
-- local comment = require("Comment")
-- comment.setup

-- set_keymap("n", "<leader>L", ":lua ", "Open Lua prompt")

-- Set keymaps for commenting and uncommenting code
-- set_keymap("n", "<leader>/", comment.toggle, "Toggle comment")
-- set_keymap("v", "<leader>/", comment.toggle, "Toggle comment")

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
--set_keymap("n", "<leader>T", "<cmd>-tabnew | Alpha<CR>", "Open new tab before current onto home screen") -- TODO: This is gonna be better served by taskwarrior - when have I ever used this keybinding?

-- Navigate tabs
-- NOTE: I don't know if unsetting these entirely is a long-term thing, but it'll help me build the new habit
vim.keymap.set("n", "gt", "<nop>")
vim.keymap.set("n", "gT", "<nop>")
set_keymap("n", "<leader>l", "<cmd>tabnext<CR>", "Next tab") -- TODO: Make repeatable
set_keymap("n", "<leader>h", "<cmd>tabprev<CR>", "Previous tab")
set_keymap("n", "<leader>k", "<cmd>tabnext<CR>", "Next tab") -- TODO: Make repeatable
set_keymap("n", "<leader>j", "<cmd>tabprev<CR>", "Previous tab")
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
set_keymap("n", "<leader>L", "<cmd>Lazy<cr>", "Lazy")

-- Telescope
local telescope = require("telescope.builtin")
set_keymap("n", "<leader>/", telescope.live_grep, "Find in files")
set_keymap("n", "<C-t>", telescope.find_files, "Find files")
set_keymap("n", "<leader>fb", telescope.buffers, "Find buffers")
set_keymap("n", "<leader>fh", telescope.help_tags, "Find help tags")
set_keymap("n", "<C-r>", telescope.oldfiles, "Find recent files")
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

-- TODO: Broken, figure it out (only works when there's 1 code action at present - modify to run first if multiple)
-- TODO: Review this, consider making the default ca behaviour
local function code_action_apply()
    vim.lsp.buf.code_action({
        apply = true
    })
end
set_keymap("n", "<leader>cl", "<cmd>LspInfo<CR>", "Open LspInfo")
set_keymap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
set_keymap("n", "<leader>cA", code_action_apply, "Code action")
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
set_keymap("n", "<leader>r", vim.lsp.buf.rename, "Rename current symbol") -- TODO: Don't need both of these. Make a call, bucko

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
-- TODO: (insane): Fork CopilotChat.nvim, and modify this file to allow you to call it smokes: https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/feca60cf0ae08d866ba35cc8a95d12941ccc4f59/lua/CopilotChat/prompts.lua#L5
-- TODO: "fix" and "fix diagnostics" - https://github.com/CopilotC-Nvim/CopilotChat.nvim

local chat = require("CopilotChat")
local CopilotChatSelect = require("CopilotChat.select")

local function ask_copilot(prompt, selectionMethod, callback)
	return function()
		local question
		if prompt ~= nil and prompt ~= "" then
			question = prompt
		else
			question = vim.fn.input("Quick Chat: ")
		end
		-- TODO: Bail if no question
		chat.ask(question, {
			selection = CopilotChatSelect[selectionMethod],
			callback = callback or function() end,
		})
	end
end

-- Function which uses set_keymap and ask_copilot to create the same keymap for visual and normal mode
local function set_copilot_ask_keymap(key, question, desc, callback)
	set_keymap("n", key, ask_copilot(question, "buffer", callback), desc .. " current buffer")
	set_keymap("v", key, ask_copilot(question, "visual", callback), desc .. " selection")
end

local function open_copilot_chat(selectionMethod)
	return function()
		chat.open({
			selection = CopilotChatSelect[selectionMethod],
		})
	end
end

-- Open Copilot chat window fully
set_keymap("n", "<leader>C", open_copilot_chat("buffer"), "Open Copilot chat window")
set_keymap("v", "<leader>C", open_copilot_chat("visual"), "Open Copilot chat window")

-- Ask Copilot a single question
set_copilot_ask_keymap("<leader>cc", nil, "Open Copilot chat window")

set_keymap("n", "<leader>gd", "<cmd>CopilotChatCommit<CR>", "Generate a commit message for the current diff")
set_keymap("n", "<leader>gs", "<cmd>CopilotChatCommitStaged<CR>", "Generate a commit message for the staged changes")

-- Open options in telescope

local CopilotChatTelescope = require("CopilotChat.integrations.telescope")
-- Open help actions with telescope
set_keymap("n", "<leader>ch", function()
	local actions = require("CopilotChat.actions").help_actions()
	CopilotChatTelescope.pick(actions)
end, "CopilotChat - Help actions")

-- Show prompts actions with telescope
set_keymap("n", "<leader>cp", function()
	local actions = require("CopilotChat.actions").prompt_actions()
	CopilotChatTelescope.pick(actions)
end, "CopilotChat - Prompt actions")

-- Explain
set_copilot_ask_keymap("<leader>ce", "Please explain how this code works", "Ask Copilot to explain")

-- TODO: This seems inconsistent
-- Review
set_copilot_ask_keymap("<leader>cr", "Please review this code", "Ask Copilot to review") -- TODO: This doesn't add the in-line hinting like CopilotChatReview
--set_keymap("n", "<leader>cr", "<cmd>CopilotChatReview<CR>", "Ask copilot to review current buffer")
--set_keymap("v", "<leader>cr", "<cmd>CopilotChatReview<CR>", "Ask copilot to review selection")

-- Optimize
set_copilot_ask_keymap(
	"<leader>co",
	"Please optimize this code to improve performance and readablilty",
	"Ask Copilot to optimize"
)

-- Document
set_copilot_ask_keymap("<leader>cd", "Please add documentation comment(s) for this code", "Ask Copilot to document")

-- Generate Tests
set_copilot_ask_keymap("<leader>ct", "Please generate tests for this code", "Ask Copilot to document")

-- Quick win
set_copilot_ask_keymap("<leader>cq", "Give me a quick win", "Ask Copilot for a quick win")

--set_keymap("n", "<leader>9", function()
--local buf = vim.api.nvim_create_buf(false, true)
--vim.api.nvim_buf_set_lines(buf, 0, -1, true, {"test", "text"})
--local opts = {relative='cursor', width=10, height=2, col=0, row=1, anchor='NW', style='minimal'}
--local win = vim.api.nvim_open_win(buf, false, opts)
-- optional: change highlight, otherwise Pmenu is used
-- vim.api.nvim_win_set_option(win, 'winhl', 'Normal:MyHighlight')
--end
--)
-- taskwarrior
local task = require("taskwarrior_nvim")
set_keymap("n", "<leader>T", function() task.browser({"ready"}) end, "Open taskwarrior list");
