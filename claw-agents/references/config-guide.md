# OpenClaw Multi-Agent Config Guide

这份参考基于 OpenClaw 官方文档：

- [Multi-Agent Routing](https://docs.openclaw.ai/concepts/multi-agent)

## 核心概念

一个 agent 是一套完全隔离的运行单元，至少包括：

- `workspace`
- `agentDir`
- `sessions` 目录

官方路径约定：

- 配置文件：`~/.openclaw/openclaw.json`
- state dir：`~/.openclaw`
- 默认单 agent workspace：`~/.openclaw/workspace`
- 多 agent workspace：`~/.openclaw/workspace-<agentId>`
- agentDir：`~/.openclaw/agents/<agentId>/agent`
- sessions：`~/.openclaw/agents/<agentId>/sessions`
- per-agent auth：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

`workspace` 下通常有：

- `AGENTS.md`
- `SOUL.md`
- `USER.md`
- `skills/`

## 最小配置结构

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "name": "Main",
        "workspace": "~/.openclaw/workspace",
        "agentDir": "~/.openclaw/agents/main/agent"
      },
      {
        "id": "coding",
        "name": "Coding",
        "workspace": "~/.openclaw/workspace-coding",
        "agentDir": "~/.openclaw/agents/coding/agent",
        "tools": {
          "allow": ["read", "exec"],
          "deny": ["write", "edit", "apply_patch"]
        },
        "sandbox": {
          "mode": "all",
          "scope": "agent"
        }
      }
    ]
  },
  "bindings": [
    {
      "agentId": "main",
      "match": { "channel": "telegram", "accountId": "default" }
    },
    {
      "agentId": "coding",
      "match": { "channel": "telegram", "accountId": "coding" }
    }
  ],
  "hooks": {
    "internal": {
      "entries": {
        "session-memory": {
          "enabled": true
        }
      }
    }
  }
}
```

## Routing 优先级

OpenClaw 文档里的匹配顺序是：

1. `peer`
2. `parentPeer`
3. `guildId + roles`
4. `guildId`
5. `teamId`
6. `accountId`
7. channel-level match
8. default agent

同一优先级下，配置文件中更靠前的规则优先。

## 常见 bindings

### WhatsApp 多号码 / 多账号

```json
{
  "bindings": [
    { "agentId": "home", "match": { "channel": "whatsapp", "accountId": "home" } },
    { "agentId": "work", "match": { "channel": "whatsapp", "accountId": "work" } }
  ]
}
```

### WhatsApp 按私聊用户拆分

```json
{
  "bindings": [
    {
      "agentId": "alex",
      "match": {
        "channel": "whatsapp",
        "peer": { "kind": "direct", "id": "+15551230001" }
      }
    },
    {
      "agentId": "mia",
      "match": {
        "channel": "whatsapp",
        "peer": { "kind": "direct", "id": "+15551230002" }
      }
    }
  ],
  "channels": {
    "whatsapp": {
      "dmPolicy": "allowlist",
      "allowFrom": ["+15551230001", "+15551230002"]
    }
  }
}
```

### Slack 按工作区

```json
{
  "bindings": [
    { "agentId": "ops", "match": { "channel": "slack", "teamId": "T001" } },
    { "agentId": "sales", "match": { "channel": "slack", "teamId": "T002" } }
  ]
}
```

### Slack / Discord 按频道

```json
{
  "bindings": [
    {
      "agentId": "dev",
      "match": {
        "channel": "slack",
        "teamId": "T001",
        "peer": { "kind": "channel", "id": "C123" }
      }
    },
    {
      "agentId": "family",
      "match": {
        "channel": "discord",
        "guildId": "123456789",
        "peer": { "kind": "channel", "id": "222222222" }
      }
    }
  ]
}
```

### Discord 按服务器

```json
{
  "bindings": [
    { "agentId": "guild-a", "match": { "channel": "discord", "guildId": "123456789" } },
    { "agentId": "guild-b", "match": { "channel": "discord", "guildId": "987654321" } }
  ]
}
```

## 渠道账号与凭据

多 agent 自动化通常分两步：

1. 写 `agents.list` 和 `bindings`
2. 用 OpenClaw CLI 绑定渠道账号或登录凭据

常用命令：

```bash
openclaw agents add work
openclaw agents list --bindings
openclaw channels login --channel telegram --account alerts
openclaw channels login --channel whatsapp --account work
openclaw channels status --probe
openclaw gateway restart
```

## 目录隔离检查清单

每个 agent 都应满足：

- `workspace` 唯一
- `agentDir` 唯一
- `sessions` 目录存在
- `auth-profiles.json` 存在
- `AGENTS.md` 和 `SOUL.md` 已创建

绝不要复用同一个 `agentDir` 给多个 agent。

## tools / sandbox

per-agent 工具权限和沙箱放在每个 agent 对象里，不是放在 `agents.list` 外面：

```json
{
  "id": "public-support",
  "workspace": "~/.openclaw/workspace-public-support",
  "agentDir": "~/.openclaw/agents/public-support/agent",
  "tools": {
    "allow": ["read", "exec"],
    "deny": ["write", "edit", "apply_patch"]
  },
  "sandbox": {
    "mode": "all",
    "scope": "agent"
  }
}
```

## 故障排查

### 消息路由错了

- 先看 `openclaw agents list --bindings`
- 再检查 binding 顺序
- 再检查 `peer/teamId/guildId/accountId` 是否写对

### agent 之间串号

- 检查 `workspace` 是否唯一
- 检查 `agentDir` 是否唯一
- 检查是否误共享了 `auth-profiles.json`

### 改了配置没生效

- 执行 `openclaw gateway restart`
- 再执行 `openclaw agents list --bindings`
- 再执行 `openclaw channels status --probe`

### 跨对话记忆没生效

- 检查 `hooks.internal.entries.session-memory.enabled` 是否为 `true`
- 执行 `openclaw gateway restart`
- 执行 `openclaw logs | grep -i memory`
