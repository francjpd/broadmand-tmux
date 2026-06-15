#!/usr/bin/env bash
# scripts/picker.sh — choose a directory using fzf.
#
# Backed by fd (default) or zoxide. Configurable via @broadcast-picker-engine
# (values: fd | zoxide | both).
#
# Usage:
#   picker.sh            # interactive; echoes chosen path to stdout
#   picker.sh --print    # print the resolved engine + command, no fzf
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

# Where fd should start from. Pass as $1 from cd-all.sh, else default to $HOME.
_fd_root="${1:-$HOME}"

# Build the input stream based on engine choice.
# Paths are always absolute (we prepend the root) so cd-all.sh doesn't need to resolve.
build_stream_fd() {
  if command -v fd >/dev/null 2>&1; then
    fd --type=d --hidden --follow --exclude .git --base-directory "$_fd_root" . "$_fd_root" 2>/dev/null
  else
    find "$_fd_root" -type d -not -path '*/.git*' 2>/dev/null
  fi
}

build_stream_zoxide() {
  command -v zoxide >/dev/null 2>&1 || return 1
  zoxide query -l 2>/dev/null
}

run_fzf() {
  local prompt="dir> "
  fzf --prompt="$prompt" --height=100% --reverse --no-multi \
      --bind 'ctrl-/:toggle-preview' \
      --preview 'ls -la --color=always {} 2>/dev/null | head -50'
}

case "$ENGINE" in
  fd)
    chosen=$(build_stream_fd | run_fzf) || exit 0
    ;;
  zoxide)
    chosen=$(build_stream_zoxide | run_fzf) || exit 0
    ;;
  both)
    {
      build_stream_zoxide 2>/dev/null | sed 's/^/z  /'
      build_stream_fd      2>/dev/null | sed 's/^/   /'
    } | run_fzf | sed 's/^[z ]\{1,3\}//' | head -1
    ;;
  *)
    die "unknown picker engine: $ENGINE (expected fd|zoxide|both)"
    ;;
esac

[ -z "${chosen:-}" ] && exit 0
printf '%s\n' "$chosen"
