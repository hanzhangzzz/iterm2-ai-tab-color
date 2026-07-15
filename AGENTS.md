# iTerm2 AI Tab Color 维护说明

iTerm2 AI Tab Color 是本工具的唯一事实源。它通过 Claude Code / Codex hook 和 iTerm2 Python API，把等待人处理的非活跃 tab 显示为绿色、黄色或红色。

## 行为边界

- 当前活跃 tab 始终保持白色。
- 颜色是 tab 级别，同 tab 多 pane 取最严重状态：`red > yellow > green`。
- 新请求只能清理当前 session 的 state，不能删除同 tab 其他 session。
- hook 负责立即变绿或重置；daemon watch loop 是唯一长期颜色写入者。
- poller 只能更新 state 元数据，不能直接写 iTerm2 tab color。
- daemon 必须使用 `iterm2.run_forever(main, retry=True)`，保证 iTerm2 重启后可重连。
- 处理失败必须暴露，不得吞异常或伪造成功。

## 安装契约

- 正式入口是根目录 `./install.sh` 和 `./uninstall.sh`。
- 稳定运行时位于 `~/.iterm2-ai-tab-color/app/`；LaunchAgent 不能依赖 clone 目录。
- 用户配置位于 `~/.iterm2-ai-tab-color/config.sh`，重复安装必须 byte-for-byte 保留已有配置和权限。
- hook、runtime app 和 plist 必须校验本工具所有权标记；不得覆盖或删除同名用户资产。
- state 和日志位于 `~/.iterm2-ai-tab-color/state/`。
- LaunchAgent label 是 `io.github.hanzhangzzz.iterm2-ai-tab-color`，plist 必须是 `~/Library/LaunchAgents/` 下的真实文件。
- 卸载默认保留配置、state 和日志；只有 `--purge-state` 删除 state 与日志。
- launchd 启动、停止或状态确认失败必须非零退出，不能继续报告安装/卸载完成。
- 测试必须使用临时 HOME，不能修改用户真实的 Claude、Codex、LaunchAgent 或运行时文件。

## 验证

修改后至少运行：

```bash
bash -n install.sh uninstall.sh demo_record.sh iterm2_ai_tab_color_hook.sh scripts/e2e-install-verify.sh scripts/prepare-demo.sh
python3 -m py_compile iterm2_ai_tab_color_daemon.py test_daemon.py
python3 -m unittest test_daemon.py
scripts/e2e-install-verify.sh
git diff --check
```

真实安装会修改用户配置并启动 launchd，必须得到用户明确确认后才能执行。
