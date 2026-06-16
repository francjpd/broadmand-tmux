# broadmand-tmux

![broadmand-tmux logo](broadmand.png)

Broadcast a shell command to every pane of the active tmux window. Ships
with a modal-style `cd` picker and a free-form command broadcaster.

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   prefix d →   ┌── broadcast command ──────────────┐         │
│                │                                   │         │
│                │  > make test                      │         │
│                │                                   │         │
│                └───────────────────────────────────┘         │
│                                                              │
│   prefix D →   ┌── pick directory ─────────────────┐         │
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

- **`prefix d`** — broadcast a free-form shell command to every pane
  in the current window (including the active one).
  Type a command, press `Enter`, and each pane receives it.

- **`prefix D`** — pick a directory with `fzf`, then broadcast
  `cd <picked-directory>` to every pane (including the active one).
  The initial list combines the active pane's cwd with `$HOME`, so the
  picker is useful from anywhere. Type to fuzzy-filter that list. If
  the typed text is an existing directory path, the list switches to
  that directory plus its subdirectories.

Panes running excluded commands (editors, `ssh`, `htop`, …) or currently
in copy mode are skipped automatically. A short status message flashes
in the tmux status line when the broadcast finishes.

## Features

- **Broadcast any command** — `prefix d` opens an empty input; the typed
  command is sent to every pane in the active window.
- **`cd-all` picker** — `prefix D` opens an `fzf` directory picker and
  broadcasts `cd <dir>` to all panes including the active one.
- **Reusable modal primitive** — `scripts/popup.sh` is a generic single-line
  input box; future features build on it.
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

## Install with TPM

1. Add TPM if you don't have it yet:

```tmux
set -g @plugin 'tmux-plugins/tpm'
```

2. Add this plugin:

```tmux
set -g @plugin 'francjpd/broadmand-tmux'
```

3. Initialize TPM at the bottom of your `~/.config/tmux/tmux.conf`:

```tmux
run '~/.tmux/plugins/tpm/tpm'
```

4. Reload tmux config (`prefix r`) and press `prefix I` to fetch the plugin.

## Install (manual)

```sh
git clone git@github.com:francjpd/broadmand-tmux.git \
  ~/.tmux/plugins/broadmand-tmux
```

Add this to your `tmux.conf` and reload with `prefix r`:

```tmux
set -g @broadcast-run-key       'd'
set -g @broadcast-cd-picker-key 'D'
run-shell '~/.tmux/plugins/broadmand-tmux/broadmand.tmux'
```

## Configuration

| Option                          | Default                                          | Description                                  |
| ------------------------------- | ------------------------------------------------ | -------------------------------------------- |
| `@broadcast-run-key`            | `d`                                              | Prefix key for free-form command broadcast   |
| `@broadcast-cd-picker-key`      | `D`                                              | Prefix key for picker `cd`                   |
| `@broadcast-picker-engine`      | `fd`                                             | `fd`, `zoxide`, or `both`                    |
| `@broadcast-excluded`           | `vim,vi,nvim,less,man,ssh,htop,top,mc,opencode,claude,aider,continue,qwen,qwen-cli,gemini,gemini-cli,openai,ollama,copilot,codeium,anthropic,chatgpt,chatgpt-cli,sgpt,aichat,pplx,perplexity` | Comma-separated commands to skip; whitespace around entries is allowed |
| `@broadcast-pane-delay`         | `5`                                              | Milliseconds between `send-keys` ops         |

See [`examples/tmux.conf.snippet`](examples/tmux.conf.snippet) for a
drop-in config block.

## How it works

1. `run-all.sh` / `cd-all.sh` opens a tmux popup via `display-popup -E`,
   capturing stdout.
2. Inside the popup, `popup.sh` (the primitive) runs `read -e` to gather input.
3. On submit, `cd-all.sh` expands a leading `~` and invokes
   `broadcast.sh "cd <path>"` while `run-all.sh` invokes
   `broadcast.sh "<command>"`.
4. `broadcast.sh` walks all panes in the active window, skipping excluded
   commands and panes in copy mode, and sends `C-u` + literal line +
   `Enter` to each.
5. A short summary is printed to stderr, which `tmux run-shell` displays
   in the status line without cluttering the active pane.

## License

MIT.
