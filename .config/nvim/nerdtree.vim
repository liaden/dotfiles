autocmd VimEnter * NERDTree | wincmd p          " open NERDTree when opening vim but without cursor focus
" TODO: causes ale linter to error on missing endif
"autocmd BufWinEnter * silent NERDTreeMirror     " mirror NERDTREE across all tabs
" autoclose if only NERDTree is let
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

nnoremap <leader>nt :NERDTreeToggle<CR>
nnoremap <silent> <Leader>ng :NERDTreeFind<CR>

let NERDTreeMinimalUI = 1
