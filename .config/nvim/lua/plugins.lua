-- bootstrap packer.nvim if not installed
local execute = vim.api.nvim_command
local fn = vim.fn

local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
end

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]]

vim.cmd [[packadd packer.nvim]]

return require('packer').startup({function()
  use 'wbthomason/packer.nvim'

  use {
    'glacambre/firenvim',
    run = function() vim.fn['firenvim#install'](0) end
  }

  use 'liuchengxu/vista.vim'

  use 'tpope/vim-abolish'
  use { 'tpope/vim-dispatch', opt = true, cmd = { 'Dispatch', 'Make', 'Focus', 'Start' }}
  use 'tpope/vim-endwise'
  use 'tpope/vim-surround'

  use 'wsdjeg/vim-fetch'

  use 'simnalamburt/vim-mundo'

  use {
    'nvim-telescope/telescope.nvim',
    requires = {{ 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' }}
  }

  use 'neovim/nvim-lspconfig'
  use 'williamboman/nvim-lsp-installer'
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'nvim-treesitter/playground'
  use 'onsails/lspkind-nvim'

  use { 'weilbith/nvim-code-action-menu', cmd = 'CodeActionMenu' }
  use 'kosayoda/nvim-lightbulb'

  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/nvim-cmp'

  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'

  -- neoterm specific
  use 'kassio/neoterm'
  use 'voldikss/vim-floaterm'
  use 'kamykn/popup-menu.nvim'

  use 'kamykn/spelunker.vim'

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

  -- pair programming stuff
  use 'sunjon/Shade.nvim'
  use 'folke/twilight.nvim'
  use 'machakann/vim-highlightedyank'

  -- git
  use 'tpope/vim-fugitive'
  use 'airblade/vim-gitgutter'
  use 'rhysd/committia.vim'
  use 'junegunn/gv.vim'

  use 'kana/vim-textobj-user'
  use 'ntpeters/vim-better-whitespace'
  use 'scrooloose/nerdcommenter'
  use 'tmhedberg/matchit'
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

  use {
      "folke/which-key.nvim",
      config = function() require("which-key").setup {
        }
      end
  }

  ---- colorschemes
  use 'flazz/vim-colorschemes'
  use 'mhartington/oceanic-next'

  if packer_bootstrap then
    require('packer').sync()
  end
end,
config = {
  display = {
    open_fn = require('packer.util').float,
  }
}
})
