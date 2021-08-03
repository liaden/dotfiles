set nocompatible
filetype off

source $HOME/.config/nvim/dotfiles.vim
lua require('plugins')

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

set timeoutlen=250

" Use zsh as the default vim shell
set shell=zsh

" Save unwriteable files with sudo
cmap w!! w !sudo tee > /dev/null %

set guioptions-=m
set guioptions-=T
set mouse=a
set guioptions+=lbrLR
set guioptions-=lbrLR

" make basic controls easier to use
let mapleader = " "

source $HOME/.config/nvim/vipsql.vim
source $HOME/.config/nvim/nerdtree.vim
source $HOME/.config/nvim/telescope.vim
lua require('lsp-config')
lua require('treesitter-config')
lua require('completion')
lua require('pairing')
source $HOME/.config/nvim/colors.vim
source $HOME/.config/nvim/terminal.vim
source $HOME/.config/nvim/mundo.vim
source $HOME/.config/nvim/spell.vim

" make regex behave sanely
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set inccommand=split
set showmatch
set hlsearch
nnoremap <leader><space> :noh<cr>

" persist undoes when closing vim
set undofile
set undodir=~/.cache/nvim/undo

syntax on
set nocp

" space is a valid filename character
set isfname+=33

"commands to make buffers easier to use
nnoremap <leader>b :buffers<CR>:buffer<Space>
nnoremap <C-a><C-a> :b#<CR>

set guifont=Ubuntu\ Mono\ 9

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

" exit command without it staying in history
cnoremap <esc> <c-e><c-u><c-c>

au BufNewFile,BufRead *.js.erb      set filetype=javascript
au BufNewFile,BufRead *.yaml,*.yml  setf yaml

autocmd BufWritePre * StripWhitespace
