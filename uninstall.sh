#!/usr/bin/env bash
# =============================================================================
# Script Name: uninstall.sh
# Description: Dotfiles uninstaller — removes all symlinks, installed tools,
#              and bootstrapped environments, leaving a clean system state.
# Author: Juan Garcia (arpatek)
# Created: 2026-05-05
# Version: 3.0
# =============================================================================

# ──[ Bash Version Check ]──────────────────────────────────────────────────────
if ((BASH_VERSINFO[0] < 4)); then
  printf "uninstall.sh requires bash 4 or higher (detected: %s)\n" "$BASH_VERSION" >&2
  exit 1
fi

# Uninstallers must be resilient — do NOT use set -e here.
# Individual failures are logged and skipped so a broken step never leaves
# the shell in an unusable state (e.g. PATH gone after .zshrc is removed).
set -o pipefail

# ──[ Paths ]───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──[ Shared Utilities ]────────────────────────────────────────────────────────
source "$DOTFILES_DIR/lib.sh"

# ──[ Privileged Session Caching ]──────────────────────────────────────────────
cache_sudo

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
  local label="${2:-$target}"
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
  local backup_base="$HOME/.dotfiles_backup"
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

# ──[ Uninstallation ]──────────────────────────────────────────────────────────
# ORDER MATTERS: tools and data first, shell config and symlinks last.
# Removing .zshrc early destroys PATH for the rest of the script.
printf "%s Starting Full Dotfiles Uninstall\n" "$(BANNER)"
sleep 1

# ── lazygit ───────────────────────────────────────────────────────────────────
printf "%s Removing lazygit\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/lazygit true
printf "\n"

# ── Go ────────────────────────────────────────────────────────────────────────
printf "%s Removing Go\n" "$(BANNER)"
sleep 0.5
# The module cache sets files read-only — go clean -modcache handles this;
# plain rm -rf will fail with "Permission denied" on every cached module file
if command -v go >/dev/null 2>&1 && [[ -d "$HOME/go/pkg/mod" ]]; then
  printf "%s Cleaning Go module cache...\n" "$(PLUS)"
  go clean -modcache || warn "go clean -modcache failed"
fi
if [[ -d /usr/local/go ]]; then
  sudo rm -rf /usr/local/go && printf "%s Removed /usr/local/go\n" "$(COMPLETE)" \
    || warn "Could not remove /usr/local/go"
else
  printf "%s /usr/local/go not found, skipping\n" "$(PLUS)"
fi
remove_dir "$HOME/go" "~/go (GOPATH)"
printf "\n"

# ── LazyVim / Neovim config ───────────────────────────────────────────────────
printf "%s Removing LazyVim / Neovim config\n" "$(BANNER)"
sleep 0.5
unlink_file "$HOME/.config/nvim/init.vim"
remove_dir "$HOME/.config/nvim"      "~/.config/nvim"
remove_dir "$HOME/.local/share/nvim" "~/.local/share/nvim (plugin data)"
remove_dir "$HOME/.local/state/nvim" "~/.local/state/nvim"
remove_dir "$HOME/.cache/nvim"       "~/.cache/nvim"
printf "\n"

# ── pyenv ─────────────────────────────────────────────────────────────────────
printf "%s Removing pyenv\n" "$(BANNER)"
sleep 0.5
remove_dir "$HOME/.pyenv" "~/.pyenv"
printf "\n"

# ── zinit ─────────────────────────────────────────────────────────────────────
printf "%s Removing zinit\n" "$(BANNER)"
sleep 0.5
remove_dir "$HOME/.local/share/zinit" "~/.local/share/zinit"
printf "\n"

# ── Fonts ─────────────────────────────────────────────────────────────────────
printf "%s Removing JetBrains Mono Nerd Font\n" "$(BANNER)"
sleep 0.5
remove_dir "$HOME/.local/share/fonts/JetBrainsMono" "~/.local/share/fonts/JetBrainsMono"
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f && printf "%s Font cache refreshed\n" "$(COMPLETE)" \
    || warn "fc-cache failed"
fi
printf "\n"

# ── upu ───────────────────────────────────────────────────────────────────────
printf "%s Removing upu\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/upu true
printf "\n"

# ── SSH Config ────────────────────────────────────────────────────────────────
printf "%s Removing SSH Config\n" "$(BANNER)"
sleep 0.5
remove_file ~/.ssh/config
printf "\n"

# ── Default shell — revert before dotfiles are removed ───────────────────────
printf "%s Reverting default shell to bash\n" "$(BANNER)"
sleep 0.5
BASH_BIN="$(command -v bash 2>/dev/null || true)"
if [[ -n "$BASH_BIN" && "$SHELL" != "$BASH_BIN" ]]; then
  sudo chsh -s "$BASH_BIN" "$USER" \
    && printf "%s Default shell reverted to %s\n\n" "$(COMPLETE)" "$BASH_BIN" \
    || warn "chsh failed — revert shell manually: sudo chsh -s $BASH_BIN $USER"
else
  printf "%s Shell already bash or bash not found, skipping\n\n" "$(PLUS)"
fi

# ── Dotfile symlinks — last, so PATH stays intact throughout ─────────────────
printf "%s Removing Dotfile Symlinks\n" "$(BANNER)"
sleep 0.5
unlink_file ~/.zsh/themes/arpatek.zsh-theme
unlink_file ~/.tmux.conf
unlink_file ~/.gitconfig
unlink_file ~/.vimrc
unlink_file ~/.git-commit-template
unlink_file ~/.editorconfig
unlink_file ~/.curlrc
unlink_file ~/.config/lazygit/config.yml
unlink_file ~/.zsh_aliases
unlink_file ~/.zprofile
# .zshrc removed absolutely last — removing it earlier kills PATH in the
# current shell session and makes every subsequent command fail
unlink_file ~/.zshrc
remove_dir "$HOME/.zsh" "~/.zsh"
printf "\n"
sleep 1

# ── Backups ───────────────────────────────────────────────────────────────────
if confirm "Restore pre-install backups from ~/.dotfiles_backup?"; then
  printf "\n"
  restore_backups
  printf "\n"
fi

if confirm "Delete ~/.dotfiles_backup?"; then
  remove_dir "$HOME/.dotfiles_backup" "~/.dotfiles_backup"
  printf "\n"
fi

if (( ERRORS > 0 )); then
  printf "%s Uninstall finished with %d warning(s) — check output above\n" \
    "$(FAILED)" "$ERRORS"
else
  printf "%s Uninstall Complete — system restored to clean state\n" "$(COMPLETE)"
fi
