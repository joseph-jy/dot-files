" set wiki list
let g:vimwiki_list = [
  \ {
    \ 'path': '~/Documents/wiki',
    \ 'ext': '.md',
    \ 'diary_rel_path': '.'
  \ }
\ ]

" better off vimwiki's conceallevel
let g:vimwiki_conceallevel = 0

" only markdown files in vimwiki_list.path apply vimwiki
let g:vimwiki_global_ext = 0
let g:md_modify_disabled = 0

" set maplocalleader
let maplocalleader = "\\"

" automate `updated` 
autocmd BufWritePre *.md call LastModified()

" automate new file's meta
autocmd BufRead,BufNewFile *.md call NewTemplate()
