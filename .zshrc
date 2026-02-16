# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek – Zsh Configuration                                  │
# │ A modern, minimal Zsh setup with plugins and a custom theme  │
# └──────────────────────────────────────────────────────────────┘

# ──[ Plugin Manager ]─────────────────────────────────────────────────────────
source ~/.zinit/bin/zinit.zsh

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
source ~/.zsh/themes/gg3.zsh-theme

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

# ──[ Homebrew  ]──────────────────────────────────────────────────────────────
export PATH="$HOME/bin:/opt/homebrew/bin:$PATH"
setopt NO_NOMATCH
