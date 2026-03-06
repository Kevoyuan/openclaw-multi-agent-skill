# Security

## Local State

This skill writes local OpenClaw state under `~/.openclaw` by default:

- `~/.openclaw/openclaw.json`
- `~/.openclaw/workspace*`
- `~/.openclaw/agents/<agentId>/agent`
- `~/.openclaw/agents/<agentId>/sessions`

You can override these paths with:

- `OPENCLAW_STATE_DIR`
- `OPENCLAW_CONFIG_PATH`

## Credentials

This repository does not store channel secrets directly.

Official channel provisioning is delegated to the `openclaw` CLI via:

- `openclaw channels login ...`
- `openclaw channels add ...`

Any credentials or auth artifacts created by those commands are managed by OpenClaw, not by this repository.

## Threat Model

This project is a local skill and script bundle:

- it runs as the current local user
- it edits local state files only
- it does not open its own network listener
- it may invoke the official `openclaw` CLI when you choose provisioning

The primary risks are:

- writing config to the wrong path
- reusing one `workspace` or `agentDir` across multiple agents
- provisioning the wrong channel account

Mitigations:

- `doctor.sh` checks directory isolation and binding structure
- setup and add flows create one `workspace` and one `agentDir` per agent
- provisioning is explicit and routed through the official CLI

## Review Before Running

Before running this skill from an untrusted source:

1. Read [SKILL.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/SKILL.md)
2. Review files in [claw-agents/scripts](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts)
3. Confirm the install target in [install-codex.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/install-codex.sh)
