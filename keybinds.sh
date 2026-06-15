# keybinds.sh — emit the keybinds. Sourced from broadcast.tmux.
# Users can override by re-binding in their own tmux.conf after the plugin loads.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_cd_key=$(tmux show-options -gqv @broadcast-cd-key 2>/dev/null)
_cd_key="${_cd_key:-d}"

_picker_key=$(tmux show-options -gqv @broadcast-cd-picker-key 2>/dev/null)
_picker_key="${_picker_key:-D}"

bind "$_cd_key"        run-shell "bash '$PLUGIN_DIR/scripts/cd-all.sh' freeform"
bind "$_picker_key"    run-shell "bash '$PLUGIN_DIR/scripts/cd-all.sh' picker"
