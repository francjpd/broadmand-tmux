# defaults.sh — sanity check for broadmand-tmux.
# Sourced by broadmand.bash.

# Ensure tmux is available. The actual option defaults live in util.sh::tmux_opt().
command -v tmux >/dev/null 2>&1 || {
  printf 'broadmand-tmux: tmux not found in PATH\n' >&2
  return 1 2>/dev/null || exit 1
}
