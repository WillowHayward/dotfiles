-- Parsers are installed asynchronously and need the tree-sitter CLI and a C compiler.
return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		if not require("profile").features.godot then
			return
		end
		require("nvim-treesitter").install({ "gdscript", "gdshader" })
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("GodotTreesitter", { clear = true }),
			pattern = { "gdscript", "gdshader" },
			callback = function(args)
				-- First-time parser installation is asynchronous.
				pcall(vim.treesitter.start, args.buf)
			end,
		})
	end,
}
