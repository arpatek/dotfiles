#!/usr/bin/env bash

set -e

# Get Dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Created Directories
mkdir -p ~/.zsh/themes
mkdir -p ~/.config/nvim
mkdir -p ~/.ssh/

# Symlink Dotfiles
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.zsh_aliases" ~/.zsh_aliases
ln -sf "$DOTFILES_DIR/.zsh/themes/arpatek.zsh-theme" ~/.zsh/themes/arpatek.zsh-theme
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/.vimrc" ~/.vimrc
ln -sf "$DOTFILES_DIR/.config/nvim/init.vim" ~/.config/nvim/init.vim

# Copy SSH Config File
cp "$DOTFILES_DIR/.ssh/config" ~/.ssh/config
chmod 600 ~/.ssh/config

# Install upu to /usr/local/bin
sudo ln -sf "$DOTFILES_DIR/upu" /usr/local/bin/upu
