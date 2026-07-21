# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - Zsh Profile                                        │
# │ Login shells. Builds PATH after macOS path_helper runs.      │
# └──────────────────────────────────────────────────────────────┘

# ──[ Homebrew (macOS) ]────────────────────────────────────────────────────────
# Must run before the PATH block. Apple Silicon uses /opt/homebrew; Intel /usr/local.
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ──[ PATH ]────────────────────────────────────────────────────────────────────
# Prepend low-to-high priority; typeset -U (.zshenv) keeps entries deduped. Each
# is dir-guarded, so tools absent on a given host are skipped cleanly.
[ -d "/usr/local/bin" ]    && path=("/usr/local/bin" $path)
[ -d "$HOME/bin" ]         && path=("$HOME/bin" $path)
[ -d "$HOME/.local/bin" ]  && path=("$HOME/.local/bin" $path)
[ -d "$CARGO_HOME/bin" ]   && path=("$CARGO_HOME/bin" $path)
[ -d "/usr/local/go/bin" ] && path=("/usr/local/go/bin" $path)
[ -d "$HOME/go/bin" ]      && path=("$HOME/go/bin" $path)
[ -d "$PYENV_ROOT/bin" ]   && path=("$PYENV_ROOT/bin" $path)
export PATH
