-- Per-device settings: hypr/devices/<WHC_DEVICE>.lua returns a table; with no file the
-- defaults apply. WHC_DEVICE comes from /etc/environment (the greeter's PAM session reads it).
-- Known keys: gameMonitor (output that hosts the portrait game preview).
local name = (os.getenv("WHC_DEVICE") or ""):gsub("[^%w_-]", "")
local module = "devices." .. name
local ok, settings = pcall(require, module)
if not ok then
    if not tostring(settings):find("module '" .. module .. "' not found", 1, true) then
        hl.notification.create({ text = "hypr device config: " .. tostring(settings), timeout = 8000 })
    end
    return {}
end
return type(settings) == "table" and settings or {}
