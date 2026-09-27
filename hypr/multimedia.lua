-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
-- The volume knob emits the same keys as the keyboard's volume controls.
local super = require("constants").keys.super
local brightnessScript = debug.getinfo(1, "S").source:sub(2):match("^(.*)/") .. "/brightness.sh"
local function brightnessCommand(direction, target)
    return "sh '" .. brightnessScript:gsub("'", "'\\''") .. "' " .. direction .. " " .. target
end
for _, bind in ipairs({
    { key = "XF86MonBrightnessUp", direction = "up", target = "internal" },
    { key = "XF86MonBrightnessDown", direction = "down", target = "internal" },
    { key = super .. " + XF86AudioRaiseVolume", direction = "up", target = "active" },
    { key = super .. " + XF86AudioLowerVolume", direction = "down", target = "active" },
}) do
    hl.bind(bind.key, hl.dsp.exec_cmd(brightnessCommand(bind.direction, bind.target)), { locked = true, repeating = true })
end

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


-- Hardware lock key. Power and sleep keys are handled by systemd-logind.
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })
