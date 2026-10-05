-- Local integration around godotdev's scene picker/tree; no plugin-cache edits.
local M = {}
local state = { generation = 0, busy = false, placement = {} }
local helper = vim.fn.stdpath("config") .. "/bin/godot-session"

local function console()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(buf) == "godotdev://console" then
                state.buf = buf
                return buf
            end
        end
        state.buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(state.buf, "godotdev://console")
        vim.bo[state.buf].bufhidden = "hide"
        vim.bo[state.buf].filetype = "log"
        vim.bo[state.buf].modifiable = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = state.buf })
    end
    return state.buf
end

local function append(lines)
    local buf = console()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
end

function M.show()
    local buf = console()
    local win = vim.fn.bufwinid(buf)
    if win == -1 then
        vim.cmd("botright " .. math.max(8, math.floor(vim.o.lines * 0.28)) .. "split")
        win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)
    else
        vim.api.nvim_set_current_win(win)
    end
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].wrap = false
    return true
end

local function stop_project(root, callback)
    if state.busy then
        state.pending = { root, callback }
        return true
    end
    state.busy = true
    vim.system({ "python3", helper, "stop", root }, { text = true }, function(result)
        vim.schedule(function()
            state.busy = false
            if result.code ~= 0 then
                state.pending = nil
                vim.notify(result.stderr, vim.log.levels.ERROR)
                return
            end
            state.generation = state.generation + 1
            state.process = nil
            local previous = vim.trim(result.stdout)
            if previous ~= "null" and previous ~= "" then
                state.placement[root] = previous
            end
            callback(state.placement[root] or "null")
            if state.pending then
                local pending = state.pending
                state.pending = nil
                stop_project(pending[1], pending[2])
            end
        end)
    end)
    return true
end

function M.start(cmd, root)
    -- Save only modified files inside this project, including the selected scene.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.bo[buf].modified and vim.bo[buf].buftype == "" and name:sub(1, #root + 1) == root .. "/" then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("update")
            end)
        end
    end
    local editor = vim.api.nvim_get_current_win()
    return stop_project(root, function(previous)
        -- Capture output without opening a split; <leader>oc shows it on demand.
        local buf = console()
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Godot Console", "Project: " .. root, "" })
        vim.bo[buf].modifiable = false
        local generation = state.generation
        local partial = { stdout = "", stderr = "" }
        local function stream(kind, data)
            if not data or generation ~= state.generation then
                return
            end
            local lines = vim.split(partial[kind] .. data, "\n", { plain = true })
            partial[kind] = table.remove(lines) or ""
            if kind == "stderr" then
                for i, line in ipairs(lines) do
                    lines[i] = "[stderr] " .. line
                end
            end
            append(lines)
        end
        local ok, process = pcall(vim.system, cmd, {
            cwd = root,
            text = true,
            stdout = function(_, data)
                vim.schedule(function()
                    stream("stdout", data)
                end)
            end,
            stderr = function(_, data)
                vim.schedule(function()
                    stream("stderr", data)
                end)
            end,
        }, function(result)
            vim.schedule(function()
                if generation ~= state.generation then
                    return
                end
                for kind, text in pairs(partial) do
                    if text ~= "" then
                        append({ kind .. ": " .. text })
                    end
                end
                append({ "", "[Process exited] code=" .. result.code .. " signal=" .. result.signal })
                state.process = nil
            end)
        end)
        if not ok then
            append({ "[spawn error] " .. tostring(process) })
            return
        end
        state.process, state.root = process, root
        vim.system({ "python3", helper, "place", tostring(process.pid), previous }, { text = true }, function(result)
            if result.code ~= 0 then
                vim.schedule(function()
                    vim.notify(result.stderr, vim.log.levels.WARN)
                end)
            end
        end)
        if vim.api.nvim_win_is_valid(editor) then
            vim.api.nvim_set_current_win(editor)
        end
    end)
end

function M.stop()
    local root = require("godotdev.utils").find_project_root() or state.root
    if not root then
        return
    end
    stop_project(root, function()
        append({ "[Stopped]" })
    end)
end

function M.layout()
    local editor = vim.api.nvim_get_current_win()
    if not require("godotdev.scene_tree").open() then
        return
    end
    M.show()
    if vim.api.nvim_win_is_valid(editor) then
        vim.api.nvim_set_current_win(editor)
    end
end

function M.setup()
    local run_console = require("godotdev.run_console")
    run_console.start, run_console.show = M.start, M.show
    vim.api.nvim_create_user_command("GodotWorkspace", M.layout, { desc = "Scene tree, script and console" })
    vim.api.nvim_create_user_command("GodotStop", M.stop, { desc = "Stop this project's game" })
    vim.keymap.set("n", "<leader>ow", M.layout, { desc = "Godot development layout" })
    vim.keymap.set("n", "<leader>ox", M.stop, { desc = "Stop Godot game" })
    local group = vim.api.nvim_create_augroup("GodotWorkflow", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "gdscript", "gdshader", "godot", "gdresource" },
        callback = function(args)
            for key, command in pairs({
                ["<F5>"] = "GodotRunProject",
                ["<F6>"] = "GodotRunCurrentScene",
                ["<F8>"] = "GodotStop",
            }) do
                vim.keymap.set("n", key, "<cmd>" .. command .. "<cr>", { buffer = args.buf, desc = command })
            end
        end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            if state.process then
                state.process:kill(15)
            end
        end,
    })
end
return M
