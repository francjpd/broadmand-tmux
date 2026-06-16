#!/usr/bin/env bash
# scripts/util.sh — shared helpers for broadmand-tmux
# Source this from sibling scripts. Not executable on its own.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../defaults.sh
. "$SCRIPT_DIR/../defaults.sh"

# Print an error to tmux status line and exit non-zero.
die() {
  local msg="$1"
  if command -v tmux >/dev/null 2>&1; then
    tmux display-message "broadmand-tmux: $msg"
  fi
  printf 'broadmand-tmux: %s\n' "$msg" >&2
  exit 1
}

# Read a tmux @-option from global scope, fall back to default.
tmux_opt() {
  local name="$1" default="$2"
  local val
  val=$(tmux show-options -gqv "$name" 2>/dev/null) || val=""
  printf '%s' "${val:-$default}"
}

# Option accessors using the centralized defaults from defaults.sh.
broadcast_run_key() {
  tmux_opt "$BROADCAST_RUN_KEY_OPTION" "$BROADCAST_RUN_KEY_DEFAULT"
}

broadcast_cd_picker_key() {
  tmux_opt "$BROADCAST_CD_PICKER_KEY_OPTION" "$BROADCAST_CD_PICKER_KEY_DEFAULT"
}

broadcast_picker_engine() {
  tmux_opt "$BROADCAST_PICKER_ENGINE_OPTION" "$BROADCAST_PICKER_ENGINE_DEFAULT"
}

broadcast_excluded() {
  tmux_opt "$BROADCAST_EXCLUDED_OPTION" "$BROADCAST_EXCLUDED_DEFAULT"
}

broadcast_pane_delay() {
  tmux_opt "$BROADCAST_PANE_DELAY_OPTION" "$BROADCAST_PANE_DELAY_DEFAULT"
}

# Get all pane IDs in the active window, one per line.
active_pane_ids() {
  local wid
  wid=$(tmux display-message -p '#{window_id}')
  tmux list-panes -t "$wid" -F '#{pane_id}'
}

# Get the active pane id.
active_pane_id() {
  tmux display-message -p '#{pane_id}'
}

# Get the working command of a pane (e.g. "zsh", "vim").
pane_command() {
  tmux display-message -p -t "$1" '#{pane_current_command}' 2>/dev/null
}

# Is the pane currently in copy mode? Echoes yes/no.
pane_in_mode() {
  local in
  in=$(tmux display-message -p -t "$1" '#{pane_in_mode}' 2>/dev/null)
  [ "$in" = "1" ] && echo yes || echo no
}

# Is the pane's command in the excluded list? Echoes yes/no.
# Entries are comma-separated; surrounding whitespace is trimmed.
pane_excluded() {
  local pane_id="$1" excluded="$2"
  local cmd x
  cmd=$(pane_command "$pane_id")
  [ -z "$cmd" ] && { echo yes; return; }

  local IFS=','
  for x in $excluded; do
    x="${x#${x%%[![:space:]]*}}"   # trim leading whitespace
    x="${x%${x##*[![:space:]]}}"  # trim trailing whitespace
    [ "$x" = "$cmd" ] || [ "$x" = "${cmd%%.*}" ] && { echo yes; return; }
  done
  echo no
}

# Quote a string using single-quote escaping.
# Each embedded single-quote is replaced with '\''  (end literal, add quote, resume literal).
# The whole string is wrapped in single quotes so the shell preserves spaces/special chars.
# This is compatible with zoxide, zsh, and bash.
shell_quote() {
  local s="$1"
  # Escape embedded single quotes: '  →  '\''
  s=${s//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

# Return the number of seconds to sleep for the configured pane delay.
__pane_delay_seconds() {
  local delay_ms="${PANE_DELAY_MS:-5}"
  if [[ "$delay_ms" =~ ^[0-9]+$ ]] && [ "$delay_ms" -gt 0 ]; then
    awk "BEGIN{print $delay_ms/1000}"
  else
    printf '0\n'
  fi
}

# Send a literal line to a pane, clearing any half-typed input first.
# Honors PANE_DELAY_MS between operations.
send_to_pane() {
  local pane_id="$1" line="$2"
  local delay_sec
  delay_sec=$(__pane_delay_seconds)

  tmux send-keys -t "$pane_id" C-u
  [ "$delay_sec" != "0" ] && sleep "$delay_sec"
  tmux send-keys -t "$pane_id" -l -- "$line"
  [ "$delay_sec" != "0" ] && sleep "$delay_sec"
  tmux send-keys -t "$pane_id" Enter
  [ "$delay_sec" != "0" ] && sleep "$delay_sec"
}

# Find the fd executable. On Debian/Ubuntu it may be installed as fdfind.
find_fd() {
  if command -v fd >/dev/null 2>&1; then
    printf '%s\n' "fd"
  elif command -v fdfind >/dev/null 2>&1; then
    printf '%s\n' "fdfind"
  else
    printf '%s\n' ""
  fi
}
