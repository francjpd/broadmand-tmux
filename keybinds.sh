#!/usr/bin/env bash
# keybinds.sh — emit the keybinds. Run via `run-shell` from broadcast.tmux.
# Users can override by re-binding in their own tmux.conf after the plugin loads.
# (Note: this script is invoked as a subshell via `run-shell`, so all tmux
# commands are prefixed with `tmux` explicitly.)

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_cd_key=$(tmux show-options -gqv @broadcast-cd-key 2>/dev/null)
_cd_key="${_cd_key:-d}"

_picker_key=$(tmux show-options -gqv @broadcast-cd-picker-key 2>/dev/null)
_picker_key="${_picker_key:-D}"

# Unbind first so the user can override after the plugin loads.
tmux unbind-key -T prefix "$_cd_key"     2>/dev/null || true
tmux unbind-key -T prefix "$_picker_key" 2>/dev/null || true

tmux bind-key -T prefix "$_cd_key"     run-shell "bash '$PLUGIN_DIR/scripts/cd-all.sh' freeform"
tmux bind-key -T prefix "$_picker_key" run-shell "bash '$PLUGIN_DIR/scripts/cd-all.sh' picker"
