#!/usr/bin/env bash
# =============================================================================
# Script Name: install.sh
# Description: Dotfiles installer — optionally bootstraps required packages,
#              backs up existing configs, and symlinks dotfiles into place.
# Author: Juan Garcia (arpatek)
# Created: 2026-05-05
# Version: 2.0
# =============================================================================

# ──[ Bash Version Check ]──────────────────────────────────────────────────────
if ((BASH_VERSINFO[0] < 4)); then
  printf "install.sh requires bash 4 or higher (detected: %s)\n" "$BASH_VERSION" >&2
  exit 1
fi

set -eo pipefail

# ──[ Paths ]───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ──[ Shared Utilities ]────────────────────────────────────────────────────────
source "$DOTFILES_DIR/lib.sh"

# ──[ Error Trap ]──────────────────────────────────────────────────────────────
trap 'printf "\n%s Installation failed. Aborting.\n" "$(FAILED)"' ERR

# ──[ Argument Parsing ]────────────────────────────────────────────────────────
SKIP_PACKAGES=false

usage() {
  printf "Usage: install.sh [OPTIONS]\n"
  printf "Options:\n"
  printf "  -h, --help            Show this help message\n"
  printf "  --skip-packages       Skip package bootstrap (symlinks only)\n"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  --skip-packages) SKIP_PACKAGES=true ;;
  *)
    printf "Unknown option: %s\n" "$1" >&2
    usage >&2
    exit 1
    ;;
  esac
  shift
done

# ──[ Privileged Session Caching ]──────────────────────────────────────────────
# Ask for the sudo password upfront before any output scrolls past — the user
# only sees one prompt at the very start of the run.
cache_sudo

# ──[ Backup Function ]─────────────────────────────────────────────────────────
# Backs up a file or directory only if it exists and is not already a symlink
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
  backup "$dst"
  ln -sf "$src" "$dst"
  printf "%s Linked %s\n" "$(COMPLETE)" "$dst"
}

bootstrap_epel() {
  command -v dnf >/dev/null 2>&1 || return 0

  if dnf repolist enabled 2>/dev/null | grep -qi "epel"; then
    printf "%s EPEL already enabled\n" "$(COMPLETE)"
    return
  fi

  printf "%s Enabling EPEL...\n" "$(PLUS)"

  local rhel_ver
  rhel_ver=$(rpm -E %rhel 2>/dev/null)

  # On actual RHEL, epel-release is not in the default repos — install from the
  # Fedora EPEL URL. On CentOS/AlmaLinux/Rocky it is available as a package.
  if grep -qi "red hat enterprise" /etc/redhat-release 2>/dev/null; then
    sudo dnf install -y \
      "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhel_ver}.noarch.rpm"
  else
    sudo dnf install -y epel-release
  fi

  printf "%s EPEL enabled\n" "$(COMPLETE)"
}

