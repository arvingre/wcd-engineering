> **中文翻译版** · 英文正本以 `project-registry.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 项目注册表(Project Registry)

## 目的

这是 OpenClaw(以及任何其他 AI 代理——包括 Claude Code)在开始工作前用来了解存在哪些项目的单一、统一入口。**任何 AI 代理在开始处理某个它在当前会话中尚未加载上下文的项目之前,都必须先阅读本注册表。** 它回答:存在哪些项目、它们的代码在哪里、它们处于什么状态、它们使用哪个 Terraform 执行平台、哪些 ADR/标准治理它们,以及在未获批准的情况下有哪些内容不可触碰——而无需代理通过浏览文件系统或猜测来重新发现这些内容。

**本注册表不是什么:**
- 不是存放业务逻辑、应用设计或实现细节的地方——那些内容存在于每个项目自己的仓库中。
- 不是密钥存储——绝不存放凭据、令牌或连接字符串。
- 不是 Terraform state 存储——workspace 的*名称*作为指针被记录(以便代理知道 state 存放在何处),但绝不记录 state 的*内容*。

**设计意图:**本文件旨在无需重构即可扩展到 100 多个项目。每个项目在 `## Projects` 下获得一个自包含的 `###` 条目,遵循 `## Project Template` 中的形态。添加第 101 个项目的方式,应当与当初添加第 2 个项目完全一致——是新增一个子小节,而不是一次 schema 变更。

## 当前工程 OS Plan

| 字段 | 值 |
|---|---|
| Active Plan | PLAN-0003 — Engineering Roadmap |
| Status | In Progress |
| Plan Sync | Pending — Memory Update 步骤尚未完成 |
| Last Updated | 2026-07-13 |
| Next Plan | PLAN-0004 — 在 PLAN-0003 的 Plan Sync 关闭之前不要开始 |

> Plan 生命周期关卡:PR merged → **Memory Updated** → Roadmap Updated → Closed。
> PLAN-0003 的 PR 已合并到 main;Memory Update 是剩余的步骤。

## Projects

### dae-k8s

| 字段 | 值 |
|---|---|
| Project Name | dae-k8s (K8sInsight) |
| Description | Kubernetes 异常检测 / 根因分析工具。业务逻辑存在于其自有的上游仓库中;此 workspace 仅存放面向实验室规模部署的 GitOps 接线(`labs/mac-platform-infra/lab/dae-k8s/`)。检测 Pod 级别的异常(CrashLoopBackOff、OOMKilled、ImagePullBackOff、FailedScheduling、Evicted 等),推断根因,并可通过通用出站 Webhook、Lark 或 Telegram sink(`internal/notify/`)发出通知。 |
| Repository | `https://github.com/DAELabs/dae-k8s` — 该 fork 没有 `main` 分支,因此 Argo CD 不从 GitHub 拉取;一个私有的 Gitea 镜像(`gitea_admin/dae-k8s`)才是实际的同步源(见 `lab/dae-k8s/README.md` → "仓库来源")。更新需要手动推送到该 Gitea 镜像。 |
| Owner | TBD — 尚未分配给具体的个人/团队 |
| Status | Active |
| Default Branch | `main`(仅 Gitea 镜像 — GitHub fork 没有 `main`) |
| Integration Branch | N/A |
| Local Path | 源码:`/Users/arvin/Documents/devops/labs/DAELabs/dae-k8s`;GitOps 接线:`/Users/arvin/Documents/devops/labs/mac-platform-infra/lab/dae-k8s` |
| HCP Terraform Workspace | N/A |
| Execution Platform | Kubernetes(OrbStack,实验室规模),由 Argo CD 从 Gitea 镜像同步 |
| Related ADR | 暂无 |
| Standards | 暂无 |
| Dependencies | 候选的未来集成,尚未开始:通用 Webhook sink(`internal/notify/sink/webhook.go`)发出一个 `AnomalyEvent` 载荷(`type/pod/namespace/message/rootCause/suggestion/dedupKey`),在结构上与 `VISION.md` 的 `### 1. Goal` 中 "Monitoring / Alerts" 源及其示例 Goal 相匹配。见 `memory/organization/lessons/` 中的 `LES-0001`。范围限定于 PLAN-0006 Bootstrap(Draft)——在该 Plan 开启之前,不要提前构建接收端。 |

**Metadata(元数据)**

| 字段 | 值 |
|---|---|
| Type | Application / Observability tool(实验室部署) |
| Visibility | Private(Gitea 镜像);GitHub fork 可见性 TBD |
| Primary Language | Go(后端)、TypeScript/React(前端) |
| Infrastructure | Kubernetes(OrbStack) |
| Cloud Provider | N/A — 本地实验室集群 |
| Repository URL | `https://github.com/DAELabs/dae-k8s` |
| Workspace | N/A |
| Maintainer | TBD |

### devops-terraform-jenkins-eks

