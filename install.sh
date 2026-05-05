#!/usr/bin/env bash
# =============================================================================
# Script Name: install.sh
# Description: Dotfiles installer — backs up existing configs, symlinks
#              dotfiles into place, and installs upu system-wide.
# Author: Juan Garcia (arpatek)
# Version: 1.0
# =============================================================================

# ──[ Bash Version Check ]─────────────────────────────────────────────────────
if ((BASH_VERSINFO[0] < 4)); then
  printf "install.sh requires bash 4 or higher (detected: %s)\n" "$BASH_VERSION" >&2
  exit 1
fi

set -eo pipefail

# ──[ ANSI Color Codes ]───────────────────────────────────────────────────────
declare -A C=(
  [red]=$'\033[0;31m'
  [green]=$'\033[0;32m'
  [yellow]=$'\033[0;33m'
  [blue]=$'\033[0;34m'
  [purple]=$'\033[0;35m'
  [reset]=$'\033[0m'
)

# ──[ Decoration Functions ]───────────────────────────────────────────────────
BANNER()   { printf "%s[%s^%s]%s" "${C[yellow]}" "${C[purple]}" "${C[yellow]}" "${C[reset]}"; }
PLUS()     { printf "%s[%s+%s]%s" "${C[yellow]}" "${C[green]}"  "${C[yellow]}" "${C[reset]}"; }
COMPLETE() { printf "%s[%s*%s]%s" "${C[yellow]}" "${C[blue]}"   "${C[yellow]}" "${C[reset]}"; }
FAILED()   { printf "%s[%s!%s]%s" "${C[yellow]}" "${C[red]}"    "${C[yellow]}" "${C[reset]}"; }

# ──[ Error Trap ]─────────────────────────────────────────────────────────────
trap 'printf "\n%s Installation failed. Aborting.\n" "$(FAILED)"' ERR

# ──[ Paths ]──────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ──[ Backup Function ]────────────────────────────────────────────────────────
# Backs up a file or directory only if it exists and is not already a symlink
backup() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$target" "$BACKUP_DIR/"
    printf "%s Backed up %s\n" "$(PLUS)" "$target"
  fi
}

# ──[ Symlink Function ]───────────────────────────────────────────────────────
link() {
  local src="$1"
  local dst="$2"
  backup "$dst"
  ln -sf "$src" "$dst"
  printf "%s Linked %s\n" "$(COMPLETE)" "$dst"
}

# ──[ Installation ]───────────────────────────────────────────────────────────
printf "%s Starting Dotfiles Installation\n\n" "$(BANNER)"

printf "%s Creating Directories\n" "$(BANNER)"
mkdir -p ~/.zsh/themes
mkdir -p ~/.config/nvim
mkdir -p ~/.ssh/
printf "%s Directories ready\n\n" "$(COMPLETE)"

printf "%s Symlinking Dotfiles\n" "$(BANNER)"
link "$DOTFILES_DIR/.zshrc"                        ~/.zshrc
link "$DOTFILES_DIR/.zsh_aliases"                  ~/.zsh_aliases
link "$DOTFILES_DIR/.zsh/themes/arpatek.zsh-theme" ~/.zsh/themes/arpatek.zsh-theme
link "$DOTFILES_DIR/.tmux.conf"                    ~/.tmux.conf
link "$DOTFILES_DIR/.gitconfig"                    ~/.gitconfig
link "$DOTFILES_DIR/.vimrc"                        ~/.vimrc
link "$DOTFILES_DIR/.config/nvim/init.vim"         ~/.config/nvim/init.vim
printf "\n"

printf "%s Installing SSH Config\n" "$(BANNER)"
backup ~/.ssh/config
cp "$DOTFILES_DIR/.ssh/config" ~/.ssh/config
chmod 600 ~/.ssh/config
printf "%s SSH config installed\n\n" "$(COMPLETE)"

printf "%s Installing upu\n" "$(BANNER)"
sudo ln -sf "$DOTFILES_DIR/upu" /usr/local/bin/upu
printf "%s upu installed to /usr/local/bin/upu\n\n" "$(COMPLETE)"

printf "%s Installation Complete\n" "$(COMPLETE)"
[[ -d "$BACKUP_DIR" ]] && printf "%s Backups saved to %s\n" "$(PLUS)" "$BACKUP_DIR"
