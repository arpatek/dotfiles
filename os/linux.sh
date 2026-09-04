#!/usr/bin/env bash
# =============================================================================
# Script Name: os/linux.sh
# Description: Linux package + tool bootstrap and OS-specific symlinks.
#              Sourced by install.sh on Linux; not executed directly.
# Author: Juan Garcia (arpatek)
# Created: 2026-07-22
# Version: 1.0
# =============================================================================
#
# Relies on helpers from the install.sh scope: DOTFILES_DIR, UPDATE, link(),
# backup(), and the lib.sh decorators (BANNER/PLUS/COMPLETE/FAILED/LAMBDA).

# ──[ Bootstrap Functions ]─────────────────────────────────────────────────────

bootstrap_epel() {
  command -v dnf >/dev/null 2>&1 || return 0

  # Fedora is the upstream of RHEL — EPEL targets downstream distros only.
  # Everything in EPEL is already in Fedora's own repos; skip entirely.
  if grep -qi "^ID=fedora" /etc/os-release 2>/dev/null; then
    printf "%s Fedora detected — skipping EPEL (not needed)\n" "$(COMPLETE)"
    return
  fi

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
    $SUDO dnf install -y \
      "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhel_ver}.noarch.rpm"
  else
    $SUDO dnf install -y epel-release
  fi

  # Many EPEL packages require CRB — install dnf-plugins-core if needed
  command -v crb >/dev/null 2>&1 || $SUDO dnf install -y dnf-plugins-core
  $SUDO crb enable
  printf "%s CRB enabled\n" "$(COMPLETE)"

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

  # Force color output for dnf — sudo strips TERM so dnf defaults to no color
  if [[ "$pm" == "dnf" || "$pm" == "yum" ]]; then
    grep -q "^color=" /etc/dnf/dnf.conf 2>/dev/null \
      || echo "color=always" | $SUDO tee -a /etc/dnf/dnf.conf >/dev/null
    printf "%s dnf color output enabled\n" "$(COMPLETE)"
  fi

  # ── Core tools ──────────────────────────────────────────────────────────────
  # Each entry: [package-key]="binary-to-check"
  # The binary check prevents re-installing already-present tools.
  declare -A TOOLS=(
    [zsh]="zsh"           [git]="git"
    [tmux]="tmux"         [neovim]="nvim"
    [curl]="curl"         [wget]="wget"
    [btop]="btop"
    [ncdu]="ncdu"
    [lynx]="lynx"         [unzip]="unzip"
    [fontconfig]="fc-cache" [gcc]="gcc"
    [make]="make"
  )

  # ── Python build dependencies (pyenv compiles CPython from source) ──────────
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

  # ── Collect missing core tools ──────────────────────────────────────────────
  local missing=()
  for tool in "${!TOOLS[@]}"; do
    if ! command -v "${TOOLS[$tool]}" >/dev/null 2>&1; then
      missing+=("$tool")
      printf "%s Missing: %s\n" "$(PLUS)" "$tool"
    else
      printf "%s Found:   %s\n" "$(COMPLETE)" "$tool"
    fi
  done

  # ── Install missing core tools ──────────────────────────────────────────────
  if (( ${#missing[@]} > 0 )); then
    printf "\n%s Installing %d missing package(s)...\n" "$(BANNER)" "${#missing[@]}"
    sleep 0.5
    # Install one at a time so a package absent from the repos skips gracefully
    # rather than aborting the entire run (e.g. yazi on Debian/Ubuntu).
    for pkg in "${missing[@]}"; do
      case "$pm" in
        nala)        $SUDO nala install -y "$pkg"          || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        apt)         $SUDO apt install -y  "$pkg"          || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        dnf | yum)   $SUDO "$pm" install -y "$pkg"        || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        pacman)      $SUDO pacman -S --noconfirm "$pkg"   || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        zypper)      $SUDO zypper install -y "$pkg"       || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
        apk)         $SUDO apk add "$pkg"                 || printf "%s Skipped: %s (not in repos)\n" "$(PLUS)" "$pkg" ;;
      esac
    done
    printf "%s Core packages installed\n" "$(COMPLETE)"
  else
    printf "%s All core packages already present\n" "$(COMPLETE)"
  fi

  # ── Install Python build dependencies ───────────────────────────────────────
  printf "\n%s Installing Python build dependencies\n" "$(BANNER)"
  sleep 0.5
  case "$pm" in
    nala | apt)
      $SUDO apt install -y "${PYTHON_DEPS_APT[@]}"
      ;;
    dnf | yum)
      $SUDO "$pm" install -y "${PYTHON_DEPS_DNF[@]}"
      ;;
    pacman)
      $SUDO pacman -S --noconfirm "${PYTHON_DEPS_PACMAN[@]}"
      ;;
  esac
  printf "%s Python build dependencies installed\n" "$(COMPLETE)"
  printf "\n"
}

