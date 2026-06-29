# nvim configurations

## Directory Structures

```text
📂 ROOT
├── 🌑 init.lua
└── 📂 lua
   ├── 📂 core
   │  ├── 🌑 options.lua
   │  ├── 🌑 keymaps.lua
   │  ├── 🌑 plugins.lua (lazy.nvim)
   │  ├── 🌑 colorscheme.lua
   │  └── 🌑 autocommands.lua
   ├── 📂 lsp
   │  ├──── 📂 settings
   │  │   ├──🌑 jsonls.lua
   │  │   ├──🌑 lua_ls.lua
   │  │   └──🌑 pyright.lua
   │  ├── 🌑 init.lua
   │  ├── 🌑 mason.lua
   │  └── 🌑 handlers.lua
   └── 📂 plugins
      ├── 🌑 alpha.lua
      ├── 🌑 autopairs.lua
      ├── 🌑 bufferline.lua
      ├── 🌑 cmp.lua
      ├── 🌑 comment.lua
      ├── 🌑 gitsigns.lua
      ├── 🌑 indentline.lua
      ├── 🌑 lualine.lua
      ├── 🌑 project.lua
      ├── 🌑 telescope.lua
      ├── 🌑 toggleterm.lua
      ├── 🌑 treesitter.lua
      └── 🌑 whichkey.lua
```

## Plugin Manager

- [lazy.nvim](https://github.com/folke/lazy.nvim)

## Plugins

| Plugin | Description |
|--------|-------------|
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion engine |
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | Comment toggling |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git integration |
| [alpha-nvim](https://github.com/goolord/alpha-nvim) | Dashboard |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding hints |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Terminal integration |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffer tabs |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indentation guides |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | LSP installer |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | Debug Adapter Protocol |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | UI for nvim-dap |

## Debugging

This configuration uses `nvim-dap` for debugging. Debuggers (like `debugpy`, `cpptools`) are managed via `mason.nvim`.

### Keymaps

| Key | Description |
|-----|-------------|
| `<leader>dt` | Toggle Breakpoint |
| `<leader>ds` | Start / Continue |
| `<leader>dc` | Continue |
| `<leader>di` | Step Into |
| `<leader>do` | Step Over |
| `<leader>du` | Step Out |
| `<leader>dr` | Toggle REPL |
| `<leader>dl` | Run Last |
| `<leader>dh` | Hover Variables |
| `<leader>dg` | Get Session |
| `<leader>dq` | Terminate |
| `<leader>dU` | Toggle UI |
