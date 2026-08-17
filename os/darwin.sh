#!/usr/bin/env bash
# =============================================================================
# Script Name: os/darwin.sh
# Description: macOS package bootstrap (Homebrew/Brewfile) and OS-specific
#              symlinks. Sourced by install.sh on macOS; not executed directly.
# Author: Juan Garcia (arpatek)
# Created: 2026-07-22
# Version: 1.0
# =============================================================================
#
# Relies on helpers from the install.sh scope: DOTFILES_DIR, link(), backup(),
# and the lib.sh decorators (BANNER/PLUS/COMPLETE/FAILED/LAMBDA).

# ──[ Xcode Command Line Tools ]────────────────────────────────────────────────
bootstrap_xcode() {
  if xcode-select -p &>/dev/null; then
    printf "%s Xcode Command Line Tools already installed\n" "$(COMPLETE)"
    return
  fi
  printf "%s Installing Xcode Command Line Tools...\n" "$(PLUS)"
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
  printf "%s Xcode Command Line Tools installed\n" "$(COMPLETE)"
}

# ──[ Homebrew ]────────────────────────────────────────────────────────────────
bootstrap_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    printf "%s Homebrew already installed\n" "$(COMPLETE)"
    return
  fi
  printf "%s Installing Homebrew...\n" "$(PLUS)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  printf "%s Homebrew installed\n" "$(COMPLETE)"
}

# ──[ Brewfile ]────────────────────────────────────────────────────────────────
bootstrap_packages() {
  printf "%s Installing packages from Brewfile...\n" "$(PLUS)"
  if ! brew bundle --file="$DOTFILES_DIR/Brewfile"; then
    printf "%s Some Brewfile packages failed to install — continuing\n" "$(FAILED)"
    printf "%s Run 'brew bundle check --file=%s' to see what's missing\n" "$(PLUS)" "$DOTFILES_DIR/Brewfile"
  else
    printf "%s Brewfile packages installed\n" "$(COMPLETE)"
  fi
}

# ──[ OS Entry Points ]─────────────────────────────────────────────────────────
os_bootstrap() {
  bootstrap_xcode
  bootstrap_homebrew
  bootstrap_packages
}

os_link() {
  local brew_prefix
  brew_prefix="$(brew --prefix)"

  printf "%s iTerm2\n" "$(BANNER)"
  mkdir -p "$HOME/.config/iterm2"
  cp "$DOTFILES_DIR/.config/iterm2/arpatek.itermcolors" "$HOME/.config/iterm2/arpatek.itermcolors"
  printf "%s Copied arpatek.itermcolors\n" "$(COMPLETE)"

  mkdir -p "$HOME/.config/zed"
  link "$DOTFILES_DIR/.config/zed/settings.json" "$HOME/.config/zed/settings.json"
  link "$DOTFILES_DIR/.aerospace.toml"           "$HOME/.aerospace.toml"

  printf "%s Installing mpu\n" "$(BANNER)"
  ln -sf "$DOTFILES_DIR/mpu" "$brew_prefix/bin/mpu"
  printf "%s mpu installed to %s/bin/mpu\n" "$(COMPLETE)" "$brew_prefix"

  printf "%s Installing ipkg\n" "$(BANNER)"
  ln -sf "$DOTFILES_DIR/ipkg-macos" "$brew_prefix/bin/ipkg"
  printf "%s ipkg installed to %s/bin/ipkg\n" "$(COMPLETE)" "$brew_prefix"
}

os_post() {
  # macOS terminals are already login shells running zsh — no chsh or bash cleanup.
  :
}

# ──[ Uninstall ]───────────────────────────────────────────────────────────────
os_uninstall() {
  printf "%s Homebrew Package Removal\n" "$(BANNER)"
  if ! command -v brew >/dev/null 2>&1; then
    printf "%s Homebrew not found, skipping\n" "$(PLUS)"
  else
    if confirm "Uninstall all packages listed in the Brewfile?"; then
      while IFS= read -r line; do
        line="${line%%#*}"
        if [[ "$line" =~ ^[[:space:]]*brew[[:space:]]+\"([^\"]+)\" ]]; then
          pkg="${BASH_REMATCH[1]}"
          brew uninstall --formula --force "$pkg" 2>/dev/null \
            && printf "%s Removed formula: %s\n" "$(COMPLETE)" "$pkg" \
            || printf "%s Skipped (not installed): %s\n" "$(PLUS)" "$pkg"
        elif [[ "$line" =~ ^[[:space:]]*cask[[:space:]]+\"([^\"]+)\" ]]; then
          pkg="${BASH_REMATCH[1]}"
          brew uninstall --cask --force "$pkg" 2>/dev/null \
            && printf "%s Removed cask: %s\n" "$(COMPLETE)" "$pkg" \
            || printf "%s Skipped (not installed): %s\n" "$(PLUS)" "$pkg"
        elif [[ "$line" =~ ^[[:space:]]*mas[[:space:]] ]]; then
          printf "%s mas apps must be removed manually via the App Store\n" "$(PLUS)"
          break
        fi
      done < "$DOTFILES_DIR/Brewfile"
      printf "%s Brewfile packages removed\n" "$(COMPLETE)"
      while IFS= read -r line; do
        line="${line%%#*}"
        if [[ "$line" =~ ^[[:space:]]*tap[[:space:]]+\"([^\"]+)\" ]]; then
          brew untap "${BASH_REMATCH[1]}" 2>/dev/null \
            && printf "%s Untapped %s\n" "$(COMPLETE)" "${BASH_REMATCH[1]}" \
            || printf "%s Could not untap %s\n" "$(PLUS)" "${BASH_REMATCH[1]}"
        fi
      done < "$DOTFILES_DIR/Brewfile"
    else
      printf "%s Skipping package removal\n" "$(PLUS)"
    fi
  fi

  printf "%s Removing mpu and ipkg\n" "$(BANNER)"
  if command -v brew >/dev/null 2>&1; then
    remove_file "$(brew --prefix)/bin/mpu"
    remove_file "$(brew --prefix)/bin/ipkg"
  fi

  unlink_file "$HOME/.config/zed/settings.json"
  unlink_file "$HOME/.aerospace.toml"
  remove_file "$HOME/.config/iterm2/arpatek.itermcolors"
}

os_uninstall_shell() {
  # macOS was never chsh'd and its bash configs were untouched — nothing to do.
  :
}

# shellcheck disable=SC2034  # consumed by uninstall.sh
OS_UNINSTALL_SHELL="zsh"