bootstrap_pyenv() {
  if $UPDATE && command -v pyenv >/dev/null 2>&1; then
    printf "%s Updating pyenv...\n" "$(PLUS)"
    pyenv update
    printf "%s pyenv updated\n" "$(COMPLETE)"
    return
  fi

  if ! $UPDATE && (command -v pyenv >/dev/null 2>&1 || [[ -d "$HOME/.local/share/pyenv" ]]); then
    printf "%s pyenv already installed\n" "$(COMPLETE)"
    return
  fi

  printf "%s Installing pyenv...\n" "$(PLUS)"
  local pyenv_out
  # The installer warns about load path when rc files aren't at the default
  # locations — our XDG zsh config already handles pyenv init, so suppress it.
  pyenv_out=$(curl -fsSL https://pyenv.run | bash 2>&1) || {
    printf "%s\n" "$pyenv_out"
    printf "%s pyenv install failed\n" "$(FAILED)" >&2
    return 1
  }
  printf "%s\n" "$pyenv_out" \
    | sed '/^WARNING: seems you still have not added/,/^eval ".*pyenv virtualenv-init/d' \
    || true
  printf "%s pyenv installed\n" "$(COMPLETE)"
}

bootstrap_starship() {
  if ! $UPDATE && command -v starship >/dev/null 2>&1; then
    printf "%s starship already installed\n" "$(COMPLETE)"
    return
  fi

  printf "%s Installing starship...\n" "$(PLUS)"
  # --yes skips the interactive confirmation prompt
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  printf "%s starship installed\n" "$(COMPLETE)"
}

bootstrap_fzf() {
  # fzf --zsh was added in 0.48 — verify any existing install is new enough
  if ! $UPDATE && command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
    printf "%s fzf already installed\n" "$(COMPLETE)"
    return
  fi

  local arch
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) printf "%s Unsupported architecture for fzf: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing fzf...\n" "$(PLUS)"
  local fzf_tag tmp_dir
  fzf_tag=$(curl -fsSL "https://api.github.com/repos/junegunn/fzf/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$fzf_tag" ]]; then
    printf "%s Could not determine latest fzf version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/junegunn/fzf/releases/download/${fzf_tag}/fzf-${fzf_tag#v}-linux_${arch}.tar.gz" \
    -o "$tmp_dir/fzf.tar.gz"
  tar -xf "$tmp_dir/fzf.tar.gz" -C "$tmp_dir"
  $SUDO install "$tmp_dir/fzf" -D -t /usr/local/bin/
  printf "%s fzf %s installed\n" "$(COMPLETE)" "${fzf_tag#v}"
}

