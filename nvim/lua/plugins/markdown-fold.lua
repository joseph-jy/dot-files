vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldnestmax = 4
  end,
})

vim.keymap.set("n", "<leader>mf", function()
  -- Toggle all folds in buffer
  local all_closed = true
  for i = 1, vim.api.nvim_buf_line_count(0) do
    if vim.fn.foldclosed(i) == -1 and vim.fn.foldlevel(i) > 0 then
      all_closed = false
      break
    end
  end
  if all_closed then
    vim.cmd("normal! zR")
  else
    vim.cmd("normal! zM")
  end
end, { desc = "Toggle all markdown folds" })
