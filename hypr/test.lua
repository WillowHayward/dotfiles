-- Loads hyprland.lua against a recording stub of the `hl` API and checks that it loads and
-- that every bind has a description. Run with `nvim -l hypr/test.lua` (part of `just test`).
local dir = debug.getinfo(1, "S").source:sub(2):match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path

local function stub()
    local node
    node = setmetatable({}, {
        __index = function() return node end,
        __call = function() return node end,
    })
    return node
end

local binds = {}
local any = stub()
hl = setmetatable({
    bind = function(keys, _, options)
        binds[#binds + 1] = { keys = keys, description = options and options.description }
    end,
    get_monitors = function() return {} end,
    on = function() end,
    notification = { create = function(options) error("unexpected notification: " .. options.text) end },
    plugin = { load = function() end },
    window_rule = function() return any end,
    workspace_rule = function() return any end,
}, { __index = function() return any end })

local ok, err = pcall(dofile, dir .. "/hyprland.lua")
if not ok then
    io.stderr:write("hyprland.lua failed to load: " .. tostring(err) .. "\n")
    os.exit(1)
end
local missing = {}
for _, bind in ipairs(binds) do
    if not bind.description or bind.description == "" then
        missing[#missing + 1] = bind.keys
    end
end
if #missing > 0 then
    io.stderr:write("binds without a description: " .. table.concat(missing, ", ") .. "\n")
    os.exit(1)
end
if #binds < 40 then
    io.stderr:write("only " .. #binds .. " binds registered; expected the full set\n")
    os.exit(1)
end
print("hypr config tests passed (" .. #binds .. " binds).")
