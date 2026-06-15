# broadcast-tmux

Run a shell command in every pane of the active tmux window. Ships with a
modal-style `cd` action that changes directory across all your splits at
once.

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   prefix d →  ┌── cd all panes ────────────────────┐         │
│                │                                   │         │
│                │  > /home/user/projects            │         │
│                │                                   │         │
│                └───────────────────────────────────┘         │
│                                                              │
│   prefix D →  ┌── pick directory ──────────────────┐         │
│                │   .config/                        │         │
│                │   projects/                       │         │
│                │   Documents/                      │         │
│                │ ▸ Downloads/                      │         │
│                │   …                               │         │
│                └───────────────────────────────────┘         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Quick start

- **`prefix d`** — change directory in every pane of the current window.
  A popup opens pre-filled with the active pane's current directory.
  Type a path, press `Enter`, and every eligible pane runs `cd <path>`.

- **`prefix D`** — pick a directory with `fzf`, then broadcast it the
  same way. The list is loaded once from `fd` or `zoxide` and filtered
  as you type.

Panes running excluded commands (editors, `ssh`, `htop`, …) or currently
in copy mode are skipped automatically. A short status message flashes
in the tmux status line when the broadcast finishes.

## Features

- **`cd-all`** — broadcast `cd <path>` to every pane in the active window.
  - Free-form: `prefix d` opens an input pre-filled with the active pane's cwd.
  - Picker: `prefix D` opens an `fzf` directory picker and broadcasts the pick.
- **Reusable modal primitive** — `scripts/popup.sh` is a generic single-line
  input box; future features (env vars, "run command in all panes", etc.)
  build on it.
- **Pluggable picker** — backed by `fd` (default), `zoxide`, or both.
- **Safe by default** — skips panes running editors (`vim`, `vi`, `nvim`,
  `less`, `man`, `mc`), `ssh`, system monitors (`htop`, `top`), and panes
  currently in copy mode. The list is configurable.

## Requirements

- tmux
- bash
- `fzf` (used by the directory picker)
- `fd` or `zoxide` (picker engine; install the one matching
  `@broadcast-picker-engine`)

## Install (TPM)

Add to your `~/.config/tmux/tmux.conf`:

```tmux
set -g @plugin 'you/broadcast-tmux'
set -g @broadcast-cd-key        'd'
set -g @broadcast-cd-picker-key 'D'
run-shell "~/.tmux/plugins/broadcast-tmux/broadcast.tmux"
```

Then press `prefix I` to fetch the plugin.

## Install (manual)

```sh
git clone https://github.com/you/broadcast-tmux \
  ~/.tmux/plugins/broadcast-tmux
```

Add the `run-shell` line above to your `tmux.conf` and reload with
`prefix r`.

## Configuration

| Option                          | Default                                          | Description                                  |
| ------------------------------- | ------------------------------------------------ | -------------------------------------------- |
| `@broadcast-cd-key`             | `d`                                              | Prefix key for free-form `cd`                |
| `@broadcast-cd-picker-key`      | `D`                                              | Prefix key for picker `cd`                   |
| `@broadcast-picker-engine`      | `fd`                                             | `fd`, `zoxide`, or `both`                    |
| `@broadcast-excluded`           | `vim,vi,nvim,less,man,ssh,htop,top,mc`           | Comma-separated commands to skip             |
| `@broadcast-pane-delay`         | `5`                                              | Milliseconds between `send-keys` ops         |

See [`examples/tmux.conf.snippet`](examples/tmux.conf.snippet) for a
drop-in config block.

## How it works

1. `cd-all.sh` opens a tmux popup via `display-popup -E`, capturing stdout.
2. Inside the popup, `popup.sh` (the primitive) runs `read -e` to gather input.
3. On submit, `cd-all.sh` expands a leading `~` and invokes
   `broadcast.sh "cd <path>"`.
4. `broadcast.sh` walks all panes in the active window, skipping excluded
   commands and panes in copy mode, and sends `C-u` + literal `cd …` +
   `Enter` to each.
5. A short summary is printed to stderr, which `tmux run-shell` displays
   in the status line without cluttering the active pane.

## Project layout

```
broadcast-tmux/
  broadcast.tmux         # entrypoint; source from your tmux.conf
  defaults.sh            # @-option fallbacks
  keybinds.sh            # all `bind` lines (override after sourcing)
  scripts/
    util.sh              # shared helpers
    popup.sh             # the reusable input modal primitive
    picker.sh            # fzf-backed directory picker
    picker-stream.sh     # directory stream for the picker
    broadcast.sh         # the engine
    cd-all.sh            # the user-facing feature
  examples/
    tmux.conf.snippet    # drop-in install block
  README.md
  LICENSE
```

## Testing in isolation

```sh
# Engine dry-run (prints what it would send, sends nothing):
bash scripts/broadcast.sh "cd /tmp" --dry-run

# Picker engine discovery:
bash scripts/picker.sh --print

# Popup (interactive; requires a real terminal):
tmux display-popup -E -w 60% -h 20% \
  -T "test" "bash scripts/popup.sh '/tmp'"

# cd-all end-to-end:
prefix d
# (type a path, press Enter)
```

## Future features

Built on the same `popup.sh` + `broadcast.sh` primitives:

- Broadcast environment variables: `prefix E` → `NAME=VALUE` → sent as `export NAME=VALUE` to each pane.
- Broadcast a one-off command: `prefix !` → popup → executed in all panes.
- Per-window sync: optionally include other windows in the current session.

## License

MIT.
