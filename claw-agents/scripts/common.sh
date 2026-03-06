#!/bin/bash

set -euo pipefail

claw_lang() {
  local raw="${CLAW_AGENTS_LANG:-${LANG:-en}}"
  if [[ "$raw" =~ ^zh ]]; then
    printf '%s\n' "zh"
  else
    printf '%s\n' "en"
  fi
}

claw_is_zh() {
  [[ "$(claw_lang)" == "zh" ]]
}

prompt_text() {
  local label="$1"
  local default_value="${2:-}"
  local answer
  if [[ -n "$default_value" ]]; then
    read -r -p "$label [$default_value]: " answer
    printf '%s\n' "${answer:-$default_value}"
  else
    while true; do
      read -r -p "$label: " answer
      if [[ -n "$answer" ]]; then
        printf '%s\n' "$answer"
        return
      fi
    done
  fi
}

prompt_yes_no() {
  local label="$1"
  local default_value="${2:-n}"
  local suffix="[y/N]"
  if [[ "$default_value" =~ ^[Yy]$ ]]; then
    suffix="[Y/n]"
  fi

  local answer
  read -r -p "$label $suffix: " answer
  answer="${answer:-$default_value}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_number() {
  local label="$1"
  local default_value="$2"
  local min_value="$3"
  local max_value="$4"
  local value

  while true; do
    value=$(prompt_text "$label" "$default_value")
    if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= min_value && value <= max_value )); then
      printf '%s\n' "$value"
      return
    fi
    if claw_is_zh; then
      echo "请输入 $min_value 到 $max_value 之间的数字。"
    else
      echo "Please enter a number between $min_value and $max_value."
    fi
  done
}

prompt_select() {
  local label="$1"
  shift
  local options=("$@")
  local choice

  echo "$label:" >&2
  local index=1
  local key text
  for option in "${options[@]}"; do
    key="${option%%:*}"
    text="${option#*:}"
    echo "  $index. $text" >&2
    ((index++))
  done

  while true; do
    if claw_is_zh; then
      read -r -p "选择 [1-$#]: " choice >&2
    else
      read -r -p "Choose [1-$#]: " choice >&2
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= $# )); then
      printf '%s\n' "${options[$((choice - 1))]%%:*}"
      return
    fi
    if claw_is_zh; then
      echo "无效选择，请重试。" >&2
    else
      echo "Invalid choice. Try again." >&2
    fi
  done
}

title_case() {
  python3 - "$1" <<'PY'
import sys
text = sys.argv[1].replace("-", " ").replace("_", " ").strip()
print(" ".join(part.capitalize() for part in text.split()) or sys.argv[1])
PY
}

normalize_agent_id() {
  python3 - "$1" <<'PY'
import re
import sys
value = sys.argv[1].strip().lower()
value = re.sub(r"[^a-z0-9_-]+", "-", value)
value = re.sub(r"-{2,}", "-", value).strip("-")
print(value or "agent")
PY
}

prompt_agent_id() {
  local label="$1"
  local default_value="$2"
  local raw
  raw=$(prompt_text "$label" "$default_value")
  normalize_agent_id "$raw"
}

append_json_array() {
  python3 - "$1" "$2" <<'PY'
import json
import sys
arr = json.loads(sys.argv[1])
arr.append(json.loads(sys.argv[2]))
print(json.dumps(arr))
PY
}

csv_to_json_array() {
  python3 - "$1" <<'PY'
import json
import sys
parts = [part.strip() for part in sys.argv[1].split(",") if part.strip()]
print(json.dumps(parts))
PY
}

preset_tools_json() {
  local preset="$1"
  local custom_allow="${2:-}"
  local custom_deny="${3:-}"

  case "$preset" in
    default)
      printf '%s\n' ""
      ;;
    safe-exec)
      printf '%s\n' '{"allow":["read","exec"],"deny":["write","edit","apply_patch"]}'
      ;;
    read-only)
      printf '%s\n' '{"allow":["read"],"deny":["exec","write","edit","apply_patch"]}'
      ;;
    custom)
      local allow_json deny_json
      allow_json=$(csv_to_json_array "$custom_allow")
      deny_json=$(csv_to_json_array "$custom_deny")
      python3 - "$allow_json" "$deny_json" <<'PY'
