#!/usr/bin/env bash
# scripts/cd-all.sh — broadcast `cd <path>` to every pane in the active window.
#
# Usage:
#   cd-all.sh freeform   # popup pre-filled with active pane's cwd
#   cd-all.sh picker     # open fzf picker first, then popup pre-filled with the pick
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

POPUP_W=$(tmux_opt @broadcast-popup-width '80%')
POPUP_H=$(tmux_opt @broadcast-popup-height '30%')

# Active pane's cwd is a good default for freeform mode.
active_cwd=$(tmux display-message -p '#{pane_current_path}')

if [ "$mode" = "picker" ]; then
  picked=$(tmux display-popup \
    -E -w 90% -h 90% \
    -T "pick directory" \
    "bash '$SCRIPT_DIR/picker.sh'") || true
  [ -z "$picked" ] && { tmux display-message "cd-all: cancelled"; exit 0; }
  default="$picked"
else
  default="$active_cwd"
fi

# Open the popup and capture the user's chosen value on stdout.
chosen=$(tmux display-popup \
  -E -w "$POPUP_W" -h "$POPUP_H" \
  -T "cd all panes" \
  "bash '$SCRIPT_DIR/popup.sh' 'cd all panes →' $(printf '%q' "$default")") || true

if [ -z "$chosen" ]; then
  tmux display-message "cd-all: cancelled"
  exit 0
fi

# Resolve ~, $HOME, relative paths; verify it's a directory.
target=$(resolve_dir "$chosen" 2>/dev/null) || {
  tmux display-message "cd-all: not a directory: $chosen"
  exit 1
}

# Build the shell line, safely quoted.
quoted=$(shell_quote "$target")
line="cd $quoted"

# Hand off to the broadcast engine.
bash "$SCRIPT_DIR/broadcast.sh" "$line"
