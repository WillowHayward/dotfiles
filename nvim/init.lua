vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site")

require("plugins")
require("options")
require("keymaps")
require("server")
