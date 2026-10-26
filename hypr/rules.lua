-- Window rules that apply on every device. Device- or project-specific rules go in
-- local.lua (untracked) or devices/<device>.lua.
hl.window_rule({
    -- Ignore maximize requests from all apps.
    name = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },

    no_focus = true,
})

-- Hyprland-run windows
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move = "20 monitor_h-120",
    float = true,
})

-- A lone tiled window fills the screen: no gaps, border or rounding. w[tv1] is a workspace
-- with exactly one visible tiled window; f[1] one whose window is maximised.
for _, workspace in ipairs({ "w[tv1]", "f[1]" }) do
    hl.workspace_rule({ workspace = workspace, gaps_out = 0, gaps_in = 0 })
    hl.window_rule({
        name = "borderless-when-alone-" .. workspace,
        match = { float = false, workspace = workspace },
        border_size = 0,
        rounding = 0,
    })
end
