local status_ok, diagram = pcall(require, "diagram")
if not status_ok then
  return
end

diagram.setup({
  integrations = {
    require("diagram.integrations.markdown"),
  },
  events = {
    render_buffer = { "InsertLeave", "BufWinEnter" },
    clear_buffer = { "BufLeave", "BufWinLeave", "BufHidden" },
  },
  renderer_options = {
    mermaid = {
      background = nil,
      theme = nil,
      scale = 1,
    },
  },
})

vim.keymap.set("n", "<leader>dd", function()
  require("diagram").show_diagram_hover()
end, { desc = "Show diagram hover" })