bootstrap_zoxide() {
  if ! $UPDATE && command -v zoxide >/dev/null 2>&1; then
    printf "%s zoxide already installed\n" "$(COMPLETE)"
    return
  fi

  local pm=""
  for candidate in nala apt dnf pacman yum zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      pm="$candidate"
      break
    fi
  done

  # Try package manager first — zoxide is in Fedora, Arch, and Ubuntu 21.10+
  case "$pm" in
    dnf | yum | pacman | nala | apt)
      if $SUDO "${pm/nala/apt}" install -y zoxide 2>/dev/null \
         && command -v zoxide >/dev/null 2>&1; then
        printf "%s zoxide installed\n" "$(COMPLETE)"
        return
      fi
      ;;
  esac

  # Fall back to GitHub releases for RHEL and other distros without zoxide in repos
  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="aarch64" ;;
    *) printf "%s Unsupported architecture for zoxide: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing zoxide from GitHub releases...\n" "$(PLUS)"
  local zoxide_tag tmp_dir
  zoxide_tag=$(curl -fsSL "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$zoxide_tag" ]]; then
    printf "%s Could not determine latest zoxide version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/ajeetdsouza/zoxide/releases/download/${zoxide_tag}/zoxide-${zoxide_tag#v}-${arch}-unknown-linux-musl.tar.gz" \
    -o "$tmp_dir/zoxide.tar.gz"
  tar -xf "$tmp_dir/zoxide.tar.gz" -C "$tmp_dir"
  $SUDO install "$tmp_dir/zoxide" -D -t /usr/local/bin/
  printf "%s zoxide %s installed\n" "$(COMPLETE)" "${zoxide_tag#v}"
}

bootstrap_fastfetch() {
  if ! $UPDATE && command -v fastfetch >/dev/null 2>&1; then
    printf "%s fastfetch already installed\n" "$(COMPLETE)"
    return
  fi

  local pm=""
  for candidate in nala apt dnf pacman yum zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      pm="$candidate"
      break
    fi
  done

  # Try package manager first — fastfetch is in Fedora, Arch, and Ubuntu 24.04+
  case "$pm" in
    dnf | yum)  $SUDO "$pm" install -y fastfetch 2>/dev/null && command -v fastfetch >/dev/null 2>&1 && { printf "%s fastfetch installed\n" "$(COMPLETE)"; return; } ;;
    pacman)     $SUDO pacman -S --noconfirm fastfetch 2>/dev/null && command -v fastfetch >/dev/null 2>&1 && { printf "%s fastfetch installed\n" "$(COMPLETE)"; return; } ;;
    nala | apt) $SUDO "$pm" install -y fastfetch 2>/dev/null && command -v fastfetch >/dev/null 2>&1 && { printf "%s fastfetch installed\n" "$(COMPLETE)"; return; } ;;
  esac

  # Fall back to GitHub releases for distros without fastfetch in repos
  local arch
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="aarch64" ;;
    *) printf "%s Unsupported architecture for fastfetch: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  printf "%s Installing fastfetch...\n" "$(PLUS)"
  local ff_tag tmp_dir
  ff_tag=$(curl -fsSL "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$ff_tag" ]]; then
    printf "%s Could not determine latest fastfetch version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/${ff_tag}/fastfetch-linux-${arch}.tar.gz" \
    -o "$tmp_dir/fastfetch.tar.gz"
  tar -xf "$tmp_dir/fastfetch.tar.gz" -C "$tmp_dir"
  $SUDO install "$tmp_dir/usr/bin/fastfetch" -D -t /usr/local/bin/
  printf "%s fastfetch %s installed\n" "$(COMPLETE)" "${ff_tag#v}"
}

bootstrap_fonts() {
  # Linux: fontconfig must be present for font discovery
  if ! command -v fc-cache >/dev/null 2>&1; then
    printf "%s fontconfig not found — skipping font install\n" "$(PLUS)"
    return
  fi

  if ! $UPDATE && fc-list | grep -qi "JetBrainsMono"; then
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
  if ! $UPDATE && command -v go >/dev/null 2>&1; then
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
  $SUDO rm -rf /usr/local/go
  $SUDO tar -C /usr/local -xzf "$tmp_dir/go.tar.gz"
  printf "%s Go %s installed to /usr/local/go\n" "$(COMPLETE)" "$go_version"
}

