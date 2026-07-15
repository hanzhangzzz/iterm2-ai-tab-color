#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
FAKE_LAUNCHD_STATE="$TEST_ROOT/launchd-loaded"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_HOME/.claude" "$TEST_HOME/.codex" "$TEST_HOME/.iterm2-ai-tab-color" "$FAKE_BIN"
cat > "$FAKE_BIN/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

command="${1:-}"
if [ "${FAKE_LAUNCHCTL_FAIL:-}" = "$command" ]; then
  exit 1
fi
case "$command" in
  print) test -f "$FAKE_LAUNCHD_STATE" ;;
  bootstrap|load) : > "$FAKE_LAUNCHD_STATE" ;;
  kickstart) test -f "$FAKE_LAUNCHD_STATE" ;;
  bootout|unload) rm -f "$FAKE_LAUNCHD_STATE" ;;
  *) exit 1 ;;
esac
SH
chmod +x "$FAKE_BIN/launchctl"

cat > "$TEST_HOME/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "keep-me",
        "hooks": [
          {"type": "command", "command": "/tmp/unrelated-hook"},
          {"type": "command", "command": "/opt/other/iterm2_ai_tab_color_hook.sh"}
        ]
      }
    ]
  }
}
JSON
cat > "$TEST_HOME/.codex/hooks.json" <<'JSON'
{"hooks": {}}
JSON
cat > "$TEST_HOME/.iterm2-ai-tab-color/config.sh" <<'SH'
THRESHOLD_YELLOW=7
THRESHOLD_RED=14
COLOR_GREEN_R=30; COLOR_GREEN_G=180; COLOR_GREEN_B=30
COLOR_YELLOW_R=220; COLOR_YELLOW_G=160; COLOR_YELLOW_B=0
COLOR_RED_R=200; COLOR_RED_G=40; COLOR_RED_B=40
POLL_INTERVAL=15
IDLE_STATE_DIR="$HOME/.iterm2-ai-tab-color/state"
CONCURRENT_TARGET=3
SH
chmod 640 "$TEST_HOME/.iterm2-ai-tab-color/config.sh"

config_hash_before="$(shasum -a 256 "$TEST_HOME/.iterm2-ai-tab-color/config.sh" | awk '{print $1}')"
config_mode_before="$(stat -f '%Lp' "$TEST_HOME/.iterm2-ai-tab-color/config.sh")"

env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" FAKE_LAUNCHD_STATE="$FAKE_LAUNCHD_STATE" \
  "$ROOT/install.sh" --skip-python-check >/dev/null
env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" FAKE_LAUNCHD_STATE="$FAKE_LAUNCHD_STATE" \
  "$ROOT/install.sh" --skip-python-check >/dev/null

test -x "$TEST_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"
test -x "$TEST_HOME/.codex/hooks/iterm2_ai_tab_color_hook.sh"
test -x "$TEST_HOME/.iterm2-ai-tab-color/app/iterm2_ai_tab_color_daemon.py"
test "$(cat "$TEST_HOME/.iterm2-ai-tab-color/app/.managed-by-iterm2-ai-tab-color")" = "iterm2-ai-tab-color"
test -f "$TEST_HOME/Library/LaunchAgents/io.github.hanzhangzzz.iterm2-ai-tab-color.plist"
test -f "$FAKE_LAUNCHD_STATE"
test "$(stat -f '%Lp' "$TEST_HOME/.iterm2-ai-tab-color")" = "700"
test "$(stat -f '%Lp' "$TEST_HOME/.iterm2-ai-tab-color/state")" = "700"

config_hash_after="$(shasum -a 256 "$TEST_HOME/.iterm2-ai-tab-color/config.sh" | awk '{print $1}')"
config_mode_after="$(stat -f '%Lp' "$TEST_HOME/.iterm2-ai-tab-color/config.sh")"
test "$config_hash_before" = "$config_hash_after"
test "$config_mode_before" = "$config_mode_after"

TEST_HOME="$TEST_HOME" python3 - <<'PY'
import os
import plistlib
from pathlib import Path

home = Path(os.environ["TEST_HOME"])
with (home / "Library/LaunchAgents/io.github.hanzhangzzz.iterm2-ai-tab-color.plist").open("rb") as f:
    plist = plistlib.load(f)
assert plist["Label"] == "io.github.hanzhangzzz.iterm2-ai-tab-color"
assert plist["ProgramArguments"][1] == str(
    home / ".iterm2-ai-tab-color/app/iterm2_ai_tab_color_daemon.py"
)
assert plist["StandardOutPath"] == str(home / ".iterm2-ai-tab-color/state/daemon.log")
PY

HOME="$TEST_HOME" ITERM_SESSION_ID="w0t1p0:TEST-UUID" \
  "$TEST_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh" <<'JSON'
{"hook_event_name":"Stop","session_id":"e2e-session"}
JSON
test -f "$TEST_HOME/.iterm2-ai-tab-color/state/e2e-session.json"
test "$(stat -f '%Lp' "$TEST_HOME/.iterm2-ai-tab-color/state/e2e-session.json")" = "600"

TEST_HOME="$TEST_HOME" python3 - <<'PY'
import json
import os
from pathlib import Path

home = Path(os.environ["TEST_HOME"])
claude = json.loads((home / ".claude/settings.json").read_text())
codex = json.loads((home / ".codex/hooks.json").read_text())

claude_commands = [
    hook.get("command", "")
    for groups in claude.get("hooks", {}).values()
    for group in groups
    for hook in group.get("hooks", [])
]
assert "/tmp/unrelated-hook" in claude_commands
assert "/opt/other/iterm2_ai_tab_color_hook.sh" in claude_commands

