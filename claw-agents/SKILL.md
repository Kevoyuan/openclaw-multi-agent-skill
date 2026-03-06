---
name: claw-agents
description: Use when setting up or maintaining OpenClaw multi-agent routing, especially when the user wants `/claw-agents setup`, `/claw-agents add`, `/claw-agents status`, or `/claw-agents doctor` style workflows for WhatsApp, Telegram, Slack, or Discord.
---

# Claw Agents

This skill packages OpenClaw multi-agent setup as a native `/claw-agents ...` workflow, with local scripts handling the actual file and CLI operations.

## Trigger Intents

Use this skill when the user says things like:

- `/claw-agents setup`
- `/claw-agents add work`
- `/claw-agents status`
- `/claw-agents doctor`
- “配置 OpenClaw 多 agent”
- “给不同渠道绑定不同 agent”
- “检查 workspace / agentDir / bindings 对不对”

## Command Mapping

Treat these as the canonical actions:

```text
/claw-agents setup
/claw-agents add <agentId>
/claw-agents status
/claw-agents doctor
```

Backend mapping:

```bash
./scripts/openclaw-agents.sh setup
./scripts/openclaw-agents.sh add <agentId>
./scripts/openclaw-agents.sh status
./scripts/openclaw-agents.sh doctor
```

If the user also wants official channel provisioning, run:

```bash
./scripts/openclaw-agents.sh provision --channel <channel> --accounts <csv>
```

## What Each Command Does

### `/claw-agents setup`

Use for first-time setup. It will:

- collect channel and routing mode
- create one isolated `workspace` per agent
- create one isolated `agentDir` per agent
- create `sessions`, `AGENTS.md`, `SOUL.md`, `USER.md`, and `auth-profiles.json`
- write `~/.openclaw/openclaw.json`
- optionally hand off to official `openclaw channels ...` provisioning

### `/claw-agents add <agentId>`

Use to append one new agent to an existing config without hand-editing JSON.

### `/claw-agents status`

Use to show the local config first, and when the `openclaw` CLI is installed, also show `openclaw agents list --bindings`.

### `/claw-agents doctor`

Use to validate:

- `workspace` uniqueness
- `agentDir` uniqueness
- `sessions` existence
- `auth-profiles.json`
- binding order and binding completeness

## Operating Rules

- Prefer the wrapper script over direct script calls.
- Keep one unique `workspace` and one unique `agentDir` per agent.
- Keep `tools` and `sandbox` inside each agent object.
- Put more specific bindings first: `peer` before `guildId/teamId/accountId`, then channel-wide matches, then default agent.
- Treat credentials as official CLI work. Do not synthesize tokens or login artifacts in the skill itself.

## Post-Change Verification

After `setup` or `add`:

```bash
./scripts/openclaw-agents.sh doctor
openclaw agents list --bindings
openclaw channels status --probe
```

If probe fails or runtime state is stale:

```bash
openclaw gateway restart
```

## Reference

- [config-guide.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/references/config-guide.md)
