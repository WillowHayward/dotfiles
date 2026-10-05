-- lazy.nvim bootstrap. Plugin specs live in lua/plugins/*.lua (one file per topic).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    -- A new machine has no GitHub SSH key yet, so keep git config rewrites out of this first
    -- session (lazy.nvim clones every plugin over https). Only this Neovim process and its
    -- children are affected; later sessions use the normal config.
    vim.env.GIT_CONFIG_GLOBAL = "/dev/null"
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins" } }, {
    -- The lockfile is committed; update deliberately with `just nvim-update`.
    change_detection = { notify = false },
})
