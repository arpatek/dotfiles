# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh, Linux                                         │
# │ Only what bash cannot share. Portable Linux bits live in     │
# │ .config/shell/os.d/linux, sourced by .zshrc first.           │
# └──────────────────────────────────────────────────────────────┘

# Last, so it sees STARSHIP_CONFIG from the shared module.
eval "$(starship init zsh)"
