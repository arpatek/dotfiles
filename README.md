# dotfiles

Personal dotfiles for Zsh, tmux, Vim/Neovim, Git, and SSH — **cross-platform
(Linux + macOS)**, managed via symlinks with a fully automated, OS-aware bootstrap
installer.

One repo, one source of truth. The OS is detected at **install time** (which packages
and tools to bootstrap) and again at **shell runtime** (which interactive tweaks to
load), so the same checkout drives a RHEL server, an Asahi laptop, and a Mac.

---

## Architecture

The OS-specific surface is small and quarantined into modules; everything else is shared.

| Layer | Detects OS via | Shared | Per-OS module |
|---|---|---|---|
| Install (`bash`) | `uname -s` in `install.sh` | packages-agnostic flow, symlinks, zsh plugins, LazyVim | `os/linux.sh`, `os/darwin.sh` |
| Shell runtime (`zsh`) | `$OSTYPE` in `.zshrc` | plugins, completion, history, keybinds | `.config/zsh/os.d/{linux,darwin}.zsh` |

**`os/<os>.sh`** (install) defines `os_bootstrap`, `os_link`, `os_post`, `os_uninstall`,
`os_uninstall_shell`. `install.sh` / `uninstall.sh` are thin dispatchers that source the
matching module and call these hooks.

**`os.d/<os>.zsh`** (runtime) holds the ~10-line interactive delta — keybinds, fzf border,
OS-only aliases, and the Starship prompt (which must load last).

### Zsh load model

```
.zshenv    every shell     ZDOTDIR, `typeset -U path`, pure env vars (tool roots, EDITOR)
.zprofile  login shells    Homebrew (macOS) + PATH — runs AFTER macOS path_helper so order wins
.zshrc     interactive     plugins, completion, fzf/zoxide, pyenv, then the $OSTYPE module
os.d/*     sourced by .zshrc   per-OS keybinds/aliases/prompt
```

Two portability details make one config correct on both platforms:

- **`typeset -U path`** (in `.zshenv`) keeps PATH duplicate-free, so building it is idempotent.
- **Non-login bridge** — Linux terminal emulators spawn *non-login* shells that skip
  `.zprofile`; `.zshrc` runs `[[ -o login ]] || source "$ZDOTDIR/.zprofile"` to pull it in.
  On macOS (login shells) this no-ops, and PATH is built in `.zprofile` so Apple's
  `path_helper` can't reorder it ahead of our entries.

---

## Contents

| Path | Description |
|---|---|
| `install.sh` / `uninstall.sh` | OS-aware bootstrap / teardown dispatchers |
| `os/linux.sh` | Linux package + tool bootstrap, symlinks, teardown |
| `os/darwin.sh` | macOS Homebrew/Brewfile bootstrap, symlinks, teardown |
| `lib.sh` | Shared utilities — colors, decoration functions, `cache_sudo` |
| `Brewfile` | macOS package manifest (`brew bundle`) |
| `lpu` / `mpu` | Linux / Mac Package Updater |
| `ipkg-linux` / `ipkg-macos` | Interactive package browser (linked as `ipkg` per OS) |
| `.zshenv` | `ZDOTDIR`, `typeset -U path`, tool-root env vars |
| `.config/zsh/.zprofile` | Login-shell PATH (built after macOS path_helper) |
| `.config/zsh/.zshrc` | Interactive config — plugins, fzf, zoxide, pyenv, `$OSTYPE` module |
| `.config/zsh/os.d/{linux,darwin}.zsh` | Per-OS interactive delta — keybinds, fzf, aliases, prompt |
| `.config/zsh/.zsh_aliases` | Shared aliases (OS-specific ones live in `os.d/`) |
| `.config/starship.toml` | Starship prompt — catppuccin macchiato, two-line |
| `.config/git/{config,commit-template}` | Git config + conventional commit template |
| `.config/tmux/tmux.conf` | tmux — truecolor, vi copy mode, 50k scrollback, tokyo-night |
| `.config/vim/vimrc`, `.config/nvim/init.vim` | Vim config + Neovim fallback for nvim < 0.11.2 |
| `.config/lazygit/config.yml`, `.config/curlrc` | lazygit theme, curl defaults |
| `.config/ghostty/config` | Ghostty — arpatek palette, JetBrainsMono NFM; shared by macOS and Linux |
| `.config/vscodium/{settings.json,extensions.txt}` | VSCodium settings + extension manifest, restored by `os/darwin.sh` |
| `.aerospace.toml`, `.config/zed/` | macOS-only — linked by `os/darwin.sh` |
| `.config/starship-sysadmin.toml` | Linux-only alt prompt for the `sysadmin` user |
| `.ssh/config`, `.editorconfig`, `.gitignore` | SSH templates, editor rules, repo ignores |

---

## Installation

