# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Configuration                                  │
# │ A modern, minimal Zsh setup with plugins and a custom theme  │
# └──────────────────────────────────────────────────────────────┘

# ──[ Plugin Manager ]─────────────────────────────────────────────────────────
# Load Zinit (cross-platform)

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
autoload -Uz compinit
compinit
zmodload zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

# ──[ Git Plugin (Oh-My-Zsh, Minimal) ]────────────────────────────────────────
zinit ice depth=1
zinit light ohmyzsh/ohmyzsh
source ${ZINIT[PLUGINS_DIR]}/ohmyzsh---ohmyzsh/plugins/git/git.plugin.zsh

# ──[ Autosuggestions ]────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ──[ Custom Theme ]───────────────────────────────────────────────────────────
source ~/.zsh/themes/arpatek.zsh-theme

# ──[ Syntax Highlighting ]────────────────────────────────────────────────────
zinit light zsh-users/zsh-syntax-highlighting

# ──[ User Aliases ]───────────────────────────────────────────────────────────
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# ──[ Colored Man Pages ]──────────────────────────────────────────────────────
export LESS='-R'
export MANPAGER='less -R'

export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'

# ──[ PATH Export ]─────────────────────────────────────────────────────────────
# Add ~/bin if it exists
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

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
