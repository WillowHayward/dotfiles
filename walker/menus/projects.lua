Name = "projects"
NamePretty = "Projects"
Description = "Open a project in tmux"
Icon = "folder-development"
Cache = false
FixedOrder = true
History = false
Action = "lua:OpenProject"

local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end
local script = os.getenv("HOME") .. "/dotfiles/walker/tmux-projects.py"

function GetEntries()
    local handle = assert(io.popen("python3 " .. quote(script) .. " entries"))
    local output = handle:read("*a")
    handle:close()
    return assert(jsonDecode(output))
end

function OpenProject(value)
    os.execute("python3 " .. quote(script) .. " open " .. quote(value) .. " >/dev/null 2>&1 &")
end
