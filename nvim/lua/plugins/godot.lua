-- Godot (home only): GDScript LSP and debugging, scene tree, run console. Keys are under <leader>o;
-- <leader>g stays Git and <leader>c language actions.
if not require("whc.profile").features.godot then
    return {}
end

local function command(name, description)
    return { name, "<cmd>" .. description[1] .. "<CR>", desc = description[2] }
end

return {
    "Mathijs-Bakker/godotdev.nvim",
    dependencies = {
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-treesitter/nvim-treesitter",
        "saghen/blink.cmp",
    },
    keys = {
        command("<leader>or", { "GodotRunProject", "Run Godot project" }),
        command("<leader>os", { "GodotRunCurrentScene", "Run current Godot scene" }),
        command("<leader>of", { "GodotRunScenePicker", "Find and run Godot scene" }),
        command("<leader>ot", { "GodotSceneTree", "View Godot scene tree" }),
        command("<leader>ok", { "GodotDocsCursor", "Godot docs under cursor" }),
        command("<leader>oc", { "GodotShowConsole", "Show Godot console" }),
        command("<leader>ol", { "GodotReconnectLSP", "Reconnect Godot LSP" }),
        command("<leader>oh", { "checkhealth godotdev", "Check Godot integration" }),
        command("<leader>ow", { "GodotWorkspace", "Godot development layout" }),
        command("<leader>ox", { "GodotStop", "Stop Godot game" }),
    },
    opts = {
        -- Formatting goes through conform (gdformat), including <leader>cf and format on save.
        formatter = false,
        -- The installed Treesitter uses the new API; plugins/treesitter.lua configures it.
        treesitter = { auto_setup = false },
        run = { console = { enabled = true, buffer = { position = "bottom", size = 0.28 } } },
        scene_tree = { buffer = { position = "left", size = 0.32 } },
    },
    config = function(_, opts)
        require("godotdev").setup(opts)
        require("whc.godot_workflow").setup()
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        capabilities.textDocument.typeDefinition = nil -- Unsupported by Godot.
        vim.lsp.config("gdscript", { capabilities = capabilities, root_markers = { "project.godot" } })

        -- Resolve from the buffer so debugging also works from a project subdirectory.
        local function project_root()
            local root = vim.fs.root(0, "project.godot") or vim.fs.root(vim.fn.getcwd(), "project.godot")
            if not root then
                vim.notify("Open a Godot project before debugging", vim.log.levels.WARN)
                return require("dap").ABORT
            end
            return root
        end
        require("dap").configurations.gdscript = {
            {
                type = "godot",
                request = "launch",
                name = "Godot: main scene",
                project = project_root,
                scene = "main",
            },
            {
                type = "godot",
                request = "launch",
                name = "Godot: scene selected in editor",
                project = project_root,
                scene = "current",
            },
        }
    end,
}