```bash
git clone git@codeberg.org:arpatek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer detects the OS and:

- **Linux** — detects the distro package manager, installs missing packages, then Go,
  lazygit, fzf, zoxide, starship, eza, bat, yazi, and JetBrains Mono Nerd Font from
  upstream; sets zsh as the default shell via `chsh`; archives leftover bash configs.
- **macOS** — installs Xcode CLT and Homebrew, then everything in the `Brewfile`.
- **Both** — clone zsh and tmux plugins (no plugin manager), clone the LazyVim starter (nvim ≥ 0.11.2,
  else `init.vim`), symlink all shared config, link the OS-specific config, and launch zsh.

```bash
./install.sh --skip-packages   # re-link only, no package bootstrap
./install.sh --update          # re-fetch upstream-installed tools (Linux)
./uninstall.sh                 # full teardown, restores a clean state
```

`uninstall.sh` removes symlinks, tools, plugins, pyenv, and LazyVim on both platforms;
on Linux it also removes bootstrapped packages, reverts the default shell to bash, and
restores archived bash configs; on macOS it uninstalls Brewfile packages (with a prompt).

---

## Known Gotchas

**LazyVim not loading after install (Linux)** — if nvim was previously installed via apt,
`/usr/bin/nvim` shadows the script's `/usr/local/bin/nvim`; the version check reads the wrong
binary and falls back to `init.vim`. Remove the apt package (`sudo apt remove neovim`) and
re-run.

**macOS PATH order** — `/etc/zprofile` runs `path_helper` at login and reorders PATH. Our PATH
is built in `~/.zprofile` (which runs *after* it), so our entries stay in front. Do not move
PATH construction into `.zshenv`, or path_helper will shove `/usr/bin` ahead of it.

---

## Home Directory Layout

All shell and tool config lives under `~/.config/` (XDG). Files that must sit in `$HOME`:

| File | Why |
|---|---|
| `~/.zshenv` | Sets `ZDOTDIR` — zsh reads this before any other file |
| `~/.editorconfig` | EditorConfig falls back to `$HOME` |
| `~/.aerospace.toml` | AeroSpace (macOS) has no XDG support |
| `~/.ssh/` | SSH has no XDG support |

---

## Package Updaters — `lpu` / `mpu`

`lpu` (Linux) detects the system package manager and runs a full update/upgrade/cleanup
cycle. `mpu` (macOS) does the same for Homebrew. Both linked into `PATH` by the OS module.

```
Usage: lpu [OPTIONS]
  -h, --help      Show this help message
  -V, --version   Show version
  -n, --dry-run   Print commands without executing them
```

**`lpu` package managers:** `nala` · `apt` · `dnf` · `yum` · `pacman` · `zypper` · `apk` · `xbps` · `emerge` · `pkg`

---

## `ipkg` — Interactive Package Browser

A fuzzy-find TUI to install/remove packages, linked as `ipkg` on both platforms from the
OS-specific implementation:

- **`ipkg-linux`** — multi-manager (`pacman`/`apt`/`dnf`/`zypper`/`apk`/`xbps`/`pkg`);
  `alt+i` install mode, `alt+r` remove mode, `Tab` multi-select.
- **`ipkg-macos`** — Homebrew formulae + casks; `alt+f`/`alt+c` install formula/cask,
  `alt+r`/`alt+x` remove formula/cask.

---

## Zsh Features

| Feature | Detail |
|---|---|
| No plugin manager | Plugins cloned to `~/.config/zsh/plugins/` by the installer |
| Syntax highlighting | `fast-syntax-highlighting` |
| Autosuggestions | History-first with completion fallback, 20-char buffer cap |
| History substring search | Type any part of a past command, Up/Down cycles matches |
| Completions | `zsh-completions`, 24-hour compinit dump cache in `~/.cache/zsh/` |
| Fuzzy finder | fzf — `Ctrl+R` history, `Ctrl+T` files, `Alt+C` fuzzy cd |
| Smart jump | zoxide — `z <query>`, `zi` interactive |
| Prompt | Starship — catppuccin macchiato, two-line, OS icon, git |
| Vi mode toggle | Double `Esc` enters vi command mode, double `Esc` returns to emacs |
| History | 50,000 entries, dup-removed, timestamped, shared across sessions |

---

## Zsh Aliases

Shared aliases live in `.config/zsh/.zsh_aliases`; OS-specific ones (e.g. `grep` vs `ggrep`,
`shutdown` flags, macOS `flushdns`/`pubkey`) live in `os.d/<os>.zsh`.

| Alias | Command |
|---|---|
| `ls` / `ll` / `lll` / `tree` | `eza` variants with icons + git |
| `mkdir` | `mkdir -pv` |
| `gs` / `ga` / `gc` / `gp` / `gl` | Git shortcuts |
| `ssh` | Wraps ssh with `TERM=xterm-256color` (fixes Ghostty terminfo on remotes) |
| `pi` / `rhel` / `dev` | SSH into configured hosts |
| `ports` / `reload` | `lsof -i -P -n` / `exec zsh` |

---

## tmux

Theme: [tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux) — clone manually,
not managed by the installer:

```bash
git clone https://github.com/janoamaral/tokyo-night-tmux ~/.config/tmux/plugins/tokyo-night-tmux
```

| Binding | Action |
|---|---|
| `C-a` | Prefix (replaces `C-b`) |
| `Prefix + \|` / `Prefix + -` | Split vertical / horizontal |
| `Prefix + r` | Reload config |
| `v` / `y` (copy mode) | Begin selection / yank to clipboard |

Clipboard yank is cross-platform: `pbcopy` (macOS) → `xclip` → `xsel` (Linux/X11).

---

## SSH Keys

The SSH config references key files not in this repo. Generate them with
[portal-22](https://codeberg.org/arpatek/portal-22):

```bash
portal-22 -g                        # global key — {hostname}.key
portal-22 -t git -p codeberg        # git.codeberg.key
portal-22 -H netrunner              # per-host key
```

Add the `.pub` files to their respective services and `authorized_keys` files.
