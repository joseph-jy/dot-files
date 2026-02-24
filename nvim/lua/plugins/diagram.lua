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
      theme = "forest",
      scale = 4,
      width = 480,
      height = 640
    },
  },
  keys = {
    {
      "K", -- or any key you prefer
      function()
        require("diagram").show_diagram_hover()
      end,
      mode = "n",
      ft = { "markdown", "norg" }, -- Only in these filetypes
      desc = "Show diagram in new tab",
    },
  }
})

