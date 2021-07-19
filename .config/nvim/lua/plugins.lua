-- bootstrap packer.nvim if not installed
local execute = vim.api.nvim_command
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
end

vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'liuchengxu/vista.vim'

  use 'tpope/vim-abolish'
  use { 'tpope/vim-dispatch', opt = true, cmd = { 'Dispatch', 'Make', 'Focus', 'Start' }}
  use 'tpope/vim-endwise'
  use 'tpope/vim-surround'

  use 'wsdjeg/vim-fetch'

  use 'simnalamburt/vim-mundo'

  -- neoterm specific
  use 'kassio/neoterm'
  use 'voldikss/vim-floaterm'

  -- languages
  use 'rust-lang/rust.vim'
  use 'elzr/vim-json'
  use 'ingydotnet/yaml-vim'
  use 'ap/vim-css-color'

  -- ruby
  use 'nelstrom/vim-textobj-rubyblock'
  use 'vim-ruby/vim-ruby'
  use 'tpope/vim-rake'
  use 'tpope/vim-bundler'
  use 'tpope/gem-browse'
  use 'tpope/vim-rails'

  use 'hashivim/vim-terraform'
  use 'pearofducks/ansible-vim'

  -- sql
  use 'martingms/vipsql'

  -- tmux
  use 'christoomey/vim-tmux-navigator'
  use 'tmux-plugins/vim-tmux'
  use 'tmux-plugins/vim-tmux-focus-events'
  use 'roxma/vim-tmux-clipboard'

  -- git
  use 'tpope/vim-fugitive'
  use 'airblade/vim-gitgutter'
  use 'rhysd/committia.vim'
  use 'junegunn/gv.vim'

  use 'kana/vim-textobj-user'
  use 'ntpeters/vim-better-whitespace'
  use 'scrooloose/nerdcommenter'
  use 'tmhedberg/matchit'
  use 'machakann/vim-highlightedyank'
  use 'LeafCage/yankround.vim'

  --use { 'junegunn/fzf', cmd = function() vim.fn['fzf#install']() end }
  --use { 'yuki-ycino/fzf-preview.vim', branch = 'release/rpc' }

  use 'preservim/nerdtree'
  use 'ryanoasis/vim-devicons'
  use 'PhilRunninger/nerdtree-visual-selection'
  use 'Xuyuanp/nerdtree-git-plugin'

  use {
    'iamcco/markdown-preview.nvim',
    run = 'cd app && yarn install',
    cmd = 'MarkdownPreview'
  }

  ---- colorschemes
  use 'flazz/vim-colorschemes'
  use 'mhartington/oceanic-next'

end)
