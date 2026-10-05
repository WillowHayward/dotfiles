local M = {}

local function metadata()
    local script = (vim.env.WHC_DOTFILES_DIR or (vim.env.HOME .. "/dotfiles")) .. "/walker/tmux-projects.py"
    local result = vim.system({ "python3", script, "roots", vim.fn.getcwd() }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify("Cannot load .whc workspace roots: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
        return { root = vim.fn.getcwd(), search_dirs = { "." } }
    end
    local ok, value = pcall(vim.json.decode, result.stdout)
    if not ok or type(value) ~= "table" then
        vim.notify("Invalid project metadata response", vim.log.levels.WARN)
        return { root = vim.fn.getcwd(), search_dirs = { "." } }
    end
    return value
end

local function workspace_options()
    local project = metadata()
    return { cwd = project.root, search_dirs = project.search_dirs }
end

function M.find_files()
    require("telescope.builtin").find_files(workspace_options())
end

function M.live_grep()
    require("telescope.builtin").live_grep(workspace_options())
end

function M.grep_string()
    require("telescope.builtin").grep_string(workspace_options())
end

-- Pick a project from the same list as `pp` and Walker, and switch the tmux client to its session.
function M.switch()
    local script = (vim.env.WHC_DOTFILES_DIR or (vim.env.HOME .. "/dotfiles")) .. "/walker/tmux-projects.py"
    if not vim.env.TMUX then
        vim.notify("Project switching needs tmux (use pp in a terminal)", vim.log.levels.WARN)
        return
    end
    local result = vim.system({ "python3", script, "list" }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify("Cannot list projects: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
        return
    end
    local labels = vim.split(vim.trim(result.stdout), "\n", { plain = true })
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    require("telescope.pickers")
        .new({}, {
            prompt_title = "Projects",
            finder = require("telescope.finders").new_table({ results = labels }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local entry = state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if entry then
                        vim.system({ "python3", script, "terminal-open", entry[1] }, { detach = true })
                    end
                end)
                return true
            end,
        })
        :find()
end

return M
