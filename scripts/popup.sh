#!/usr/bin/env bash
# scripts/popup.sh — reusable single-line input modal with Tab completion.
# Part of broadmand-tmux.
#
# Usage (inside a tmux display-popup -E):
#   popup.sh "<default>"
#
# Prints the chosen value to stdout.
# Exits 0 with empty stdout if cancelled (Esc or Ctrl-C), non-zero on read error.
#
# Keys:
#   Enter  — submit
#   Esc    — cancel (clears any default/input and closes the modal)
#   Tab    — file-name completion

set -euo pipefail

default="${1:-}"

# Make Esc clear the line and send EOF, so read -e exits with empty output.
# Ctrl-C is also bound to abort cleanly.
bind '"\e": "\C-a\C-k\C-d"' 2>/dev/null || true
bind '"\C-c": abort' 2>/dev/null || true

# read -e enables readline with Tab completion (filename completion by default).
# -i "$default" pre-seeds the edit buffer so the user sees it and can edit.
# -p writes the prompt to stderr (visible in the popup terminal).
if IFS= read -r -e -i "$default" -p '> ' ans; then
  printf '%s\n' "$ans"
else
  # Esc, Ctrl-C, or EOF: print nothing and exit 0 so the caller treats it as cancel.
  printf ''
  exit 0
fi
