# nvim configurations

## Directory Structures

```text
📂 ROOT
├── 🌑 init.lua
└── 📂 lua  
   ├── 📂 core
   │  ├── 🌑 options.lua
   │  ├── 🌑 keymaps.lua
   │  ├── 🌑 plugins.lua
   │  ├── 🌑 colorscheme.lua
   │  └── 🌑 autocommands.lua
   ├── 📂 lsp
   │  ├──── 📂 settings
   │  │   ├──🌑 jsonls.lua
   │  │   ├──🌑 lua_ls.lua
   │  │   └──🌑 pyright.lua
   │  ├── 🌑 init.lua
   │  ├── 🌑 mason.lua
   │  ├── 🌑 null-ls.lua
   │  └── 🌑 handlers.lua
   └── 📂 plugins
      ├── 🌑 alpha.lua
      ├── 🌑 autopairs.lua
      ├── 🌑 bufferline.lua
      ├── 🌑 cmp.lua
      ├── 🌑 comment.lua
      ├── 🌑 gitsigns.lua
      ├── 🌑 impatient.lua
      ├── 🌑 indentline.lua
      ├── 🌑 lualine.lua
      ├── 🌑 nvim-tree.lua
      ├── 🌑 project.lua
      ├── 🌑 telescope.lua
      ├── 🌑 toggleterm.lua
      ├── 🌑 treesitter.lua
      └── 🌑 whichkey.lua
```

## Plugins

### nvim-cmp
 
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) 는 자동완성 엔진이다. 

### Comment

- [Comment](https://github.com/numToStr/Comment.nvim) 는 각종 주석처리용 플러그인이다.

### gitsigns

- [gitsigns](https://github.com/lewis6991/gitsigns.nvim) 는 git 통합 플러그인이다.

### alpha-nvim

- [alph-nvim](https://github.com/goolord/alpha-nvim) 는 nvim 용 Dashboard 같은 플러그인이다.
