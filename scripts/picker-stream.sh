#!/usr/bin/env bash
# scripts/picker-stream.sh — directory stream for picker.sh.
#
# Usage:
#   picker-stream.sh [query]
#
# Empty/missing query: initial load combines the active pane's cwd
# (BROADCAST_FALLBACK_ROOT) with $HOME, so the picker is useful from
# anywhere. Duplicates are removed; cwd results come first.
#
# Non-empty query:
#   - If the typed text is an existing directory (after expanding a leading
#     ~), show that directory plus its subdirectories.
#   - Otherwise fall back to the combined cwd + $HOME list and let fzf
#     fuzzy-filter it, so partial names like "proj" still match "projects".
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

# Normalize a path: expand leading ~, resolve relative paths against the
# active pane's cwd ($root), and strip trailing slashes (except for /).
__normalize_path() {
  local p="${1:-}"
  [ -z "$p" ] && return 0
  p="${p/#\~/$HOME}"
  case "$p" in
    /*) ;;
    *)  p="$root/$p" ;;
  esac
  while [ "$p" != "${p%/}" ] && [ "$p" != "/" ]; do
    p="${p%/}"
  done
  printf '%s' "$p"
}

# Maximum directory depth for fd scans. A value of 3 means the search
# root plus two levels of subdirectories, which keeps the picker fast
# on large home directories (notably macOS with deep Library trees).
FD_MAX_DEPTH=3

__fd_dirs() {
  local base="$1"
  if [ -n "$FD_CMD" ] && [ -d "$base" ]; then
    "$FD_CMD" --type=d --hidden --follow --exclude .git \
      --max-depth "$FD_MAX_DEPTH" \
      --base-directory "$base" . "$base" 2>/dev/null
  fi
}

# Merge multiple directory streams, preserving input order and removing
# duplicates. Trailing-slash differences are normalized for dedup.
__merge_streams() {
  awk '
    function norm(p) {
      while (p != "/" && substr(p, length(p), 1) == "/") {
        p = substr(p, 1, length(p) - 1)
      }
      return p
    }
    {
      n = norm($0)
      if (n != "" && !seen[n]++) print $0
    }
  '
}

# Emit the initial combined list (cwd + $HOME) for the configured engine.
__initial_stream() {
  case "$ENGINE" in
    fd)
      {
        __fd_dirs "$root"
        __fd_dirs "$HOME"
      } | __merge_streams
      ;;
    zoxide)
      if command -v zoxide >/dev/null 2>&1; then
        zoxide query -l 2>/dev/null
      else
        {
          __fd_dirs "$root"
          __fd_dirs "$HOME"
        } | __merge_streams
      fi
      ;;
    both)
      {
        if command -v zoxide >/dev/null 2>&1; then
          zoxide query -l 2>/dev/null
        fi
        __fd_dirs "$root"
        __fd_dirs "$HOME"
      } | __merge_streams
      ;;
  esac
}

if [ -z "$query" ]; then
  __initial_stream
else
  target=$(__normalize_path "$query")
  if [ -d "$target" ]; then
    # Directory path typed: show it plus its subdirectories.
    printf '%s\n' "$target"
    __fd_dirs "$target"
  else
    # Not a directory: let fzf fuzzy-filter the initial combined list.
    __initial_stream
  fi
fi
