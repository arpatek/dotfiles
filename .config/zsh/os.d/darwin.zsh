# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh, macOS                                         │
# │ Only what bash cannot share. Portable macOS bits live in     │
# │ .config/shell/os.d/darwin, sourced by .zshrc first.          │
# └──────────────────────────────────────────────────────────────┘

# viins is a separate keymap: the bindings in .zshrc cover emacs mode, and
# these repeat them so the arrows still search after the Alt-Alt toggle.
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down

# Last, so it sees anything the shared module exported.
eval "$(starship init zsh)"
