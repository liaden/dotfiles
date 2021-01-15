set nocompatible
filetype off

set rtp+=~/.config/nvim/bundle/vundle/
call plug#begin()

Plug 'junegunn/vim-plug'

Plug 'tpope/vim-abolish'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'

Plug 'wsdjeg/vim-fetch'

" neoterm specific
Plug 'kassio/neoterm'

" languages
Plug 'rust-lang/rust.vim'
Plug 'elzr/vim-json'
Plug 'ingydotnet/yaml-vim'
Plug 'ap/vim-css-color'

" ruby
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'

Plug 'hashivim/vim-terraform'

" sql
Plug 'martingms/vipsql'

" tmux
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'roxma/vim-tmux-clipboard'

" git
Plug 'tpope/vim-fugitive', { 'tag': 'v2.5' }
Plug 'airblade/vim-gitgutter'
Plug 'rhysd/committia.vim'
Plug 'junegunn/gv.vim'

Plug 'kana/vim-textobj-user'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdcommenter'
Plug 'tmhedberg/matchit'
Plug 'machakann/vim-highlightedyank'
Plug 'junegunn/fzf'

" colorschemes
Plug 'flazz/vim-colorschemes'
Plug 'mhartington/oceanic-next'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

" lint
Plug 'w0rp/ale'

call plug#end()

"let g:syntastic_ruby_checkers = ['rubocop', 'mri']
let g:ale_open_list        = 1
let g:ale_set_quickfix     = 1
let g:ale_set_loclist      = 0

" Fix vim-tmux-focus-events leaving text behind
au FocusLost * silent redraw!

filetype plugin on

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

set splitright
set splitbelow

" Use zsh as the default vim shell
set shell=zsh

" Fix dropping out of terminal mode
tnoremap <Esc> <C-\><C-n>

" Save unwriteable files with sudo
cmap w!! w !sudo tee > /dev/null %

set guioptions-=m
set guioptions-=T
set mouse-=a
set guioptions+=lbrLR
set guioptions-=lbrLR

" make basic controls easier to use
let mapleader = " "

" vipsql configuration -- vim postgres

noremap <leader>po :VipsqlOpenSession<CR>
noremap <silent> <leader>pk :VipsqlCloseSession<CR>
nnoremap <leader>ps :VipsqlShell<CR>
vnoremap <leader>ps :VipsqlSendSelection<CR>
noremap <leader>pr :VipsqlSendRange<CR>
noremap <leader>pl :VipsqlSendCurrentLine<CR>
noremap <leader>pb :VipsqlSendBuffer<CR>
noremap <leader>pc :VipsqlSendInterrupt<CR>

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


syntax on
set nocp

" space is a valid filename character
set isfname+=33

"commands to make buffers easier to use
nnoremap <leader>b :buffers<CR>:buffer<Space>
nnoremap <C-a><C-a> :b#<CR>

set guifont=Ubuntu\ Mono\ 9

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

" ruby postfix conditional to wrapped
" caputres: (indent)(code)(if|unless) (conditional)
" places cursor on the first line of code
nnoremap <leader>i <S-v>:s/\(\s*\)\(.*\)\s\(if\\|unless\)\s\(.*\)/\1\3 \4\r\1  \2\r\1end/<CR>zok:noh<CR>

" undoes the above: replace three line if/unless conditional to postfix conditional one liner
" caputres: (indent)(conditional)\n\s*(code)\n\s*end\n
nnoremap <leader>I $?^\s*\<if\\|unless\><CR>0:.,.+2s/\(\s*\)\(.*\)\n\s*\(.*\)\n\s*end\n/\1\3 \2\r/<CR>k^:noh<CR>

set rtp+=/usr/local/Cellar/fzf/0.10.2/

"disable hiding quotes around keys in json
let g:vim_json_syntax_conceal=0

" set indent to 2 for ruby
autocmd FileType ruby set sw=2 sts=2 et

"set colorcolumn=80,120
set rnu

set foldmethod=syntax
set foldlevelstart=1

if (has("termguicolors"))
 set termguicolors
endif

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
"colors herald
let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1
colors OceanicNext

hi CursorLine term=underline cterm=underline gui=underline

" Zoom In/Out into another tab
function! s:TabToggle() abort
  if tabpagewinnr(tabpagenr(), '$') > 1
    " Zoom in when this tab has more than one window
    tab split
  elseif tabpagenr('$') > 1
    " Zoom out when this tab is not the last tab
    if tabpagenr() < tabpagenr('$')
      tabclose
      tabprevious
    else
      tabclose
    endif
  endif
endfunction
command! TabToggle call s:TabToggle()
nnoremap <leader>t :TabToggle<cr>

highlight Folded guifg=grey

" split bindings
map <A-j> <C-W>j
map <A-h> <C-W>h
map <A-k> <C-W>k
map <A-l> <C-W>l

" syntastic
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" fix muscle memory
nnoremap $a :echo "Use A"<CR>
nnoremap ^i :echo "Use I"<CR>

"autocmd BufEnter [^_]*[^.][^.][^.][^.] execute ":source  ~/cpp.vim"
"autocmd BufEnter *cpp execute ":source ~/cpp.vim"
"autocmd BufEnter *xml execute ":source ~/xml.vim"
"autocmd BufEnter *txt,*rtf execute ":source ~/txt.vim"
au BufNewFile,BufRead *.js.erb      set filetype=javascript
au BufNewFile,BufRead *.yaml,*.yml  setf yaml

autocmd BufWritePre * StripWhitespace
