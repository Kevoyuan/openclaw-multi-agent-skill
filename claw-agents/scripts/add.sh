#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="${OPENCLAW_CONFIG_PATH:-$CONFIG_DIR/openclaw.json}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  if claw_is_zh; then
    echo "未找到配置文件: $CONFIG_FILE"
    echo "请先运行 setup.sh"
  else
    echo "Config file not found: $CONFIG_FILE"
    echo "Run setup.sh first."
  fi
  exit 1
fi

if claw_is_zh; then
  NEW_AGENT_LABEL="新的 agent ID"
  DISPLAY_NAME_LABEL="显示名称"
  WORKSPACE_LABEL="workspace 路径"
  AGENT_DIR_LABEL="agentDir 路径"
  CHANNEL_LABEL="绑定到哪个渠道"
  BINDING_LABEL="绑定规则类型"
  TOOLS_LABEL="工具权限预设"
  SANDBOX_LABEL="沙箱预设"
  ACCOUNT_LABEL="accountId"
  DIRECT_LABEL="私聊用户 ID / E.164"
  GROUP_LABEL="群组 ID"
  CHANNEL_ID_LABEL="频道 ID"
  TEAM_LABEL="teamId"
  GUILD_LABEL="guildId"
  ADDED_PREFIX="已添加 agent"
  DOCTOR_HINT="建议运行"
  DEFAULT_OPTION="默认"
  SAFE_OPTION="安全执行（read, exec）"
  READONLY_OPTION="只读"
  OFF_OPTION="关闭"
  ALL_OPTION="每 agent Docker"
  BY_ACCOUNT_OPTION="按 accountId"
  BY_DIRECT_OPTION="按私聊用户（peer.kind=direct）"
  BY_GROUP_OPTION="按群组（peer.kind=group）"
  BY_CHANNEL_PEER_OPTION="按频道（peer.kind=channel）"
  BY_TEAM_OPTION="按 teamId（Slack）"
  BY_GUILD_OPTION="按 guildId（Discord）"
  WHOLE_CHANNEL_OPTION="整个渠道"
  MEMORY_LABEL="如果缺少配置，启用跨对话记忆（session-memory hook）"
else
  NEW_AGENT_LABEL="new agent ID"
  DISPLAY_NAME_LABEL="display name"
  WORKSPACE_LABEL="workspace path"
  AGENT_DIR_LABEL="agentDir path"
  CHANNEL_LABEL="Which channel should it bind to"
  BINDING_LABEL="Binding rule type"
  TOOLS_LABEL="Tools preset"
  SANDBOX_LABEL="Sandbox preset"
  ACCOUNT_LABEL="accountId"
  DIRECT_LABEL="Direct user ID / E.164"
  GROUP_LABEL="Group ID"
  CHANNEL_ID_LABEL="Channel ID"
  TEAM_LABEL="teamId"
  GUILD_LABEL="guildId"
  ADDED_PREFIX="Added agent"
  DOCTOR_HINT="Suggested next step:"
  DEFAULT_OPTION="Default"
  SAFE_OPTION="Safe execution (read, exec)"
  READONLY_OPTION="Read-only"
  OFF_OPTION="Off"
  ALL_OPTION="Per-agent Docker"
  BY_ACCOUNT_OPTION="By accountId"
  BY_DIRECT_OPTION="By direct user (peer.kind=direct)"
  BY_GROUP_OPTION="By group (peer.kind=group)"
  BY_CHANNEL_PEER_OPTION="By channel (peer.kind=channel)"
  BY_TEAM_OPTION="By teamId (Slack)"
  BY_GUILD_OPTION="By guildId (Discord)"
  WHOLE_CHANNEL_OPTION="Entire channel"
  MEMORY_LABEL="Enable cross-conversation memory if it is not configured yet"
fi

CLI_AGENT_ID="${1:-}"
if [[ -n "$CLI_AGENT_ID" ]]; then
  AGENT_ID=$(normalize_agent_id "$CLI_AGENT_ID")
else
  AGENT_ID=$(prompt_agent_id "$NEW_AGENT_LABEL" "work")
fi

AGENT_NAME=$(prompt_text "$DISPLAY_NAME_LABEL" "$(title_case "$AGENT_ID")")
WORKSPACE=$(prompt_text "$WORKSPACE_LABEL" "$CONFIG_DIR/workspace-$AGENT_ID")
AGENT_DIR=$(prompt_text "$AGENT_DIR_LABEL" "$CONFIG_DIR/agents/$AGENT_ID/agent")
SESSIONS_DIR="$(dirname "$AGENT_DIR")/sessions"

CHANNEL=$(prompt_select \
  "$CHANNEL_LABEL" \
  "whatsapp:WhatsApp" \
  "telegram:Telegram" \
  "slack:Slack" \
  "discord:Discord")

BINDING_MODE=$(prompt_select \
  "$BINDING_LABEL" \
  "account:$BY_ACCOUNT_OPTION" \
  "direct:$BY_DIRECT_OPTION" \
  "group:$BY_GROUP_OPTION" \
  "channel-peer:$BY_CHANNEL_PEER_OPTION" \
  "team:$BY_TEAM_OPTION" \
  "guild:$BY_GUILD_OPTION" \
  "channel:$WHOLE_CHANNEL_OPTION")

