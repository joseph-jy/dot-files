local dap = require("dap")
local dapui = require("dapui")

require("mason-nvim-dap").setup({
  ensure_installed = { "python", "cppdbg" },
  automatic_installation = true,
  handlers = {},
})

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