# ──[ Package Bootstrap ]───────────────────────────────────────────────────────
bootstrap_packages() {
  local pm=""
  for candidate in nala apt dnf pacman yum zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      pm="$candidate"
      break
    fi
  done

  if [[ -z "$pm" ]]; then
    printf "%s No supported package manager found — skipping package install\n" "$(PLUS)"
    return
  fi

  printf "%s Detected package manager: %s\n" "$(PLUS)" "$pm"
  sleep 0.5

  # ── Core tools ────────────────────────────────────────────────────────────
  # Each entry: [package-key]="binary-to-check"
  # The binary check prevents re-installing already-present tools.
  declare -A TOOLS=(
    [zsh]="zsh"           [git]="git"
    [tmux]="tmux"         [neovim]="nvim"
    [curl]="curl"         [wget]="wget"
    [btop]="btop"
    [ncdu]="ncdu"         [asciinema]="asciinema"
    [lynx]="lynx"         [unzip]="unzip"
    [fontconfig]="fc-cache" [gcc]="gcc"
    [make]="make"
  )

  # ── Python build dependencies (pyenv compiles CPython from source) ─────────
  # These are not checked by binary — they're libraries, not commands.
  # Grouped separately so they can be installed as a batch without binary checks.
  declare -A PYTHON_DEPS_DNF=(
    [0]="zlib-devel"       [1]="bzip2-devel"     [2]="readline-devel"
    [3]="sqlite-devel"     [4]="openssl-devel"   [5]="libffi-devel"
    [6]="xz-devel"         [7]="tk-devel"        [8]="libuuid-devel"
  )
  declare -A PYTHON_DEPS_APT=(
    [0]="build-essential"   [1]="libssl-dev"     [2]="zlib1g-dev"
    [3]="libbz2-dev"        [4]="libreadline-dev" [5]="libsqlite3-dev"
    [6]="libncursesw5-dev"  [7]="xz-utils"       [8]="tk-dev"
    [9]="libxml2-dev"       [10]="libxmlsec1-dev" [11]="libffi-dev"
    [12]="liblzma-dev"
  )
  declare -A PYTHON_DEPS_PACMAN=(
    [0]="base-devel" [1]="openssl" [2]="zlib" [3]="xz" [4]="tk"
  )

  # ── Collect missing core tools ─────────────────────────────────────────────
  local missing=()
  for tool in "${!TOOLS[@]}"; do
    if ! command -v "${TOOLS[$tool]}" >/dev/null 2>&1; then
      missing+=("$tool")
      printf "%s Missing: %s\n" "$(PLUS)" "$tool"
    else
      printf "%s Found:   %s\n" "$(COMPLETE)" "$tool"
    fi
  done

  # ── Install missing core tools ─────────────────────────────────────────────
  if (( ${#missing[@]} > 0 )); then
    printf "\n%s Installing %d missing package(s)...\n" "$(BANNER)" "${#missing[@]}"
    sleep 0.5
    # Install one at a time so a package absent from the repos skips gracefully
    # rather than aborting the entire run (e.g. yazi on Debian/Ubuntu).
    for pkg in "${missing[@]}"; do
      case "$pm" in
        nala)        sudo nala install -y "$pkg"          || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        apt)         sudo apt install -y  "$pkg"          || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        dnf | yum)   sudo "$pm" install -y "$pkg"        || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        pacman)      sudo pacman -S --noconfirm "$pkg"   || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        zypper)      sudo zypper install -y "$pkg"       || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        apk)         sudo apk add "$pkg"                 || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
      esac
    done
    printf "%s Core packages installed\n" "$(COMPLETE)"
  else
    printf "%s All core packages already present\n" "$(COMPLETE)"
  fi

  # ── Install Python build dependencies ────────────────────────────────────
  printf "\n%s Installing Python build dependencies\n" "$(BANNER)"
  sleep 0.5
  case "$pm" in
    nala | apt)
      sudo apt install -y "${PYTHON_DEPS_APT[@]}"
      ;;
    dnf | yum)
      sudo "$pm" install -y "${PYTHON_DEPS_DNF[@]}"
      ;;
    pacman)
      sudo pacman -S --noconfirm "${PYTHON_DEPS_PACMAN[@]}"
      ;;
  esac
  printf "%s Python build dependencies installed\n" "$(COMPLETE)"
  printf "\n"
}

bootstrap_pyenv() {
  if command -v pyenv >/dev/null 2>&1 || [[ -d "$HOME/.pyenv" ]]; then
    printf "%s pyenv already installed\n" "$(COMPLETE)"
    return
  fi
  printf "%s Installing pyenv...\n" "$(PLUS)"
  curl -fsSL https://pyenv.run | bash
  printf "%s pyenv installed\n" "$(COMPLETE)"
}

