local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Install your plugins here
return packer.startup(function(use)
  use { "wbthomason/packer.nvim", commit = "ea0cc3c59f67c440c5ff0bbe4fb9420f4350b9a3" } -- Have packer manage itself
  use { "nvim-lua/plenary.nvim", commit = "857c5ac632080dba10aae49dba902ce3abf91b35" } -- Useful lua functions used by lots of plugins
  use { "windwp/nvim-autopairs", commit = "2a406cdd8c373ae7fe378a9e062a5424472bd8d8" } -- Autopairs, integrates with both cmp and treesitter
  use { "numToStr/Comment.nvim", commit = "e30b7f2008e52442154b66f7c519bfd2f1e32acb" }
  use { "JoosepAlviste/nvim-ts-context-commentstring", commit = "1b212c2eee76d787bbea6aa5e92a2b534e7b4f8f" }
  use { "nvim-tree/nvim-web-devicons", commit = "1fb58cca9aebbc4fd32b086cb413548ce132c127" }
  use { "nvim-tree/nvim-tree.lua", commit = "1c733e8c1957dc67f47580fe9c458a13b5612d5b" }
  use { "akinsho/bufferline.nvim", commit = "73edc1f2732678e7a681e3d3be49782610914f6b" }
	use { "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" }
  use { "nvim-lualine/lualine.nvim", commit = "d3ff69639e78f2732e86ae2130496bd2b66e25c9" }
  use { "akinsho/toggleterm.nvim", commit = "b4b0dfcab480d3449fbd28535b7a717411e9412f" }
  use { "ahmedkhalf/project.nvim", commit = "8c6bad7d22eef1b71144b401c9f74ed01526a4fb" }
  use { "lewis6991/impatient.nvim", commit = "47302af74be7b79f002773011f0d8e85679a7618" }
  use { "lukas-reineke/indent-blankline.nvim", commit = "005b56001b2cb30bfa61b7986bc50657816ba4ba" }
  use { "goolord/alpha-nvim", commit = "0f24de96293d31bf11a2b5bb08040952fa6f3aff" }
	use { "folke/which-key.nvim", commit = "fcbf4eea17cb299c02557d576f0d568878e354a4" }

	-- Colorschemes
  use { "folke/tokyonight.nvim", commit = "0c68bc3876897613110a2f71340f2dc760c9c761" }
  use { "lunarvim/darkplus.nvim", commit = "c7fff5ce62406121fc6c9e4746f118b2b2499c4c" }

	-- Cmp 
  use { "hrsh7th/nvim-cmp", commit = "b5311ab3ed9c846b585c0c15b7559be131ec4be9" } -- The completion plugin
  use { "hrsh7th/cmp-buffer", commit = "3022dbc9166796b644a841a02de8dd1cc1d311fa" } -- buffer completions
  use { "hrsh7th/cmp-path", commit = "91ff86cd9c29299a64f968ebb45846c485725f23" } -- path completions
	use { "saadparwaiz1/cmp_luasnip", commit = "98d9cb5c2c38532bd9bdb481067b20fea8f32e90" } -- snippet completions
	use { "hrsh7th/cmp-nvim-lsp", commit = "99290b3ec1322070bcfb9e846450a46f6efa50f0" }
	use { "hrsh7th/cmp-nvim-lua", commit = "f12408bdb54c39c23e67cab726264c10db33ada8" }

	-- Snippets
  use { "L3MON4D3/LuaSnip", commit = "5271933f7cea9f6b1c7de953379469010ed4553a" } --snippet engine
  use { "rafamadriz/friendly-snippets", commit = "572f5660cf05f8cd8834e096d7b4c921ba18e175" } -- a bunch of snippets to use

	-- LSP
	use { "neovim/nvim-lspconfig", commit = "a182334ba933e58240c2c45e6ae2d9c7ae313e00" } -- enable LSP
  use { "mason-org/mason.nvim", commit = "8024d64e1330b86044fed4c8494ef3dcd483a67c"} -- simple to use language server installer
  use { "mason-org/mason-lspconfig.nvim", commit = "bef29b653ba71d442816bf56286c2a686210be04" }
	use { "jose-elias-alvarez/null-ls.nvim", commit = "e45670abdcda293282b7a00d0e2f7d473e7d6251" } -- for formatters and linters
  use { "RRethy/vim-illuminate", commit = "2086527383c780983c702d0cdb304409dc0358f6" }

	-- Telescope
	use { "nvim-telescope/telescope.nvim", commit = "b4da76be54691e854d3e0e02c36b0245f945c2c7" }

	-- Treesitter
	use { "nvim-treesitter/nvim-treesitter", commit = "066fd6505377e3fd4aa219e61ce94c2b8bdb0b79" }

	-- Git
	use { "lewis6991/gitsigns.nvim", commit = "d0f90ef51d4be86b824b012ec52ed715b5622e51" }
  use { "tpope/vim-fugitive", commit = "fcb4db52e7f65b95705aa58f0f2df1312c1f2df2" }

  -- Markdown
  use { 'iamcco/markdown-preview.nvim', commit = "a923f5fc5ba36a3b17e289dc35dc17f66d0548ee" }

  -- Debugger
  use { 'mfussenegger/nvim-dap', commit = "b0f983507e3702f073bfe1516846e58b56d4e42f" }
  -- Debugger For Python
  use { 'mfussenegger/nvim-dap-python', commit = "261ce649d05bc455a29f9636dc03f8cdaa7e0e2c" }
  use { 'rcarriga/nvim-dap-ui', commit = "73a26abf4941aa27da59820fd6b028ebcdbcf932" }

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
