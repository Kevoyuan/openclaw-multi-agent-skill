#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./scripts/openclaw-agents.sh <command> [args]

Commands:
  setup               Run interactive multi-agent setup
  add <agentId>       Add one agent to an existing config
  status              Show agents, bindings, and channel config
  doctor              Validate workspaces, agentDir isolation, and bindings
  provision [...]     Run official OpenClaw CLI provisioning + probes
EOF
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
  setup)
    exec bash "$SCRIPT_DIR/setup.sh" "$@"
    ;;
  add)
    exec bash "$SCRIPT_DIR/add.sh" "$@"
    ;;
  status)
    exec bash "$SCRIPT_DIR/status.sh" "$@"
    ;;
  doctor)
    exec bash "$SCRIPT_DIR/doctor.sh" "$@"
    ;;
  provision)
    exec bash "$SCRIPT_DIR/provision.sh" "$@"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    usage >&2
    exit 1
    ;;
esac
