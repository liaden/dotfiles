let g:textobj#quote#educate = 0 " disable

function! Prose()
  call pencil#init()
  "call lexical#init()
  "call litecorrect#init()
  call textobj#quote#init()
  call textobj#sentence#init()

  " manual reformatting shortcuts
  " nnoremap <buffer> <silent> Q gqap
  " xnoremap <buffer> <silent> Q gq
  " nnoremap <buffer> <silent> <leader>Q vapJgqap
endfunction

" automatically initialize buffer by file type
autocmd FileType markdown,mkd,text call Prose()

" invoke manually by command for other file types
command! -nargs=0 Prose call Prose()

