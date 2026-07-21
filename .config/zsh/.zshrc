# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Configuration                                  │
# │ Modern, minimal Zsh — no framework, no plugin manager.       │
# └──────────────────────────────────────────────────────────────┘

# ──[ Shared Env Bridge ]───────────────────────────────────────────────────────
# Linux terminal emulators spawn non-login shells, which skip .zprofile. Pull it
# in so PATH and tool roots exist here too. On macOS (login shells) this no-ops;
# typeset -U keeps PATH duplicate-free either way.
[[ -o login ]] || source "$ZDOTDIR/.zprofile"

# ──[ Plugins ]─────────────────────────────────────────────────────────────────
# Plugins are cloned to ~/.config/zsh/plugins/ by install.sh — no manager needed.
# zsh-completions must be added to fpath before compinit runs.
PLUGINS_DIR="$HOME/.config/zsh/plugins"
fpath=("${PLUGINS_DIR}/zsh-completions/src" $fpath)
source "${PLUGINS_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ──[ Completion System ]───────────────────────────────────────────────────────
ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE" ]] || mkdir -p "$ZSH_CACHE"
autoload -Uz compinit
# Rebuild the completion dump only if older than 24h; otherwise load from cache
# with -C (skips the security check and full scan — ~100ms faster).
if [[ -n ${ZSH_CACHE}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "${ZSH_CACHE}/.zcompdump"
else
    compinit -C -d "${ZSH_CACHE}/.zcompdump"
fi
zmodload zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# ──[ Autosuggestions ]─────────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Cap how long a command autosuggestions will try to match — without this, long
# pipeline history entries cause noticeable lag on every keystroke.
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ──[ History Substring Search ]────────────────────────────────────────────────
# Type any part of a previous command, then Up/Down to cycle matches. Complements
# the inline autosuggestion. Must load before fast-syntax-highlighting.
source "${PLUGINS_DIR}/zsh-history-substring-search/zsh-history-substring-search.zsh"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ──[ Vi Mode Toggle ]──────────────────────────────────────────────────────────
# Emacs mode by default. Double Esc enters vi command mode; double Esc again
# returns to emacs. Single Esc inside vi insert still goes to vi command (normal
# vi behaviour). Starship's vimcmd_symbol updates on each toggle.
_toggle_vi_mode() {
  if [[ "$KEYMAP" == vicmd ]] || [[ "$KEYMAP" == viins ]]; then
    bindkey -e
  else
    bindkey -v
    zle -K vicmd
  fi
  zle reset-prompt
}
zle -N _toggle_vi_mode
bindkey          '\e\e' _toggle_vi_mode
bindkey -M vicmd '\e\e' _toggle_vi_mode
bindkey -M viins '\e\e' _toggle_vi_mode

# 50ms — short enough to feel instant, long enough to catch the second Esc.
KEYTIMEOUT=5

# ──[ Syntax Highlighting ]─────────────────────────────────────────────────────
# Must load after all other plugins — it wraps zle widgets and will miss any
# widgets registered after it loads.
source "${PLUGINS_DIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ──[ Fuzzy Finder (fzf) ]──────────────────────────────────────────────────────
# Ctrl+R history · Ctrl+T files · Alt+C cd. Border style is set per-OS in os.d/.
eval "$(fzf --zsh)"

# ──[ Smart Directory Jump (zoxide) ]───────────────────────────────────────────
# z <query> jumps to the most-frecent match; zi is an fzf picker.
eval "$(zoxide init zsh)"

# ──[ User Aliases ]────────────────────────────────────────────────────────────
[[ -f "$ZDOTDIR/.zsh_aliases" ]] && source "$ZDOTDIR/.zsh_aliases"

# ──[ GPG ]─────────────────────────────────────────────────────────────────────
# GPG commit signing needs the tty for pinentry. Interactive-only.
export GPG_TTY=$(tty)

# ──[ Manpages ]────────────────────────────────────────────────────────────────
export LESS='-R'
# bat renders man pages with syntax highlighting — no LESS_TERMCAP_* needed.
export MANPAGER='bat -l man -p'

# ──[ History ]─────────────────────────────────────────────────────────────────
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # record : <timestamp>:<elapsed>;<cmd> per entry
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicate anywhere before recording
setopt HIST_IGNORE_SPACE      # skip commands prefixed with a space
setopt SHARE_HISTORY          # share history across sessions in real time
setopt HIST_VERIFY            # expand !! in place before executing

# ──[ Shell Behavior ]──────────────────────────────────────────────────────────
setopt AUTO_CD    # type a directory name alone to cd into it
setopt GLOB_DOTS  # include dotfiles in glob patterns without needing .*
setopt NO_BEEP    # disable terminal bell on errors or no match

# ──[ Python (pyenv) ]──────────────────────────────────────────────────────────
# Interactive shell function + completions. PYENV_ROOT/bin is on PATH via .zprofile.
command -v pyenv >/dev/null && eval "$(pyenv init -)"

# ──[ Platform Module ]─────────────────────────────────────────────────────────
# OS-specific interactive bits — keybinds, fzf border, OS aliases, and the prompt.
# Starship init must run last, so each module ends with it.
case "$OSTYPE" in
  darwin*) source "$ZDOTDIR/os.d/darwin.zsh" ;;
  linux*)  source "$ZDOTDIR/os.d/linux.zsh"  ;;
esac
