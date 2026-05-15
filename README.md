# dotfiles

Personal dotfiles for Zsh, tmux, Vim/Neovim, Git, and SSH — Linux-first, managed via symlinks with a fully automated bootstrap installer.

> macOS setup lives in a separate repo: [mac-setup](https://codeberg.org/arpatek/mac-setup)

---

## Contents

| File | Description |
|---|---|
| `lib.sh` | Shared utilities — colors, decoration functions, `cache_sudo` |
| `install.sh` | Full bootstrap — packages, tools, pyenv, zinit, fonts, LazyVim, symlinks |
| `uninstall.sh` | Full cleanup — removes all tools, symlinks, and bootstrapped environments |
| `upu` | Universal Package Updater |
| `ipkg` | Interactive package browser — fuzzy-find and install packages via fzf |
| `.zshrc` | Zsh config — Zinit, fzf, zoxide, pyenv, Go, plugins |
| `.zprofile` | Login shell env — PATH, pyenv, Go (active for non-interactive SSH) |
| `.zsh_aliases` | Aliases for navigation, git, SSH, networking, and system |
| `.zsh/themes/arpatek.zsh-theme` | Custom two-line Zsh prompt with git status |
| `.tmux.conf` | tmux — truecolor, vi copy mode, 50k scrollback, focus events |
| `.gitconfig` | Git config — aliases, editor, fetch prune, autosquash, colorMoved |
| `.git-commit-template` | Conventional commit template |
| `.vimrc` | Minimal Vim config for CLI/DevOps workflows |
| `.config/nvim/init.vim` | Neovim fallback for nvim < 0.9 or no network (LazyVim used otherwise) |
| `.ssh/config` | SSH — global ControlMaster defaults and connection templates |
| `.editorconfig` | Universal indent/charset rules for all editors |
| `.curlrc` | curl defaults — follow redirects, retry, fail-fast |
| `.config/lazygit/config.yml` | lazygit catppuccin mocha theme |
| `.gitignore` | Repo-level ignores — swap files, history, pyc, secrets |

---

## Installation

Clone and run the installer. It handles everything automatically.

```bash
git clone git@codeberg.org:arpatek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
- Detect your distro and install missing packages
- Install Go, lazygit, pyenv, zinit, and JetBrains Mono Nerd Font
- Clone the LazyVim starter (requires nvim ≥ 0.9; falls back to `init.vim`)
- Symlink all dotfiles into place
- Set zsh as your default shell via `chsh`
- Launch zsh on completion

**To skip package installation** (re-link only):

```bash
./install.sh --skip-packages
```

**To uninstall:**

```bash
./uninstall.sh
```

Removes all symlinks, tools, Go, pyenv, zinit, LazyVim, fonts, and reverts the default shell.

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

**Supported package managers:** `nala` · `apt` · `dnf` · `yum` · `pacman` · `zypper` · `apk` · `xbps` · `emerge` · `pkg`

---

## Zsh Features

| Feature | Detail |
|---|---|
| Plugin manager | Zinit with lazy loading and annexes |
| Syntax highlighting | `fast-syntax-highlighting` — faster than zsh-syntax-highlighting |
| Autosuggestions | History-first with completion fallback, 20-char buffer cap |
| Completions | `zsh-completions` with 24-hour compinit dump cache |
| Fuzzy finder | fzf — `Ctrl+R` history, `Ctrl+T` file picker, `Alt+C` fuzzy cd |
| Smart jump | zoxide — `z <query>` jumps to most-frecent directory, `zi` interactive |
| History | 50,000 entries, all-duplicates removed, timestamps, shared across sessions |
| `AUTO_CD` | Type a directory name to navigate without `cd` |
| `GLOB_DOTS` | Glob patterns include dotfiles without `.*` |
| `NO_BEEP` | Disables terminal bell |

---

## Zsh Aliases

| Alias | Command |
|---|---|
| `la` | `eza -A --icons --git` |
| `ll` | `eza -lagh --icons --git` |
| `lll` | `eza -lagShi --icons --git` |
| `ltree` | `eza -T --level=5 --icons --git` |
| `grep` | `grep --color=auto` |
| `ip` | `ip --color=auto` |
| `mkdir` | `mkdir -pv` |
| `gs` / `ga` / `gc` / `gp` / `gl` | Git shortcuts |
| `pi` / `rhel` / `dev` | SSH into configured hosts |
| `ports` | `lsof -i -P -n` |
| `reload` | `exec zsh` |

---

## tmux Key Bindings

| Binding | Action |
|---|---|
| `C-a` | Prefix (replaces `C-b`) |
| `Prefix + \|` | Split vertically |
| `Prefix + -` | Split horizontally |
| `Prefix + r` | Reload config |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Copy to system clipboard |

---

## SSH Keys

The SSH config references key files not included in this repo. Generate them with:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/git.codeberg.key   -C "Codeberg | $(hostname)"      -N ""
ssh-keygen -t ed25519 -f ~/.ssh/git.github.key     -C "GitHub | $(hostname)"        -N ""
ssh-keygen -t ed25519 -f ~/.ssh/git.gitlab.key     -C "GitLab | $(hostname)"        -N ""
ssh-keygen -t ed25519 -f ~/.ssh/netrunner-rpi.key  -C "Netrunner RPi | $(hostname)" -N ""
ssh-keygen -t ed25519 -f ~/.ssh/dev-ubuntu-0.key   -C "Ubuntu Dev | $(hostname)"    -N ""
```

Add the `.pub` files to their respective services and `authorized_keys` files.
