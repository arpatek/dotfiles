# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Configuration                                  │
# │ A modern, minimal Zsh setup with plugins and a custom theme  │
# └──────────────────────────────────────────────────────────────┘

# ──[ Plugin Manager ]──────────────────────────────────────────────────────────
# Try common Zinit install locations in order — Linux default, Homebrew, legacy
if [ -f ~/.local/share/zinit/zinit.git/zinit.zsh ]; then
    source ~/.local/share/zinit/zinit.git/zinit.zsh
elif [ -f /opt/homebrew/opt/zinit/bin/zinit.zsh ]; then
    source /opt/homebrew/opt/zinit/bin/zinit.zsh
elif [ -f ~/.zinit/bin/zinit.zsh ]; then
    source ~/.zinit/bin/zinit.zsh
elif [ -f /usr/local/opt/zinit/bin/zinit.zsh ]; then
    source /usr/local/opt/zinit/bin/zinit.zsh
fi

# ──[ Zinit Annexes ]───────────────────────────────────────────────────────────
# Must load before any zinit light/snippet calls — annexes extend zinit's ice
# system, so anything that uses from"gh-r", atload, etc. depends on them
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ──[ Completion System ]───────────────────────────────────────────────────────
# zsh-completions must load before compinit to register its extra completions
zinit light zsh-users/zsh-completions
autoload -Uz compinit
# Rebuild the completion dump only if it is older than 24 hours; otherwise
# load from cache with -C (skips security check and full file scan — ~100ms faster)
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zmodload zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

# ──[ Prompt Prerequisites ]────────────────────────────────────────────────────
# PROMPT_SUBST lets zsh expand $VARIABLES inside PROMPT on every render.
# Without it, $PROMPT_PWD/$PROMPT_GIT show up as literal strings.
setopt PROMPT_SUBST

# Populate $fg[], $bg[], and $reset_color — used by the custom theme.
# Previously OMZ's init script did this automatically; now we do it explicitly.
autoload -U colors && colors

# lib/git.zsh defines git_prompt_short_sha and git_prompt_status called by the
# custom theme. These live in the OMZ library layer, not the plugin itself.
zinit snippet OMZ::lib/git.zsh

# ──[ Git Plugin (Oh-My-Zsh snippet) ]──────────────────────────────────────────
# Git aliases (ga, gco, glg, etc.) — avoids cloning the full 300 MB OMZ repo
zinit snippet OMZ::plugins/git/git.plugin.zsh

# ──[ Autosuggestions ]─────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Cap the length of commands autosuggestions will try to match — without this,
# long pipeline history entries cause noticeable lag on every keystroke
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ──[ Custom Theme ]────────────────────────────────────────────────────────────
source ~/.zsh/themes/arpatek.zsh-theme

# ──[ Syntax Highlighting ]─────────────────────────────────────────────────────
# Must load after all other plugins — it wraps zle widgets and will miss any
# widgets registered after it loads.
# fast-syntax-highlighting is a drop-in replacement that is measurably faster
# on large pastes and adds more highlight categories (paths, aliases, builtins)
zinit light zdharma-continuum/fast-syntax-highlighting

# ──[ Fuzzy Finder (fzf) ]──────────────────────────────────────────────────────
# Ctrl+R → fuzzy history search
# Ctrl+T → fuzzy file picker (inserts path at cursor)
# Alt+C  → fuzzy cd into a subdirectory
zinit ice from"gh-r" as"program"
zinit light junegunn/fzf
zinit snippet 'https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh'
zinit snippet 'https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ──[ Smart Directory Jump (zoxide) ]───────────────────────────────────────────
# z <query>  → jump to most-frecent directory matching the query
# zi         → interactive picker using fzf
# atload runs eval after zinit adds zoxide to PATH, so the shell functions
# (z, zi, __zoxide_hook) are available immediately on first shell open
zinit ice from"gh-r" as"program" atload"eval \$(zoxide init zsh)"
zinit light ajeetdsouza/zoxide

# ──[ User Aliases ]────────────────────────────────────────────────────────────
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# ──[ Colored Man Pages ]───────────────────────────────────────────────────────
export LESS='-R'
export MANPAGER='less -R'

# LESS_TERMCAP_* maps terminal capabilities to ANSI escape sequences
# mb = start blink      → bold red
export LESS_TERMCAP_mb=$'\e[1;31m'
# md = start bold       → bold cyan
export LESS_TERMCAP_md=$'\e[1;36m'
# me = end bold/blink   → reset
export LESS_TERMCAP_me=$'\e[0m'
# so = start standout   → yellow on blue (search highlights)
export LESS_TERMCAP_so=$'\e[01;44;33m'
# se = end standout     → reset
export LESS_TERMCAP_se=$'\e[0m'
# us = start underline  → bold green
export LESS_TERMCAP_us=$'\e[1;32m'
# ue = end underline    → reset
export LESS_TERMCAP_ue=$'\e[0m'

# ──[ Default Editor ]──────────────────────────────────────────────────────────
export EDITOR='nvim'

# ──[ History ]─────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # record : <timestamp>:<elapsed>;<cmd> per entry
setopt HIST_IGNORE_ALL_DUPS   # remove older copy anywhere in history before recording
setopt HIST_IGNORE_SPACE      # skip recording commands prefixed with a space
setopt SHARE_HISTORY          # share history across all open sessions in real time
setopt HIST_VERIFY            # expand !! in place before executing

# ──[ Shell Behavior ]──────────────────────────────────────────────────────────
setopt AUTO_CD    # type a directory name alone to cd into it
# setopt CORRECT    # suggest corrections for mistyped commands
setopt GLOB_DOTS  # include dotfiles in glob patterns without needing .*
setopt NO_BEEP    # disable terminal bell on errors or no match

# ──[ PATH Export ]─────────────────────────────────────────────────────────────
[ -d "$HOME/bin" ]        && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

if [ -d "/opt/homebrew/bin" ]; then
    PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
    PATH="/usr/local/bin:$PATH"
fi

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