bootstrap_lazygit() {
  if ! $UPDATE && command -v lazygit >/dev/null 2>&1; then
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
  $SUDO install "$tmp_dir/lazygit" -D -t /usr/local/bin/
  printf "%s lazygit %s installed\n" "$(COMPLETE)" "$lg_ver"
}

bootstrap_nvim() {
  local arch nvim_arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64"; nvim_arch="x86_64" ;;
    aarch64) arch="arm64";  nvim_arch="arm64"  ;;
    *) printf "%s Unsupported architecture for nvim: %s\n" "$(FAILED)" "$(uname -m)" >&2; return 1 ;;
  esac

  if ! $UPDATE && command -v nvim >/dev/null 2>&1; then
    local nvim_ver nvim_minor nvim_patch
    nvim_ver=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    nvim_minor=$(printf "%s" "$nvim_ver" | cut -d. -f2)
    nvim_patch=$(printf "%s" "$nvim_ver" | cut -d. -f3)
    if (( nvim_minor > 11 || ( nvim_minor == 11 && nvim_patch >= 2 ) )); then
      printf "%s nvim %s already meets requirement (>= 0.11.2)\n" "$(COMPLETE)" "$nvim_ver"
      return
    fi
    printf "%s nvim %s < 0.11.2 — upgrading from GitHub releases\n" "$(PLUS)" "$nvim_ver"
  else
    printf "%s Installing nvim from GitHub releases...\n" "$(PLUS)"
  fi

  local nvim_tag tmp_dir
  nvim_tag=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" \
    | grep '"tag_name"' | grep -o 'v[0-9][^"]*' | tr -d '\r') || true

  if [[ -z "$nvim_tag" ]]; then
    printf "%s Could not determine latest nvim version — skipping\n" "$(PLUS)"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    "https://github.com/neovim/neovim/releases/download/${nvim_tag}/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$tmp_dir/nvim.tar.gz"
  tar -xf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
  $SUDO rm -rf /opt/nvim
  $SUDO mv "$tmp_dir/nvim-linux-${nvim_arch}" /opt/nvim
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  printf "%s nvim %s installed to /opt/nvim\n" "$(COMPLETE)" "${nvim_tag#v}"
}

bootstrap_bat() {
  if ! $UPDATE && command -v bat >/dev/null 2>&1; then
    printf "%s bat already installed\n" "$(COMPLETE)"
    return
  fi

  # Debian/Ubuntu install bat as batcat to avoid a conflict with an unrelated
  # system package — if it's already present just wire up the symlink.
  if ! $UPDATE && command -v batcat >/dev/null 2>&1; then
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
    nala | apt)  $SUDO "$pm" install -y bat ;;
    dnf | yum)   $SUDO "$pm" install -y bat ;;
    pacman)      $SUDO pacman -S --noconfirm bat ;;
    zypper)      $SUDO zypper install -y bat ;;
    apk)         $SUDO apk add bat ;;
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
  if ! $UPDATE && command -v yazi >/dev/null 2>&1; then
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
  $SUDO install "$tmp_dir/yazi-${arch}-unknown-linux-gnu/yazi" -D -t /usr/local/bin/
  $SUDO install "$tmp_dir/yazi-${arch}-unknown-linux-gnu/ya"   -D -t /usr/local/bin/
  printf "%s yazi %s installed\n" "$(COMPLETE)" "$yazi_tag"
}

