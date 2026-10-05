-- return {
	-- "nvim-treesitter/nvim-treesitter",
	-- event = { "BufReadPost", "BufNewFile" },
	-- build = ":TSUpdate",
	-- opts = {
		-- ensure_installed = "all",
		-- auto_install = false,
		-- highlight = { enable = true },
		-- indent = { enable = true, disable = { "python" } },
		-- context_commentstring = { enable = true, enable_autocmd = false },
		-- additional_vim_regex_highlighting = true,
	-- },
	-- config = function(_, opts)
		-- require("nvim-treesitter.configs").setup(opts)
	-- end,
-- }
return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
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
