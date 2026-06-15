#!/usr/bin/env bash
# scripts/run-all.sh — broadcast a free-form shell command to every pane
# in the active window except the active one.
#
# Usage:
#   run-all.sh
#
# Opens an empty single-line popup, then broadcasts the typed command
# via broadcast.sh (active pane is skipped).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

# display-popup -E propagates exit status but NOT stdout.
# Use a temp file to capture the popup's output.
_out=$(mktemp /tmp/broadmand-run.XXXXXX) || die "failed to create temp file"
trap "rm -f '$_out'" EXIT

tmux display-popup \
  -E -w 60% -h 15% \
  -T "broadcast command" \
  "bash '$SCRIPT_DIR/popup.sh' '' > '$_out'" || true

command=$(cat "$_out" 2>/dev/null || true)
[ -z "$command" ] && { tmux display-message "run-all: cancelled"; exit 0; }

bash "$SCRIPT_DIR/broadcast.sh" "$command"
