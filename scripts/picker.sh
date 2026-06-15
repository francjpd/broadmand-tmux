#!/usr/bin/env bash
# scripts/picker.sh — choose a directory using fzf with dynamic loading.
#
# Usage:
#   picker.sh [active_cwd]
#   picker.sh --print
#
# Initial load: zoxide frecent (most-used) paths; falls back to
# active_cwd contents via fd if zoxide is not installed.
#
# Dynamic load: as the user types, fzf's change:reload binding
# re-runs stream_dirs, which shows the typed path itself plus
# its subdirectories. Pressing Enter on the typed path selects
# it directly; navigating to a subdir and pressing Enter
# selects that subdir.
#
# Returns 0 with empty stdout if user cancels (Esc in fzf).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

ENGINE=$(tmux_opt @broadcast-picker-engine 'zoxide')

if [ "${1:-}" = "--print" ]; then
  printf 'engine=%s\n' "$ENGINE"
  exit 0
fi

# Where fd should start from for the fallback initial load.
# Passed as $1 from cd-all.sh (the active pane's cwd).
_fd_root="${1:-$HOME}"

# The stream function: called by fzf for both the initial load and
# every keystroke (via change:reload). Exported so fzf's subshell
# can invoke it.
#
#   stream_dirs ""   -> initial: zoxide frecent or fd fallback
#   stream_dirs "X"  -> dynamic: "X" itself + subdirs of X
stream_dirs() {
  local query="$1"
  if [ -z "$query" ]; then
    case "$ENGINE" in
      fd)
        fd --type=d --hidden --follow --exclude .git \
           --base-directory "$_fd_root" . "$_fd_root" 2>/dev/null
        ;;
      zoxide|both)
        if command -v zoxide >/dev/null 2>&1; then
          zoxide query -l 2>/dev/null
        else
          fd --type=d --hidden --follow --exclude .git \
             --base-directory "$_fd_root" . "$_fd_root" 2>/dev/null
        fi
        ;;
      *)
        return 1
        ;;
    esac
  else
    # Show the typed path as a selectable item, then its subdirs.
    printf '%s\n' "$query"
    fd --type=d --hidden --follow --exclude .git \
       --base-directory "$query" . "$query" 2>/dev/null
  fi
}

export -f stream_dirs
export _fd_root ENGINE

run_fzf() {
  fzf --prompt="dir> " \
      --height=100% \
      --reverse \
      --no-multi \
      --header 'enter: select · type to browse subdirs' \
      --bind 'change:reload(stream_dirs "{q}" 2>/dev/null || true)' \
      --preview 'ls -la --color=always {} 2>/dev/null | head -50'
}

# Initial load: stream_dirs with empty query, piped into fzf.
chosen=$(stream_dirs "" | run_fzf) || exit 0

[ -z "${chosen:-}" ] && exit 0
printf '%s\n' "$chosen"
