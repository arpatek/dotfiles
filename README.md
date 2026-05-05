# dotfiles

Personal dotfiles for Zsh, tmux, Vim/Neovim, Git, and SSH — managed via symlinks and a single install script.

---

## Contents

| File | Description |
|---|---|
| `.zshrc` | Zsh configuration — Zinit, plugins, PATH, editor |
| `.zsh_aliases` | Aliases for navigation, git, SSH, networking, and system |
| `.zsh/themes/arpatek.zsh-theme` | Custom Zsh prompt theme |
| `.tmux.conf` | tmux config — prefix, splits, mouse, usability tweaks |
| `.gitconfig` | Git config — aliases, editor, branch/merge defaults |
| `.git-commit-template` | Conventional commit message template (optional) |
| `.vimrc` | Minimal Vim config for CLI/DevOps workflows |
| `.config/nvim/init.vim` | Neovim config |
| `.ssh/config` | SSH config template — admin hosts and git deploy keys |
| `install.sh` | Symlink installer |
| `uninstall.sh` | Removes symlinks, uninstalls upu, optionally restores backups |
| `upu` | Universal Package Updater script |

---

## Requirements

- Bash 4+
- Zsh
- [Zinit](https://github.com/zdharma-continuum/zinit) — must be installed before sourcing `.zshrc`
- [eza](https://github.com/eza-community/eza) — used by shell aliases
- Neovim — primary editor
- tmux

---

## Installation

**1. Install Zinit**

```bash
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
```

> When prompted to install recommended extras, choose **no** — plugins are already configured in `.zshrc`

**2. Clone and run the installer**

```bash
git clone git@codeberg.org:arpatek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script creates the required directories, symlinks all dotfiles into place, and installs `upu` to `/usr/local/bin` so it is available system-wide. The SSH config is copied rather than symlinked so each host can have its own entries without affecting the template.

**To uninstall**

```bash
./uninstall.sh
```

Removes all symlinks, uninstalls `upu` from `/usr/local/bin`, and prompts to restore the most recent backup created by `install.sh`.

---

## SSH Keys

The SSH config references key files that are not included in this repo. Generate them with:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/git.codeberg.key  -C "Codeberg | $(hostname)"     -N ""
ssh-keygen -t ed25519 -f ~/.ssh/git.github.key    -C "GitHub | $(hostname)"       -N ""
ssh-keygen -t ed25519 -f ~/.ssh/git.gitlab.key    -C "GitLab | $(hostname)"       -N ""
ssh-keygen -t ed25519 -f ~/.ssh/netrunner-rpi.key -C "Netrunner RPi | $(hostname)" -N ""
ssh-keygen -t ed25519 -f ~/.ssh/dev-rhel-0.key    -C "RHEL Lab | $(hostname)"     -N ""
ssh-keygen -t ed25519 -f ~/.ssh/dev-ubuntu-0.key  -C "Ubuntu Dev | $(hostname)"   -N ""
```

Add the `.pub` files to their respective services and `authorized_keys` files.

---

## upu — Universal Package Updater

Detects the system package manager and runs a full update/upgrade cycle with cleanup.

```
Usage: upu [OPTIONS]
Options:
  -h, --help      Show this help message
  -V, --version   Show version
  -n, --dry-run   Print commands without executing them
```

**Supported package managers:** `nala`, `apt`, `dnf`, `pacman`, `yum`, `zypper`, `apk`, `xbps`, `emerge`, `pkg`, `brew`

---

## Zsh — Features

| Feature | Detail |
|---|---|
| Plugin manager | Zinit with autosuggestions, syntax highlighting, completions |
| History | 50,000 entries, no duplicates, shared across sessions, space-prefixed commands excluded |
| `AUTO_CD` | Type a directory name to navigate into it without `cd` |
| `CORRECT` | Suggests corrections for mistyped commands |
| `GLOB_DOTS` | Glob patterns include dotfiles without needing `.*` |
| `NO_BEEP` | Disables terminal bell on completion errors |

---

## Zsh Aliases — Quick Reference

| Alias | Command |
|---|---|
| `la` | `eza -A --icons --git` |
| `ll` | `eza -lagh --icons --git` |
| `lll` | `eza -lagShi --icons --git` |
| `ltree` | `eza -T --level=5 --icons --git` |
| `gs` / `ga` / `gc` / `gp` / `gl` | Git shortcuts |
| `pi` / `rhel` / `dev` | SSH into configured hosts |
| `ports` | `lsof -i -P -n` |
| `reload` | `exec zsh` |

---

## tmux — Key Bindings

| Binding | Action |
|---|---|
| `C-a` | Prefix (replaces `C-b`) |
| `Prefix + \|` | Split vertically |
| `Prefix + -` | Split horizontally |
| `Prefix + r` | Reload config |
