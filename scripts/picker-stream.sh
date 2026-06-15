#!/usr/bin/env bash
# scripts/picker-stream.sh — directory stream for picker.sh.
#
# Usage:
#   picker-stream.sh [query]
#
# Empty/missing query: initial load (zoxide frecent or fd fallback).
# Non-empty query: show the query itself + its subdirectories.
#
# Reads BROADCAST_FALLBACK_ROOT from env for the fd fallback root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

ENGINE=$(broadcast_picker_engine)
query="${1:-}"
root="${BROADCAST_FALLBACK_ROOT:-$HOME}"

FD_CMD=$(find_fd)

__fd_dirs() {
  local base="$1"
  if [ -n "$FD_CMD" ]; then
    "$FD_CMD" --type=d --hidden --follow --exclude .git \
      --base-directory "$base" . "$base" 2>/dev/null
  fi
}

if [ -z "$query" ]; then
  case "$ENGINE" in
    fd)
      __fd_dirs "$root"
      ;;
    zoxide)
      if command -v zoxide >/dev/null 2>&1; then
        zoxide query -l 2>/dev/null
      else
        __fd_dirs "$root"
      fi
      ;;
    both)
      {
        if command -v zoxide >/dev/null 2>&1; then
          zoxide query -l 2>/dev/null
        fi
        __fd_dirs "$root"
      } | awk '!seen[$0]++'
      ;;
  esac
else
  # Show the typed path as a selectable item, then its subdirs.
  printf '%s\n' "$query"
  __fd_dirs "$query"
fi
