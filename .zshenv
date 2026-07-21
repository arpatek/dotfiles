# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Environment                                    │
# │ Read by every shell — keep it cheap, no slow evals.          │
# └──────────────────────────────────────────────────────────────┘

# ──[ zsh Config Home ]─────────────────────────────────────────────────────────
export ZDOTDIR="$HOME/.config/zsh"

# ──[ PATH Uniqueness Guard ]───────────────────────────────────────────────────
# -U collapses duplicate path entries: later prepends replace, never stack.
# Set here (the earliest-read file) so sourcing the PATH block from both
# .zprofile and .zshrc stays idempotent regardless of how zsh was invoked.
typeset -U path fpath

# ──[ Tool Roots ]──────────────────────────────────────────────────────────────
# Pure string exports: cheap, script-safe, and unaffected by macOS path_helper
# (they carry no PATH ordering). Actual PATH additions live in .zprofile.
export PYENV_ROOT="$HOME/.local/share/pyenv"
export CARGO_HOME="$HOME/.local/share/cargo"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export KUBECONFIG="$HOME/.config/kube/config"
export KUBECACHEDIR="$HOME/.cache/kube"
export NPM_CONFIG_USERCONFIG="$HOME/.config/npm/npmrc"
export NPM_CONFIG_CACHE="$HOME/.cache/npm"

# ──[ Default Editor ]──────────────────────────────────────────────────────────
# In .zshenv so git, cron, and other non-interactive tools inherit it.
export EDITOR='nvim'
export VISUAL='nvim'
