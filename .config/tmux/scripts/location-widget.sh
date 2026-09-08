#!/usr/bin/env bash
# =============================================================================
# Script Name: location-widget.sh
# Description: tmux status widget — ssh target, running app, or cwd per pane.
# Author: Juan Garcia (arpatek)
# Created: 2026-09-08
# Version: 1.1
# =============================================================================

set -eo pipefail

# ──[ Arguments ]───────────────────────────────────────────────────────────────
# pane_path is last and read with a default because tmux emits nothing at all for
# an empty format — an empty argument in any earlier position would silently
# shift every argument after it.
pane_tty="${1#/dev/}"
pane_cmd="$2"
pane_cwd="$3"
pane_alt="$4"        # #{alternate_on} — 1 while a fullscreen app holds the screen
pane_osc7="${5:-}"   # #{pane_path} — only populated when a shell emits OSC 7

# ──[ Theme ]───────────────────────────────────────────────────────────────────
# Mirrors tokyo-night-tmux's own path widget so the bar stays visually uniform.
RESET="#[fg=brightwhite,bg=#15161e,nobold,noitalics,nounderscore,nodim]"
DIR_ICON=""
SSH_ICON="󰣀"
APP_ICON=""
CLAUDE_ICON=""
VIM_ICON=""
NVIM_ICON=""
TMUX_ICON=""
PAGER_ICON=""
MONITOR_ICON=""
GIT_ICON=""
K8S_ICON="󱃾"
PYTHON_ICON=""
NODE_ICON=""
DOCKER_ICON=""

# ──[ SSH Target ]──────────────────────────────────────────────────────────────
# Matched by tty rather than by walking the pane's process tree, so ssh started
# from a wrapper, a shell function, or behind sudo is still found. ProxyJump
# spawns a second ssh on the same tty carrying the *jump* host, so the one whose
# parent is not itself ssh is the one holding the destination the user typed.
ssh_command_line() {
  ps -t "$pane_tty" -o pid=,ppid=,args= 2>/dev/null | awk '
    { cmd = $3; sub(/.*\//, "", cmd) }
    cmd == "ssh" { n++; pids[$1] = 1; parent[n] = $2; line[n] = $0 }
    END {
      for (i = 1; i <= n; i++)
        if (!(parent[i] in pids)) { print line[i]; exit }
    }'
}

# The target is the first non-option argument. The bracketed set is ssh's own
# flags that consume the argument after them; everything else is a bare flag.
ssh_target() {
  local line target=""
  line="$(ssh_command_line)"
  [ -n "$line" ] || return 1

  # Deliberate word splitting — this is a command line, not a path.
  # shellcheck disable=SC2086
  set -- $line
  shift 3   # pid, ppid, and ssh itself

  while [ $# -gt 0 ]; do
    case "$1" in
      -[bcDEeFIiJLlmOopQRSWw]) shift 2 || return 1 ;;
      -*)                      shift ;;
      *)                       target="$1"; break ;;
    esac
  done

  [ -n "$target" ] || return 1
  printf '%s' "$target"
}

# ──[ Remote Path ]─────────────────────────────────────────────────────────────
# OSC 7 arrives as file://host/path. Read only while ssh is the pane's command —
# tmux never clears pane_path, so trusting it afterwards shows a stale remote cwd.
osc7_path() {
  local rest
  [ -n "$pane_osc7" ] || return 1
  rest="${pane_osc7#file://}"
  [ "$rest" != "$pane_osc7" ] || return 1
  case "$rest" in
    */*) ;;
    *) return 1 ;;
  esac
  printf '/%s' "${rest#*/}"
}

# ──[ Path Formatting ]─────────────────────────────────────────────────────────
path_format() {
  tmux show-option -gv @tokyo-night-tmux_path_format 2>/dev/null || true
}

abbrev_local() {
  [ "$(path_format)" = "full" ] && { printf '%s' "$1"; return; }
  printf '%s' "$1" | sed -e "s|^$HOME|~|"
}

# The remote $HOME is unknown, so the common layouts are matched by shape.
abbrev_remote() {
  [ "$(path_format)" = "full" ] && { printf '%s' "$1"; return; }
  printf '%s' "$1" | sed -e 's|^/home/[^/]*|~|' -e 's|^/root|~|'
}

# Only a name gets its domain trimmed — an address is meaningless truncated.
short_host() {
  case "$1" in
    *:*)          printf '%s' "$1" ;;         # IPv6 literal
    *[!0-9.]*)    printf '%s' "${1%%.*}" ;;   # hostname
    *)            printf '%s' "$1" ;;         # IPv4 literal
  esac
}

# macOS ships /usr/bin/man and friends as shell scripts, so tmux reports the
# shell and not the command that was actually run. The outermost shell executing
# a script names it better than any of its children — the tree under `man ls` is
# sh -> sh -> bat -> less, where only the script path says "man".
wrapper_command() {
  ps -t "$pane_tty" -o pid=,ppid=,args= 2>/dev/null | awk '
    {
      cmd = $3; sub(/.*\//, "", cmd)
      if (cmd !~ /^-?(sh|bash|zsh|dash|ksh)$/) next
      for (i = 4; i <= NF; i++) {
        if ($i == "-c") next        # a -c pipeline has no one name
        if ($i ~ /^-/) continue
        script = $i; sub(/.*\//, "", script)
        print script; exit
      }
    }'
}

# A fullscreen app owns the pane, so name the app — the cwd it was launched from
# tells you nothing while it is on screen. Anything unmapped keeps its own name
# behind a generic terminal glyph rather than being dropped.
app_icon() {
  case "$1" in
    claude)                printf '%s' "$CLAUDE_ICON" ;;
    vim|vi|view)           printf '%s' "$VIM_ICON" ;;
    nvim)                  printf '%s' "$NVIM_ICON" ;;
    tmux)                  printf '%s' "$TMUX_ICON" ;;
    less|more|man)         printf '%s' "$PAGER_ICON" ;;
    top|htop|btop)         printf '%s' "$MONITOR_ICON" ;;
    lazygit|tig)           printf '%s' "$GIT_ICON" ;;
    k9s)                   printf '%s' "$K8S_ICON" ;;
    [Pp]ython|python3)     printf '%s' "$PYTHON_ICON" ;;
    node)                  printf '%s' "$NODE_ICON" ;;
    docker|lazydocker)     printf '%s' "$DOCKER_ICON" ;;
    *)                     printf '%s' "$APP_ICON" ;;
  esac
}

render() {
  printf '#[fg=%s,bg=default]░ %s %s#[bg=default]%s ' "$1" "$2" "$RESET" "$3"
}

# ──[ Main ]────────────────────────────────────────────────────────────────────
if [ "$pane_cmd" = "ssh" ] && target="$(ssh_target)"; then
  host="$(short_host "${target#*@}")"

  if remote_path="$(osc7_path)"; then
    render magenta "$SSH_ICON" "${host}:$(abbrev_remote "$remote_path")"
  else
    render magenta "$SSH_ICON" "$target"
  fi
elif [ "$pane_alt" = "1" ]; then
  app="$pane_cmd"
  case "$app" in
    sh|bash|zsh|dash|ksh) app="$(wrapper_command)" ;;
  esac
  [ -n "$app" ] || app="$pane_cmd"

  render cyan "$(app_icon "$app")" "$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]')"
else
  render blue "$DIR_ICON" "$(abbrev_local "$pane_cwd")"
fi
