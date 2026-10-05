-- Sidekick agent terminals, one per tool and project directory. The tools a profile offers
-- come from whc.profile (first is the default); `current` is the one toggles and sends use.
local M = {}
local tools = require("whc.profile").features.ai_tools
M.current = tools[1]

local function session_for(tool, cwd)
    local Session = require("sidekick.cli.session")
    local State = require("sidekick.cli.state")
    Session.setup()
    cwd = Session.cwd({ cwd = cwd })
    local candidates = State.get({ name = tool, started = true })
    -- Prefer a local terminal; existing external contexts remain usable during migration.
    table.sort(candidates, function(a, b)
        local function rank(s)
            return (s.terminal and 4 or 0) + (s.attached and 2 or 0)
        end
        return rank(a) > rank(b)
    end)
    for _, state in ipairs(candidates) do
        if state.session.cwd == cwd then
            return State.attach(state, { show = false })
        end
    end
    local session = Session.new({ tool = tool, cwd = cwd, backend = "terminal" })
    local state = State.attach(State.get_state(session), { show = false })
    state.terminal:hide()
    return state
end

-- Attach (starting if needed) the tool's terminal for cwd without showing it.
function M.attach(cwd, tool)
    return session_for(tool or M.current, cwd)
end

function M.toggle(tool)
    local state = M.attach(nil, tool)
    if state.terminal then
        state.terminal:toggle()
        if state.terminal:is_open() then
            state.terminal:focus()
        end
    end
end

function M.send(message, tool)
    tool = tool or M.current
    local state = M.attach(nil, tool)
    require("sidekick.cli").send(vim.tbl_extend("force", message, {
        name = tool,
        filter = { session = state.session.id },
    }))
end

-- Choose which tool toggles and sends use for the rest of this session.
function M.choose()
    vim.ui.select(tools, { prompt = "Agent tool" }, function(choice)
        if choice then
            M.current = choice
            vim.notify("Agent tool: " .. choice)
        end
    end)
end

return M
