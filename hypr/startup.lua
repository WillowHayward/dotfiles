local startupCommands = {
    "systemctl --user start udiskie.service",
    "hypridle",
    "systemctl --user start hyprpolkitagent",
    "systemctl --user start elephant.service",
    "walker --gapplication-service",
    "flameshot",
}

-- greetd's automatic login (WHC_AUTOLOGIN=1, see setup/tasks/manual-lock.sh) leaves this marker;
-- lock straight away so an unattended boot never leaves an open desktop. Manual logins have none.
local function lockAfterAutologin()
    local marker = (os.getenv("XDG_RUNTIME_DIR") or "") .. "/whc-autologin"
    if os.remove(marker) then
        hl.exec_cmd("pidof hyprlock || hyprlock")
    end
end

hl.on("hyprland.start", function()
    pcall(lockAfterAutologin)
    for _, command in ipairs(startupCommands) do
        hl.exec_cmd(command)
    end
end)
