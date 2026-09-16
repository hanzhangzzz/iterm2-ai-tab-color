# iTerm2 AI Tab Color

**Color the whole iTerm2 tab by how long a Claude Code or OpenAI Codex session has been waiting for you.**

[中文说明](README.zh-CN.md)

![iTerm2 tabs changing from green to yellow to red as AI sessions wait](assets/demo.gif)

Run several AI coding agents in parallel and the bottleneck stops being the terminal. It becomes your attention. A notification tells you *that* an agent finished. This tool tells you *which* tabs are waiting and *how long* they have been waiting, on the tab itself, until you come back.

| Color | Meaning |
|---|---|
| Green | Claude Code or Codex just finished and is waiting |
| Yellow | The session has waited longer than 10 minutes |
| Red | The session has waited longer than 20 minutes |
| White | The tab is active, processing, or has no waiting session |

Only inactive tabs are colored. The tab you are looking at stays white, so every colored tab is an unread badge. Multiple panes in one tab share the most urgent color, so a red waiting pane cannot be hidden behind an active one.

## Why not the built-in iTerm2 integration?

iTerm2 ships a [Claude Code integration](https://iterm2.com/claude-code-integration.html) that shows a colored dot and a subtitle per session. It answers "what state is this session in". This tool answers "which tab should I go to next". The two can run side by side.

| | iTerm2 built-in integration | Alert plugins ([cc-iterm2-tab-alert](https://github.com/STRML/cc-iterm2-tab-alert), [tab-status](https://github.com/JasperSui/claude-code-iterm2-tab-status)) | iTerm2 AI Tab Color |
|---|---|---|---|
| Where it shows | Dot and subtitle on the tab | Tab title emoji; tab flashes orange when input is needed | Whole tab background color, kept until you return |
| Escalates with waiting time | No | No | Green → yellow → red |
| OpenAI Codex CLI | No, Claude Code only | No | Yes, same hook and daemon |
| Split panes in one tab | Per session | Per session | Aggregated: the tab shows its most urgent pane |
| Currently focused tab | Shows status | Alert clears on focus | Always white |
| Runs as | Built into iTerm2 | Claude Code plugin | Hooks + one LaunchAgent daemon |

Comparison reflects the projects' documentation as of September 2026.

## Features

- Supports Claude Code and OpenAI Codex CLI
- Green → yellow → red escalation based on waiting time
- Correct tab-level aggregation across split panes
- Keeps the currently focused tab white
- Clears stale state when a session closes or returns to the shell
- Reconnects automatically after iTerm2 restarts or its websocket disconnects
- Stores all state locally; no telemetry, upload, or network service
- Installs through one script and runs as a macOS LaunchAgent

## Requirements

- macOS with [iTerm2](https://iterm2.com/)
- Python 3.10+
- Claude Code and/or OpenAI Codex CLI

## Install

```bash
git clone https://github.com/hanzhangzzz/iterm2-ai-tab-color.git
cd iterm2-ai-tab-color
pip3 install iterm2
./install.sh
```

The installer:

- copies hooks to `~/.claude/hooks/` and `~/.codex/hooks/`;
- installs a stable runtime under `~/.iterm2-ai-tab-color/app/`;
- preserves an existing `~/.iterm2-ai-tab-color/config.sh` byte-for-byte;
- refuses to overwrite same-named hook, runtime, or plist files not marked as managed by this project;
- registers Claude Code and Codex hook events;
- creates a real LaunchAgent plist and starts the daemon;
- backs up JSON settings before changing them.

Preview every change without writing files:

```bash
./install.sh --dry-run
```

Install for one agent only:

```bash
./install.sh --no-codex
./install.sh --no-claude
```

## Verify

```bash
launchctl print gui/$(id -u)/io.github.hanzhangzzz.iterm2-ai-tab-color
tail -f ~/.iterm2-ai-tab-color/state/daemon.log
```

Open Claude Code or Codex in iTerm2, ask a question, then switch to another tab. When the response finishes, the inactive tab should turn green.

## Configure

Edit `~/.iterm2-ai-tab-color/config.sh`:

```bash
THRESHOLD_YELLOW=10
THRESHOLD_RED=20

COLOR_GREEN_R=30;   COLOR_GREEN_G=180;  COLOR_GREEN_B=30
COLOR_YELLOW_R=220; COLOR_YELLOW_G=160; COLOR_YELLOW_B=0
COLOR_RED_R=200;    COLOR_RED_G=40;      COLOR_RED_B=40

POLL_INTERVAL=30
CONCURRENT_TARGET=3
```

Restart the daemon after editing:

```bash
launchctl kickstart -k gui/$(id -u)/io.github.hanzhangzzz.iterm2-ai-tab-color
```

## How it works

```text
Claude Code / Codex hook event
            │
            ▼
iterm2_ai_tab_color_hook.sh
            │ writes local session state
            ▼
~/.iterm2-ai-tab-color/state/*.json
            │
            ▼
iterm2_ai_tab_color_daemon.py
            │ iTerm2 Python API
            ▼
       iTerm2 tab color
```

The hook gives immediate green/reset feedback. A single daemon owns long-running color updates, aggregates split panes, escalates waiting time, removes stale sessions, and keeps the active tab white. The daemon starts iTerm2's Python API with retry enabled so it can reconnect after iTerm2 restarts.

Everything stays on your Mac. The project does not persist or transmit credentials and does not call Claude/OpenAI usage APIs. For Codex sessions inside tmux, the hook inspects local process metadata and extracts only `ITERM_SESSION_ID` so it can map the tmux client back to the visible iTerm2 pane.

## Uninstall

```bash
./uninstall.sh
```

This removes the hooks, installed runtime, LaunchAgent, and JSON hook entries. Configuration, state, and logs are preserved by default. Remove state and logs too with:

```bash
./uninstall.sh --purge-state
```

## Development

```bash
bash -n install.sh uninstall.sh demo_record.sh iterm2_ai_tab_color_hook.sh scripts/e2e-install-verify.sh scripts/prepare-demo.sh
python3 -m py_compile iterm2_ai_tab_color_daemon.py test_daemon.py
python3 -m unittest test_daemon.py
scripts/e2e-install-verify.sh
```

## License

[MIT](LICENSE)
