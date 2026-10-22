-- lualine's `auto` theme loads lualine/themes/<colors_name>.lua, and files in this config win over
-- lualine's own (hard-coded Dracula) one. Use whc-theme's: Normal mode in this machine's colour.
local ok, theme = pcall(require, "whc.theme")
if ok then
    return theme.lualine()
end
return dofile(vim.api.nvim_get_runtime_file("lua/lualine/themes/dracula-nvim.lua", false)[1])
