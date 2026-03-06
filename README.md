# OpenClaw Multi-Agent Skill

[中文说明 / Chinese README](./README.zh.md)

## Overview

This repository packages an OpenClaw-native multi-agent setup flow around four commands:

- `/claw-agents setup`
- `/claw-agents add <agentId>`
- `/claw-agents status`
- `/claw-agents doctor`

The execution logic lives under [claw-agents/scripts](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts), so the skill can stay conversational while file changes remain deterministic.

## Features

This skill focuses on the parts of OpenClaw multi-agent setup that are easy to get wrong:

- creating isolated `workspace` directories
- creating isolated `agentDir` directories
- creating `sessions` and `auth-profiles.json`
- writing `~/.openclaw/openclaw.json`
- building bindings for `accountId`, `teamId`, `guildId`, and `peer.kind`
- checking routing order and directory isolation
- optionally calling official `openclaw channels ...` commands and `channels status --probe`

## Requirements

- OpenClaw or a compatible skill-enabled environment
- Bash
- Python 3
- `openclaw` CLI if you want official provisioning and probe verification

## Install

Install this skill into the OpenClaw or Codex skills directory you use locally.

### `npx skills` (recommended)

Install directly with the skills installer:

```bash
npx skills install https://github.com/Kevoyuan/openclaw-multi-agent-skill
```

If you use a curated registry or a local shortcut, use the matching `npx skills ...` command for your environment.

### Install script

This repo also includes a local installer:

```bash
bash claw-agents/scripts/install-codex.sh
```

To install as a symlink instead of copying:

```bash
bash claw-agents/scripts/install-codex.sh --link
```

### Git clone

Clone the repo directly into your skills directory:

```bash
git clone https://github.com/Kevoyuan/openclaw-multi-agent-skill ~/.codex/skills/claw-agents
```

If your OpenClaw installation uses another skills path, clone it there instead.

### Symlink

If you prefer to keep the repo elsewhere for development:

```bash
git clone https://github.com/Kevoyuan/openclaw-multi-agent-skill ~/code/openclaw-multi-agent-skill
mkdir -p ~/.codex/skills
ln -s ~/code/openclaw-multi-agent-skill/claw-agents ~/.codex/skills/claw-agents
```

### Verify installation

Start a new session and ask what skills are available, or trigger:

```text
/claw-agents status
```

## Quick Start

```bash
bash claw-agents/scripts/openclaw-agents.sh setup
bash claw-agents/scripts/openclaw-agents.sh doctor
```

Then verify with the official CLI when available:

```bash
openclaw agents list --bindings
openclaw channels status --probe
```

## Commands

From this repo:

```bash
bash claw-agents/scripts/openclaw-agents.sh setup
bash claw-agents/scripts/openclaw-agents.sh add work
bash claw-agents/scripts/openclaw-agents.sh status
bash claw-agents/scripts/openclaw-agents.sh doctor
```

To run official account provisioning explicitly:

```bash
bash claw-agents/scripts/openclaw-agents.sh provision --channel telegram --accounts alerts,ops
```

Inside OpenClaw, the intended UX is:

```text
/claw-agents setup
/claw-agents add work
/claw-agents status
/claw-agents doctor
```

## Verification

Local validation:

```bash
bash claw-agents/scripts/openclaw-agents.sh doctor
bash claw-agents/scripts/openclaw-agents.sh status
```

Official OpenClaw validation:

```bash
openclaw agents list --bindings
openclaw channels status --probe
```

If the probe fails or the runtime appears stale:

```bash
openclaw gateway restart
```

## Project Structure

- [SKILL.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/SKILL.md): OpenClaw-facing skill behavior
- [install-codex.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/install-codex.sh): local installer for Codex skills
- [config-guide.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/references/config-guide.md): official-model reference and config patterns
- [openclaw-agents.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/openclaw-agents.sh): unified wrapper
- [setup.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/setup.sh): initial config creation
- [add.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/add.sh): append one agent
- [doctor.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/doctor.sh): isolation and binding checks
- [provision.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/provision.sh): official channel provisioning and probe wrapper
- [config.env.example](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/config.env.example): environment override examples
- [SECURITY.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/SECURITY.md): security notes and local-state model
