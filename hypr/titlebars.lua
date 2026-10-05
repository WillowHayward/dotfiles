-- Build/install with ~/.config/hypr/install-hyprbars.sh after Hyprland upgrades.
local library = os.getenv("HOME") .. "/.local/lib/hyprland/hyprbars.so"
local file = io.open(library, "rb")
if file then
    file:close()
    hl.plugin.load(library)
end

-- Plugin loading triggers another config reload once its options are registered.
if hl.plugin.hyprbars then
    hl.config({
        plugin = {
            hyprbars = {
                bar_height = 28,
                bar_color = 0xff242936,
                ["col.text"] = 0xffeeeeee,
                bar_text_size = 12,
                bar_text_font = "Sans",
                bar_part_of_window = true,
            },
        },
    })
    hl.window_rule({
        name = "hide-titlebars-on-tiled-windows",
        match = { float = false },
        ["hyprbars:no_bar"] = true,
    })
    hl.window_rule({
        name = "hide-titlebars-on-overlays",
        match = { class = "^flameshot$" },
        ["hyprbars:no_bar"] = true,
    })
end
