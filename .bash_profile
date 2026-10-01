# ┌──────────────────────────────────────────────────────────────┐
# │ arpatek - .bash_profile stub                                 │
# └──────────────────────────────────────────────────────────────┘
# Login shells. Bash reads this instead of .bashrc, never both, which is why
# the real profile sources the rc itself.
_profile="${XDG_CONFIG_HOME:-$HOME/.config}/bash/bash_profile"
[ -r "$_profile" ] && . "$_profile"
unset _profile
