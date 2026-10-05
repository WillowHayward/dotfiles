-- Media keys, brightness and the lock key. Each bind carries a description for `just keybinds`.
local super = require("constants").keys.super

local function bindMedia(description, key, command, options)
    options = options or {}
    options.locked = true
    options.description = description
    hl.bind(key, hl.dsp.exec_cmd(command), options)
end

bindMedia("Volume up", "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", { repeating = true })
bindMedia("Volume down", "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { repeating = true })
bindMedia("Mute output", "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { repeating = true })
bindMedia("Mute microphone", "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { repeating = true })

-- The volume knob emits the same keys as the keyboard's volume controls.
local brightnessScript = debug.getinfo(1, "S").source:sub(2):match("^(.*)/") .. "/brightness.sh"
local function brightnessCommand(direction, target)
    return "sh '" .. brightnessScript:gsub("'", "'\\''") .. "' " .. direction .. " " .. target
end
for _, bind in ipairs({
    { description = "Internal panel brightness up", key = "XF86MonBrightnessUp", direction = "up", target = "internal" },
    { description = "Internal panel brightness down", key = "XF86MonBrightnessDown", direction = "down", target = "internal" },
    { description = "Focused monitor brightness up", key = super .. " + XF86AudioRaiseVolume", direction = "up", target = "active" },
    { description = "Focused monitor brightness down", key = super .. " + XF86AudioLowerVolume", direction = "down", target = "active" },
}) do
    bindMedia(bind.description, bind.key, brightnessCommand(bind.direction, bind.target), { repeating = true })
end

-- Requires playerctl
bindMedia("Next track", "XF86AudioNext", "playerctl next")
bindMedia("Play or pause", "XF86AudioPause", "playerctl play-pause")
bindMedia("Play or pause", "XF86AudioPlay", "playerctl play-pause")
bindMedia("Previous track", "XF86AudioPrev", "playerctl previous")

-- Hardware lock key. Power and sleep keys are handled by systemd-logind.
bindMedia("Lock the session", "XF86ScreenSaver", "loginctl lock-session")
