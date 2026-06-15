#!/usr/bin/env bash
# scripts/cd-all.sh — broadcast `cd <path>` to every pane in the active window.
#
# Usage:
#   cd-all.sh freeform   # popup with Tab-completable input, pre-filled with cwd
#   cd-all.sh picker     # fzf directory picker → broadcast directly
#   cd-all.sh            # default: freeform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

mode="${1:-freeform}"
case "$mode" in
  freeform|picker) ;;
  *) die "unknown mode: $mode (expected freeform|picker)" ;;
esac

active_cwd=$(tmux display-message -p '#{pane_current_path}')

if [ "$mode" = "picker" ]; then
  # Single popup: open fzf, user picks a path, immediately broadcast.
  picked=$(tmux display-popup \
    -E -w 60% -h 40% \
    -T "pick directory" \
    "bash '$SCRIPT_DIR/picker.sh'") || true
  [ -z "$picked" ] && { tmux display-message "cd-all: cancelled"; exit 0; }
  target="$picked"
else
  # Freeform popup with read -e -i and Tab-completion.
  chosen=$(tmux display-popup \
    -E -w 40% -h 10% \
    -T "cd all panes" \
    "bash '$SCRIPT_DIR/popup.sh' $(printf '%q' "$active_cwd")") || true
  [ -z "$chosen" ] && { tmux display-message "cd-all: cancelled"; exit 0; }
  # Expand leading ~ but leave relative paths as-is (each pane resolves them).
  target="${chosen/#\~/$HOME}"
fi

# Build the shell line, safely quoted.
quoted=$(shell_quote "$target")
line="cd $quoted"

# Broadcast to ALL panes including the active one.
bash "$SCRIPT_DIR/broadcast.sh" "$line" --include-active