TOOLS_PRESET=$(prompt_select \
  "$TOOLS_LABEL" \
  "default:$DEFAULT_OPTION" \
  "safe-exec:$SAFE_OPTION" \
  "read-only:$READONLY_OPTION")
SANDBOX_PRESET=$(prompt_select \
  "$SANDBOX_LABEL" \
  "off:$OFF_OPTION" \
  "all:$ALL_OPTION")

TOOLS_JSON=$(preset_tools_json "$TOOLS_PRESET")
SANDBOX_JSON=$(preset_sandbox_json "$SANDBOX_PRESET")

scaffold_agent "$AGENT_ID" "$AGENT_NAME" "$WORKSPACE" "$AGENT_DIR" "$SESSIONS_DIR"

BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$BINDING_MODE" <<'PY'
import json
import sys

agent_id, channel, mode = sys.argv[1:]
payload = {"agentId": agent_id, "match": {"channel": channel}}
print(json.dumps(payload))
PY
)

PROVISION_ACCOUNT="default"
PROVISION_NAME="$AGENT_NAME"
ENABLE_MEMORY="false"

case "$BINDING_MODE" in
  account)
    VALUE=$(prompt_text "$ACCOUNT_LABEL" "$AGENT_ID")
    PROVISION_ACCOUNT="$VALUE"
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "accountId": value}}))
PY
)
    ;;
  direct)
    VALUE=$(prompt_text "$DIRECT_LABEL" "")
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "peer": {"kind": "direct", "id": value}}}))
PY
)
    ;;
  group)
    VALUE=$(prompt_text "$GROUP_LABEL" "")
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "peer": {"kind": "group", "id": value}}}))
PY
)
    ;;
  channel-peer)
    VALUE=$(prompt_text "$CHANNEL_ID_LABEL" "")
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "peer": {"kind": "channel", "id": value}}}))
PY
)
    ;;
  team)
    VALUE=$(prompt_text "$TEAM_LABEL" "")
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "teamId": value}}))
PY
)
    ;;
  guild)
    VALUE=$(prompt_text "$GUILD_LABEL" "")
    BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$VALUE" <<'PY'
import json
import sys
agent_id, channel, value = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "guildId": value}}))
PY
)
    ;;
  channel)
    ;;
  *)
    if claw_is_zh; then
      echo "不支持的绑定类型: $BINDING_MODE" >&2
    else
      echo "Unsupported binding mode: $BINDING_MODE" >&2
    fi
    exit 1
    ;;
esac

python3 - "$CONFIG_FILE" "$AGENT_ID" "$AGENT_NAME" "$WORKSPACE" "$AGENT_DIR" "$TOOLS_JSON" "$SANDBOX_JSON" "$BINDING_OBJECT" <<'PY'
import json
import sys

config_file, agent_id, name, workspace, agent_dir, tools_json, sandbox_json, binding_json = sys.argv[1:]
with open(config_file, "r", encoding="utf-8") as fh:
    config = json.load(fh)

agents = config.setdefault("agents", {}).setdefault("list", [])
if any(agent.get("id") == agent_id for agent in agents):
    raise SystemExit(f"agent '{agent_id}' 已存在")

agent = {
    "id": agent_id,
    "name": name,
    "workspace": workspace,
    "agentDir": agent_dir,
}
if tools_json:
    agent["tools"] = json.loads(tools_json)
if sandbox_json:
    agent["sandbox"] = json.loads(sandbox_json)
agents.append(agent)

bindings = config.setdefault("bindings", [])
bindings.append(json.loads(binding_json))

with open(config_file, "w", encoding="utf-8") as fh:
    json.dump(config, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

if python3 - "$CONFIG_FILE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    config = json.load(fh)
enabled = (
    config.get("hooks", {})
    .get("internal", {})
    .get("entries", {})
    .get("session-memory", {})
    .get("enabled")
)
raise SystemExit(0 if enabled else 1)
PY
then
  :
else
  if prompt_yes_no "$MEMORY_LABEL" "n"; then
    python3 - "$CONFIG_FILE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    config = json.load(fh)
config.setdefault("hooks", {}).setdefault("internal", {}).setdefault("entries", {})["session-memory"] = {"enabled": True}
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(config, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
  fi
fi

if claw_is_zh; then
  echo "$ADDED_PREFIX '$AGENT_ID'。"
  echo "$DOCTOR_HINT: $SCRIPT_DIR/openclaw-agents.sh doctor"
else
  echo "$ADDED_PREFIX '$AGENT_ID'."
  echo "$DOCTOR_HINT $SCRIPT_DIR/openclaw-agents.sh doctor"
fi

run_official_post_setup "$SCRIPT_DIR" "$CHANNEL" "$PROVISION_ACCOUNT" "$(json_names_map_from_pairs "$PROVISION_ACCOUNT=$PROVISION_NAME")"
