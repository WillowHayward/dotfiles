-- Colours from whc-theme: lua/whc/theme.lua is generated (`just theme apply <theme>`) and holds
-- the theme's palette for every machine. This spec gives it to dracula.nvim (configured in
-- ui.lua) as its palette, so dracula.nvim's highlight groups render the WHC theme. lazy.nvim
-- merges this with ui.lua's spec; only `colors` is set here, so the merge order does not matter.
local ok, theme = pcall(require, "whc.theme")
if not ok then
    return {}
end

return {
    {
        "Mofiqul/dracula.nvim",
        opts = function(_, opts)
            opts.colors = theme.dracula_colors()
            -- A few groups on top (cursor, diff rows, float borders), and the background
            -- option for light themes, which dracula.nvim always sets to dark.
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("whc_theme", { clear = true }),
                pattern = "dracula",
                callback = function()
                    local groups = {}
                    if theme.mode == "light" then
                        -- Changing 'background' resets the default groups, so redo dracula.nvim's.
                        local name = vim.g.colors_name
                        vim.g.colors_name = nil -- otherwise setting 'background' reloads the scheme
                        vim.o.background = "light"
                        vim.g.colors_name = name
                        local config = require("dracula").configs()
                        groups = require("dracula.groups").setup(config)
                        local extra = config.overrides
                        extra = type(extra) == "function" and extra(config.colors) or extra or {}
                        groups = vim.tbl_extend("force", groups, extra)
                    end
                    groups = vim.tbl_extend("force", groups, theme.overrides())
                    for group, spec in pairs(groups) do
                        vim.api.nvim_set_hl(0, group, spec)
                    end
                end,
            })
            return opts
        end,
    },
}
