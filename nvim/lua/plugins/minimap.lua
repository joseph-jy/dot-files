local status_ok, minimap = pcall(require, "mini.map")
if not status_ok then
  return
end

minimap.setup({
  integrations = {
    minimap.gen_integration.builtin_search(),
    minimap.gen_integration.gitsigns(),
    minimap.gen_integration.diagnostic(),
  },
  window = {
    width = 10,
    winblend = 50,
  },
})

vim.keymap.set("n", "<leader>mm", minimap.toggle, { desc = "Toggle minimap" })