bootstrap_eza() {
  if ! $UPDATE && command -v eza >/dev/null 2>&1; then
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
    nala | apt) $SUDO "$pm" install -y eza 2>/dev/null && command -v eza >/dev/null 2>&1 && { printf "%s eza installed\n" "$(COMPLETE)"; return; } ;;
    pacman)     $SUDO pacman -S --noconfirm eza 2>/dev/null && command -v eza >/dev/null 2>&1 && { printf "%s eza installed\n" "$(COMPLETE)"; return; } ;;
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
  $SUDO install "$tmp_dir/eza" -D -t /usr/local/bin/
  printf "%s eza %s installed\n" "$(COMPLETE)" "$eza_tag"
}

# ──[ Bash Config Cleanup ]─────────────────────────────────────────────────────
# Back up and remove leftover bash config files from $HOME. Since we switch
# the default shell to zsh, these are no longer loaded and only add clutter.
cleanup_bash_configs() {
  local -a bash_configs=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.bash_login"
    "$HOME/.bash_logout"
    "$HOME/.bash_aliases"
    "$HOME/.bash_history"
  )

  local found=false
  local f
  for f in "${bash_configs[@]}"; do
    [[ -f "$f" && ! -L "$f" ]] && found=true && break
  done

  if ! $found; then
    printf "%s No bash config files found — skipping cleanup\n" "$(COMPLETE)"
    return
  fi

  printf "%s Archiving bash config files...\n" "$(PLUS)"
  for f in "${bash_configs[@]}"; do
    if [[ -f "$f" && ! -L "$f" ]]; then
      backup "$f"
      rm "$f"
      printf "%s Archived and removed %s\n" "$(COMPLETE)" "$f"
    fi
  done
}

# ──[ Login Shell ]─────────────────────────────────────────────────────────────
# chsh comes from the shadow package and does not exist on a stock busybox
# system. Fall back to rewriting the passwd entry so the login shell is set
# either way rather than making shadow a hard requirement.
set_login_shell() {
  local shell_bin="$1"
  local user="$2"

  # chsh refuses a shell that /etc/shells does not list.
  if ! grep -qxF "$shell_bin" /etc/shells 2>/dev/null; then
    printf "%s\n" "$shell_bin" | $SUDO tee -a /etc/shells >/dev/null
  fi

  if command -v chsh >/dev/null 2>&1 && $SUDO chsh -s "$shell_bin" "$user" 2>/dev/null; then
    return 0
  fi

  printf "%s chsh unavailable or refused — rewriting the passwd entry\n" "$(PLUS)"
  $SUDO sed -i "s|^\(${user}:.*:\)[^:]*$|\1${shell_bin}|" /etc/passwd
}

# ──[ Alpine ]──────────────────────────────────────────────────────────────────
# Alpine is a lightweight distro and is treated as one here. Every package below
# comes from the official main/community repos on 3.24 — no GitHub tarballs, no
# source builds, no pyenv, no Go toolchain, no Nerd Fonts. Quality of life only.

is_alpine() {
  grep -qi '^ID=alpine' /etc/os-release 2>/dev/null
}

bootstrap_alpine() {
  # Grouped by purpose. apk resolves the set in one transaction, so there is no
  # per-package skipping — every name here is verified present in the repos.
  local -a pkgs=(
    zsh git tmux                          # shell + core
    neovim                                # editor
    curl wget openssh-client-default      # network
    starship fzf zoxide eza bat           # prompt + navigation
    ripgrep fd                            # search
    lazygit delta                         # git ux
    yazi btop ncdu tree less lynx         # files + monitoring
    fastfetch                             # system info
    jq unzip                              # misc
    shadow musl-utils                     # provides chsh and getent
  )

  printf "%s Alpine detected — installing official packages only\n" "$(BANNER)"
  sleep 0.5

  printf "%s Updating package index...\n" "$(PLUS)"
  $SUDO apk update

  printf "%s Installing %d packages...\n" "$(PLUS)" "${#pkgs[@]}"
  $SUDO apk add "${pkgs[@]}"

  printf "%s Alpine packages installed\n" "$(COMPLETE)"
  printf "\n"
}

