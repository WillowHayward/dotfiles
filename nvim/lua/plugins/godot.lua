return {
	"Mathijs-Bakker/godotdev.nvim",
	dependencies = {
		"mfussenegger/nvim-dap",
		"rcarriga/nvim-dap-ui",
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/cmp-nvim-lsp",
	},
	opts = {
		-- Formatting goes through none-ls, including <leader>cf and format on save.
		formatter = false,
		-- The installed Treesitter uses the new API; configure it in treesitter.lua.
		treesitter = { auto_setup = false },
		run = { console = { enabled = true, buffer = { position = "bottom", size = 0.28 } } },
		scene_tree = { buffer = { position = "left", size = 0.32 } },
	},
	config = function(_, opts)
		require("godotdev").setup(opts)
		require("godot_workflow").setup()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		capabilities.textDocument.typeDefinition = nil -- Unsupported by Godot.
		vim.lsp.config("gdscript", { capabilities = capabilities, root_markers = { "project.godot" } })

		-- Resolve from the buffer so debugging also works from a project subdirectory.
		local function project_root()
			local root = vim.fs.root(0, "project.godot") or vim.fs.root(vim.fn.getcwd(), "project.godot")
			if not root then
				vim.notify("Open a Godot project before debugging", vim.log.levels.WARN)
				return require("dap").ABORT
			end
			return root
		end
		require("dap").configurations.gdscript = {
			{
				type = "godot",
				request = "launch",
				name = "Godot: main scene",
				project = project_root,
				scene = "main",
			},
			{
				type = "godot",
				request = "launch",
				name = "Godot: scene selected in editor",
				project = project_root,
				scene = "current",
			},
		}
	end,
}
