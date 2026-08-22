#!/usr/bin/env bash
# =============================================================================
# Script Name: uninstall.sh
# Description: Cross-platform dotfiles uninstaller. Detects the OS, tears down
#              packages, tools, and symlinks via the matching os/ module, and
#              restores a clean system state.
# Author: Juan Garcia (arpatek)
# Created: 2026-05-05
# Version: 5.0
# =============================================================================

# ──[ Bash Version Check ]──────────────────────────────────────────────────────
if ((BASH_VERSINFO[0] < 4)); then
  printf "uninstall.sh requires bash 4 or higher (detected: %s)\n" "$BASH_VERSION" >&2
  exit 1
fi

# Uninstallers must be resilient — do NOT use set -e here. Individual failures
# are logged and skipped so a broken step never leaves the shell unusable
# (e.g. PATH gone after .zshrc is removed).
set -o pipefail

# ──[ Paths ]───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──[ Shared Utilities ]────────────────────────────────────────────────────────
source "$DOTFILES_DIR/lib.sh"

# ──[ Privileged Session Caching ]──────────────────────────────────────────────
cache_sudo

# ──[ OS Detection ]────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *) printf "%s Unsupported OS: %s\n" "$(FAILED)" "$(uname -s)" >&2; exit 1 ;;
esac

# ──[ Helpers ]─────────────────────────────────────────────────────────────────
ERRORS=0

warn() {
  printf "%s %s\n" "$(FAILED)" "$1" >&2
  (( ERRORS++ )) || true
}

unlink_file() {
  local target="$1"
  if [[ -L "$target" ]]; then
    rm "$target" && printf "%s Removed symlink %s\n" "$(COMPLETE)" "$target" \
      || warn "Could not remove symlink $target"
  else
    printf "%s Skipped %s (not a symlink)\n" "$(PLUS)" "$target"
  fi
}

remove_dir() {
  local target="$1"
  local label="${2:-${target/#$HOME/\~}}"
  if [[ -d "$target" ]]; then
    rm -rf "$target" && printf "%s Removed %s\n" "$(COMPLETE)" "$label" \
      || warn "Could not fully remove $label"
  else
    printf "%s Not found, skipping: %s\n" "$(PLUS)" "$label"
  fi
}

remove_file() {
  local target="$1"
  local use_sudo="${2:-false}"
  if [[ -f "$target" || -L "$target" ]]; then
    if $use_sudo; then
      sudo rm -f "$target" && printf "%s Removed %s\n" "$(COMPLETE)" "$target" \
        || warn "Could not remove $target"
    else
      rm -f "$target" && printf "%s Removed %s\n" "$(COMPLETE)" "$target" \
        || warn "Could not remove $target"
    fi
  else
    printf "%s Not found, skipping: %s\n" "$(PLUS)" "$target"
  fi
}

confirm() {
  printf "%s %s [y/N] " "$(BANNER)" "$1"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ──[ Restore Backups ]─────────────────────────────────────────────────────────
restore_backups() {
  local backup_base="$HOME/.local/share/dotfiles_backup"
  if [[ ! -d "$backup_base" ]]; then
    printf "%s No backup directory found\n" "$(PLUS)"
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
    cp -r "$file" "$HOME/" && printf "%s Restored %s\n" "$(COMPLETE)" "$(basename "$file")" \
      || warn "Could not restore $(basename "$file")"
  done
}

# ──[ OS Module ]───────────────────────────────────────────────────────────────
# Defines os_uninstall, os_uninstall_shell, and OS_UNINSTALL_SHELL.
# shellcheck source=/dev/null
source "$DOTFILES_DIR/os/$OS.sh"

# ──[ Uninstallation ]──────────────────────────────────────────────────────────
# ORDER MATTERS: tools and data first, shell config and symlinks last —
# removing shell configs early destroys PATH for the rest of the script.
printf "%s Starting Dotfiles Uninstall (%s)\n" "$(BANNER)" "$OS"
sleep 1

# ── OS-specific: packages, tools, OS binaries and symlinks ──
os_uninstall
printf "\n"

# ── Shared: plugin and data directories ──
printf "%s Removing Zsh plugins\n" "$(BANNER)"
remove_dir "$HOME/.config/zsh/plugins"
printf "\n"

printf "%s Removing tmux plugins\n" "$(BANNER)"
remove_dir "$HOME/.config/tmux/plugins"
printf "\n"

printf "%s Removing LazyVim / Neovim config\n" "$(BANNER)"
unlink_file "$HOME/.config/nvim/init.vim"
remove_dir "$HOME/.config/nvim"
remove_dir "$HOME/.local/share/nvim"
remove_dir "$HOME/.local/state/nvim"
remove_dir "$HOME/.cache/nvim"
printf "\n"

printf "%s Removing pyenv\n" "$(BANNER)"
remove_dir "$HOME/.local/share/pyenv"
printf "\n"

printf "%s Removing SSH Config\n" "$(BANNER)"
remove_file ~/.ssh/config
printf "\n"

# ── OS-specific: default shell / bash config restore ──
os_uninstall_shell
printf "\n"

# ── Shared: dotfile symlinks — last, so PATH stays intact throughout ──
printf "%s Removing Dotfile Symlinks\n" "$(BANNER)"
unlink_file ~/.vim/vimrc
unlink_file ~/.config/tmux/tmux.conf
unlink_file ~/.config/git/config
unlink_file ~/.config/git/commit-template
unlink_file ~/.config/starship.toml
unlink_file ~/.editorconfig
unlink_file ~/.config/curlrc
unlink_file ~/.config/lazygit/config.yml
unlink_file ~/.claude/statusline-command.sh
unlink_file ~/.config/zsh/.zsh_aliases
unlink_file ~/.config/zsh/.zprofile
unlink_file ~/.config/zsh/os.d
# .zshrc and .zshenv removed last — removing them earlier kills PATH
unlink_file ~/.config/zsh/.zshrc
unlink_file ~/.zshenv
remove_dir "$HOME/.config/zsh"
printf "\n"
sleep 1

# ── Backups ──
if confirm "Restore pre-install backups from ~/.local/share/dotfiles_backup?"; then
  printf "\n"; restore_backups; printf "\n"
fi

if confirm "Delete ~/.local/share/dotfiles_backup?"; then
  remove_dir "$HOME/.local/share/dotfiles_backup"
  printf "\n"
fi

if (( ERRORS > 0 )); then
  printf "%s Uninstall finished with %d warning(s) — check output above\n" \
    "$(FAILED)" "$ERRORS"
else
  printf "%s Uninstall Complete — system restored to clean state\n" "$(COMPLETE)"
fi

exec "${OS_UNINSTALL_SHELL:-bash}"
