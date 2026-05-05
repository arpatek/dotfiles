# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Configuration                                  │
# │ A modern, minimal Zsh setup with plugins and a custom theme  │
# └──────────────────────────────────────────────────────────────┘

# ──[ Plugin Manager ]─────────────────────────────────────────────────────────
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

# ──[ Completion System (Flags + Descriptions) ]───────────────────────────────
# zsh-completions must load before compinit to register its completions
zinit light zsh-users/zsh-completions
autoload -Uz compinit
compinit
zmodload zsh/complist

# Navigate completion menu with arrow keys
zstyle ':completion:*' menu select
# Show descriptions alongside completions
zstyle ':completion:*' verbose yes
# Style completion group headers in blue
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

# ──[ Git Plugin (Oh-My-Zsh, Minimal) ]────────────────────────────────────────
zinit ice depth=1
zinit light ohmyzsh/ohmyzsh
source ${ZINIT[PLUGINS_DIR]}/ohmyzsh---ohmyzsh/plugins/git/git.plugin.zsh

# ──[ Autosuggestions ]────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
# Try history first, fall back to completion engine if no history match
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ──[ Custom Theme ]───────────────────────────────────────────────────────────
source ~/.zsh/themes/arpatek.zsh-theme

# ──[ Syntax Highlighting ]────────────────────────────────────────────────────
zinit light zsh-users/zsh-syntax-highlighting

# ──[ User Aliases ]───────────────────────────────────────────────────────────
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# ──[ Colored Man Pages ]──────────────────────────────────────────────────────
# Tell less to pass ANSI color codes through raw (-R)
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

# ──[ Default Editor ]─────────────────────────────────────────────────────────
export EDITOR='nvim'

# ──[ History ]────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS   # skip recording if same as previous entry
setopt HIST_IGNORE_SPACE  # skip recording commands prefixed with a space
setopt SHARE_HISTORY      # share history across all open sessions in real time
setopt HIST_VERIFY        # expand !! in place before executing

# ──[ Shell Behavior ]─────────────────────────────────────────────────────────
setopt AUTO_CD    # type a directory name alone to cd into it
setopt CORRECT    # suggest corrections for mistyped commands
setopt GLOB_DOTS  # include dotfiles in glob patterns without needing .*
setopt NO_BEEP    # disable terminal bell on errors or no match

# ──[ PATH Export ]────────────────────────────────────────────────────────────
# Add ~/bin if it exists
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

# Add ~/.local/bin if it exists
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Add Homebrew if installed
if [ -d "/opt/homebrew/bin" ]; then
    PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
    PATH="/usr/local/bin:$PATH"
fi

export PATH

# ──[ Zinit Additions ]────────────────────────────────────────────────────────
# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
