require("mtoc").setup({
  headings = {
    before_toc = false,
  },
  toc_list = {
    markers = { "-" },
    indent_size = 2,
  },
  fences = {
    enabled = true,
    start_text = "mtoc-start",
    end_text = "mtoc-end",
  },
  auto_update = {
    enabled = true,
    events = { "BufWritePre" },
    pattern = "*.{md,mdown,mkd,mkdn,markdown,mdwn}",
  },
})
