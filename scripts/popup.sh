#!/usr/bin/env bash
# scripts/popup.sh — reusable single-line input modal with Tab completion.
# Part of broadmand-tmux.
#
# Usage (inside a tmux display-popup -E):
#   popup.sh "<default>"
#
# Prints the chosen value to stdout. Empty stdout = cancelled.
#
# Keys:
#   Enter  — submit
#   Esc    — cancel
#   Tab    — file-name completion

set -euo pipefail

default="${1:-}"

# read -e enables readline with Tab completion (filename completion by default).
# -i "$default" pre-seeds the edit buffer so the user sees it and can edit.
# -p writes the prompt to stderr (visible in the popup terminal).
IFS= read -r -e -i "$default" -p '> ' ans || ans=""

printf '%s\n' "$ans"
