#!/bin/bash

set -euo pipefail

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="${OPENCLAW_CONFIG_PATH:-$CONFIG_DIR/openclaw.json}"

if [[ "${CLAW_AGENTS_LANG:-${LANG:-en}}" =~ ^zh ]]; then
  DOCTOR_TITLE="=== OpenClaw Doctor ==="
  MISSING_MSG="未找到配置文件"
  RUN_SETUP_MSG="先运行 ./scripts/setup.sh"
  FINAL_HINT_1="建议再运行: openclaw agents list --bindings"
  FINAL_HINT_2="agents/bindings 一般会热更新；如果 probe 失败或 runtime 状态异常，再执行: openclaw gateway restart"
  FINAL_HINT_3="未检测到 openclaw CLI；安装后建议运行 openclaw agents list --bindings 做最终校验"
else
  DOCTOR_TITLE="=== OpenClaw Doctor ==="
  MISSING_MSG="Config file not found"
  RUN_SETUP_MSG="Run ./scripts/setup.sh first."
  FINAL_HINT_1="Suggested next check: openclaw agents list --bindings"
  FINAL_HINT_2="agents/bindings usually hot-reload; if probes fail or runtime looks stale, run: openclaw gateway restart"
  FINAL_HINT_3="OpenClaw CLI not found; after installing it, run openclaw agents list --bindings for final validation"
fi

echo "$DOCTOR_TITLE"
echo ""

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "✗ $MISSING_MSG: $CONFIG_FILE"
  echo "  $RUN_SETUP_MSG"
  exit 1
fi

CLAW_AGENTS_LANG="${CLAW_AGENTS_LANG:-${LANG:-en}}" python3 - "$CONFIG_FILE" <<'PY'
import json
import os
import sys

config_path = sys.argv[1]
with open(config_path, "r", encoding="utf-8") as fh:
    config = json.load(fh)

issues = 0
warnings = 0
is_zh = os.environ.get("CLAW_AGENTS_LANG", "").startswith("zh")

def issue(message: str) -> None:
    global issues
    issues += 1
    print(f"✗ {message}")

def warn(message: str) -> None:
    global warnings
    warnings += 1
    print(f"○ {message}")

def ok(message: str) -> None:
    print(f"✓ {message}")

agents = config.get("agents", {}).get("list", [])
bindings = config.get("bindings", [])

if not agents:
    issue("agents.list is empty" if not is_zh else "agents.list 为空")
else:
    ok(f"Found {len(agents)} agents" if not is_zh else f"发现 {len(agents)} 个 agent")

default_agents = [agent for agent in agents if agent.get("default")]
if len(default_agents) != 1:
    warn(f"default agent count is {len(default_agents)}; expected 1" if not is_zh else f"default agent 数量为 {len(default_agents)}，通常应为 1")
else:
    ok(f"default agent: {default_agents[0].get('id')}")

seen_ids = set()
seen_workspaces = set()
seen_agent_dirs = set()

print("")
print("=== Agent Directory Checks ===" if not is_zh else "=== Agent 目录检查 ===")
for agent in agents:
    agent_id = agent.get("id")
    if not agent_id:
        issue("Found an agent without an id" if not is_zh else "存在缺少 id 的 agent")
        continue

    if agent_id in seen_ids:
        issue(f"Duplicate agent id: {agent_id}" if not is_zh else f"agent id 重复: {agent_id}")
    seen_ids.add(agent_id)

    workspace = os.path.expanduser(agent.get("workspace", ""))
    agent_dir = os.path.expanduser(agent.get("agentDir", ""))
    sessions_dir = os.path.join(os.path.dirname(agent_dir), "sessions") if agent_dir else ""

    if not workspace:
        issue(f"{agent_id}: missing workspace" if not is_zh else f"{agent_id}: 缺少 workspace")
    elif workspace in seen_workspaces:
        issue(f"{agent_id}: workspace conflicts with another agent: {workspace}" if not is_zh else f"{agent_id}: workspace 与其他 agent 冲突: {workspace}")
    else:
        seen_workspaces.add(workspace)
        if os.path.isdir(workspace):
            ok(f"{agent_id}: workspace exists" if not is_zh else f"{agent_id}: workspace 存在")
        else:
            issue(f"{agent_id}: workspace missing: {workspace}" if not is_zh else f"{agent_id}: workspace 不存在: {workspace}")

    if not agent_dir:
        issue(f"{agent_id}: missing agentDir" if not is_zh else f"{agent_id}: 缺少 agentDir")
    elif agent_dir in seen_agent_dirs:
        issue(f"{agent_id}: agentDir conflicts with another agent: {agent_dir}" if not is_zh else f"{agent_id}: agentDir 与其他 agent 冲突: {agent_dir}")
    else:
        seen_agent_dirs.add(agent_dir)
        if os.path.isdir(agent_dir):
            ok(f"{agent_id}: agentDir exists" if not is_zh else f"{agent_id}: agentDir 存在")
        else:
            issue(f"{agent_id}: agentDir missing: {agent_dir}" if not is_zh else f"{agent_id}: agentDir 不存在: {agent_dir}")

    if workspace:
      for bootstrap in ("AGENTS.md", "SOUL.md", "USER.md"):
        bootstrap_path = os.path.join(workspace, bootstrap)
        if os.path.isfile(bootstrap_path):
            ok(f"{agent_id}: {bootstrap} exists" if not is_zh else f"{agent_id}: {bootstrap} 存在")
        else:
            warn(f"{agent_id}: missing {bootstrap}" if not is_zh else f"{agent_id}: 缺少 {bootstrap}")

    if agent_dir:
        auth_profiles = os.path.join(agent_dir, "auth-profiles.json")
        if os.path.isfile(auth_profiles):
            ok(f"{agent_id}: auth-profiles.json exists" if not is_zh else f"{agent_id}: auth-profiles.json 存在")
        else:
            warn(f"{agent_id}: missing auth-profiles.json" if not is_zh else f"{agent_id}: 缺少 auth-profiles.json")

    if sessions_dir:
        if os.path.isdir(sessions_dir):
            ok(f"{agent_id}: sessions directory exists" if not is_zh else f"{agent_id}: sessions 目录存在")
        else:
            warn(f"{agent_id}: sessions directory missing" if not is_zh else f"{agent_id}: sessions 目录不存在")

