" Basic Setup
"" Encoding
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

"" Fix backspace indent
set backspace=indent,eol,start

"" Tabs. May be overridden by autocmd rules
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab

"" Map leader to ,
let mapleader=','

"" Enable hidden buffers
set hidden

"" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

set fileformats=unix,dos,mac

"" session management
let g:session_directory="~/.config/nvim/session"
let g:session_autoload="no"
let g:session_autosave="no"
let g:session_command_aliases=1 

" Visual Settings
syntax on
set ruler
set number

"" status bar
set laststatus=2
set title
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\

" source another vim files
let g:nvim_config_root = stdpath('config')
let g:config_file_list = ['plugin.vim',
            \ 'plugins/nerdtree/nerdtree.vim',
            \ 'plugins/vim-airline/vim-airline.vim',
            \ 'plugins/fugitive/fugitive.vim',
            \ 'plugins/fzf/fzf.vim',
			\ 'plugins/coc/coc.vim', 
            \ 'keymappings.vim',
            \ 'color.vim'
            \ ]

for f in g:config_file_list
    execute 'source ' . g:nvim_config_root . '/' . f 
endfor
