#!/usr/bin/env bash
# scripts/broadcast.sh — run a shell line in every pane of the active window.
# Part of broadmand-tmux.
#
# Usage:
#   broadcast.sh "<shell-line>" [--include-active] [--dry-run]
#
# Skips panes whose current command is in the @broadcast-excluded list
# and panes that are currently in copy mode.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=util.sh
. "$SCRIPT_DIR/util.sh"

[ $# -ge 1 ] || die "usage: broadcast.sh <shell-line> [--include-active] [--dry-run]"

line="$1"; shift
include_active=0
dry_run=0
for a in "$@"; do
  case "$a" in
    --include-active) include_active=1 ;;
    --dry-run)        dry_run=1 ;;
    *) die "unknown flag: $a" ;;
  esac
done

EXCLUDED=$(tmux_opt @broadcast-excluded 'vim,vi,nvim,less,man,ssh,htop,top,mc')
PANE_DELAY_MS=$(tmux_opt @broadcast-pane-delay '5')
export PANE_DELAY_MS

active_id=$(active_pane_id)
sent=0
skipped=0

for pid in $(active_pane_ids); do
  if [ "$pid" != "$active_id" ] || [ "$include_active" = "1" ]; then
    : # keep going
  else
    skipped=$((skipped+1))
    printf '[skip ] pane=%s reason=active-pane\n' "$pid"
    continue
  fi

  ex=$(pane_excluded "$pid" "$EXCLUDED")
  if [ "$ex" = "yes" ]; then
    skipped=$((skipped+1))
    cmd=$(pane_command "$pid")
    printf '[skip ] pane=%s reason=excluded(%s)\n' "$pid" "$cmd"
    continue
  fi

  if [ "$(pane_in_mode "$pid")" = "yes" ]; then
    skipped=$((skipped+1))
    printf '[skip ] pane=%s reason=in-copy-mode\n' "$pid"
    continue
  fi

  if [ "$dry_run" = "1" ]; then
    printf '[send ] pane=%s line=%q\n' "$pid" "$line"
    sent=$((sent+1))
    continue
  fi

  send_to_pane "$pid" "$line"
  sent=$((sent+1))
done

# Return focus to the originally active pane.
tmux select-pane -t "$active_id" >/dev/null 2>&1 || true

printf '[done ] sent=%d skipped=%d\n' "$sent" "$skipped" >&2
