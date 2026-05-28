local servers = {
  "lua_ls",
  "cssls",
  "html",
  "pyright",
  "jdtls",
  "kotlin_language_server",
  "ts_ls",
  "bashls",
  "jsonls",
  "yamlls",
}

local settings = {
  ui = {
    border = "none",
    icons = {
      package_installed = "◍",
      package_pending = "◍",
      package_uninstalled = "◍",
    },
  },
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
}

require("mason").setup(settings)
require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_enable = false,
})

local handlers = require("lsp.handlers")

for _, server in ipairs(servers) do
  local opts = {
    on_attach = handlers.on_attach,
    capabilities = handlers.capabilities,
  }

  local require_ok, conf_opts = pcall(require, "lsp.settings." .. server)
  if require_ok then
    opts = vim.tbl_deep_extend("force", opts, conf_opts)
  end

  vim.lsp.config[server] = opts
end

vim.lsp.enable(servers)