bootstrap_zinit() {
  if [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    printf "%s zinit already installed\n" "$(COMPLETE)"
    return
  fi
  printf "%s Installing zinit...\n" "$(PLUS)"
  # NO_INPUT=1 suppresses the post-install prompt about annexes — they are
  # already declared in .zshrc so there is nothing extra to set up
  NO_INPUT=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  printf "%s zinit installed\n" "$(COMPLETE)"
}

bootstrap_fonts() {
  # Linux: fontconfig must be present for font discovery
  if ! command -v fc-cache >/dev/null 2>&1; then
    printf "%s fontconfig not found — skipping font install\n" "$(PLUS)"
    return
  fi

  if fc-list | grep -qi "JetBrainsMono"; then
    printf "%s JetBrains Mono Nerd Font already installed\n" "$(COMPLETE)"
    return
  fi

  printf "%s Installing JetBrains Mono Nerd Font...\n" "$(PLUS)"
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  mkdir -p "$font_dir"
  curl -fsSL \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
    -o "$tmp_dir/JetBrainsMono.tar.xz"
  tar -xf "$tmp_dir/JetBrainsMono.tar.xz" -C "$font_dir"
  fc-cache -f "$font_dir"
  printf "%s JetBrains Mono Nerd Font installed\n" "$(COMPLETE)"
}

bootstrap_go() {
  if command -v go >/dev/null 2>&1; then
    printf "%s Go already installed: %s\n" "$(COMPLETE)" "$(go version)"
    return
  fi

  local arch
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) printf "%s Unsupported architecture for Go: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing Go...\n" "$(PLUS)"
  local go_version tmp_dir
  # grep -oP (Perl regex) is not reliable on all Debian builds — use basic grep
  # || true prevents a failed parse from aborting the script via set -eo pipefail
  go_version=$(curl -fsSL "https://go.dev/dl/?mode=json" \
    | grep '"version"' | grep -o 'go[0-9][^"]*' | head -1 | tr -d '\r') || true

  if [[ -z "$go_version" ]]; then
    printf "%s Could not determine latest Go version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL "https://go.dev/dl/${go_version}.linux-${arch}.tar.gz" \
    -o "$tmp_dir/go.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$tmp_dir/go.tar.gz"
  printf "%s Go %s installed to /usr/local/go\n" "$(COMPLETE)" "$go_version"
}

bootstrap_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    printf "%s lazygit already installed\n" "$(COMPLETE)"
    return
  fi

  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="arm64" ;;
    *) printf "%s Unsupported architecture for lazygit: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing lazygit...\n" "$(PLUS)"
  local lg_tag lg_ver tmp_dir
  lg_tag=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true
  lg_ver="${lg_tag#v}"

  if [[ -z "$lg_tag" ]]; then
    printf "%s Could not determine latest lazygit version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/jesseduffield/lazygit/releases/download/${lg_tag}/lazygit_${lg_ver}_Linux_${arch}.tar.gz" \
    -o "$tmp_dir/lazygit.tar.gz"
  tar -xf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit
  sudo install "$tmp_dir/lazygit" -D -t /usr/local/bin/
  printf "%s lazygit %s installed\n" "$(COMPLETE)" "$lg_ver"
}

bootstrap_lazyvim() {
  # init.vim is the zero-dependency fallback for nvim on any system where
  # LazyVim cannot be used (old nvim, no network, containers, etc.)
  local init_vim_src="$DOTFILES_DIR/.config/nvim/init.vim"
  local nvim_config_dir="$HOME/.config/nvim"

  if ! command -v nvim >/dev/null 2>&1; then
    printf "%s nvim not found — skipping\n" "$(PLUS)"
    return
  fi

  local nvim_ver nvim_minor
  nvim_ver=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  nvim_minor=${nvim_ver##*.}

  # Fall back to init.vim for nvim < 0.9 or when no network is available
  if (( ${nvim_ver%%.*} == 0 && nvim_minor < 9 )); then
    printf "%s nvim %s < 0.9 — linking init.vim fallback\n" "$(PLUS)" "$nvim_ver"
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

bootstrap_bat() {
  if command -v bat >/dev/null 2>&1; then
    printf "%s bat already installed\n" "$(COMPLETE)"
    return
  fi

  # Debian/Ubuntu install bat as batcat to avoid a conflict with an unrelated
  # system package — if it's already present just wire up the symlink.
  if command -v batcat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    printf "%s bat symlinked from batcat\n" "$(COMPLETE)"
    return
  fi

  local pm=""
  for candidate in nala apt dnf pacman yum zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      pm="$candidate"
      break
    fi
  done

  printf "%s Installing bat...\n" "$(PLUS)"
  case "$pm" in
    nala | apt)  sudo "$pm" install -y bat ;;
    dnf | yum)   sudo "$pm" install -y bat ;;
    pacman)      sudo pacman -S --noconfirm bat ;;
    zypper)      sudo zypper install -y bat ;;
    apk)         sudo apk add bat ;;
    *)
      printf "%s No supported package manager — skipping bat\n" "$(PLUS)"
      return
      ;;
  esac

  # After install on Debian/Ubuntu the binary lands as batcat
  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    printf "%s bat symlinked from batcat\n" "$(COMPLETE)"
  else
    printf "%s bat installed\n" "$(COMPLETE)"
  fi
}

