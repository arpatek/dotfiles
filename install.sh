#!/usr/bin/env bash
# =============================================================================
# Script Name: install.sh
# Description: Cross-platform dotfiles installer. Detects the OS, bootstraps
#              packages and tools via the matching os/ module, backs up
#              existing configs, and symlinks dotfiles into place.
# Author: Juan Garcia (arpatek)
# Created: 2026-05-05
# Version: 5.0
# =============================================================================

# ──[ Bash Bootstrap ]──────────────────────────────────────────────────────────
# macOS ships bash 3.2 which lacks associative arrays (declare -A) required by
# the OS modules. Re-exec with Homebrew bash 4+ if present; install it if not.
# On Linux bash is already 4+, so this block never runs there.
if ((BASH_VERSINFO[0] < 4)); then
  for _b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x "$_b" ]] && exec "$_b" "$0" "$@"
  done

  printf "bash 3.x detected — installing Homebrew and bash 4+...\n"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  brew install bash

  for _b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x "$_b" ]] && exec "$_b" "$0" "$@"
  done

  printf "install.sh: could not upgrade bash — install manually: brew install bash\n" >&2
  exit 1
fi

set -eo pipefail

# ──[ Paths ]───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.local/share/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ──[ Shared Utilities ]────────────────────────────────────────────────────────
source "$DOTFILES_DIR/lib.sh"

# ──[ Error Trap ]──────────────────────────────────────────────────────────────
trap 'printf "\n%s Installation failed. Aborting.\n" "$(FAILED)"' ERR

# ──[ OS Detection ]────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *) printf "%s Unsupported OS: %s\n" "$(FAILED)" "$(uname -s)" >&2; exit 1 ;;
esac

# ──[ Argument Parsing ]────────────────────────────────────────────────────────
SKIP_PACKAGES=false
UPDATE=false

usage() {
  printf "Usage: install.sh [OPTIONS]\n"
  printf "Options:\n"
  printf "  -h, --help            Show this help message\n"
  printf "  --skip-packages       Skip package bootstrap (symlinks only)\n"
  printf "  --update              Re-fetch bootstrapped tools from upstream (Linux)\n"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help) usage; exit 0 ;;
  --skip-packages) SKIP_PACKAGES=true ;;
  --update)        UPDATE=true ;;
  *) printf "Unknown option: %s\n" "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# ──[ Privileged Session Caching ]──────────────────────────────────────────────
cache_sudo

# ──[ Backup Function ]─────────────────────────────────────────────────────────
backup() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$target" "$BACKUP_DIR/"
    printf "%s Backed up %s\n" "$(PLUS)" "$target"
  fi
}

# ──[ Symlink Function ]────────────────────────────────────────────────────────
link() {
  local src="$1"
  local dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    printf "%s Already linked %s\n" "$(COMPLETE)" "$dst"
    return
  fi
  backup "$dst"
  ln -sf "$src" "$dst"
  printf "%s Linked %s\n" "$(COMPLETE)" "$dst"
}

# ──[ OS Module ]───────────────────────────────────────────────────────────────
# Defines os_bootstrap, os_link, os_post for the detected platform.
# shellcheck source=/dev/null
source "$DOTFILES_DIR/os/$OS.sh"

# ──[ Shared: Zsh Plugins ]─────────────────────────────────────────────────────
bootstrap_zsh_plugins() {
  local plugins_dir="$HOME/.config/zsh/plugins"
  mkdir -p "$plugins_dir"

  declare -A PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-completions]="https://github.com/zsh-users/zsh-completions"
    [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search"
    [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
  )

  local plugin
  for plugin in "${!PLUGINS[@]}"; do
    if [[ -d "${plugins_dir}/${plugin}" ]]; then
      if $UPDATE; then
        printf "%s Updating %s...\n" "$(PLUS)" "$plugin"
        git -C "${plugins_dir}/${plugin}" pull --ff-only
        printf "%s %s updated\n" "$(COMPLETE)" "$plugin"
      else
        printf "%s %s already installed\n" "$(COMPLETE)" "$plugin"
      fi
    else
      printf "%s Installing %s...\n" "$(PLUS)" "$plugin"
      git clone --depth 1 "${PLUGINS[$plugin]}" "${plugins_dir}/${plugin}"
      printf "%s %s installed\n" "$(COMPLETE)" "$plugin"
    fi
  done
}

# ──[ Shared: tmux Plugins ]────────────────────────────────────────────────────
# tmux.conf ends with `run ~/.config/tmux/plugins/tokyo-night-tmux/...`. Without
# the clone that line silently fails and the status bar falls back to default.
bootstrap_tmux_plugins() {
  local plugins_dir="$HOME/.config/tmux/plugins"
  mkdir -p "$plugins_dir"

  declare -A TMUX_PLUGINS=(
    [tokyo-night-tmux]="https://github.com/janoamaral/tokyo-night-tmux"
  )

  local plugin
  for plugin in "${!TMUX_PLUGINS[@]}"; do
    if [[ -d "${plugins_dir}/${plugin}" ]]; then
      if $UPDATE; then
        printf "%s Updating %s...\n" "$(PLUS)" "$plugin"
        git -C "${plugins_dir}/${plugin}" pull --ff-only
        printf "%s %s updated\n" "$(COMPLETE)" "$plugin"
      else
        printf "%s %s already installed\n" "$(COMPLETE)" "$plugin"
      fi
    else
      printf "%s Installing %s...\n" "$(PLUS)" "$plugin"
      git clone --depth 1 "${TMUX_PLUGINS[$plugin]}" "${plugins_dir}/${plugin}"
      printf "%s %s installed\n" "$(COMPLETE)" "$plugin"
    fi
  done
}

