# broadmand-tmux — entrypoint sourced from the user's tmux.conf.
#
# TPM install:
#   set -g @plugin 'francjpd/broadmand-tmux'
#   run '~/.tmux/plugins/tpm/tpm'
#
# Manual install:
#   run-shell "~/.tmux/plugins/broadmand-tmux/broadmand.tmux"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# shellcheck source=defaults.sh
. "$CURRENT_DIR/defaults.sh"

# shellcheck source=keybinds.sh
. "$CURRENT_DIR/keybinds.sh"
