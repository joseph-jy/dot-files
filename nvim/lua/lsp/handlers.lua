local M = {}

local status_cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_cmp_ok then
  return M
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities = cmp_nvim_lsp.default_capabilities(M.capabilities)

-- Diagnostic signs
local signs = {
  { name = "DiagnosticSignError", text = "" },
  { name = "DiagnosticSignWarn", text = "" },
  { name = "DiagnosticSignHint", text = "" },
  { name = "DiagnosticSignInfo", text = "" },
}

for _, sign in ipairs(signs) do
  vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

vim.diagnostic.config({
  virtual_text = false,
  signs = { active = signs },
  update_in_insert = true,
  underline = true,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

local function lsp_keymaps(bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
  end

  map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
  map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
  map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
  map("n", "gI", vim.lsp.buf.implementation, "Go to Implementation")
  map("n", "gr", vim.lsp.buf.references, "References")
  map("n", "gl", vim.diagnostic.open_float, "Line Diagnostics")
  map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "Format")
  map("n", "<leader>li", "<cmd>LspInfo<cr>", "Info")
  map("n", "<leader>la", vim.lsp.buf.code_action, "Code Action")
  map("n", "<leader>lj", function() vim.diagnostic.goto_next({ buffer = 0 }) end, "Next Diagnostic")
  map("n", "<leader>lk", function() vim.diagnostic.goto_prev({ buffer = 0 }) end, "Prev Diagnostic")
  map("n", "<leader>lr", vim.lsp.buf.rename, "Rename")
  map("n", "<leader>lh", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature Help")
  map("n", "<leader>lci", vim.lsp.buf.incoming_calls, "Incoming Calls")
  map("n", "<leader>lco", vim.lsp.buf.outgoing_calls, "Outgoing Calls")
  map("n", "<leader>lq", vim.diagnostic.setloclist, "Quickfix")
end

M.on_attach = function(client, bufnr)
  if client.name == "ts_ls" then
    client.server_capabilities.documentFormattingProvider = false
  end

  if client.name == "lua_ls" then
    client.server_capabilities.documentFormattingProvider = false
  end

  lsp_keymaps(bufnr)

  local status_ok, illuminate = pcall(require, "illuminate")
  if status_ok then
    illuminate.on_attach(client)
  end
end

return M
