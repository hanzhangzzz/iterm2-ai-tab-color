# iTerm2 AI Tab Color

**不用逐个打开 iTerm2 tab，也能看出哪个 Claude Code 或 Codex session 正在等你。**

[English](README.md)

![AI session 等待时，iTerm2 tab 从绿色逐渐变为黄色和红色](assets/demo.gif)

并行运行多个 AI 编程 Agent 后，真正的瓶颈往往变成了人的注意力。iTerm2 AI Tab Color 把非活跃 tab 变成一条持续可见的处理队列：

| 颜色 | 含义 |
|---|---|
| 绿色 | Claude Code 或 Codex 刚完成回复，正在等人处理 |
| 黄色 | session 已等待超过 10 分钟 |
| 红色 | session 已等待超过 20 分钟 |
| 白色 | 当前 tab、正在处理，或没有等待中的 session |

只有非活跃 tab 会被上色，当前正在查看的 tab 始终保持白色。同一个 tab 有多个 pane 时取最紧急的颜色，因此一个等待过久的红色 pane 不会被另一个活跃 pane 掩盖。

## 为什么需要它

Claude Code 和 Codex 的 hook 可以知道 Agent 何时结束，但普通通知很快就会消失。Tab 颜色会一直保留，直到你回到对应工作。这样无需新增常驻界面、云服务或账号，iTerm2 本身就是注意力面板。

## 特性

- 同时支持 Claude Code 和 OpenAI Codex CLI
- 按等待时间执行绿色 → 黄色 → 红色升级
- 正确处理 iTerm2 split pane 的 tab 级颜色聚合
- 当前活跃 tab 始终保持白色
- session 关闭或回到 shell 后自动清理过期状态
- iTerm2 重启或 websocket 断开后自动重连
- 所有状态只保存在本机；不上传遥测，不依赖网络服务
- 一条脚本安装，通过 macOS LaunchAgent 常驻运行

## 环境要求

- macOS 与 [iTerm2](https://iterm2.com/)
- Python 3.10+
- Claude Code 和/或 OpenAI Codex CLI

## 安装

```bash
git clone https://github.com/hanzhangzzz/iterm2-ai-tab-color.git
cd iterm2-ai-tab-color
pip3 install iterm2
./install.sh
```

安装器会：

- 把 hook 复制到 `~/.claude/hooks/` 和 `~/.codex/hooks/`；
- 把稳定运行时安装到 `~/.iterm2-ai-tab-color/app/`；
- byte-for-byte 保留已有的 `~/.iterm2-ai-tab-color/config.sh`；
- 遇到不带本项目所有权标记的同名 hook、runtime 或 plist 时拒绝覆盖；
- 注册 Claude Code 和 Codex hook 事件；
- 创建真实的 LaunchAgent plist 并启动 daemon；
- 修改 JSON 配置前自动备份。

只预览变更，不写文件：

```bash
./install.sh --dry-run
```

只安装一个 Agent 的 hook：

```bash
./install.sh --no-codex
./install.sh --no-claude
```

## 验证

```bash
launchctl print gui/$(id -u)/io.github.hanzhangzzz.iterm2-ai-tab-color
tail -f ~/.iterm2-ai-tab-color/state/daemon.log
```

在 iTerm2 中打开 Claude Code 或 Codex，提问后切换到其他 tab。回复完成时，刚才的非活跃 tab 应变成绿色。

## 配置

编辑 `~/.iterm2-ai-tab-color/config.sh`：

```bash
THRESHOLD_YELLOW=10
THRESHOLD_RED=20

COLOR_GREEN_R=30;   COLOR_GREEN_G=180;  COLOR_GREEN_B=30
COLOR_YELLOW_R=220; COLOR_YELLOW_G=160; COLOR_YELLOW_B=0
COLOR_RED_R=200;    COLOR_RED_G=40;      COLOR_RED_B=40

POLL_INTERVAL=30
CONCURRENT_TARGET=3
```

修改配置后重启 daemon：

```bash
launchctl kickstart -k gui/$(id -u)/io.github.hanzhangzzz.iterm2-ai-tab-color
```

## 工作原理

```text
Claude Code / Codex hook 事件
            │
            ▼
iterm2_ai_tab_color_hook.sh
            │ 写入本地 session 状态
            ▼
~/.iterm2-ai-tab-color/state/*.json
            │
            ▼
iterm2_ai_tab_color_daemon.py
            │ iTerm2 Python API
            ▼
       iTerm2 tab 颜色
```

Hook 负责立即变绿或重置；唯一的 daemon 负责长期颜色写入、split pane 聚合、等待时间升级、过期 session 清理，以及保持当前 tab 为白色。Daemon 使用支持 retry 的 iTerm2 Python API 入口，因此 iTerm2 重启后能够自动重连。

所有数据都留在本机。本项目不持久化或传输凭据，也不会请求 Claude/OpenAI usage API。Codex 运行在 tmux 内时，hook 会检查本地进程元数据，并且只提取 `ITERM_SESSION_ID`，用于把 tmux client 映射回可见的 iTerm2 pane。

## 卸载

```bash
./uninstall.sh
```

默认删除 hook、已安装运行时、LaunchAgent 和 JSON hook 条目，同时保留配置、状态和日志。连状态与日志一起删除：

```bash
./uninstall.sh --purge-state
```

## 开发验证

```bash
bash -n install.sh uninstall.sh demo_record.sh iterm2_ai_tab_color_hook.sh scripts/e2e-install-verify.sh scripts/prepare-demo.sh
python3 -m py_compile iterm2_ai_tab_color_daemon.py test_daemon.py
python3 -m unittest test_daemon.py
scripts/e2e-install-verify.sh
```

## License

[MIT](LICENSE)
