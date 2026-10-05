-- Workspace operations live here; bindings and rules live in workspaces.lua
-- and workspace_rules.lua respectively.
local M = {}
local workspaceCount = 10

function M.normalizeWorkspace(num, monitor)
    return num + (monitor or hl.get_active_monitor()).id * workspaceCount
end

local function activeRange()
    local monitor = hl.get_active_monitor()
    local active = monitor and monitor.active_workspace
    if not active or monitor.active_special_workspace then
        return
    end
    local first = M.normalizeWorkspace(1, monitor)
    if active.id < first or active.id >= first + workspaceCount then
        return
    end
    return monitor, active, first
end

function M.normalizeRelativeWorkspace(direction)
    local _, active, first = activeRange()
    if active then
        return first + (active.id - first + direction) % workspaceCount
    end
end

function M.focusAbsoluteWorkspace(workspace)
    return hl.dsp.focus({ workspace = workspace })
end

function M.focusMonitorWorkspace(num)
    return function()
        if hl.get_active_monitor() then
            hl.dispatch(M.focusAbsoluteWorkspace(M.normalizeWorkspace(num)))
        end
    end
end

function M.moveWindowToMonitorWorkspace(num)
    return function()
        if hl.get_active_monitor() and hl.get_active_window() then
            hl.dispatch(hl.dsp.window.move({ workspace = M.normalizeWorkspace(num) }))
        end
    end
end

function M.moveWindowRelativeWorkspace(direction)
    local target = M.normalizeRelativeWorkspace(direction)
    if target and hl.get_active_window() then
        hl.dispatch(hl.dsp.window.move({ workspace = target, follow = true }))
    end
end

function M.focusRelativeWorkspace(direction)
    local monitor, active, first = activeRange()
    if not monitor then
        return
    end
    for offset = 1, workspaceCount - 1 do
        local target = first + (active.id - first + direction * offset) % workspaceCount
        local workspace = hl.get_workspace(target)
        if workspace and not workspace.is_empty and workspace.monitor and workspace.monitor.id == monitor.id then
            hl.dispatch(M.focusAbsoluteWorkspace(target))
            return
        end
    end
end

function M.focusNextWorkspace()
    M.focusRelativeWorkspace(1)
end

function M.focusPreviousWorkspace()
    M.focusRelativeWorkspace(-1)
end

-- Nonexistent workspaces are empty too. Wrap within this monitor's range.
function M.findEmptyWorkSpace(direction)
    local monitor, active, first = activeRange()
    if not monitor then
        return
    end
    for offset = 1, workspaceCount - 1 do
        local target = first + (active.id - first + direction * offset) % workspaceCount
        local workspace = hl.get_workspace(target)
        if not workspace or (workspace.is_empty and workspace.monitor and workspace.monitor.id == monitor.id) then
            return target
        end
    end
end

local function refuseInsertion(text)
    hl.notification.create({ text = text, timeout = 4000 })
end

local function changeId(workspace, id)
    local numberedName = workspace.name == tostring(workspace.id)
    hl.dispatch(hl.dsp.workspace.change_id({ workspace = workspace.id, id = id }))
    if numberedName then
        hl.dispatch(hl.dsp.workspace.rename({ workspace = id, name = tostring(id) }))
    end
end

-- Shift entire workspaces from right to left, preserving their window layouts.
-- direction = 1 inserts after the current workspace; -1 inserts before it.
function M.insertWorkspace(direction, moveCurrentWindow)
    -- Capture the window before renumbering or changing focus.
    local window = moveCurrentWindow and hl.get_active_window() or nil
    local monitor, active, first = activeRange()
    if not monitor then
        refuseInsertion("Select a numbered workspace before inserting a workspace.")
        return
    end
    local target = active.id + (direction == 1 and 1 or 0)
    local last = first + workspaceCount - 1
    local tail = hl.get_workspace(last)
    if target > last or (tail and not tail.is_empty) then
        refuseInsertion("No room to insert: this monitor's workspace range ends at " .. last .. ".")
        return
    end
    -- Refuse to shift workspaces that have been moved to another monitor.
    for id = target, last do
        local workspace = hl.get_workspace(id)
        if workspace and (not workspace.monitor or workspace.monitor.id ~= monitor.id) then
            refuseInsertion("Workspace " .. id .. " belongs to another monitor.")
            return
        end
    end
    -- An existing empty last workspace can be reused at the insertion point.
    -- Park it at a free ID while shifting so no destination ID is occupied.
    if tail then
        local temporary = last + 1
        while hl.get_workspace(temporary) do
            temporary = temporary + 1
        end
        changeId(tail, temporary)
    end
    for id = last - 1, target, -1 do
        local workspace = hl.get_workspace(id)
        if workspace then
            changeId(workspace, id + 1)
        end
    end
    if tail then
        changeId(tail, target)
    end
    if window then
        hl.dispatch(hl.dsp.window.move({ window = window, workspace = target, follow = true }))
    else
        hl.dispatch(M.focusAbsoluteWorkspace(target))
    end
end

return M
