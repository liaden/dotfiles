
call pathogen#infect()

set nocompatible

set t_Co=256

" tabs and indenting
set tabstop=4
set shiftwidth=4
set smartindent
set expandtab
set autoindent

set encoding=utf-8
set scrolloff=10
set showmode
set showcmd
set hidden
set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2

set guioptions-=m
set guioptions-=T
set mouse-=a
set guioptions+=lbrLR
set guioptions-=lbrLR

" make basic controls easier to use
let mapleader = ","

" make regex behave sanely
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
nnoremap <leader><space> :noh<cr>


" persist undos when closing vim
set undofile
set undodir=~/tmp

set cursorline
hi CursorLine term=underline cterm=underline gui=underline

syntax on

set nocp
filetype plugin on

" space is a valid filename character
set isfname+=33


"commands to make buffers easier to use
nnoremap <leader>b :buffers<CR>:buffer<Space>
nnoremap <C-a><C-a> :b#<CR>

set guifont=Ubuntu\ Mono\ 11

function! BufSel(pattern)
  let bufcount = bufnr("$")
  let currbufnr = 1
  let nummatches = 0
  let firstmatchingbufnr = 0
  while currbufnr <= bufcount
    if(bufexists(currbufnr))
      let currbufname = bufname(currbufnr)
      if(match(currbufname, a:pattern) > -1)
        echo currbufnr . ": ". bufname(currbufnr)
        let nummatches += 1
        let firstmatchingbufnr = currbufnr
      endif
    endif
    let currbufnr = currbufnr + 1
  endwhile
  if(nummatches == 1)
    execute ":buffer ". firstmatchingbufnr
  elseif(nummatches > 1)
    let desiredbufnr = input("Enter buffer number: ")
    if(strlen(desiredbufnr) != 0)
      execute ":buffer ". desiredbufnr
    endif
  else
    echo "No matching buffers"
  endif
endfunction
command! -nargs=1 Bs :call BufSel("<args>")
nnoremap Bs :Bs<Space>

"disable hiding quotes around keys in json
let g:vim_json_syntax_conceal=0

" set indent to 2 for ruby
autocmd FileType ruby set sw=2 sts=2 et

"set colorcolumn=80,120
set rnu

"colorshemes that I like
"colors desert
"colors asu1dark
"colors camo
"colors darkblue2
"colors chocolateliquor
"colors darkZ
"colors darkbone
"colors darkspectrum
"colors dusk
"colors earendel
colors herald

inoremap jk <esc>
inoremap kj <esc>

" split bindings
map <A-j> <C-W>j
map <A-h> <C-W>h
map <A-k> <C-W>k
map <A-l> <C-W>l

"autocmd BufEnter [^_]*[^.][^.][^.][^.] execute ":source  ~/cpp.vim"
"autocmd BufEnter *cpp execute ":source ~/cpp.vim"
"autocmd BufEnter *xml execute ":source ~/xml.vim"
"autocmd BufEnter *txt,*rtf execute ":source ~/txt.vim"
au BufNewFile,BufRead *.js.erb set filetype=javascript

