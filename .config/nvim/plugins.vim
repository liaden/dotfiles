" Install vim-plug if not found
let autoload_plug_path = stdpath('data') . '/site/autoload/plug.vim'
if !filereadable(autoload_plug_path)
  silent execute '!curl -fLo ' . autoload_plug_path . ' --create-dirs "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
unlet autoload_plug_path

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin()

Plug 'junegunn/vim-plug'

Plug 'liuchengxu/vista.vim'

Plug 'tpope/vim-abolish'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'

Plug 'wsdjeg/vim-fetch'

" neoterm specific
Plug 'kassio/neoterm'
Plug 'voldikss/vim-floaterm'

" languages
Plug 'rust-lang/rust.vim'
Plug 'elzr/vim-json'
Plug 'ingydotnet/yaml-vim'
Plug 'ap/vim-css-color'

" ruby
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'
Plug 'tpope/gem-browse'
Plug 'tpope/vim-rails'

Plug 'hashivim/vim-terraform'
Plug 'pearofducks/ansible-vim'

" sql
Plug 'martingms/vipsql'

" tmux
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'roxma/vim-tmux-clipboard'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'rhysd/committia.vim'
Plug 'junegunn/gv.vim'

Plug 'kana/vim-textobj-user'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdcommenter'
Plug 'tmhedberg/matchit'
Plug 'machakann/vim-highlightedyank'
Plug 'LeafCage/yankround.vim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'yuki-ycino/fzf-preview.vim', { 'branch': 'release/rpc' }

Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }

" colorschemes
Plug 'flazz/vim-colorschemes'
Plug 'mhartington/oceanic-next'

" language servers
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plug 'fannheyward/coc-rust-analyzer', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-solargraph', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}

Plug 'iamcco/coc-spell-checker', {'do': 'yarn install --frozen-lockfile'}
Plug 'iamcco/coc-cspell-dicts', {'do': 'yarn install --frozen-lockfile'}


" lint
Plug 'w0rp/ale'

call plug#end()

