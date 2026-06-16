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
# macOS ships bash 3.2, whose read builtin does not support -i; using it
# there makes the popup exit immediately. Omit -i on bash < 4.
# -p writes the prompt to stderr (visible in the popup terminal).
if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
  if IFS= read -r -e -i "$default" -p '> ' ans; then
    printf '%s\n' "$ans"
  else
    printf ''
    exit 0
  fi
else
  if IFS= read -r -e -p '> ' ans; then
    printf '%s\n' "$ans"
  else
    printf ''
    exit 0
  fi
fi