bootstrap_yazi() {
  if command -v yazi >/dev/null 2>&1; then
    printf "%s yazi already installed\n" "$(COMPLETE)"
    return
  fi

  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="aarch64" ;;
    *) printf "%s Unsupported architecture for yazi: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing yazi...\n" "$(PLUS)"
  local yazi_tag tmp_dir
  yazi_tag=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$yazi_tag" ]]; then
    printf "%s Could not determine latest yazi version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/sxyazi/yazi/releases/download/${yazi_tag}/yazi-${arch}-unknown-linux-gnu.zip" \
    -o "$tmp_dir/yazi.zip"
  unzip -q "$tmp_dir/yazi.zip" -d "$tmp_dir"
  sudo install "$tmp_dir/yazi-${arch}-unknown-linux-gnu/yazi" -D -t /usr/local/bin/
  sudo install "$tmp_dir/yazi-${arch}-unknown-linux-gnu/ya"   -D -t /usr/local/bin/
  printf "%s yazi %s installed\n" "$(COMPLETE)" "$yazi_tag"
}

bootstrap_eza() {
  if command -v eza >/dev/null 2>&1; then
    printf "%s eza already installed\n" "$(COMPLETE)"
    return
  fi

  local pm=""
  for candidate in nala apt dnf pacman yum zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      pm="$candidate"
      break
    fi
  done

  # Try package manager first — eza is in repos on Debian/Ubuntu and Arch
  case "$pm" in
    nala | apt) sudo "$pm" install -y eza 2>/dev/null && command -v eza >/dev/null 2>&1 && { printf "%s eza installed\n" "$(COMPLETE)"; return; } ;;
    pacman)     sudo pacman -S --noconfirm eza 2>/dev/null && command -v eza >/dev/null 2>&1 && { printf "%s eza installed\n" "$(COMPLETE)"; return; } ;;
  esac

  # Fall back to GitHub releases (RHEL, and any other distro without eza in repos)
  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="aarch64" ;;
    *) printf "%s Unsupported architecture for eza: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing eza...\n" "$(PLUS)"
  local eza_tag tmp_dir
  eza_tag=$(curl -fsSL "https://api.github.com/repos/eza-community/eza/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$eza_tag" ]]; then
    printf "%s Could not determine latest eza version\n" "$(FAILED)" >&2
    return 1
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/eza-community/eza/releases/download/${eza_tag}/eza_${arch}-unknown-linux-gnu.tar.gz" \
    -o "$tmp_dir/eza.tar.gz"
  tar -xf "$tmp_dir/eza.tar.gz" -C "$tmp_dir"
  sudo install "$tmp_dir/eza" -D -t /usr/local/bin/
  printf "%s eza %s installed\n" "$(COMPLETE)" "$eza_tag"
}

# ──[ Installation ]────────────────────────────────────────────────────────────
printf "%s Starting Dotfiles Installation\n" "$(BANNER)"
sleep 1

