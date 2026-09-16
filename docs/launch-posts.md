# Launch posts

发布是不可逆动作，每条稿子由人审核后手动发出。发出后把链接记到本文件末尾的"已发布"表里。

## Show HN

**Title**（≤ 80 字符）

```
Show HN: Color iTerm2 tabs by how long Claude Code/Codex sessions have waited
```

**URL**

```
https://github.com/hanzhangzzz/iterm2-ai-tab-color
```

**First comment**

```
I run 3–6 Claude Code and Codex sessions in parallel in iTerm2. The terminal was never the bottleneck; my attention was. A notification tells me *that* something finished, then disappears. What I wanted was the tab bar itself to show which sessions are waiting and for how long.

So: hooks on Stop / PreToolUse / UserPromptSubmit write a tiny local state file, and one LaunchAgent daemon talks to the iTerm2 Python API. Inactive tabs go green when the agent finishes, yellow after 10 min, red after 20. The tab you are looking at stays white, so every colored tab is an unread badge. Split panes in one tab aggregate to the most urgent pane.

iTerm2 has a built-in Claude Code integration (status dot + subtitle per session). It answers "what state is this session in"; this answers "which tab do I go to next", and it also covers OpenAI Codex CLI. They coexist fine.

Everything stays local: no network, no telemetry, MIT. macOS + iTerm2 + Python 3.10+.

Bugs I hit building it that might interest people: the iterm2 Python package's run_forever awaits your main coroutine forever, so if main never returns after the websocket drops, the process sits alive doing nothing and launchd KeepAlive never restarts it. Silent failure for six days on my own machine before I noticed all tabs were stuck green.
```

## Reddit r/ClaudeAI

**Title**

```
I made my iTerm2 tabs turn green → yellow → red by how long each Claude Code / Codex session has been waiting for me
```

**Body**

```
When I run several Claude Code and Codex sessions side by side, I kept losing track of which ones had finished and were sitting idle. Notifications vanish; tab colors don't.

（附 assets/demo.gif）

What it does:
- Tab turns green when the agent finishes, yellow after 10 min, red after 20 min (thresholds configurable)
- The tab you're currently on stays white, so colors act like unread badges
- Split panes in one tab: the tab shows the most urgent pane
- Works with Claude Code and OpenAI Codex CLI through the same hooks
- 100% local: hooks + one small LaunchAgent daemon using the iTerm2 Python API. No network, no telemetry.

Different from the built-in iTerm2 Claude Code integration: that one shows a status dot per session; this one colors the whole tab and escalates with waiting time.

macOS + iTerm2 only. MIT.

https://github.com/hanzhangzzz/iterm2-ai-tab-color
```

## X

```
My iTerm2 tabs now show how long each Claude Code / Codex session has been waiting for me.

Green: just finished
Yellow: 10 min
Red: 20 min, you forgot it

Whole-tab color, split panes aggregated, current tab stays white. Local, MIT.

https://github.com/hanzhangzzz/iterm2-ai-tab-color
```

附 `assets/demo.gif`。X 把链接按 23 字符计，本文有效长度 258/280。

## V2EX（分享创造）

**标题**

```
让 iTerm2 tab 按 Claude Code / Codex 等你等了多久变色：绿 → 黄 → 红
```

**正文**

```
并行开多个 Claude Code 和 Codex 之后，最大的问题不是终端不够用，是我记不住哪个 session 已经跑完在等我。系统通知一闪就没了，tab 颜色不会。

做了个小工具：Agent 回复完成后 tab 变绿，等 10 分钟变黄，20 分钟变红；当前正在看的 tab 始终白色，所以有颜色的 tab 就是"未读"。同一个 tab 里有多个 pane 时按最紧急的那个算。

实现是 Claude Code / Codex 的 hook 写一个本地 state 文件，加一个 LaunchAgent daemon 通过 iTerm2 Python API 改 tab 颜色。全本地，无网络请求，MIT。

和 iTerm2 新出的官方 Claude Code 集成的区别：官方是每个 session 一个状态点，回答"这个 session 什么状态"；这个是整 tab 上色并随等待时长升级，回答"下一个该去哪个 tab"，而且支持 Codex。

仅 macOS + iTerm2。

https://github.com/hanzhangzzz/iterm2-ai-tab-color
```

## 即刻

```
开 5 个 Claude Code 并行之后，最贵的不是 token，是我忘了哪个 tab 在等我。

写了个小工具让 iTerm2 tab 自己变色：跑完变绿，等 10 分钟变黄，20 分钟变红。当前 tab 永远白色，有颜色的就是没处理的。Codex 也支持。

全本地，开源 MIT。
https://github.com/hanzhangzzz/iterm2-ai-tab-color
```

## 已发布

| 渠道 | 日期 | 链接 |
|---|---|---|
| X | 2026-09-16 | https://x.com/du_ethan3954/status/2100230948214194490 |
