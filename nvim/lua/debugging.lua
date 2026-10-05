-- Shared debugger UI; language plugins supply their own adapters/configurations.
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
	},
	config = function()
		local dap, dapui = require("dap"), require("dapui")
		dapui.setup()
		-- godotdev uses this same listener key, so loading it does not duplicate hooks.
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
	end,
}
