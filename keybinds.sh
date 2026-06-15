#!/usr/bin/env bash
# keybinds.sh — emit the keybinds. Run via `run-shell` from broadmand.tmux.
# Users can override by re-binding in their own tmux.conf after the plugin loads.
# (Note: this script is invoked as a subshell via `run-shell`, so all tmux
# commands are prefixed with `tmux` explicitly.)

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=defaults.sh
. "$PLUGIN_DIR/defaults.sh"

_run_key=$(tmux show-options -gqv "$BROADCAST_RUN_KEY_OPTION")
_run_key="${_run_key:-$BROADCAST_RUN_KEY_DEFAULT}"

_picker_key=$(tmux show-options -gqv "$BROADCAST_CD_PICKER_KEY_OPTION")
_picker_key="${_picker_key:-$BROADCAST_CD_PICKER_KEY_DEFAULT}"

# Unbind first so the user can override after the plugin loads.
tmux unbind-key -T prefix "$_run_key"    2>/dev/null || true
tmux unbind-key -T prefix "$_picker_key" 2>/dev/null || true

tmux bind-key -T prefix "$_run_key"    run-shell "bash '$PLUGIN_DIR/scripts/run-all.sh'"
tmux bind-key -T prefix "$_picker_key" run-shell "bash '$PLUGIN_DIR/scripts/cd-all.sh' picker"
