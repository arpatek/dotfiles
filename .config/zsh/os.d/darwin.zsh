# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - macOS Module                                       │
# │ Sourced by .zshrc on Darwin. Ends with the prompt.           │
# └──────────────────────────────────────────────────────────────┘

# ──[ Keybindings ]─────────────────────────────────────────────────────────────
# History-substring search on Up/Down in vi insert mode too.
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down

# ──[ Fuzzy Finder (fzf) ]──────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ──[ Aliases ]─────────────────────────────────────────────────────────────────
alias grep='ggrep --color=auto'   # GNU grep — supports -P Perl regex unlike BSD grep
alias diff='diff --color'
alias ipinfo='ipconfig getifaddr en0'
alias shutdown='sudo shutdown -h now'

# ──[ macOS Utilities ]─────────────────────────────────────────────────────────
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
alias pubkey='cat ~/.ssh/*.pub | pbcopy && printf "SSH public key copied to clipboard\n"'

# ──[ Prompt (Starship) ]───────────────────────────────────────────────────────
eval "$(starship init zsh)"
