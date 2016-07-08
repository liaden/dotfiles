/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install tmux
brew install hub
brew install fzf
brew install neovim/neovim/neovim

git clone https://github.com/liaden/dotfiles ~/dotfiles

cd ~/dotfiles

cp -r .config ~
cp .tmux.conf ~
cp .pryrc ~
cp .zshrc ~
cp .gitconfig ~

cd ~

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

nvim +PlugInstall +qall
