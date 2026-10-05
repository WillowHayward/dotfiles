vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site")
vim.g.mapleader = " "

-- Layout: lua/whc/ is the editor itself (options, keymaps, helpers), lua/plugins/ holds one
-- lazy.nvim spec file per topic (imported by whc.lazy), and each plugin's own keymaps live in
-- its spec so the plugin loads on first use.
require("whc.options")
require("whc.lazy")
require("whc.keymaps")
if require("whc.profile").features.godot then
    require("whc.server")
end
