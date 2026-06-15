# broadmand-tmux — entrypoint sourced from the user's tmux.conf.
#
# TPM install:
#   set -g @plugin 'francjpd/broadmand-tmux'
#   run '~/.tmux/plugins/tpm/tpm'
#
# Manual install:
#   run-shell "~/.tmux/plugins/broadmand-tmux/broadmand.tmux"
#
# This file must be POSIX-shell compatible because tmux run-shell uses
# the user's default shell (often dash on Debian/Ubuntu). It simply
# locates bash and re-execs the bash entrypoint.

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Prefer bash from PATH; fall back to common absolute paths.
BASH_CMD=""
for cmd in bash /usr/bin/bash /bin/bash; do
  if command -v "$cmd" >/dev/null 2>&1; then
    BASH_CMD="$cmd"
    break
  fi
done

if [ -z "$BASH_CMD" ]; then
  printf 'broadmand-tmux: bash is required but not found\n' >&2
  return 1 2>/dev/null || exit 1
fi

# shellcheck source=broadmand.bash
. "$CURRENT_DIR/broadmand.bash"
