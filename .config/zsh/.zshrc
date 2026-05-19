# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Configuration                                  │
# │ A modern, minimal Zsh setup — no framework, no plugin mgr.  │
# └──────────────────────────────────────────────────────────────┘

# ──[ Plugins ]─────────────────────────────────────────────────────────────────
# Plugins are cloned to ~/.config/zsh/plugins/ by install.sh — no manager needed.
# zsh-completions must be added to fpath before compinit runs
PLUGINS_DIR="$HOME/.config/zsh/plugins"
fpath=("${PLUGINS_DIR}/zsh-completions/src" $fpath)
source "${PLUGINS_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ──[ Completion System ]───────────────────────────────────────────────────────
ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE" ]] || mkdir -p "$ZSH_CACHE"
autoload -Uz compinit
# Rebuild the completion dump only if it is older than 24 hours; otherwise
# load from cache with -C (skips security check and full file scan — ~100ms faster)
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
# Cap the length of commands autosuggestions will try to match — without this,
# long pipeline history entries cause noticeable lag on every keystroke
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ──[ History Substring Search ]────────────────────────────────────────────────
# Type any part of a previous command, then use Up/Down to cycle matches.
# Complements autosuggestions: autosuggestions shows the top match inline,
# this lets you browse all matches with the arrow keys.
# Must load before fast-syntax-highlighting.
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

# 50ms — short enough to feel instant, long enough to catch the second Esc
KEYTIMEOUT=5

# ──[ Syntax Highlighting ]─────────────────────────────────────────────────────
# Must load after all other plugins — it wraps zle widgets and will miss any
# widgets registered after it loads.
source "${PLUGINS_DIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ──[ Fuzzy Finder (fzf) ]──────────────────────────────────────────────────────
# Ctrl+R → fuzzy history search
# Ctrl+T → fuzzy file picker (inserts path at cursor)
# Alt+C  → fuzzy cd into a subdirectory
eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ──[ Smart Directory Jump (zoxide) ]───────────────────────────────────────────
# z <query>  → jump to most-frecent directory matching the query
# zi         → interactive picker using fzf
eval "$(zoxide init zsh)"

# ──[ User Aliases ]────────────────────────────────────────────────────────────
[[ -f "$HOME/.config/zsh/.zsh_aliases" ]] && source "$HOME/.config/zsh/.zsh_aliases"

# ──[ Default Editor ]──────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
# Required for GPG commit signing — without this, pinentry cannot find the tty
export GPG_TTY=$(tty)

# ──[ Manpages ]────────────────────────────────────────────────────────────────
export LESS='-R'
# bat renders man pages with full syntax highlighting — no LESS_TERMCAP_* needed
export MANPAGER='bat -l man -p'

# ──[ History ]─────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.config/zsh/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # record : <timestamp>:<elapsed>;<cmd> per entry
setopt HIST_IGNORE_ALL_DUPS   # remove older copy anywhere in history before recording
setopt HIST_IGNORE_SPACE      # skip recording commands prefixed with a space
setopt SHARE_HISTORY          # share history across all open sessions in real time
setopt HIST_VERIFY            # expand !! in place before executing

# ──[ Shell Behavior ]──────────────────────────────────────────────────────────
setopt AUTO_CD    # type a directory name alone to cd into it
setopt GLOB_DOTS  # include dotfiles in glob patterns without needing .*
setopt NO_BEEP    # disable terminal bell on errors or no match

# ──[ PATH Export ]─────────────────────────────────────────────────────────────
[ -d "$HOME/bin" ]        && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "/usr/local/bin" ]   && PATH="/usr/local/bin:$PATH"

export PATH

# ──[ Go ]──────────────────────────────────────────────────────────────────────
[ -d "/usr/local/go/bin" ] && export PATH="/usr/local/go/bin:$PATH"
[ -d "$HOME/go/bin" ]      && export PATH="$HOME/go/bin:$PATH"

# ──[ Python (pyenv) ]──────────────────────────────────────────────────────────
# Set PYENV_ROOT and prepend its bin so the pyenv shim intercepts python/pip
# calls. The eval block injects the shim directory and shell function — both
# are needed; PATH alone is not enough.
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"

# ──[ Prompt (Starship) ]───────────────────────────────────────────────────────
eval "$(starship init zsh)"
