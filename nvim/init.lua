vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site")

require("plugins")
require("options")
require("keymaps")
if require("profile").features.godot then
	require("server")
end
