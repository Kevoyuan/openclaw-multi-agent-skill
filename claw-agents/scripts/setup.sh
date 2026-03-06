#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="${OPENCLAW_CONFIG_PATH:-$CONFIG_DIR/openclaw.json}"

if claw_is_zh; then
  SETUP_TITLE="=== OpenClaw 多智能体配置 ==="
  CHANNEL_LABEL="选择渠道"
  AGENT_COUNT_LABEL="需要几个智能体"
  TOOLS_LABEL="工具权限预设"
  SANDBOX_LABEL="沙箱预设"
  MEMORY_LABEL="启用跨对话记忆（session-memory hook）"
  CUSTOM_ALLOW_LABEL="allow 列表（逗号分隔，留空表示不写）"
  CUSTOM_DENY_LABEL="deny 列表（逗号分隔，留空表示不写）"
  AGENT_ID_LABEL="agent ID"
  DISPLAY_NAME_LABEL="显示名称"
  WORKSPACE_LABEL="workspace 路径"
  AGENT_DIR_LABEL="agentDir 路径"
  ACCOUNT_ID_LABEL="accountId"
  DIRECT_WA_LABEL="私聊用户 E.164（如 +15551230001）"
  DIRECT_LABEL="私聊用户 ID"
  GROUP_LABEL="群组 ID"
  TEAM_LABEL="teamId"
  GUILD_LABEL="guildId"
  CHANNEL_ID_LABEL="频道 ID"
  OPTIONAL_TEAM_LABEL="可选 teamId（留空则不写）"
  OPTIONAL_GUILD_LABEL="可选 guildId（留空则不写）"
  NEXT_STEPS_LABEL="下一步："
  NEXT_1="1. 修改每个 workspace 下的 AGENTS.md / SOUL.md 来定制人格"
  NEXT_2="2. 运行 '$SCRIPT_DIR/openclaw-agents.sh doctor' 检查隔离和 bindings"
  NEXT_3="3. 用官方 CLI 补渠道账号并做 probe 验证"
else
  SETUP_TITLE="=== OpenClaw Multi-Agent Setup ==="
  CHANNEL_LABEL="Choose a channel"
  AGENT_COUNT_LABEL="How many agents do you need"
  TOOLS_LABEL="Tools preset"
  SANDBOX_LABEL="Sandbox preset"
  MEMORY_LABEL="Enable cross-conversation memory (session-memory hook)"
  CUSTOM_ALLOW_LABEL="allow list (comma-separated, blank to skip)"
  CUSTOM_DENY_LABEL="deny list (comma-separated, blank to skip)"
  AGENT_ID_LABEL="agent ID"
  DISPLAY_NAME_LABEL="display name"
  WORKSPACE_LABEL="workspace path"
  AGENT_DIR_LABEL="agentDir path"
  ACCOUNT_ID_LABEL="accountId"
  DIRECT_WA_LABEL="Direct user E.164 (for example +15551230001)"
  DIRECT_LABEL="Direct user ID"
  GROUP_LABEL="Group ID"
  TEAM_LABEL="teamId"
  GUILD_LABEL="guildId"
  CHANNEL_ID_LABEL="Channel ID"
  OPTIONAL_TEAM_LABEL="Optional teamId (blank to omit)"
  OPTIONAL_GUILD_LABEL="Optional guildId (blank to omit)"
  NEXT_STEPS_LABEL="Next steps:"
  NEXT_1="1. Customize AGENTS.md / SOUL.md inside each workspace"
  NEXT_2="2. Run '$SCRIPT_DIR/openclaw-agents.sh doctor' to validate isolation and bindings"
  NEXT_3="3. Use the official CLI to provision channel accounts and run probes"
fi

if claw_is_zh; then
  TOOLS_DEFAULT_OPTION="默认（不写 per-agent tools）"
  TOOLS_SAFE_OPTION="安全执行（allow: read, exec）"
  TOOLS_READONLY_OPTION="只读（allow: read）"
  TOOLS_CUSTOM_OPTION="自定义 allow/deny"
  SANDBOX_OFF_OPTION="关闭沙箱"
  SANDBOX_ALL_OPTION="每个 agent 独立 Docker 沙箱"