# ──[ Shared: LazyVim ]─────────────────────────────────────────────────────────
setup_lazyvim() {
  # init.vim is the zero-dependency fallback for nvim on any system where
  # LazyVim cannot be used (old nvim, no network, containers, etc.)
  local init_vim_src="$DOTFILES_DIR/.config/nvim/init.vim"
  local nvim_config_dir="$HOME/.config/nvim"

  if ! command -v nvim >/dev/null 2>&1; then
    printf "%s nvim not found — skipping\n" "$(PLUS)"
    return
  fi

  local nvim_ver nvim_minor nvim_patch
  nvim_ver=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  nvim_minor=$(printf "%s" "$nvim_ver" | cut -d. -f2)
  nvim_patch=$(printf "%s" "$nvim_ver" | cut -d. -f3)

  # LazyVim requires nvim >= 0.11.2
  if (( nvim_minor < 11 || ( nvim_minor == 11 && nvim_patch < 2 ) )); then
    printf "%s nvim %s < 0.11.2 — linking init.vim fallback\n" "$(PLUS)" "$nvim_ver"
    mkdir -p "$nvim_config_dir"
    link "$init_vim_src" "$nvim_config_dir/init.vim"
    return
  fi

  if [[ -d "$nvim_config_dir" && -n "$(ls -A "$nvim_config_dir" 2>/dev/null)" ]]; then
    printf "%s ~/.config/nvim already populated — skipping LazyVim install\n" "$(PLUS)"
    return
  fi

  printf "%s Installing LazyVim starter...\n" "$(PLUS)"
  if git clone --depth 1 https://github.com/LazyVim/starter "$nvim_config_dir" 2>/dev/null; then
    rm -rf "$nvim_config_dir/.git"
    printf "%s LazyVim installed — open nvim to complete plugin setup\n" "$(COMPLETE)"
  else
    printf "%s LazyVim clone failed (no network?) — linking init.vim fallback\n" "$(PLUS)"
    mkdir -p "$nvim_config_dir"
    link "$init_vim_src" "$nvim_config_dir/init.vim"
  fi
}

# ──[ Installation ]────────────────────────────────────────────────────────────
printf "%s Starting Dotfiles Installation (%s)\n" "$(BANNER)" "$OS"
sleep 1

if ! $SKIP_PACKAGES; then
  printf "%s Bootstrapping Dependencies\n" "$(BANNER)"
  sleep 0.5
  os_bootstrap
  bootstrap_zsh_plugins
  bootstrap_tmux_plugins
  printf "\n"
fi

printf "%s Creating Directories\n" "$(BANNER)"
sleep 0.5
mkdir -p "$HOME"/.config/{zsh,git,tmux,lazygit,fastfetch,ghostty,kube,npm}
mkdir -p "$HOME"/.cache/{kube,npm}
mkdir -p "$HOME/.vim" "$HOME/.ssh" "$HOME/.claude"
printf "%s Directories ready\n\n" "$(COMPLETE)"

printf "%s Symlinking Dotfiles\n" "$(BANNER)"
sleep 0.5
link "$DOTFILES_DIR/.zshenv"                         "$HOME/.zshenv"
link "$DOTFILES_DIR/.config/zsh/.zshrc"              "$HOME/.config/zsh/.zshrc"
link "$DOTFILES_DIR/.config/zsh/.zprofile"           "$HOME/.config/zsh/.zprofile"
link "$DOTFILES_DIR/.config/zsh/.zsh_aliases"        "$HOME/.config/zsh/.zsh_aliases"
link "$DOTFILES_DIR/.config/zsh/os.d"                "$HOME/.config/zsh/os.d"
link "$DOTFILES_DIR/.config/git/config"              "$HOME/.config/git/config"
link "$DOTFILES_DIR/.config/git/commit-template"     "$HOME/.config/git/commit-template"
link "$DOTFILES_DIR/.config/vim/vimrc"               "$HOME/.vim/vimrc"
link "$DOTFILES_DIR/.config/tmux/tmux.conf"          "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES_DIR/.config/starship.toml"           "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/.editorconfig"                   "$HOME/.editorconfig"
link "$DOTFILES_DIR/.config/curlrc"                  "$HOME/.config/curlrc"
link "$DOTFILES_DIR/.config/lazygit/config.yml"      "$HOME/.config/lazygit/config.yml"
# fastfetch reads config.jsonc by name, so the variant is chosen at link time
# rather than through a wrapper — bare `fastfetch` then does the right thing.
if is_headless; then
  link "$DOTFILES_DIR/.config/fastfetch/config-headless.jsonc" "$HOME/.config/fastfetch/config.jsonc"
else
  link "$DOTFILES_DIR/.config/fastfetch/config.jsonc"          "$HOME/.config/fastfetch/config.jsonc"
fi
link "$DOTFILES_DIR/.config/ghostty/config"          "$HOME/.config/ghostty/config"
link "$DOTFILES_DIR/.claude/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
printf "\n"

setup_lazyvim
printf "\n"

printf "%s Installing OS-specific Configs\n" "$(BANNER)"
sleep 0.5
os_link
printf "\n"

printf "%s Installing SSH Config\n" "$(BANNER)"
sleep 0.5
cp "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
printf "%s SSH config installed\n\n" "$(COMPLETE)"

os_post
printf "\n"

printf "%s Installation Complete\n" "$(COMPLETE)"
[[ -d "$BACKUP_DIR" ]] && printf "%s Backups saved to %s\n" "$(PLUS)" "$BACKUP_DIR"
printf "%s Deployment complete. Entering the shell.\n" "$(LAMBDA)"
exec zsh
