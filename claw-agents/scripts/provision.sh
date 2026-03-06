#!/bin/bash

set -euo pipefail

CHANNEL=""
ACCOUNTS_CSV=""
NAMES_JSON='{}'

if [[ "${CLAW_AGENTS_LANG:-${LANG:-en}}" =~ ^zh ]]; then
  MISSING_CHANNEL_MSG="缺少 --channel"
  MISSING_CLI_MSG="未检测到 openclaw CLI，无法做官方 provisioning。"
  UNKNOWN_ARG_MSG="未知参数"
else
  MISSING_CHANNEL_MSG="Missing --channel"
  MISSING_CLI_MSG="OpenClaw CLI not found; official provisioning cannot run."
  UNKNOWN_ARG_MSG="Unknown argument"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)
      CHANNEL="$2"
      shift 2
      ;;
    --accounts)
      ACCOUNTS_CSV="$2"
      shift 2
      ;;
    --names-json)
      NAMES_JSON="$2"
      shift 2
      ;;
    *)
      echo "$UNKNOWN_ARG_MSG: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CHANNEL" ]]; then
  echo "$MISSING_CHANNEL_MSG" >&2
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "$MISSING_CLI_MSG"
  exit 1
fi

python3 - "$CHANNEL" "$ACCOUNTS_CSV" "$NAMES_JSON" <<'PY'
import json
import subprocess
import sys

channel, accounts_csv, names_json = sys.argv[1:]
accounts = [item.strip() for item in accounts_csv.split(",") if item.strip()]
if not accounts:
    accounts = ["default"]

try:
    names = json.loads(names_json)
except json.JSONDecodeError:
    names = {}

def run(cmd: list[str]) -> int:
    print("$ " + " ".join(cmd))
    completed = subprocess.run(cmd, check=False)
    return completed.returncode

for account in accounts:
    if channel == "whatsapp":
        cmd = ["openclaw", "channels", "login", "--channel", channel]
        if account != "default":
            cmd += ["--account", account]
        rc = run(cmd)
    else:
        cmd = [
            "openclaw",
            "channels",
            "add",
            "--channel",
            channel,
            "--account",
            account,
            "--name",
            names.get(account, account),
        ]
        rc = run(cmd)
    if rc != 0:
        raise SystemExit(rc)

print("")
print("$ openclaw agents list --bindings")
subprocess.run(["openclaw", "agents", "list", "--bindings"], check=False)
print("")
print("$ openclaw channels status --probe")
probe = subprocess.run(["openclaw", "channels", "status", "--probe"], check=False)

if probe.returncode != 0:
    print("")
    print("Probe failed. Trying gateway restart once.")
    print("$ openclaw gateway restart")
    subprocess.run(["openclaw", "gateway", "restart"], check=False)
    print("")
    print("$ openclaw channels status --probe")
    subprocess.run(["openclaw", "channels", "status", "--probe"], check=False)
PY