| 字段 | 值 |
|---|---|
| Project Name | devops-terraform-jenkins-eks |
| Description | WCD 的 AWS 基础设施即代码(Infrastructure-as-Code)基线——版本化的 Terraform 模块(network、EKS、Jenkins、IAM、security、ECR、observability、DNS),独立部署到 `lab`/`staging`/`prod`。最初源自一个 Terraform+Jenkins+EKS 教程项目,正被重构为一个长期、可重复、可审计的模板。 |
| Repository | `https://github.com/Arvingrep/devops-terraform-jenkins-eks` |
| Owner | TBD — 尚未分配给具体的个人/团队;在将任何审批视为权威之前请先确认 |
| Status | Active |
| Default Branch | `main` |
| Integration Branch | `lab` |
| Local Path | `/Users/arvin/Documents/devops/repositories/infrastructure/devops-terraform-jenkins-eks` |
| HCP Terraform Workspace | `operationarvin/infra-aws/devops-terraform-jenkins-eks` — 已存在且已连接 VCS(`execution-mode=local`、`auto-apply=false`),但**当前没有任何代码指向它**(`environments/lab/versions.tf` 中没有 `cloud {}`/backend 块)。今天向此仓库推送不会触发远程 run。 |
| Execution Platform | 未定(Proposed)——本项目自有 `docs/decisions/` 中的 ADR-0002 权衡了 HCP Terraform Cloud 与自管的 S3+DynamoDB;倾向 HCP Terraform Cloud 但尚未最终确定。 |
| Related ADR | 本项目:`docs/decisions/ADR-0001-environment-layout.md`(Adopted)、`ADR-0002-terraform-state.md`(Proposed)、`ADR-0003-github-oidc.md`(Proposed)、`ADR-0004-lab-prod-strategy.md`(Adopted)。组织级:`adr/ADR-0005-terraform-execution-identity.md`(本仓库,Proposed)——定义了本项目的 ADR-0002/ADR-0003 必须遵从的身份边界。 |
| Standards | `standards/aws/eks.md`、`standards/terraform/module-standard.md`、`standards/terraform/environment-layout.md`、`standards/security/iam.md`、`standards/security/identity-boundary.md`、`architecture/aws-eks-platform.md` — 在本仓库中当前均为占位符/草稿,指回本项目作为参考实现。 |
| Dependencies | `modules/network` 曾是 `modules/eks` 的硬性前置条件(在 Phase-4b-1 中途发现:network 模块当时仍是一个未实现的 stub,因此它成为了独立的前置 PR,而非被并入 EKS 模块的 PR)。ADR-0002 的 backend 决策阻塞了 Phase 1 的 bootstrap 工作。Phase 4a 的四份设计文档(`docs/eks-capacity-plan.md`、`docs/eks-node-group-design.md`、`docs/eks-scheduling-standard.md`、`docs/eks-storage-design.md`)曾是 Phase 4b 的 `modules/eks` 实现的硬性关卡。 |

**Metadata(元数据)**

| 字段 | 值 |
|---|---|
| Type | Infrastructure / AWS IaC |
| Visibility | Public |
| Primary Language | HCL(Terraform)、Bash |
| Infrastructure | VPC/网络、EKS、Jenkins(EC2,正被 `modules/jenkins` 替换) |
| Cloud Provider | AWS |
| Repository URL | `https://github.com/Arvingrep/devops-terraform-jenkins-eks` |
| Workspace | `operationarvin/infra-aws/devops-terraform-jenkins-eks`(HCP Terraform Cloud) |
| Maintainer | TBD |

### wcd-engineering

| 字段 | 值 |
|---|---|
| Repository | `https://github.com/arvingre/wcd-engineering` |
| Purpose | WCD DevOps workspace 的工程标准、架构决策、组织知识,以及 AI 代理运作规则。定义"好的样子";由项目仓库来实现它。这不是一个业务应用仓库——没有 Terraform 业务逻辑、没有 state、没有密钥。 |
| Owner | TBD — 尚未分配给具体的个人/团队 |
| Default Branch | `main` |
| Local Path | `/Users/arvin/Documents/devops/wcd-engineering` |
| Current Version | 未版本化 — 尚无 release/tag 方案;将 `main` HEAD 视为当前版本 |
| Related ADR | `adr/ADR-0005-terraform-execution-identity.md`(Proposed)——目前本仓库中唯一的 ADR |

**Metadata(元数据)**

| 字段 | 值 |
|---|---|
| Type | Standards / Documentation / Governance |
| Visibility | Public |
| Primary Language | Markdown |
| Infrastructure | N/A |
| Cloud Provider | N/A |
| Repository URL | `https://github.com/arvingre/wcd-engineering` |
| Workspace | N/A — 本仓库没有自己的 Terraform |
| Maintainer | TBD |

## Project Template(项目模板)

为每个新项目将此块复制到 `## Projects` 下。每个字段都是必填的;请使用 `TBD` 而不是省略某个字段或猜测某个值。

```markdown
### <project-name>

| Field | Value |
|---|---|
| Project Name | |
| Description | |
| Repository | |
| Owner | |
| Status | Planning \| Active \| Maintenance \| Archived |
| Default Branch | |
| Integration Branch | |
| Local Path | |
| HCP Terraform Workspace | (or "N/A" if this project has no Terraform) |
| Execution Platform | |
| Related ADR | |
| Standards | |
| Dependencies | |

**Metadata**

| Field | Value |
|---|---|
| Type | |
| Visibility | Public \| Private \| Internal |
| Primary Language | |
| Infrastructure | |
| Cloud Provider | |
| Repository URL | |
| Workspace | |
| Maintainer | |
```

### Status 定义

- **Planning** — 设计/ADR 阶段;尚未落地任何实现代码,或仅存在脚手架。
- **Active** — 正在积极开发;PR 定期落地;该项目是当前实际工作的焦点。
- **Maintenance** — 稳定;仅接收修复和小更新,不做新功能开发。
- **Archived** — 不再维护;仅为参考/历史而保留。在未先确认应予以解除归档(un-archived)之前,不要在此提出新的工作。

`## Projects` 中的每个项目条目都必须恰好有一个来自此列表的 `Status` 值——不允许自由文本状态。
