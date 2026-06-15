#!/usr/bin/env bash
# scripts/picker.sh — choose a directory using fzf.
#
# Usage:
#   picker.sh [active_cwd]
#   picker.sh --print
#
# Loads the directory list once via picker-stream.sh (zoxide frecent or
# active_cwd contents via fd) and lets fzf fuzzy-filter the list as the
# user types.
#
# Returns 0 with empty stdout if user cancels (Esc in fzf).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

ENGINE=$(tmux_opt @broadcast-picker-engine 'fd')

if [ "${1:-}" = "--print" ]; then
  printf 'engine=%s\n' "$ENGINE"
  exit 0
fi

# Where fd should start from for the fallback initial load.
# Passed as $1 from cd-all.sh (the active pane's cwd).
_fd_root="${1:-$HOME}"

# Export the fallback root so picker-stream.sh can read it.
export BROADCAST_FALLBACK_ROOT="$_fd_root"

run_fzf() {
  fzf --prompt="dir> " \
      --height=100% \
      --reverse \
      --no-multi \
      --preview 'ls -la --color=always {} 2>/dev/null | head -50'
}

# Initial load: picker-stream.sh with empty query, piped into fzf.
chosen=$(bash "$SCRIPT_DIR/picker-stream.sh" 2>/dev/null | run_fzf) || exit 0

[ -z "${chosen:-}" ] && exit 0
printf '%s\n' "$chosen"