else
  TOOLS_DEFAULT_OPTION="Default (omit per-agent tools)"
  TOOLS_SAFE_OPTION="Safe execution (allow: read, exec)"
  TOOLS_READONLY_OPTION="Read-only (allow: read)"
  TOOLS_CUSTOM_OPTION="Custom allow/deny"
  SANDBOX_OFF_OPTION="Disable sandbox"
  SANDBOX_ALL_OPTION="Per-agent Docker sandbox"
fi

prompt_overwrite_if_needed "$CONFIG_FILE"
mkdir -p "$CONFIG_DIR"

echo "$SETUP_TITLE"
echo ""

CHANNEL=$(prompt_select \
  "$CHANNEL_LABEL" \
  "whatsapp:WhatsApp" \
  "telegram:Telegram" \
  "slack:Slack" \
  "discord:Discord")

case "$CHANNEL" in
  whatsapp)
    if claw_is_zh; then
      BINDING_MODE=$(prompt_select \
        "选择路由方式" \
        "account:多个账号/手机号（按 accountId 路由）" \
        "direct:同一账号，按私聊用户隔离（peer.kind=direct）" \
        "group:绑定到特定群组（peer.kind=group）" \
        "channel:整个 WhatsApp 渠道走一个智能体")
    else
      BINDING_MODE=$(prompt_select \
        "Choose a routing mode" \
        "account:Multiple accounts or phone identities (route by accountId)" \
        "direct:One account, isolate by direct user (peer.kind=direct)" \
        "group:Bind to a specific group (peer.kind=group)" \
        "channel:One agent for the entire WhatsApp channel")
    fi
    ;;
  telegram)
    if claw_is_zh; then
      BINDING_MODE=$(prompt_select \
        "选择路由方式" \
        "account:多个 bot/account（按 accountId 路由）" \
        "direct:按私聊用户隔离（peer.kind=direct）" \
        "group:绑定到特定群组（peer.kind=group）" \
        "channel:整个 Telegram 渠道走一个智能体")
    else
      BINDING_MODE=$(prompt_select \
        "Choose a routing mode" \
        "account:Multiple bots or accounts (route by accountId)" \
        "direct:Isolate by direct user (peer.kind=direct)" \
        "group:Bind to a specific group (peer.kind=group)" \
        "channel:One agent for the entire Telegram channel")
    fi
    ;;
  slack)
    if claw_is_zh; then
      BINDING_MODE=$(prompt_select \
        "选择路由方式" \
        "team:按 Slack 工作区隔离（teamId）" \
        "channel-peer:按频道隔离（peer.kind=channel，可选 teamId）" \
        "channel:整个 Slack 渠道走一个智能体")
    else
      BINDING_MODE=$(prompt_select \
        "Choose a routing mode" \
        "team:Isolate by Slack workspace (teamId)" \
        "channel-peer:Isolate by channel (peer.kind=channel, optional teamId)" \
        "channel:One agent for the entire Slack channel")
    fi
    ;;
  discord)
    if claw_is_zh; then
      BINDING_MODE=$(prompt_select \
        "选择路由方式" \
        "guild:按 Discord 服务器隔离（guildId）" \
        "channel-peer:按频道隔离（peer.kind=channel，可选 guildId）" \
        "channel:整个 Discord 渠道走一个智能体")
    else
      BINDING_MODE=$(prompt_select \
        "Choose a routing mode" \
        "guild:Isolate by Discord server (guildId)" \
        "channel-peer:Isolate by channel (peer.kind=channel, optional guildId)" \
        "channel:One agent for the entire Discord channel")
    fi
    ;;
esac

AGENT_COUNT=$(prompt_number "$AGENT_COUNT_LABEL" 1 1 8)
TOOLS_PRESET=$(prompt_select \
  "$TOOLS_LABEL" \
  "default:$TOOLS_DEFAULT_OPTION" \
  "safe-exec:$TOOLS_SAFE_OPTION" \
  "read-only:$TOOLS_READONLY_OPTION" \
  "custom:$TOOLS_CUSTOM_OPTION")
SANDBOX_PRESET=$(prompt_select \
  "$SANDBOX_LABEL" \
  "off:$SANDBOX_OFF_OPTION" \
  "all:$SANDBOX_ALL_OPTION")

if prompt_yes_no "$MEMORY_LABEL" "n"; then
  MEMORY_HOOKS_JSON='{"internal":{"entries":{"session-memory":{"enabled":true}}}}'
else
  MEMORY_HOOKS_JSON='{}'
fi

