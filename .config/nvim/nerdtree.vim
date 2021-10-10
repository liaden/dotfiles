autocmd VimEnter * NERDTreeVCS | wincmd p          " open NERDTree when opening vim but without cursor focus
" TODO: causes ale linter to error on missing endif
"autocmd BufWinEnter * silent NERDTreeMirror     " mirror NERDTREE across all tabs
" autoclose if only NERDTree is let
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif


" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

nnoremap <leader>nt :NERDTreeToggleVCS<CR>
nnoremap <silent> <Leader>ng :NERDTreeFind<CR>

let NERDTreeMinimalUI = 1
let g:NERDTreeGitStatusUseNerdFonts = 1
