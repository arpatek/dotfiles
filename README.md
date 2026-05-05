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
| `upu` | Universal Package Updater script |

---

## Requirements

- Bash 4+
- Zsh
- [Zinit](https://github.com/zdharma-continuum/zinit) — installed automatically on first shell load
- [eza](https://github.com/eza-community/eza) — used by shell aliases
- Neovim — primary editor
- tmux

---

## Installation

```bash
git clone git@codeberg.org:arpatek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script creates the required directories, symlinks all dotfiles into place, and installs `upu` to `/usr/local/bin` so it is available system-wide. The SSH config is copied rather than symlinked so each host can have its own entries without affecting the template.

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
