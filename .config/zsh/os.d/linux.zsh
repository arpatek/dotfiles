# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Linux Module                                       │
# │ Sourced by .zshrc on Linux. Ends with the prompt.            │
# └──────────────────────────────────────────────────────────────┘

# ──[ Fuzzy Finder (fzf) ]──────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded'

# ──[ Aliases ]─────────────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias shutdown='sudo shutdown now'

# ──[ Prompt (Starship) ]───────────────────────────────────────────────────────
# sysadmin uses a distinct prompt config; everyone else the default.
[[ "$USER" == "sysadmin" ]] && export STARSHIP_CONFIG="$HOME/.config/starship-sysadmin.toml"
eval "$(starship init zsh)"
