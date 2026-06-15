#!/usr/bin/env bash
# scripts/util.sh — shared helpers for broadcast-tmux
# Source this from sibling scripts. Not executable on its own.

# Resolve plugin install directory from the path of the calling script.
_broadcast__plugin_dir() {
  local src="${BASH_SOURCE[1]:-$0}"
  dirname "$(readlink -f "$src")/.." | xargs -I{} dirname {}
}

# Print an error to tmux status line and exit non-zero.
die() {
  local msg="$1"
  command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ] && \
    tmux display-message "broadcast-tmux: $msg"
  command -v tmux >/dev/null 2>&1 && [ -z "${TMUX:-}" ] && \
    tmux display-message "broadcast-tmux: $msg"
  printf 'broadcast-tmux: %s\n' "$msg" >&2
  exit 1
}

# Read a tmux @-option from global scope, fall back to default.
tmux_opt() {
  local name="$1" default="$2"
  local val
  val=$(tmux show-options -gqv "$name" 2>/dev/null) || val=""
  printf '%s' "${val:-$default}"
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
pane_excluded() {
  local pane_id="$1" excluded="$2"
  local cmd
  cmd=$(pane_command "$pane_id")
  [ -z "$cmd" ] && { echo yes; return; }
  local IFS=','
  set -- $excluded
  for x in "$@"; do
    if [ "$x" = "$cmd" ]; then
      echo yes
      return
    fi
  done
  echo no
}

# Quote a string for safe inclusion as a single shell argument.
shell_quote() {
  printf %q "$1"
}

# Send a literal line to a pane, clearing any half-typed input first.
# Honors PANE_DELAY_MS between operations.
send_to_pane() {
  local pane_id="$1" line="$2" delay_ms="${PANE_DELAY_MS:-5}"
  tmux send-keys -t "$pane_id" C-u
  [ "$delay_ms" -gt 0 ] 2>/dev/null && sleep "$(awk "BEGIN{print $delay_ms/1000}")"
  tmux send-keys -t "$pane_id" -l -- "$line"
  [ "$delay_ms" -gt 0 ] 2>/dev/null && sleep "$(awk "BEGIN{print $delay_ms/1000}")"
  tmux send-keys -t "$pane_id" Enter
  [ "$delay_ms" -gt 0 ] 2>/dev/null && sleep "$(awk "BEGIN{print $delay_ms/1000}")"
}

# Resolve ~ and $HOME in a path; ensure absolute; verify it is a directory.
resolve_dir() {
  local p="$1"
  [ -z "$p" ] && return 1
  p="${p/#\~/$HOME}"
  case "$p" in
    /*) ;;
    *) p="$PWD/$p" ;;
  esac
  [ -d "$p" ] || return 2
  printf '%s\n' "$p"
}
