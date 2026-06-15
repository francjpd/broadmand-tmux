# broadcast.tmux — entrypoint sourced from the user's tmux.conf.
#
# Add this to your tmux.conf:
#   set -g @plugin 'you/broadcast-tmux'
#   run-shell "~/.tmux/plugins/broadcast-tmux/broadcast.tmux"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# shellcheck source=defaults.sh
. "$CURRENT_DIR/defaults.sh"

# shellcheck source=keybinds.sh
. "$CURRENT_DIR/keybinds.sh"