CUSTOM_ALLOW=""
CUSTOM_DENY=""
if [[ "$TOOLS_PRESET" == "custom" ]]; then
  CUSTOM_ALLOW=$(prompt_text "$CUSTOM_ALLOW_LABEL" "")
  CUSTOM_DENY=$(prompt_text "$CUSTOM_DENY_LABEL" "")
fi

AGENTS_JSON='[]'
BINDINGS_JSON='[]'
WHATSAPP_ALLOWLIST=()
ACCOUNT_IDS=()
ACCOUNT_NAME_PAIRS=()

for ((i = 1; i <= AGENT_COUNT; i++)); do
  echo ""
  echo "--- Agent $i/$AGENT_COUNT ---"

  DEFAULT_ID="agent$i"
  if [[ $AGENT_COUNT -eq 1 ]]; then
    DEFAULT_ID="main"
  fi

  AGENT_ID=$(prompt_agent_id "$AGENT_ID_LABEL" "$DEFAULT_ID")
  DEFAULT_NAME="$(title_case "$AGENT_ID")"
  AGENT_NAME=$(prompt_text "$DISPLAY_NAME_LABEL" "$DEFAULT_NAME")

  if [[ $AGENT_COUNT -eq 1 && "$AGENT_ID" == "main" ]]; then
    DEFAULT_WORKSPACE="$CONFIG_DIR/workspace"
  else
    DEFAULT_WORKSPACE="$CONFIG_DIR/workspace-$AGENT_ID"
  fi
  WORKSPACE=$(prompt_text "$WORKSPACE_LABEL" "$DEFAULT_WORKSPACE")
  AGENT_DIR=$(prompt_text "$AGENT_DIR_LABEL" "$CONFIG_DIR/agents/$AGENT_ID/agent")
  SESSIONS_DIR="$(dirname "$AGENT_DIR")/sessions"

  scaffold_agent "$AGENT_ID" "$AGENT_NAME" "$WORKSPACE" "$AGENT_DIR" "$SESSIONS_DIR"

  TOOLS_JSON=$(preset_tools_json "$TOOLS_PRESET" "$CUSTOM_ALLOW" "$CUSTOM_DENY")
  SANDBOX_JSON=$(preset_sandbox_json "$SANDBOX_PRESET")

  AGENT_OBJECT=$(python3 - "$AGENT_ID" "$AGENT_NAME" "$WORKSPACE" "$AGENT_DIR" "$TOOLS_JSON" "$SANDBOX_JSON" "$i" <<'PY'
import json
import sys

agent_id, name, workspace, agent_dir, tools_json, sandbox_json, index = sys.argv[1:]
agent = {
    "id": agent_id,
    "name": name,
    "workspace": workspace,
    "agentDir": agent_dir,
}
if index == "1":
    agent["default"] = True
if tools_json:
    agent["tools"] = json.loads(tools_json)
if sandbox_json:
    agent["sandbox"] = json.loads(sandbox_json)
print(json.dumps(agent))
PY
)
  AGENTS_JSON=$(append_json_array "$AGENTS_JSON" "$AGENT_OBJECT")

  case "$BINDING_MODE" in
    account)
      ACCOUNT_ID=$(prompt_text "$ACCOUNT_ID_LABEL" "$AGENT_ID")
      ACCOUNT_IDS+=("$ACCOUNT_ID")
      ACCOUNT_NAME_PAIRS+=("$ACCOUNT_ID=$AGENT_NAME")
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$ACCOUNT_ID" <<'PY'
import json
import sys
agent_id, channel, account_id = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "accountId": account_id}}))
PY
)
      ;;
    direct)
      if [[ "$CHANNEL" == "whatsapp" ]]; then
        PEER_ID=$(prompt_text "$DIRECT_WA_LABEL" "")
        WHATSAPP_ALLOWLIST+=("$PEER_ID")
      else
        PEER_ID=$(prompt_text "$DIRECT_LABEL" "")
      fi
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$PEER_ID" <<'PY'
import json
import sys
agent_id, channel, peer_id = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "peer": {"kind": "direct", "id": peer_id}}}))
PY
)
      ;;
    group)
      PEER_ID=$(prompt_text "$GROUP_LABEL" "")
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$PEER_ID" <<'PY'
import json
import sys
agent_id, channel, peer_id = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "peer": {"kind": "group", "id": peer_id}}}))
PY
)
      ;;
    team)
      TEAM_ID=$(prompt_text "$TEAM_LABEL" "")
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$TEAM_ID" <<'PY'
import json
import sys
agent_id, channel, team_id = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "teamId": team_id}}))
PY
)
      ;;
    guild)
      GUILD_ID=$(prompt_text "$GUILD_LABEL" "")
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$GUILD_ID" <<'PY'
import json
import sys
agent_id, channel, guild_id = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel, "guildId": guild_id}}))
PY
)
      ;;
    channel-peer)
      PEER_ID=$(prompt_text "$CHANNEL_ID_LABEL" "")
      EXTRA_SCOPE=""
      if [[ "$CHANNEL" == "slack" ]]; then
        EXTRA_SCOPE=$(prompt_text "$OPTIONAL_TEAM_LABEL" "")
        BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$PEER_ID" "$EXTRA_SCOPE" <<'PY'
