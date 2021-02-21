set termguicolors

let g:neoterm_autoscroll = '1'
let g:neoterm_default_mod = 'botright'
let g:neoterm_repl_ruby = 'pry'

" handle nested git commit
if executable('nvr')
    let $GIT_EDITOR = 'nvr -cc tabnew --remote-wait'
    autocmd FileType gitcommit,gitrebase,gitconfig set bufhidden=delete
endif

" Fix dropping out of terminal mode
tnoremap <Esc> <C-\><C-n>

autocmd TermOpen * startinsert
autocmd TermEnter * startinsert
