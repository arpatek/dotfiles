# dotfiles

Personal dotfiles for Zsh, tmux, Vim/Neovim, Git, and SSH — Linux-first, managed via symlinks with a fully automated bootstrap installer.

> macOS setup lives in a separate repo: [mac-setup](https://codeberg.org/arpatek/mac-setup)

---

## Contents

| File | Description |
|---|---|
| `lib.sh` | Shared utilities — colors, decoration functions, `cache_sudo` |
| `install.sh` | Full bootstrap — packages, tools, pyenv, starship, fonts, LazyVim, symlinks |
| `uninstall.sh` | Full cleanup — removes all tools, symlinks, and bootstrapped environments |
| `lpu` | Linux Package Updater |
| `ipkg` | Interactive package browser — fuzzy-find to install or remove packages |
| `.zshenv` | Sets `ZDOTDIR` so zsh finds all config under `~/.config/zsh/` |
| `.config/zsh/.zshrc` | Zsh config — plugins, fzf, zoxide, pyenv, Go, starship |
| `.config/zsh/.zprofile` | Login shell env — PATH, pyenv, Go (active for non-interactive SSH) |
| `.config/zsh/.zsh_aliases` | Aliases for navigation, git, SSH, networking, and system |
| `.config/starship.toml` | Starship prompt — catppuccin macchiato palette, two-line with git, path, OS icon |
| `.config/git/config` | Git config — aliases, editor, fetch prune, autosquash, colorMoved |
| `.config/git/commit-template` | Conventional commit template |
| `.config/vim/vimrc` | Minimal Vim config for CLI/DevOps workflows |
| `.config/tmux/tmux.conf` | tmux — truecolor, vi copy mode, 50k scrollback, focus events, tokyo-night theme |
| `.config/nvim/init.vim` | Neovim fallback for nvim < 0.9 or no network (LazyVim used otherwise) |
| `.config/curlrc` | curl defaults — follow redirects, retry, fail-fast |
| `.config/lazygit/config.yml` | lazygit catppuccin mocha theme |
| `.ssh/config` | SSH — global ControlMaster defaults and connection templates |
| `.editorconfig` | Universal indent/charset rules for all editors |
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
- Install Go, lazygit, fzf, zoxide, starship, and JetBrains Mono Nerd Font
- Clone zsh plugins directly — no plugin manager needed
- Clone the LazyVim starter (requires nvim ≥ 0.9; falls back to `init.vim`)
- Symlink all dotfiles into place under `~/.config/`
- Archive and remove leftover bash config files from `$HOME`
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

Removes symlinks, tools, Go, pyenv, starship, plugins, LazyVim, and non-essential dnf packages. Restores bash config files, reverts the default shell to bash.

---

## Home Directory Layout

All shell and tool config lives under `~/.config/` (XDG-compliant). The only files
installed directly to `$HOME` are:

| File | Why it must stay in `$HOME` |
|---|---|
| `~/.zshenv` | Sets `ZDOTDIR` — zsh reads this before any other file |
| `~/.editorconfig` | EditorConfig walks up from the project root, falls back to `$HOME` |
| `~/.ssh/` | SSH has no XDG support |

---

## lpu — Linux Package Updater

Detects the system package manager and runs a full update/upgrade cycle with cleanup.

```
Usage: lpu [OPTIONS]
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
| No plugin manager | Plugins cloned to `~/.config/zsh/plugins/` by the installer |
| Syntax highlighting | `fast-syntax-highlighting` — faster than zsh-syntax-highlighting |
| Autosuggestions | History-first with completion fallback, 20-char buffer cap |
| History substring search | Type any part of a past command, Up/Down cycles all matches |
| Completions | `zsh-completions` with 24-hour compinit dump cache in `~/.cache/zsh/` |
| Fuzzy finder | fzf — `Ctrl+R` history, `Ctrl+T` file picker, `Alt+C` fuzzy cd |
| Smart jump | zoxide — `z <query>` jumps to most-frecent directory, `zi` interactive |
| Prompt | Starship — catppuccin macchiato, two-line with OS icon, user@host, path, git |
| Vi mode toggle | Double `Esc` enters vi command mode, double `Esc` again returns to emacs |
| History | 50,000 entries, all-duplicates removed, timestamps, shared across sessions |
| `AUTO_CD` | Type a directory name to navigate without `cd` |
| `GLOB_DOTS` | Glob patterns include dotfiles without `.*` |
| `NO_BEEP` | Disables terminal bell |

---

## Zsh Aliases

| Alias | Command |
|---|---|
| `ls` | `eza -A --icons --git` |
| `ll` | `eza -lagh --icons --git` |
| `lll` | `eza -lagShi --icons --git` |
| `tree` | `eza -T --icons --git` |
| `grep` | `grep --color=auto` |
| `ip` | `ip --color=auto` |
| `mkdir` | `mkdir -pv` |
| `gs` / `ga` / `gc` / `gp` / `gl` | Git shortcuts |
| `ssh` | Wraps ssh with `TERM=xterm-256color` to fix Ghostty terminfo errors on remotes |
| `pi` / `rhel` / `dev` | SSH into configured hosts |
| `ports` | `lsof -i -P -n` |
| `reload` | `exec zsh` |

---

## ipkg — Interactive Package Browser

| Key | Action |
|---|---|
| `alt+r` | Switch to remove mode — installed packages, red markers |
| `alt+i` | Switch to install mode — available packages, green markers |
| `Tab` | Multi-select |
| `alt+p` | Toggle preview panel |
| `alt+j` / `alt+k` | Scroll preview line by line |
| `alt+d` / `alt+u` | Scroll preview half-page |

---

## tmux Theme

Uses [tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux). Clone it manually — it is not managed by the installer:

```bash
git clone https://github.com/janoamaral/tokyo-night-tmux ~/.config/tmux/plugins/tokyo-night-tmux
```

Enabled widgets: git status, battery, network speed, now playing, current path, hostname.

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

The SSH config references key files not included in this repo. Generate them with [portal-22](https://codeberg.org/arpatek/portal-22):

```bash
portal-22 -g                        # global key — silverhand.key
portal-22 -t git -p codeberg        # git.codeberg.key
portal-22 -t git -p github          # git.github.key
portal-22 -t git -p gitlab          # git.gitlab.key
portal-22 -t git -p gitea           # git.gitea.key
portal-22 -H netrunner              # netrunner.key
portal-22 -H blackwall              # blackwall.key
portal-22 -H mikoshi                # mikoshi.key
portal-22 -H soulkiller             # soulkiller.key
portal-22 -H netwatch               # netwatch.key
portal-22 -H erebus                 # erebus.key
portal-22 -H sandevistan            # sandevistan.key
portal-22 -H kerenzikov             # kerenzikov.key
```

Add the `.pub` files to their respective services and `authorized_keys` files.
