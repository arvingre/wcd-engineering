> **中文翻译版** · 英文正本以 `README.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# wcd-engineering

wcd-engineering 是 WCD DevOps 工作区的工程规范、架构决策、组织知识以及 AI 智能体规则仓库。

Claude Code 是我们的双手。OpenHands 和 OpenClaw 是可选的执行引擎。WCD 是大脑,负责掌管 Goal(目标)、Decision(决策)、Organization Memory(组织记忆)与 Continuous Work(持续工作)。

完整的工程愿景见 [`VISION.md`](VISION.md)——WCD 为何存在、它拥有的四大组件、MVP,以及第一个生产工作流。

它不是一个业务应用仓库。源代码、Terraform 实现细节,以及项目专属的交付产物都应归属于 `repositories/` 目录树。

## Purpose(目的)

- 为 AWS、Kubernetes、Terraform、安全、存储、备份、CI 以及相关平台实践定义共享的工程规范
- 沉淀架构决策、RFC、ADR、playbook、runbook、策略以及可复用的模板
- 保存供人工评审者与在本工作区中运作的 AI 智能体使用的、持久稳定的指令

## Directory Structure(目录结构)

- `standards/` - 组织级规范与草案策略
- `architecture/` - 平台概览与参考地图,包括 `architecture/project-registry.md`——每个 AI 智能体(OpenClaw、Claude Code 或其他)在开始任何项目的工作之前首先阅读的入口
- `module-catalog/` - 模块接口索引与归属说明
- `agents/` - AI 智能体的角色定义与运作规则
- `prompts/` - 可复用的评审与分析 prompt
- `adr/` - 架构决策记录
- `rfc/` - 提议的变更与讨论产物
- `playbooks/` - 分步操作指导
- `runbooks/` - 运维执行指南
- `policies/` - 治理与合规规则
- `templates/` - 可复用的文档模板

## Relationship To `repositories/`(与 `repositories/` 的关系)

```text
/Users/arvin/Documents/devops
├── wcd-engineering
│   └── standards, architecture, governance, prompts, agents
└── repositories
    ├── infrastructure
    │   └── project repositories and implementation code
    ├── platform
    ├── applications
    └── tools
```

`wcd-engineering` 定义"什么才是好的"。
`repositories/` 包含遵循或引用这些规范的具体实现。

## Content Boundary(内容边界)

应放入本仓库的内容:

- 共享的规范与策略
- 架构说明与决策记录
- 评审 prompt 与 AI 运作规则
- 归属、审批与治理指导

不应放入本仓库的内容:

- 应用源代码
- Terraform 业务逻辑或 provider 配置
- 生成的 state 文件、密钥,或环境专属的凭据
- 归属于某个项目仓库的生产部署产物

## How To Contribute(如何贡献)

1. 当变更会影响共享行为时,以 ADR 或 RFC 的形式提出该变更。
2. 仅在变更经过评审并获批之后,才更新相关的规范或治理文档。
3. 在适用之处补充证据、范围,以及回滚或例外说明。
4. 保持示例的通用性,避免复制密钥或仅限生产环境使用的值。
5. 当某项规范背后有可运行的参考实现时,链接到该实现仓库。
