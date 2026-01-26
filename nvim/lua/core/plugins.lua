local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  rocks = { enabled = false },
  "nvim-lua/plenary.nvim",

  { "windwp/nvim-autopairs", config = function() require "plugins.autopairs" end },
  { "numToStr/Comment.nvim", config = function() require "plugins.comment" end },
  "JoosepAlviste/nvim-ts-context-commentstring",
  "nvim-tree/nvim-web-devicons",
  { "stevearc/oil.nvim", lazy = false, config = function() require "plugins.oil" end },
  { "akinsho/bufferline.nvim", config = function() require "plugins.bufferline" end },
  "moll/vim-bbye",
  { "nvim-lualine/lualine.nvim", config = function() require "plugins.lualine" end },
  { "akinsho/toggleterm.nvim", config = function() require "plugins.toggleterm" end },
  { "ahmedkhalf/project.nvim", config = function() require "plugins.project" end },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", config = function() require "plugins.indentline" end },
  { "goolord/alpha-nvim", config = function() require "plugins.alpha" end },
  { "folke/which-key.nvim", config = function() require "plugins.whichkey" end },

  -- Colorschemes
  "folke/tokyonight.nvim",
  "lunarvim/darkplus.nvim",

  -- Cmp
  { "hrsh7th/nvim-cmp", config = function() require "plugins.cmp" end },
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-nvim-lua",

  -- Snippets
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",

  -- LSP
  "neovim/nvim-lspconfig",
  "mason-org/mason.nvim",
  "mason-org/mason-lspconfig.nvim",
  "RRethy/vim-illuminate",

  -- Telescope
  { "nvim-telescope/telescope.nvim", config = function() require "plugins.telescope" end },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function() require "plugins.treesitter" end },

  -- Git
  { "lewis6991/gitsigns.nvim", config = function() require "plugins.gitsigns" end },
  "tpope/vim-fugitive",

  -- Copilot
  { "zbirenbaum/copilot.lua", config = function() require "plugins.copilot" end },
})
