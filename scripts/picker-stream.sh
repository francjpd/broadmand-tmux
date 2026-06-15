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

ENGINE=$(tmux_opt @broadcast-picker-engine 'fd')
query="${1:-}"
root="${BROADCAST_FALLBACK_ROOT:-$HOME}"

if [ -z "$query" ]; then
  case "$ENGINE" in
    fd)
      fd --type=d --hidden --follow --exclude .git \
         --base-directory "$root" . "$root" 2>/dev/null
      ;;
    zoxide|both)
      if command -v zoxide >/dev/null 2>&1; then
        zoxide query -l 2>/dev/null
      else
        fd --type=d --hidden --follow --exclude .git \
           --base-directory "$root" . "$root" 2>/dev/null
      fi
      ;;
  esac
else
  # Show the typed path as a selectable item, then its subdirs.
  printf '%s\n' "$query"
  fd --type=d --hidden --follow --exclude .git \
     --base-directory "$query" . "$query" 2>/dev/null
fi