if ! $SKIP_PACKAGES; then
  printf "%s Bootstrapping Dependencies\n" "$(BANNER)"
  sleep 0.5
  bootstrap_epel
  bootstrap_packages
  bootstrap_go
  bootstrap_lazygit
  bootstrap_bat
  bootstrap_yazi
  bootstrap_eza
  bootstrap_pyenv
  bootstrap_zinit
  bootstrap_fonts
  bootstrap_lazyvim
  printf "\n"
fi

printf "%s Creating Directories\n" "$(BANNER)"
sleep 0.5
mkdir -p ~/.zsh/themes
mkdir -p ~/.config/lazygit
mkdir -p ~/.ssh/
printf "%s Directories ready\n\n" "$(COMPLETE)"
sleep 1

printf "%s Symlinking Dotfiles\n" "$(BANNER)"
sleep 0.5
link "$DOTFILES_DIR/.zshrc"                              ~/.zshrc
sleep 0.2
link "$DOTFILES_DIR/.zsh_aliases"                        ~/.zsh_aliases
sleep 0.2
link "$DOTFILES_DIR/.zsh/themes/arpatek.zsh-theme"       ~/.zsh/themes/arpatek.zsh-theme
sleep 0.2
link "$DOTFILES_DIR/.tmux.conf"                          ~/.tmux.conf
sleep 0.2
link "$DOTFILES_DIR/.gitconfig"                          ~/.gitconfig
sleep 0.2
link "$DOTFILES_DIR/.vimrc"                              ~/.vimrc
sleep 0.2
link "$DOTFILES_DIR/.git-commit-template"                ~/.git-commit-template
sleep 0.2
link "$DOTFILES_DIR/.zprofile"                           ~/.zprofile
sleep 0.2
link "$DOTFILES_DIR/.editorconfig"                       ~/.editorconfig
sleep 0.2
link "$DOTFILES_DIR/.curlrc"                             ~/.curlrc
sleep 0.2
link "$DOTFILES_DIR/.config/lazygit/config.yml"          ~/.config/lazygit/config.yml
printf "\n"
sleep 1

printf "%s Installing SSH Config\n" "$(BANNER)"
sleep 0.5
backup ~/.ssh/config
cp "$DOTFILES_DIR/.ssh/config" ~/.ssh/config
chmod 600 ~/.ssh/config
printf "%s SSH config installed\n\n" "$(COMPLETE)"
sleep 1

printf "%s Installing lpu\n" "$(BANNER)"
sleep 0.5
sudo ln -sf "$DOTFILES_DIR/lpu" /usr/local/bin/lpu
printf "%s lpu installed to /usr/local/bin/lpu\n\n" "$(COMPLETE)"
sleep 1

printf "%s Installing ipkg\n" "$(BANNER)"
sleep 0.5
sudo ln -sf "$DOTFILES_DIR/ipkg" /usr/local/bin/ipkg
printf "%s ipkg installed to /usr/local/bin/ipkg\n\n" "$(COMPLETE)"
sleep 1

# ──[ Default Shell ]───────────────────────────────────────────────────────────
ZSH_BIN="$(command -v zsh 2>/dev/null)"
if [[ -n "$ZSH_BIN" && "$SHELL" != "$ZSH_BIN" ]]; then
  printf "%s Setting zsh as default shell\n" "$(BANNER)"
  sleep 0.5
  # /etc/shells must list zsh for chsh to accept it
  if ! grep -qx "$ZSH_BIN" /etc/shells; then
    printf "%s\n" "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi
  sudo chsh -s "$ZSH_BIN" "$USER"
  printf "%s Default shell set to %s\n\n" "$(COMPLETE)" "$ZSH_BIN"
else
  printf "%s zsh is already the default shell\n\n" "$(COMPLETE)"
fi
sleep 1

printf "%s Installation Complete\n" "$(COMPLETE)"
[[ -d "$BACKUP_DIR" ]] && printf "%s Backups saved to %s\n" "$(PLUS)" "$BACKUP_DIR"
printf "%s Deployment complete. Entering the shell.\n" "$(LAMBDA)"
exec zsh