import json
import sys
allow = json.loads(sys.argv[1])
deny = json.loads(sys.argv[2])
payload = {}
if allow:
    payload["allow"] = allow
if deny:
    payload["deny"] = deny
print(json.dumps(payload) if payload else "")
PY
      ;;
    *)
      if claw_is_zh; then
        echo "未知工具预设: $preset" >&2
      else
        echo "Unknown tools preset: $preset" >&2
      fi
      return 1
      ;;
  esac
}

preset_sandbox_json() {
  local preset="$1"
  case "$preset" in
    off)
      printf '%s\n' ""
      ;;
    all)
      printf '%s\n' '{"mode":"all","scope":"agent","docker":{"setupCommand":"apt-get update && apt-get install -y git curl"}}'
      ;;
    *)
      if claw_is_zh; then
        echo "未知沙箱预设: $preset" >&2
      else
        echo "Unknown sandbox preset: $preset" >&2
      fi
      return 1
      ;;
  esac
}

json_names_map_from_pairs() {
  python3 - "$@" <<'PY'
import json
import sys

result = {}
for value in sys.argv[1:]:
    if "=" not in value:
        continue
    key, name = value.split("=", 1)
    if key:
        result[key] = name
print(json.dumps(result))
PY
}

run_official_post_setup() {
  local script_dir="$1"
  local channel="$2"
  local accounts_csv="$3"
  local names_json="${4:-{}}"

  if ! command -v openclaw >/dev/null 2>&1; then
    if claw_is_zh; then
      echo "未检测到 openclaw CLI，跳过官方 provisioning。"
    else
      echo "OpenClaw CLI not found. Skipping official provisioning."
    fi
    return 0
  fi

  if claw_is_zh; then
    if ! prompt_yes_no "现在调用官方 OpenClaw CLI 配置渠道账号并做 probe 验证？" "y"; then
      return 0
    fi
  else
    if ! prompt_yes_no "Run the official OpenClaw CLI now to provision channel accounts and run probes?" "y"; then
      return 0
    fi
  fi

  "$script_dir/provision.sh" --channel "$channel" --accounts "$accounts_csv" --names-json "$names_json"
}

scaffold_agent() {
  local agent_id="$1"
  local agent_name="$2"
  local workspace="$3"
  local agent_dir="$4"
  local sessions_dir="$5"

  mkdir -p "$workspace" "$workspace/skills" "$agent_dir" "$sessions_dir"

  if [[ ! -f "$workspace/AGENTS.md" ]]; then
    cat >"$workspace/AGENTS.md" <<EOF
# $agent_name

- Role: define this agent's behavior and boundaries.
- Preferred channels: update after routing is verified.
- Notes: replace this file with the persona and workflow for $agent_id.
EOF
  fi

  if [[ ! -f "$workspace/SOUL.md" ]]; then
    cat >"$workspace/SOUL.md" <<EOF
# $agent_name Soul

Describe tone, long-term identity, and decision style for $agent_id.
EOF
  fi

  if [[ ! -f "$workspace/USER.md" ]]; then
    cat >"$workspace/USER.md" <<EOF
# User Context

Store durable user preferences for $agent_id here.
EOF
  fi

  if [[ ! -f "$agent_dir/auth-profiles.json" ]]; then
    printf '{}\n' >"$agent_dir/auth-profiles.json"
  fi
}

prompt_overwrite_if_needed() {
  local path="$1"
  if [[ -f "$path" ]]; then
    local answer
    if claw_is_zh; then
      read -r -p "检测到已有配置 $path，是否覆盖？[y/N]: " answer
    else
      read -r -p "Existing config found at $path. Overwrite? [y/N]: " answer
    fi
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      if claw_is_zh; then
        echo "取消。"
      else
        echo "Cancelled."
      fi
      exit 0
    fi
  fi
}
