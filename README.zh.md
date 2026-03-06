# OpenClaw 多智能体 Skill

[English README](./README.md)

## 简介

这个仓库把 OpenClaw 多智能体配置收敛成 4 个原生命令：

- `/claw-agents setup`
- `/claw-agents add <agentId>`
- `/claw-agents status`
- `/claw-agents doctor`

实际执行逻辑在 [claw-agents/scripts](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts) 下，本 skill 负责交互和流程，脚本负责稳定地改文件、建目录和调用 CLI。

## 功能

这个 skill 主要处理 OpenClaw 多智能体配置里最容易出错的部分：

- 创建隔离的 `workspace`
- 创建隔离的 `agentDir`
- 创建 `sessions` 和 `auth-profiles.json`
- 写入 `~/.openclaw/openclaw.json`
- 为 `accountId`、`teamId`、`guildId`、`peer.kind` 生成 bindings
- 检查路由顺序和目录隔离
- 可选调用官方 `openclaw channels ...` 和 `channels status --probe`

## 环境要求

- OpenClaw 或兼容的 skill 运行环境
- Bash
- Python 3
- 如果要跑官方 provisioning 和 probe，需安装 `openclaw` CLI

## 安装

把这个 skill 安装到你本地使用的 OpenClaw 或 Codex skills 目录。

### `npx skills`（推荐）

优先使用 skills 安装器直接安装：

```bash
npx skills install https://github.com/Kevoyuan/openclaw-multi-agent-skill
```

如果你使用的是内部 registry 或本地封装命令，就按你当前环境对应的 `npx skills ...` 用法安装。

### 安装脚本

这个仓库也自带一个本地安装脚本：

```bash
bash claw-agents/scripts/install-codex.sh
```

如果你想用软链接而不是复制：

```bash
bash claw-agents/scripts/install-codex.sh --link
```

### Git clone

直接把仓库克隆到 skills 目录：

```bash
git clone https://github.com/Kevoyuan/openclaw-multi-agent-skill ~/.codex/skills/claw-agents
```

如果你的 OpenClaw 安装使用的是其他 skills 路径，就克隆到对应位置。

### 软链接

如果你想把仓库放在别处做开发：

```bash
git clone https://github.com/Kevoyuan/openclaw-multi-agent-skill ~/code/openclaw-multi-agent-skill
mkdir -p ~/.codex/skills
ln -s ~/code/openclaw-multi-agent-skill/claw-agents ~/.codex/skills/claw-agents
```

### 验证安装

启动一个新会话，询问当前可用 skills，或者直接触发：

```text
/claw-agents status
```

## 快速开始

```bash
bash claw-agents/scripts/openclaw-agents.sh setup
bash claw-agents/scripts/openclaw-agents.sh doctor
```

如果本机装了官方 CLI，再继续验证：

```bash
openclaw agents list --bindings
openclaw channels status --probe
```

## 命令

在当前仓库里直接运行：

```bash
bash claw-agents/scripts/openclaw-agents.sh setup
bash claw-agents/scripts/openclaw-agents.sh add work
bash claw-agents/scripts/openclaw-agents.sh status
bash claw-agents/scripts/openclaw-agents.sh doctor
```

如果你想显式调用官方账号 provisioning：

```bash
bash claw-agents/scripts/openclaw-agents.sh provision --channel telegram --accounts alerts,ops
```

在 OpenClaw 里的目标用法：

```text
/claw-agents setup
/claw-agents add work
/claw-agents status
/claw-agents doctor
```

## 验证

本地验证：

```bash
bash claw-agents/scripts/openclaw-agents.sh doctor
bash claw-agents/scripts/openclaw-agents.sh status
```

官方 OpenClaw 验证：

```bash
openclaw agents list --bindings
openclaw channels status --probe
```

如果 probe 失败或 runtime 状态不一致：

```bash
openclaw gateway restart
```

## 项目结构

- [SKILL.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/SKILL.md)：面向 OpenClaw 的 skill 定义
- [install-codex.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/install-codex.sh)：本地 Codex 安装脚本
- [config-guide.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/references/config-guide.md)：官方模型参考和配置模式
- [openclaw-agents.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/openclaw-agents.sh)：统一入口
- [setup.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/setup.sh)：首次配置创建
- [add.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/add.sh)：追加单个 agent
- [doctor.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/doctor.sh)：隔离和绑定检查
- [provision.sh](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/claw-agents/scripts/provision.sh)：官方渠道 provisioning 和 probe 封装
- [config.env.example](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/config.env.example)：环境变量覆盖示例
- [SECURITY.md](/Volumes/SSD/Projects/Code/openclaw-multi-agent-skill/SECURITY.md)：安全说明和本地状态模型
