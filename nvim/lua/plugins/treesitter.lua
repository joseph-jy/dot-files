local M = {}

function M.config()
  require("nvim-treesitter").setup({})

  local languages = { "lua", "markdown", "markdown_inline", "bash", "python", "javascript" }
  local installed = require("nvim-treesitter.config").get_installed()
  local missing = vim.tbl_filter(function(lang)
    return not vim.list_contains(installed, lang)
  end, languages)
  if #missing > 0 then
    require("nvim-treesitter").install(missing)
  end

  vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
    end,
  })
end

return M
