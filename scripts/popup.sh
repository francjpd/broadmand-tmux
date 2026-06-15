#!/usr/bin/env bash
# scripts/popup.sh — reusable single-line input modal with Tab completion.
# Part of broadmand-tmux.
#
# Usage (inside a tmux display-popup -E):
#   popup.sh "<default>"
#
# Prints the chosen value to stdout.
# Exits 0 with empty stdout if cancelled (Esc), non-zero on read error.
#
# Keys:
#   Enter  — submit
#   Esc    — cancel
#   Tab    — file-name completion

set -euo pipefail

default="${1:-}"

# Map Esc to exit cleanly. bind only affects readline within this script.
# Accept-line already submits; aborting on Esc gives a 0 exit with empty output.
bind '"\e": abort' 2>/dev/null || true

# read -e enables readline with Tab completion (filename completion by default).
# -i "$default" pre-seeds the edit buffer so the user sees it and can edit.
# -p writes the prompt to stderr (visible in the popup terminal).
if IFS= read -r -e -i "$default" -p '> ' ans; then
  printf '%s\n' "$ans"
else
  # Esc or EOF: print nothing and exit 0 so the caller sees an empty result.
  printf ''
  exit 0
fi
