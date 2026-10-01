#!/usr/bin/env bash
# =============================================================================
# Script Name: root-setup.sh
# Description: Installs the shell and editor config for root, as copies rather
#              than symlinks. Run with sudo from a user's clone.
# Author: Juan Garcia (arpatek)
# Created: 2026-10-01
# Version: 1.0
# =============================================================================
#
# Why a separate script, and why copies.
#
# install.sh configures whoever runs it, out of a clone in that user's home.
# Pointing root's config at such a clone would be a privilege escalation: any
# process running as that user could append a line to root's .bashrc and own
# root on the next `sudo -i`. Copies cannot be edited by a non-root user, and a
# static root config is the right behaviour anyway — root's shell should not
# change because somebody pulled a repo.
#
# The cost is that copies do not track the repo. After changing the shell
# config, re-run this. It is idempotent.
#
# Usage:
#   sudo ./root-setup.sh
#
# Removal:
#   sudo rm -rf /root/.bashrc /root/.bash_profile /root/.config/bash \
#               /root/.config/shell /root/.vim/vimrc

set -eo pipefail

# ──[ Paths ]───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──[ Shared Utilities ]────────────────────────────────────────────────────────
source "$DOTFILES_DIR/lib.sh"

# ──[ Error Trap ]──────────────────────────────────────────────────────────────
trap 'printf "\n%s root setup failed. Aborting.\n" "$(FAILED)"' ERR

# ──[ Preconditions ]───────────────────────────────────────────────────────────
if ((EUID != 0)); then
  printf "%s Must run as root: sudo %s\n" "$(FAILED)" "$0" >&2
  exit 1
fi

# Read root's home from passwd rather than assuming /root — it is usually /root
# but need not be. awk over /etc/passwd, not getent: on musl that lives in
# musl-utils and may be absent.
ROOT_HOME="$(awk -F: '$1 == "root" { print $6 }' /etc/passwd)"
if [[ -z "$ROOT_HOME" || ! -d "$ROOT_HOME" ]]; then
  printf "%s Could not resolve root's home directory\n" "$(FAILED)" >&2
  exit 1
fi

BACKUP_DIR="$ROOT_HOME/.local/share/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ──[ Copy With Backup ]────────────────────────────────────────────────────────
# Skips when the destination is already identical, so a re-run is quiet. Backs
# up anything it is about to replace, including the distro's own .bashrc.
copy() {
  local src="$1" dst="$2"

  if [[ ! -r "$src" ]]; then
    printf "%s Missing source, skipping: %s\n" "$(PLUS)" "${src#"$DOTFILES_DIR"/}"
    return
  fi

  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    printf "%s Already current: %s\n" "$(COMPLETE)" "${dst#"$ROOT_HOME"/}"
    return
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    printf "%s Backed up %s\n" "$(PLUS)" "${dst#"$ROOT_HOME"/}"
  fi

  # mkdir + cp + chmod rather than `install -D`: -D creates leading directories
  # on GNU but takes a destdir argument on BSD, so the GNU form misparses on
  # macOS. The result is also checked — an unchecked install that fails still
  # prints a success line, which is worse than the failure.
  mkdir -p "$(dirname "$dst")"
  if ! cp "$src" "$dst"; then
    printf "%s Failed to install %s\n" "$(FAILED)" "${dst#"$ROOT_HOME"/}" >&2
    return 1
  fi
  chmod 0644 "$dst"
  printf "%s Installed %s\n" "$(COMPLETE)" "${dst#"$ROOT_HOME"/}"
}

# ──[ Install ]─────────────────────────────────────────────────────────────────
printf "%s Installing root config into %s\n" "$(BANNER)" "$ROOT_HOME"

# bash. The stubs cannot move — bash has no ZDOTDIR — so they are what reaches
# the XDG location below.
copy "$DOTFILES_DIR/.bashrc" "$ROOT_HOME/.bashrc"
copy "$DOTFILES_DIR/.bash_profile" "$ROOT_HOME/.bash_profile"
copy "$DOTFILES_DIR/.config/bash/bashrc" "$ROOT_HOME/.config/bash/bashrc"
copy "$DOTFILES_DIR/.config/bash/bash_profile" "$ROOT_HOME/.config/bash/bash_profile"
copy "$DOTFILES_DIR/.config/bash/bash_aliases" "$ROOT_HOME/.config/bash/bash_aliases"

# Shared with zsh, though root never runs zsh.
copy "$DOTFILES_DIR/.config/shell/aliases" "$ROOT_HOME/.config/shell/aliases"

case "$(uname -s)" in
Linux) copy "$DOTFILES_DIR/.config/shell/os.d/linux" "$ROOT_HOME/.config/shell/os.d/linux" ;;
Darwin) copy "$DOTFILES_DIR/.config/shell/os.d/darwin" "$ROOT_HOME/.config/shell/os.d/darwin" ;;
esac

# vim, not nvim: root edits config files, and vi is what a rescue shell has.
copy "$DOTFILES_DIR/.config/vim/vimrc" "$ROOT_HOME/.vim/vimrc"

# ──[ Deliberately Absent ]─────────────────────────────────────────────────────
# No zsh, no plugins, no starship config, no fonts, no packages, and no chsh.
# root's prompt is the plain red PS1 in bashrc's EUID branch, which evaluates
# no third-party tooling — starship, fzf and zoxide would each run as root on
# every prompt. root's login shell stays the system default so a rescue boot
# lands somewhere that exists.

printf "\n%s root config installed\n" "$(COMPLETE)"
[[ -d "$BACKUP_DIR" ]] && printf "%s Replaced files are in %s\n" "$(PLUS)" "$BACKUP_DIR"
printf "%s Re-run after changing the shell config — these are copies, not links\n" "$(PLUS)"
