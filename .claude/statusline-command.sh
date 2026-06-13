#!/usr/bin/env bash
# =============================================================================
# Script Name: statusline-command.sh
# Description: Claude Code status line — visual bars, tokens, cost, cache.
# Author: Juan Garcia (arpatek)
# Created: 2026-06-13
# Version: 3.0
# =============================================================================

input=$(cat)

# ──[ Parse JSON ]─────────────────────────────────────────────────────────────
model=$(printf '%s' "$input"      | jq -r '.model.display_name // empty')
used_pct=$(printf '%s' "$input"   | jq -r '.context_window.used_percentage // empty')
total_in=$(printf '%s' "$input"   | jq -r '.context_window.total_input_tokens // empty')
total_out=$(printf '%s' "$input"  | jq -r '.context_window.total_output_tokens // empty')
in_tok=$(printf '%s' "$input"     | jq -r '.context_window.current_usage.input_tokens // empty')
out_tok=$(printf '%s' "$input"    | jq -r '.context_window.current_usage.output_tokens // empty')
cache_write=$(printf '%s' "$input"| jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
cache_read=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
effort=$(printf '%s' "$input"      | jq -r '.effort.level // empty')
vim_mode=$(printf '%s' "$input"   | jq -r '.vim.mode // empty')
repo=$(printf '%s' "$input"       | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
session_cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')
five_hour=$(printf '%s' "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(printf '%s' "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ──[ ANSI colors ]────────────────────────────────────────────────────────────
R='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
WHITE='\033[37m'

# ──[ Helpers ]─────────────────────────────────────────────────────────────────
# Build a Unicode progress bar: bar <pct_int> <width>
bar() {
  local pct=$1 width=$2
  awk -v p="$pct" -v w="$width" 'BEGIN {
    filled = int(p * w / 100 + 0.5)
    if (filled > w) filled = w
    empty = w - filled
    b = ""
    for (i = 0; i < filled; i++) b = b "█"
    for (i = 0; i < empty; i++) b = b "░"
    printf "%s", b
  }'
}

# Format token count as Xk or X
ktok() {
  awk -v t="$1" 'BEGIN {
    if (t >= 1000) printf "%.1fk", t/1000
    else printf "%d", t
  }'
}

# ──[ Context bar ]────────────────────────────────────────────────────────────
ctx_part=""
if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct")
  if   [ "$pct_int" -ge 80 ]; then bar_color="$RED"
  elif [ "$pct_int" -ge 50 ]; then bar_color="$YELLOW"
  else                              bar_color="$GREEN"
  fi
  ctx_bar=$(bar "$pct_int" 10)
  ctx_part="$(printf "ctx ${bar_color}▕%s▏${R} ${bar_color}%s%%${R}" "$ctx_bar" "$pct_int")"
fi

# ──[ Turn token counts ]──────────────────────────────────────────────────────
tok_part=""
if [ -n "$in_tok" ] && [ -n "$out_tok" ]; then
  _i=$(ktok "$in_tok")
  _o=$(ktok "$out_tok")
  tok_part="$(printf "${DIM}↓${R}%s ${DIM}↑${R}%s" "$_i" "$_o")"

  if [ -n "$cache_read" ] && [ "$cache_read" -gt 0 ]; then
    _cr=$(ktok "$cache_read")
    tok_part="$tok_part $(printf "${GREEN}⚡%s${R}" "$_cr")"
  fi
  if [ -n "$cache_write" ] && [ "$cache_write" -gt 0 ]; then
    _cw=$(ktok "$cache_write")
    tok_part="$tok_part $(printf "${DIM}✎%s${R}" "$_cw")"
  fi
fi

# ──[ Cumulative session totals ]───────────────────────────────────────────────
session_tok_part=""
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  _ti=$(ktok "$total_in")
  _to=$(ktok "$total_out")
  session_tok_part="$(printf "${DIM}Σ ↓%s ↑%s${R}" "$_ti" "$_to")"
fi

# ──[ Session cost ]───────────────────────────────────────────────────────────
cost_part=""
if [ -n "$session_cost" ]; then
  cost_part=$(awk -v c="$session_cost" 'BEGIN { printf "'"${YELLOW}"'$%.4f'"${R}"'", c }')
elif [ -n "$in_tok" ] && [ -n "$out_tok" ]; then
  # Fallback: estimate from last turn if session cost unavailable
  _cw=${cache_write:-0}
  _cr=${cache_read:-0}
  _plain=$(( in_tok - _cw - _cr ))
  [ "$_plain" -lt 0 ] && _plain=0
  cost_part=$(awk -v pin="$_plain" -v pout="$out_tok" -v pcw="$_cw" -v pcr="$_cr" \
    'BEGIN { printf "'"${YELLOW}"'~$%.4f'"${R}"'", (pin*3 + pout*15 + pcw*3.75 + pcr*0.30)/1000000 }')
fi

# ──[ Rate limits ]─────────────────────────────────────────────────────────────
rl_part=""
if [ -n "$five_hour" ]; then
  fh_int=$(printf '%.0f' "$five_hour")
  if   [ "$fh_int" -ge 90 ]; then rl_col="$RED"
  elif [ "$fh_int" -ge 70 ]; then rl_col="$YELLOW"
  else                             rl_col="$GREEN"
  fi
  fh_bar=$(bar "$fh_int" 10)
  reset_time=""
  if [ -n "$five_reset" ]; then
    reset_time=$(date -r "$five_reset" "+%-I:%M%p" 2>/dev/null \
              || date -d "@$five_reset" "+%-I:%M%p" 2>/dev/null)
  fi
  rl_part="$(printf "${rl_col}5h ▕%s▏ %s%%${R}" "$fh_bar" "$fh_int")"
  [ -n "$reset_time" ] && rl_part="$rl_part $(printf "${DIM}↺%s${R}" "$reset_time")"
fi
if [ -n "$seven_day" ]; then
  sd_int=$(printf '%.0f' "$seven_day")
  if   [ "$sd_int" -ge 90 ]; then rl_col="$RED"
  elif [ "$sd_int" -ge 70 ]; then rl_col="$YELLOW"
  else                             rl_col="$GREEN"
  fi
  sd_bar=$(bar "$sd_int" 10)
  sep="${rl_part:+ │ }"
  rl_part="${rl_part}${sep}$(printf "${rl_col}7d ▕%s▏ %s%%${R}" "$sd_bar" "$sd_int")"
fi

# ──[ Git ]────────────────────────────────────────────────────────────────────
git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  git_part="$branch"
  [ "$staged" -gt 0 ]   && git_part="$git_part $(printf "${GREEN}+%s${R}" "$staged")"
  [ "$modified" -gt 0 ] && git_part="$git_part $(printf "${YELLOW}~%s${R}" "$modified")"
fi

# ──[ Effort ]─────────────────────────────────────────────────────────────────
effort_part=""
if [ -n "$effort" ]; then
  case "$effort" in
    low)        dot="${DIM}●${R}"  ;;
    medium)     dot="${GREEN}●${R}" ;;
    high)       dot="${YELLOW}●${R}" ;;
    xhigh|max)  dot="${RED}●${R}"   ;;
    *)          dot="●"             ;;
  esac
  effort_part="$(printf "%s %s" "$dot" "$effort")"
fi

# ──[ Assemble ]───────────────────────────────────────────────────────────────
parts=()

[ -n "$model" ]        && parts+=("$(printf "${CYAN}%s${R}" "$model")")
[ -n "$effort_part" ]  && parts+=("$effort_part")
[ -n "$vim_mode" ]     && parts+=("$(printf "${MAGENTA}[%s]${R}" "$vim_mode")")
[ -n "$rl_part" ]      && parts+=("$rl_part")
[ -n "$ctx_part" ]     && parts+=("$ctx_part")
[ -n "$tok_part" ]     && parts+=("$tok_part")
[ -n "$session_tok_part" ] && parts+=("$session_tok_part")
[ -n "$cost_part" ]    && parts+=("$cost_part")
[ -n "$git_part" ]     && parts+=("$git_part")

# ──[ Render ]─────────────────────────────────────────────────────────────────
if [ "${#parts[@]}" -gt 0 ]; then
  out="${parts[0]}"
  for part in "${parts[@]:1}"; do
    out="$out $(printf "${DIM}│${R}") $part"
  done
  printf '%b\n' "$out"
fi
