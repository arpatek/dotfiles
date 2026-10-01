# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - .bashrc stub                                       │
# └──────────────────────────────────────────────────────────────┘
# Bash has no ZDOTDIR, so this path cannot be moved. The real config lives at
# $XDG_CONFIG_HOME/bash/bashrc; this exists only to reach it.
_rc="${XDG_CONFIG_HOME:-$HOME/.config}/bash/bashrc"
[ -r "$_rc" ] && . "$_rc"
unset _rc