# ──[ OS Entry Points ]─────────────────────────────────────────────────────────
os_bootstrap() {
  # Alpine takes the lean path and returns — none of the upstream fetching below
  # applies to it, and its repos already cover everything worth having.
  if is_alpine; then
    bootstrap_alpine
    return
  fi

  bootstrap_epel
  bootstrap_packages
  bootstrap_go
  bootstrap_lazygit
  bootstrap_bat
  bootstrap_yazi
  bootstrap_eza
  bootstrap_fzf
  bootstrap_zoxide
  bootstrap_starship
  bootstrap_fastfetch
  bootstrap_pyenv
  bootstrap_fonts
  bootstrap_nvim
}

os_link() {
  printf "%s Installing lpu\n" "$(BANNER)"
  $SUDO ln -sf "$DOTFILES_DIR/lpu" /usr/local/bin/lpu
  printf "%s lpu installed to /usr/local/bin/lpu\n" "$(COMPLETE)"

  printf "%s Installing ipkg\n" "$(BANNER)"
  $SUDO ln -sf "$DOTFILES_DIR/ipkg-linux" /usr/local/bin/ipkg
  printf "%s ipkg installed to /usr/local/bin/ipkg\n" "$(COMPLETE)"

  link "$DOTFILES_DIR/.config/starship-sysadmin.toml" "$HOME/.config/starship-sysadmin.toml"

  # VSCodium is not part of the Linux bootstrap — these VMs are headless. Link
  # the config anyway so a desktop install picks it up without extra steps.
  # Path is XDG here, unlike macOS's ~/Library/Application Support.
  local vscodium_user="$HOME/.config/VSCodium/User"
  mkdir -p "$vscodium_user"
  link "$DOTFILES_DIR/.config/vscodium/settings.json" "$vscodium_user/settings.json"
}

