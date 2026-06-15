#!/usr/bin/env bash
# scripts/popup.sh — reusable single-line input modal.
#
# This is the primitive on which other features are built.
#
# Usage (inside a tmux display-popup -E):
#   popup.sh "<title>" "<default>" [prefill-only]
#
# Prints the chosen value to stdout. Empty stdout = cancelled.
#
# Keys (handled by the caller's `read` loop):
#   Enter  — submit current line
#   Esc    — cancel (exits 130, caller sees empty stdout)
#   C-c    — cancel
#
# In picker-style flows, the caller pre-seeds <default> with a path
# chosen from a directory picker. This keeps the popup itself trivial.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

title="${1:-input}"
default="${2:-}"

# Render the prompt area. We keep it minimal so the popup is a
# single visible input line.
printf '\033[2J\033[H' >/dev/tty
printf '\033[1;36m%s\033[0m\n\n' "$title" >/dev/tty
printf '  \033[1;34m>\033[0m ' >/dev/tty

# Pre-populate the input buffer. `read -e -i` does not exist portably,
# so we emulate it: print the default, then read with editing enabled.
if [ -n "$default" ]; then
  printf '%s' "$default" >/dev/tty
fi

# Use a one-shot read. The shell handles line editing, history, and Esc.
IFS= read -r -e ans < /dev/tty || ans=""
rc=$?

# Non-zero exit with empty input ⇒ user pressed Esc/C-c.
if [ $rc -ne 0 ] && [ -z "$ans" ]; then
  exit 130
fi

# Echo the chosen value to stdout for the caller to capture.
printf '%s\n' "$ans"
