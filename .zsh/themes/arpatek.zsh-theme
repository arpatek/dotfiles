# ┌────────────────────────────────────────────────────────────────────┐
# │ arpatek - arpatek.zsh-theme                                        │
# │ Custom Oh My Zsh prompt for automation-friendly environments.      │
# │ Two-line prompt showing:                                           │
# │   - Python virtualenv (if active)                                  │
# │   - user@host                                                      │
# │   - shortened path (last 3 dirs max)                               │
# │   - Git branch + SHA + status                                      │
# │ Designed for easy reading, color-coded scanning, and vgrep logs.   │
# └────────────────────────────────────────────────────────────────────┘


# ──[ Virtualenv Appearance Config ]───────────────────────────────────────────
ZSH_THEME_VIRTUALENV_PREFIX="%{$fg[white]%}(%{$fg[magenta]%}"
ZSH_THEME_VIRTUALENV_SUFFIX="%{$fg[white]%})%{$reset_color%}"

# ──[ Git Status Symbols ]─────────────────────────────────────────────────────
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[cyan]%} +"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%} ✱"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%} ➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%} ✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[blue]%} ✈"
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" %{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%{$reset_color%}"

# ──[ VENV ]───────────────────────────────────────────────────────────────────
custom_virtualenv_prompt_info() {
  [[ -n "$VIRTUAL_ENV" ]] || return
  echo "${ZSH_THEME_VIRTUALENV_PREFIX}$(basename "$VIRTUAL_ENV")${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

# ──[ Git Prompt W/ Branch ]───────────────────────────────────────────────────
# (depends on oh-my-zsh git plugin)
mygit() {
  [[ "$(git config --get oh-my-zsh.hide-status)" == "1" ]] && return

  local ref
  ref=$(command git symbolic-ref HEAD 2>/dev/null) \
    || ref=$(command git rev-parse --short HEAD 2>/dev/null) \
    || return

  echo " %B[${ref#refs/heads/}$(git_prompt_short_sha)$(git_prompt_status)%{$reset_color%}%b%B]%b "
}

# ──[ Smart Path Shortening ]──────────────────────────────────────────────────
# ~/ or .../last/3/dirs
prompt_truncated_pwd() {
  local path="${PWD/#$HOME/~}"
  [[ "$path" == "~" ]] && { echo "~"; return; }

  local -a dirs
  dirs=("${(s:/:)path}")

  if (( ${#dirs[@]} > 3 )); then
    echo ".../${dirs[-3]}/${dirs[-2]}/${dirs[-1]}"
  else
    echo "$path"
  fi
}

# ──[ Cached Prompt Segments ]─────────────────────────────────────────────────
# These are populated once per prompt via precmd
PROMPT_PWD=""
PROMPT_VENV=""
PROMPT_GIT=""

precmd() {
  PROMPT_PWD="$(prompt_truncated_pwd)"
  PROMPT_VENV="$(custom_virtualenv_prompt_info)"
  PROMPT_GIT="$(mygit)"
}

# ──[ Two-line terminal prompt ]───────────────────────────────────────────────
PROMPT=$'%{\e[0;31m%}%B┌─[%{\e[1;34m%}%B%n%{\e[0m%}%b%{\e[1;37m%}@%{\e[0;32m%}%B%m%{\e[0m%}%b%{\e[0;31m%}]%b%{\e[0;31m%}[%{\e[0;33m%}$PROMPT_PWD%{\e[0;31m%}]%b %{$fg[magenta]%}$PROMPT_VENV%{$reset_color%}$PROMPT_GIT
%{\e[0;31m%}%B└─▪%b%{\e[0;37m%}$ %b'

# Continuation prompt
PS2=$' \e[0;34m%}%B>%{\e[0m%}%b '