for config, expected in ((claude, 4), (codex, 3)):
    commands = [
        hook.get("command", "")
        for groups in config.get("hooks", {}).values()
        for group in groups
        for hook in group.get("hooks", [])
    ]
    assert len(commands) == expected
PY

# 用户在安装后替换了同名 Claude hook；卸载器必须保留它。
printf '# user-owned replacement\n' > "$TEST_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"

env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" FAKE_LAUNCHD_STATE="$FAKE_LAUNCHD_STATE" \
  "$ROOT/uninstall.sh" --purge-state >/dev/null

test -f "$TEST_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"
grep -Fqx '# user-owned replacement' "$TEST_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"
test ! -e "$TEST_HOME/.codex/hooks/iterm2_ai_tab_color_hook.sh"
test ! -e "$TEST_HOME/.iterm2-ai-tab-color/app"
test ! -e "$TEST_HOME/.iterm2-ai-tab-color/state/e2e-session.json"
test -f "$TEST_HOME/.iterm2-ai-tab-color/config.sh"
test ! -e "$TEST_HOME/Library/LaunchAgents/io.github.hanzhangzzz.iterm2-ai-tab-color.plist"
test ! -e "$FAKE_LAUNCHD_STATE"

TEST_HOME="$TEST_HOME" python3 - <<'PY'
import json
import os
from pathlib import Path

home = Path(os.environ["TEST_HOME"])
claude = json.loads((home / ".claude/settings.json").read_text())
claude_commands = [
    hook.get("command", "")
    for groups in claude.get("hooks", {}).values()
    for group in groups
    for hook in group.get("hooks", [])
]
assert "/opt/other/iterm2_ai_tab_color_hook.sh" in claude_commands
assert str(home / ".claude/hooks/iterm2_ai_tab_color_hook.sh") not in claude_commands
PY

# 同名用户文件不能被安装器覆盖。
COLLISION_HOME="$TEST_ROOT/collision-home"
mkdir -p "$COLLISION_HOME/.claude/hooks"
printf '# user-owned\n' > "$COLLISION_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"
if HOME="$COLLISION_HOME" "$ROOT/install.sh" --no-codex --no-launchd --skip-python-check >/dev/null 2>&1; then
  echo "expected hook collision to fail" >&2
  exit 1
fi
grep -Fqx '# user-owned' "$COLLISION_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"

# runtime 根目录软链不能被跟随写入或 chmod。
SYMLINK_HOME="$TEST_ROOT/symlink-home"
SYMLINK_TARGET="$TEST_ROOT/user-runtime"
mkdir -p "$SYMLINK_HOME" "$SYMLINK_TARGET"
chmod 755 "$SYMLINK_TARGET"
ln -s "$SYMLINK_TARGET" "$SYMLINK_HOME/.iterm2-ai-tab-color"
if HOME="$SYMLINK_HOME" "$ROOT/install.sh" --no-claude --no-codex --no-launchd --skip-python-check >/dev/null 2>&1; then
  echo "expected runtime symlink collision to fail" >&2
  exit 1
fi
test "$(stat -f '%Lp' "$SYMLINK_TARGET")" = "755"
test -z "$(find "$SYMLINK_TARGET" -mindepth 1 -print -quit)"

# 卸载 purge 不能跟随 state 软链删除外部文件。
STATE_LINK_HOME="$TEST_ROOT/state-link-home"
STATE_LINK_TARGET="$TEST_ROOT/user-state"
mkdir -p "$STATE_LINK_HOME/.iterm2-ai-tab-color/app" "$STATE_LINK_TARGET"
printf 'iterm2-ai-tab-color\n' > "$STATE_LINK_HOME/.iterm2-ai-tab-color/app/.managed-by-iterm2-ai-tab-color"
printf 'user log\n' > "$STATE_LINK_TARGET/daemon.log"
printf '{"owner":"user"}\n' > "$STATE_LINK_TARGET/user.json"
ln -s "$STATE_LINK_TARGET" "$STATE_LINK_HOME/.iterm2-ai-tab-color/state"
if HOME="$STATE_LINK_HOME" "$ROOT/uninstall.sh" --purge-state >/dev/null 2>&1; then
  echo "expected state symlink purge to fail" >&2
  exit 1
fi
grep -Fqx 'user log' "$STATE_LINK_TARGET/daemon.log"
grep -Fqx '{"owner":"user"}' "$STATE_LINK_TARGET/user.json"

# 缺少配置时创建 600 配置，且 --no-claude 不复制 Claude hook。
FRESH_HOME="$TEST_ROOT/fresh-home"
HOME="$FRESH_HOME" "$ROOT/install.sh" --no-claude --no-launchd --skip-python-check >/dev/null
test "$(stat -f '%Lp' "$FRESH_HOME/.iterm2-ai-tab-color/config.sh")" = "600"
test ! -e "$FRESH_HOME/.claude/hooks/iterm2_ai_tab_color_hook.sh"
test -x "$FRESH_HOME/.codex/hooks/iterm2_ai_tab_color_hook.sh"

# launchd 注册失败必须非零退出，不能报告安装完成。
FAIL_HOME="$TEST_ROOT/fail-home"
if env HOME="$FAIL_HOME" PATH="$FAKE_BIN:$PATH" FAKE_LAUNCHD_STATE="$TEST_ROOT/fail-state" \
  FAKE_LAUNCHCTL_FAIL=bootstrap "$ROOT/install.sh" --skip-python-check >"$TEST_ROOT/fail.log" 2>&1; then
  echo "expected launchd bootstrap failure" >&2
  exit 1
fi
! grep -Fq '安装完成' "$TEST_ROOT/fail.log"

printf 'PASS isolated install, reinstall, ownership, launchd, hook, and uninstall verification\n'