print("")
print("=== Binding Checks ===" if not is_zh else "=== Bindings 检查 ===")
if not bindings:
    issue("missing bindings" if not is_zh else "缺少 bindings")
else:
    ok(f"Found {len(bindings)} binding rules" if not is_zh else f"发现 {len(bindings)} 条绑定规则")

tiers = []
priority = {
    "peer": 1,
    "parentPeer": 2,
    "guild+roles": 3,
    "guildId": 4,
    "teamId": 5,
    "accountId": 6,
    "channel": 7,
}

for index, binding in enumerate(bindings, start=1):
    agent_id = binding.get("agentId")
    match = binding.get("match", {})

    if agent_id not in seen_ids:
        issue(f"binding #{index}: points to unknown agentId '{agent_id}'" if not is_zh else f"binding #{index}: 指向未知 agentId '{agent_id}'")

    if "channel" not in match:
        issue(f"binding #{index}: missing match.channel" if not is_zh else f"binding #{index}: 缺少 match.channel")

    if "peer" in match:
        tiers.append(priority["peer"])
    elif "guildId" in match and match.get("roles"):
        tiers.append(priority["guild+roles"])
    elif "guildId" in match:
        tiers.append(priority["guildId"])
    elif "teamId" in match:
        tiers.append(priority["teamId"])
    elif "accountId" in match:
        tiers.append(priority["accountId"])
    else:
        tiers.append(priority["channel"])

if tiers != sorted(tiers):
    warn("bindings are not ordered from more specific to less specific" if not is_zh else "bindings 顺序不是从高优先级到低优先级；更具体的规则应排在前面")
else:
    ok("binding order matches the usual priority rules" if not is_zh else "bindings 顺序符合常见优先级")

channels = config.get("channels", {})
whatsapp = channels.get("whatsapp") if isinstance(channels, dict) else None
if whatsapp and whatsapp.get("dmPolicy") == "allowlist":
    allow_from = whatsapp.get("allowFrom", [])
    if allow_from:
        ok(f"WhatsApp allowlist configured with {len(allow_from)} entries" if not is_zh else f"WhatsApp allowlist 已配置 {len(allow_from)} 项")
    else:
        warn("WhatsApp dmPolicy=allowlist but allowFrom is empty" if not is_zh else "WhatsApp dmPolicy=allowlist 但 allowFrom 为空")

hooks = config.get("hooks", {})
session_memory_enabled = (
    hooks.get("internal", {})
    .get("entries", {})
    .get("session-memory", {})
    .get("enabled")
)
if session_memory_enabled:
    ok("session-memory hook enabled" if not is_zh else "session-memory hook 已启用")
else:
    warn("session-memory hook is not enabled" if not is_zh else "session-memory hook 未启用")

print("")
print("=== Summary ===" if not is_zh else "=== 汇总 ===")
if issues == 0:
    print("✓ No blocking issues found" if not is_zh else "✓ 未发现阻断问题")
else:
    print(f"✗ Found {issues} blocking issues" if not is_zh else f"✗ 发现 {issues} 个阻断问题")
if warnings:
    print(f"○ {warnings} additional warnings" if not is_zh else f"○ 另有 {warnings} 个提醒")
PY

echo ""
if command -v openclaw >/dev/null 2>&1; then
  echo "$FINAL_HINT_1"
  echo "$FINAL_HINT_2"
else
  echo "$FINAL_HINT_3"
fi
