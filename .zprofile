# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Profile                                        │
# │ Loaded for login shells, including non-interactive SSH runs  │
# │ (e.g. ssh host 'python script.py'). Keep this minimal —      │
# │ only env vars that must exist before .zshrc or in headless   │
# │ contexts where .zshrc is never sourced.                      │
# └──────────────────────────────────────────────────────────────┘

# ──[ PATH ]───────────────────────────────────────────────────────────────────
[ -d "$HOME/bin" ]        && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ──[ Go ]─────────────────────────────────────────────────────────────────────
[ -d "/usr/local/go/bin" ] && export PATH="/usr/local/go/bin:$PATH"
[ -d "$HOME/go/bin" ]      && export PATH="$HOME/go/bin:$PATH"

# ──[ Python (pyenv) ]─────────────────────────────────────────────────────────
# Exported here so pyenv-managed python/pip is available even in non-interactive
# login shells (cron jobs, remote commands over SSH, etc.)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
