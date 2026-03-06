#!/bin/bash

set -euo pipefail

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="${OPENCLAW_CONFIG_PATH:-$CONFIG_DIR/openclaw.json}"

if [[ "${CLAW_AGENTS_LANG:-${LANG:-en}}" =~ ^zh ]]; then
  STATUS_TITLE="=== OpenClaw 状态 ==="
  MISSING_MSG="未找到配置文件"
  CONFIG_LABEL="配置文件"
  TIMEOUT_MSG="(openclaw CLI 调用超时，改用本地配置解析)"
  EMPTY_CLI_MSG="(openclaw CLI 未返回输出)"
else
  STATUS_TITLE="=== OpenClaw Status ==="
  MISSING_MSG="Config file not found"
  CONFIG_LABEL="Config file"
  TIMEOUT_MSG="(openclaw CLI timed out, falling back to local config parsing)"
  EMPTY_CLI_MSG="(openclaw CLI returned no output)"
fi

echo "$STATUS_TITLE"
echo ""

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "$MISSING_MSG: $CONFIG_FILE"
  exit 1
fi

echo "$CONFIG_LABEL: $CONFIG_FILE"
echo ""

if command -v openclaw >/dev/null 2>&1; then
  echo "=== openclaw agents list --bindings ==="
  TIMEOUT_MSG="$TIMEOUT_MSG" EMPTY_CLI_MSG="$EMPTY_CLI_MSG" python3 <<'PY'
import os
import subprocess

try:
    result = subprocess.run(
        ["openclaw", "agents", "list", "--bindings"],
        check=False,
        capture_output=True,
        text=True,
        timeout=5,
    )
except subprocess.TimeoutExpired:
    print(os.environ["TIMEOUT_MSG"])
else:
    output = (result.stdout or result.stderr).strip()
    print(output if output else os.environ["EMPTY_CLI_MSG"])
PY
  echo ""
fi

CLAW_AGENTS_LANG="${CLAW_AGENTS_LANG:-${LANG:-en}}" python3 - "$CONFIG_FILE" <<'PY'
import json
import os
import sys

config_path = sys.argv[1]
with open(config_path, "r", encoding="utf-8") as fh:
    config = json.load(fh)

is_zh = os.environ.get("CLAW_AGENTS_LANG", "").startswith("zh")
agents = config.get("agents", {}).get("list", [])
bindings = config.get("bindings", [])

print("=== Agent List ===" if not is_zh else "=== Agent 列表 ===")
if not agents:
    print("(no agents)" if not is_zh else "(无 agent)")
else:
    for agent in agents:
        flags = []
        if agent.get("default"):
            flags.append("default")
        print(f"- {agent.get('id')} ({agent.get('name', agent.get('id'))})")
        print(f"  workspace: {agent.get('workspace', '(missing)')}")
        print(f"  agentDir: {agent.get('agentDir', '(missing)')}")
        if flags:
            print(f"  flags: {', '.join(flags)}")
        if agent.get("tools"):
            print(f"  tools: {json.dumps(agent['tools'], ensure_ascii=False)}")
        if agent.get("sandbox"):
            print(f"  sandbox: {json.dumps(agent['sandbox'], ensure_ascii=False)}")

print("")
print("=== Bindings ===" if not is_zh else "=== 绑定规则 ===")
if not bindings:
    print("(no bindings)" if not is_zh else "(无 bindings)")
else:
    for binding in bindings:
        agent_id = binding.get("agentId", "(missing)")
        match = binding.get("match", {})
        parts = [f"channel={match.get('channel', '(missing)')}"]
        for key in ("accountId", "teamId", "guildId"):
            if key in match:
                parts.append(f"{key}={match[key]}")
        peer = match.get("peer")
        if isinstance(peer, dict):
            parts.append(f"peer.{peer.get('kind', 'unknown')}={peer.get('id', '(missing)')}")
        print(f"- {agent_id}: " + ", ".join(parts))

channels = config.get("channels")
if channels:
    print("")
    print("=== Channel Config ===" if not is_zh else "=== 渠道级配置 ===")
    print(json.dumps(channels, ensure_ascii=False, indent=2))

hooks = config.get("hooks")
if hooks:
    print("")
    print("=== Hooks ===")
    print(json.dumps(hooks, ensure_ascii=False, indent=2))
PY
