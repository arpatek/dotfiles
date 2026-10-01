# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Bash, Linux                                        │
# └──────────────────────────────────────────────────────────────┘
# Mirrors .config/zsh/os.d/linux.zsh. The starship config selection lives in
# bashrc's prompt block, not here, because root must not reach it at all.

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded'

alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias shutdown='sudo shutdown now'
