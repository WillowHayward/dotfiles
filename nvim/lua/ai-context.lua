-- Prefer the current directory's running Codex terminal without showing a picker.
local M = {}

function M.attach(cwd)
    local Session = require("sidekick.cli.session")
    local State = require("sidekick.cli.state")
    Session.setup()
    cwd = Session.cwd({ cwd = cwd })
    local candidates = State.get({ name = "codex", started = true })
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
    local session = Session.new({ tool = "codex", cwd = cwd, backend = "terminal" })
    local state = State.attach(State.get_state(session), { show = false })
    state.terminal:hide()
    return state
end

function M.toggle()
    local state = M.attach()
    if state.terminal then
        state.terminal:toggle()
        if state.terminal:is_open() then
            state.terminal:focus()
        end
    end
end

function M.send(message)
    local state = M.attach()
    require("sidekick.cli").send(vim.tbl_extend("force", message, {
        name = "codex",
        filter = { session = state.session.id },
    }))
end

return M
