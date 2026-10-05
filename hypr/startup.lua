local startupCommands = {
    "systemctl --user start udiskie.service",
    "hypridle",
    "systemctl --user start hyprpolkitagent",
    "systemctl --user start elephant.service",
    "walker --gapplication-service",
    "flameshot",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(startupCommands) do
        hl.exec_cmd(command)
    end
end)