import json
import sys
agent_id, channel, peer_id, team_id = sys.argv[1:]
match = {"channel": channel, "peer": {"kind": "channel", "id": peer_id}}
if team_id:
    match["teamId"] = team_id
print(json.dumps({"agentId": agent_id, "match": match}))
PY
)
      else
        EXTRA_SCOPE=$(prompt_text "$OPTIONAL_GUILD_LABEL" "")
        BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" "$PEER_ID" "$EXTRA_SCOPE" <<'PY'
import json
import sys
agent_id, channel, peer_id, guild_id = sys.argv[1:]
match = {"channel": channel, "peer": {"kind": "channel", "id": peer_id}}
if guild_id:
    match["guildId"] = guild_id
print(json.dumps({"agentId": agent_id, "match": match}))
PY
)
      fi
      ;;
    channel)
      BINDING_OBJECT=$(python3 - "$AGENT_ID" "$CHANNEL" <<'PY'
import json
import sys
agent_id, channel = sys.argv[1:]
print(json.dumps({"agentId": agent_id, "match": {"channel": channel}}))
PY
)
      ;;
    *)
      if claw_is_zh; then
        echo "未知路由模式: $BINDING_MODE" >&2
      else
        echo "Unknown routing mode: $BINDING_MODE" >&2
      fi
      exit 1
      ;;
  esac

  BINDINGS_JSON=$(append_json_array "$BINDINGS_JSON" "$BINDING_OBJECT")
done

CHANNELS_JSON='{}'
if [[ "$CHANNEL" == "whatsapp" && ${#WHATSAPP_ALLOWLIST[@]} -gt 0 ]]; then
  CHANNELS_JSON=$(python3 - "${WHATSAPP_ALLOWLIST[@]}" <<'PY'
import json
import sys
allow_from = [value for value in sys.argv[1:] if value]
print(json.dumps({"whatsapp": {"dmPolicy": "allowlist", "allowFrom": allow_from}}))
PY
)
fi

if [[ ${#ACCOUNT_IDS[@]} -eq 0 ]]; then
  ACCOUNT_IDS=("default")
  ACCOUNT_NAME_PAIRS+=("default=$(title_case "$CHANNEL")")
fi

ACCOUNTS_CSV=$(IFS=,; echo "${ACCOUNT_IDS[*]}")
ACCOUNT_NAMES_JSON=$(json_names_map_from_pairs "${ACCOUNT_NAME_PAIRS[@]}")

python3 - "$CONFIG_FILE" "$AGENTS_JSON" "$BINDINGS_JSON" "$CHANNELS_JSON" "$MEMORY_HOOKS_JSON" <<'PY'
import json
import os
import sys

config_file, agents_json, bindings_json, channels_json, hooks_json = sys.argv[1:]
config = {
    "agents": {"list": json.loads(agents_json)},
    "bindings": json.loads(bindings_json),
}
channels = json.loads(channels_json)
if channels:
    config["channels"] = channels
hooks = json.loads(hooks_json)
if hooks:
    config["hooks"] = hooks

os.makedirs(os.path.dirname(config_file), exist_ok=True)
with open(config_file, "w", encoding="utf-8") as fh:
    json.dump(config, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

echo ""
if claw_is_zh; then
  echo "配置已生成: $CONFIG_FILE"
else
  echo "Configuration written to: $CONFIG_FILE"
fi
echo ""
echo "$NEXT_STEPS_LABEL"
echo "$NEXT_1"
echo "$NEXT_2"
echo "$NEXT_3"

run_official_post_setup "$SCRIPT_DIR" "$CHANNEL" "$ACCOUNTS_CSV" "$ACCOUNT_NAMES_JSON"
