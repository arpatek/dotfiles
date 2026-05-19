#!/usr/bin/env bash
# =============================================================================
# Script Name: uninstall.sh
# Description: Dotfiles uninstaller — removes all symlinks, installed tools,
#              and bootstrapped environments, leaving a clean system state.
# Author: Juan Garcia (arpatek)
# Created: 2026-05-05
# Version: 4.0
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
# Removing shell configs early destroys PATH for the rest of the script.
printf "%s Starting Full Dotfiles Uninstall\n" "$(BANNER)"
sleep 1

# ── dnf packages ─────────────────────────────────────────────────────────────
# Remove non-essential packages the installer bootstraps via the package manager.
# Core dev tools (git, curl, wget, gcc, make, etc.) are intentionally kept.
remove_dnf_packages() {
  command -v dnf >/dev/null 2>&1 || return 0

  local -a pkgs=(
    zsh tmux neovim btop ncdu bat fzf zoxide
    zlib-devel bzip2-devel readline-devel sqlite-devel openssl-devel
    libffi-devel xz-devel tk-devel libuuid-devel
  )

  local found=false
  for pkg in "${pkgs[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
      found=true
      printf "%s Removing %s...\n" "$(PLUS)" "$pkg"
      sudo dnf remove -y "$pkg" \
        && printf "%s Removed %s\n" "$(COMPLETE)" "$pkg" \
        || warn "Could not remove $pkg"
    else
      printf "%s Not installed, skipping: %s\n" "$(PLUS)" "$pkg"
    fi
  done

  $found || printf "%s No dnf packages to remove\n" "$(COMPLETE)"
}

printf "%s Removing dnf packages\n" "$(BANNER)"
sleep 0.5
remove_dnf_packages
printf "\n"

# ── lazygit ───────────────────────────────────────────────────────────────────
printf "%s Removing lazygit\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/lazygit true
printf "\n"

# ── yazi ──────────────────────────────────────────────────────────────────────
printf "%s Removing yazi\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/yazi true
remove_file /usr/local/bin/ya   true
printf "\n"

# ── eza ───────────────────────────────────────────────────────────────────────
# Only remove if installed to /usr/local/bin (bootstrap install on RHEL).
# On Debian/Ubuntu it lands in /usr/bin via apt — leave that alone.
printf "%s Removing eza\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/eza true
printf "\n"

# ── bat ───────────────────────────────────────────────────────────────────────
# On Debian/Ubuntu, bootstrap_bat symlinks batcat → ~/.local/bin/bat.
printf "%s Removing bat symlink\n" "$(BANNER)"
sleep 0.5
remove_file "$HOME/.local/bin/bat"
printf "\n"

# ── fzf ───────────────────────────────────────────────────────────────────────
printf "%s Removing fzf\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/fzf true
printf "\n"

# ── zoxide ────────────────────────────────────────────────────────────────────
printf "%s Removing zoxide\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/zoxide true
printf "\n"

# ── starship ──────────────────────────────────────────────────────────────────
printf "%s Removing starship\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/starship true
printf "\n"

# ── zsh plugins ───────────────────────────────────────────────────────────────
printf "%s Removing Zsh plugins\n" "$(BANNER)"
sleep 0.5
remove_dir "$HOME/.config/zsh/plugins" "~/.config/zsh/plugins"
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

# ── Fonts ─────────────────────────────────────────────────────────────────────
# Fonts are left in place — removing them while Ghostty is running triggers a
# fontconfig SIGSEGV. Keeping the font is harmless and avoids the crash.
printf "%s Keeping JetBrains Mono Nerd Font (safe to remove manually later)\n" "$(PLUS)"
printf "\n"

# ── lpu / ipkg ────────────────────────────────────────────────────────────────
printf "%s Removing lpu and ipkg\n" "$(BANNER)"
sleep 0.5
remove_file /usr/local/bin/lpu true
remove_file /usr/local/bin/ipkg true
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
unlink_file ~/.vim/vimrc
unlink_file ~/.config/tmux/tmux.conf
unlink_file ~/.config/git/config
unlink_file ~/.config/git/commit-template
unlink_file ~/.config/starship.toml
unlink_file ~/.editorconfig
unlink_file ~/.config/curlrc
unlink_file ~/.config/lazygit/config.yml
unlink_file ~/.config/zsh/.zsh_aliases
unlink_file ~/.config/zsh/.zprofile
# .zshrc and .zshenv removed last — removing them earlier kills PATH
unlink_file ~/.config/zsh/.zshrc
unlink_file ~/.zshenv
remove_dir "$HOME/.config/zsh" "~/.config/zsh"
printf "\n"
sleep 1

# ── Bash Configs ─────────────────────────────────────────────────────────────
# Always restore bash configs removed by cleanup_bash_configs during install
printf "%s Restoring bash config files\n" "$(BANNER)"
sleep 0.5
local_backup=$(ls -t "$HOME/.dotfiles_backup" 2>/dev/null | head -1)
if [[ -n "$local_backup" ]]; then
  for f in .bashrc .bash_profile .bash_login .bash_logout .bash_aliases .bash_history; do
    src="$HOME/.dotfiles_backup/$local_backup/$f"
    if [[ -f "$src" ]]; then
      cp "$src" "$HOME/$f" && printf "%s Restored ~/%s\n" "$(COMPLETE)" "$f" \
        || warn "Could not restore $f"
    fi
  done
else
  printf "%s No backup found — bash configs could not be restored\n" "$(PLUS)"
fi
printf "\n"

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

exec bash
