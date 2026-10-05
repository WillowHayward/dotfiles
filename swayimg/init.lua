-- Include other images in the opened image's directory.
swayimg.imagelist.adjacent = true

-- Hide file details, dimensions, and scale on startup.
swayimg.text.visible = false

swayimg.viewer.on_key("h", function()
    swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("l", function()
    swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("left", function()
    swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("right", function()
    swayimg.viewer.open("next")
end)

-- Zoom around the pointer without holding a modifier.
swayimg.viewer.on_mouse("ScrollUp", function()
    local mouse = swayimg.get_mouse_pos()
    local scale = swayimg.viewer.scale
    swayimg.viewer.set_abs_scale(scale + scale / 10, mouse.x, mouse.y)
end)

swayimg.viewer.on_mouse("ScrollDown", function()
    local mouse = swayimg.get_mouse_pos()
    local scale = swayimg.viewer.scale
    swayimg.viewer.set_abs_scale(scale - scale / 10, mouse.x, mouse.y)
end)
