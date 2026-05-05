#!/usr/bin/env bash
# =============================================================================
# Script Name: uninstall.sh
# Description: Dotfiles uninstaller — removes symlinks, uninstalls upu, and
#              optionally restores backups created by install.sh.
# Author: Juan Garcia (arpatek)
# Version: 1.0
# =============================================================================

# ──[ Bash Version Check ]─────────────────────────────────────────────────────
if ((BASH_VERSINFO[0] < 4)); then
  printf "uninstall.sh requires bash 4 or higher (detected: %s)\n" "$BASH_VERSION" >&2
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
trap 'printf "\n%s Uninstall failed. Aborting.\n" "$(FAILED)"' ERR

# ──[ Privileged Session Caching ]─────────────────────────────────────────────
sudo -v || exit 1
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# ──[ Remove Symlink Function ]─────────────────────────────────────────────────
unlink_file() {
  local target="$1"
  if [[ -L "$target" ]]; then
    rm "$target"
    printf "%s Removed %s\n" "$(COMPLETE)" "$target"
  else
    printf "%s Skipped %s (not a symlink)\n" "$(PLUS)" "$target"
  fi
  sleep 0.2
}

# ──[ Restore Function ]───────────────────────────────────────────────────────
restore_backups() {
  local backup_base="$HOME/.dotfiles_backup"
  if [[ ! -d "$backup_base" ]]; then
    printf "%s No backup directory found at %s\n" "$(PLUS)" "$backup_base"
    return
  fi

  local latest
  latest=$(ls -t "$backup_base" | head -1)

  if [[ -z "$latest" ]]; then
    printf "%s No backups found\n" "$(PLUS)"
    return
  fi

  printf "%s Restoring from %s/%s\n" "$(BANNER)" "$backup_base" "$latest"
  sleep 0.5
  for file in "$backup_base/$latest"/.*  "$backup_base/$latest"/*; do
    [[ -e "$file" ]] || continue
    cp -r "$file" "$HOME/"
    printf "%s Restored %s\n" "$(COMPLETE)" "$(basename "$file")"
    sleep 0.2
  done
}

# ──[ Uninstallation ]─────────────────────────────────────────────────────────
printf "%s Starting Dotfiles Uninstall\n" "$(BANNER)"
sleep 1

printf "%s Removing Symlinks\n" "$(BANNER)"
sleep 0.5
unlink_file ~/.zshrc
unlink_file ~/.zsh_aliases
unlink_file ~/.zsh/themes/arpatek.zsh-theme
unlink_file ~/.tmux.conf
unlink_file ~/.gitconfig
unlink_file ~/.vimrc
unlink_file ~/.config/nvim/init.vim
printf "\n"
sleep 1

printf "%s Removing SSH Config\n" "$(BANNER)"
sleep 0.5
if [[ -f ~/.ssh/config ]]; then
  rm ~/.ssh/config
  printf "%s SSH config removed\n\n" "$(COMPLETE)"
else
  printf "%s SSH config not found, skipping\n\n" "$(PLUS)"
fi
sleep 1

printf "%s Removing upu\n" "$(BANNER)"
sleep 0.5
if [[ -L /usr/local/bin/upu ]]; then
  sudo rm /usr/local/bin/upu
  printf "%s upu removed from /usr/local/bin\n\n" "$(COMPLETE)"
else
  printf "%s upu not found at /usr/local/bin, skipping\n\n" "$(PLUS)"
fi
sleep 1

printf "%s Restore Backups? [y/N] " "$(BANNER)"
read -r reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  printf "\n"
  restore_backups
  printf "\n"
fi

printf "%s Uninstall Complete\n" "$(COMPLETE)"
