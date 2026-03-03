require("render-markdown").setup({
  enabled = true,
  render_modes = { "n", "c", "t" },
  file_types = { "markdown" },
  pipe_table = {
    enabled = true,
    preset = "round",
    cell = "padded",
    padding = 1,
    min_width = 0,
    border_enabled = true,
    alignment_indicator = "━",
    style = "full",
  },
})
