#!/usr/bin/env bash
# =============================================================================
# Script Name: window-pane-count.sh
# Description: Make the tmux window label show how many panes it holds.
# Author: Juan Garcia (arpatek)
# Created: 2026-09-08
# Version: 1.0
# =============================================================================

set -eo pipefail

# ──[ Rewrite ]─────────────────────────────────────────────────────────────────
# tokyo-night-tmux hardcodes #P — the focused pane's index — into both window
# status formats. #{window_panes} is the pane count. Runs after the plugin has
# set the formats, and is idempotent, so re-sourcing tmux.conf is safe.
readonly FROM='custom-number.sh #P'
readonly TO='custom-number.sh #{window_panes}'

for option in window-status-format window-status-current-format; do
  value="$(tmux show-option -gv "$option" 2>/dev/null || true)"
  [ -n "$value" ] || continue
  tmux set-option -g "$option" "${value//$FROM/$TO}"
done