os_post() {
  printf "%s Cleaning Up Shell Config Files\n" "$(BANNER)"
  cleanup_bash_configs

  local zsh_bin login_shell user
  zsh_bin="$(command -v zsh 2>/dev/null)"
  # id -un rather than $USER — the variable is routinely unset in containers.
  user="$(id -un)"
  # Read the real login shell from passwd, not $SHELL — $SHELL reflects the
  # session's startup shell and goes stale after a chsh in the same session.
  # awk over /etc/passwd rather than getent: on musl that lives in musl-utils.
  login_shell="$(awk -F: -v u="$user" '$1 == u { print $7 }' /etc/passwd)"
  if [[ -n "$zsh_bin" && "$login_shell" != "$zsh_bin" ]]; then
    printf "%s Setting zsh as default shell\n" "$(BANNER)"
    set_login_shell "$zsh_bin" "$user"
    printf "%s Default shell set to %s\n" "$(COMPLETE)" "$zsh_bin"
  else
    printf "%s zsh is already the default shell\n" "$(COMPLETE)"
  fi

  # Only runs where VSCodium is actually installed — headless VMs skip this.
  local ext_list="$DOTFILES_DIR/.config/vscodium/extensions.txt"
  if command -v codium >/dev/null 2>&1 && [[ -f "$ext_list" ]]; then
    printf "%s VSCodium Extensions\n" "$(BANNER)"
    local ext
    while read -r ext; do
      [[ -z "$ext" || "$ext" == \#* ]] && continue
      if codium --install-extension "$ext" --force >/dev/null 2>&1; then
        printf "%s %s\n" "$(COMPLETE)" "$ext"
      else
        printf "%s %s — not on Open VSX?\n" "$(FAILED)" "$ext"
      fi
    done <"$ext_list"
  fi
}

# ──[ Uninstall ]───────────────────────────────────────────────────────────────
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
      $SUDO dnf remove -y "$pkg" \
        && printf "%s Removed %s\n" "$(COMPLETE)" "$pkg" \
        || warn "Could not remove $pkg"
    else
      printf "%s Not installed, skipping: %s\n" "$(PLUS)" "$pkg"
    fi
  done

  $found || printf "%s No dnf packages to remove\n" "$(COMPLETE)"
}

os_uninstall() {
  printf "%s Removing dnf packages\n" "$(BANNER)"
  remove_dnf_packages
  printf "\n"

  printf "%s Removing tarball tools\n" "$(BANNER)"
  remove_file /usr/local/bin/lazygit  true
  remove_file /usr/local/bin/yazi     true
  remove_file /usr/local/bin/ya       true
  remove_file /usr/local/bin/eza      true
  remove_file "$HOME/.local/bin/bat"
  remove_file /usr/local/bin/fzf      true
  remove_file /usr/local/bin/zoxide   true
  remove_file /usr/local/bin/starship true
  printf "\n"

  printf "%s Removing Go\n" "$(BANNER)"
  # Module cache is read-only — go clean -modcache handles it; plain rm fails.
  if command -v go >/dev/null 2>&1 && [[ -d "$HOME/go/pkg/mod" ]]; then
    printf "%s Cleaning Go module cache...\n" "$(PLUS)"
    go clean -modcache || warn "go clean -modcache failed"
  fi
  if [[ -d /usr/local/go ]]; then
    $SUDO rm -rf /usr/local/go && printf "%s Removed /usr/local/go\n" "$(COMPLETE)" \
      || warn "Could not remove /usr/local/go"
  fi
  remove_dir "$HOME/go"
  printf "\n"

  printf "%s Removing lpu, ipkg, sysadmin prompt\n" "$(BANNER)"
  remove_file /usr/local/bin/lpu  true
  remove_file /usr/local/bin/ipkg true
  unlink_file "$HOME/.config/starship-sysadmin.toml"
  unlink_file "$HOME/.config/VSCodium/User/settings.json"
  printf "\n"

  # Fonts stay — removing them while Ghostty runs triggers a fontconfig SIGSEGV.
  printf "%s Keeping JetBrains Mono Nerd Font (remove manually if desired)\n" "$(PLUS)"
}

os_uninstall_shell() {
  printf "%s Reverting default shell to bash\n" "$(BANNER)"
  local bash_bin login_shell user
  bash_bin="$(command -v bash 2>/dev/null || true)"
  user="$(id -un)"
  # Read the real login shell from passwd, not $SHELL (stale after chsh in-session).
  # awk over /etc/passwd rather than getent: on musl that lives in musl-utils.
  login_shell="$(awk -F: -v u="$user" '$1 == u { print $7 }' /etc/passwd)"
  if [[ -n "$bash_bin" && "$login_shell" != "$bash_bin" ]]; then
    set_login_shell "$bash_bin" "$user" \
      && printf "%s Default shell reverted to %s\n" "$(COMPLETE)" "$bash_bin" \
      || warn "Could not revert the login shell to $bash_bin"
  else
    printf "%s Shell already bash or bash not found, skipping\n" "$(PLUS)"
  fi

  printf "%s Restoring bash config files\n" "$(BANNER)"
  local latest src f
  latest=$(ls -t "$HOME/.local/share/dotfiles_backup" 2>/dev/null | head -1)
  if [[ -n "$latest" ]]; then
    for f in .bashrc .bash_profile .bash_login .bash_logout .bash_aliases .bash_history; do
      src="$HOME/.local/share/dotfiles_backup/$latest/$f"
      [[ -f "$src" ]] && { cp "$src" "$HOME/$f" \
        && printf "%s Restored ~/%s\n" "$(COMPLETE)" "$f" \
        || warn "Could not restore $f"; }
    done
  else
    printf "%s No backup found — bash configs not restored\n" "$(PLUS)"
  fi
}

# shellcheck disable=SC2034  # consumed by uninstall.sh
OS_UNINSTALL_SHELL="bash"
