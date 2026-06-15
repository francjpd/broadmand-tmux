# defaults.sh — resolve @broadcast-* options with safe fallbacks.
# Source this from broadcast.tmux.

_broadcast__resolve() {
  local name="$1" default="$2"
  local val
  val=$(tmux show-options -gqv "$name" 2>/dev/null) || val=""
  printf '%s' "${val:-$default}"
}

# These are exposed only via tmux_opt in subprocesses. We just ensure
# they have reasonable defaults if the user never set them.
# (Subprocess scripts read them on demand; nothing to do here at source time.)

# Optional: a quick sanity check that tmux is running.
command -v tmux >/dev/null 2>&1 || {
  printf 'broadcast-tmux: tmux not found in PATH\n' >&2
  return 1 2>/dev/null || exit 1
}
