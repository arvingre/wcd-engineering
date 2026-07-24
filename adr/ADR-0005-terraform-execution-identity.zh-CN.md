> **中文翻译版** · 英文正本以 `ADR-0005-terraform-execution-identity.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# ADR-0005: Terraform 执行身份(Terraform Execution Identity)

**Status:** Proposed(提议中)— 2026-07-12。此 PR 仍处于 Draft(草稿)状态;状态在合并时才转为 Adopted(已采纳),在此之前不会转变。

## Context(背景)

WCD 的工程流水线涉及五个在原则上都可能接触 AWS 的独立参与方(actor):OpenClaw(规划/记忆/评审编排器)、Claude Code(实现)、GitHub Actions(CI)、HCP Terraform(plan/apply/state,即计划/应用/状态)以及作为目标的 AWS 本身。如果没有明确的边界,一个为图省事的实现捷径——例如为方便起见把 AWS 密钥导出到 CI 环境中、或者"以防万一"给某个 agent 工作站配一个常驻的 IAM role(IAM 角色)——就可能悄无声息地把这几个参与方合并成一个共享身份,而这恰恰破坏了一开始就让不同参与方各司其职、各担其责的初衷。

作为面向全组织的标准,这份 ADR 将 `devops-terraform-jenkins-eks` 中已经做出的按项目决策加以推广:ADR-0002(Terraform state 后端,包含 HCP Terraform Cloud workspace 选项)和 ADR-0003(GitHub → AWS 通过 OIDC,而非静态密钥)。

## Decision(决策)

1. **OpenClaw** —— 负责规划、记忆与评审。默认不持有 AWS 凭据。
2. **Claude Code** —— 负责实现(编写 Terraform、开 PR)。默认不持有 AWS 凭据。
3. **GitHub Actions** —— **仅**负责 CI,**除非另行明确批准**。默认情况下,这意味着无凭据的 `fmt`/`validate`/lint/security-scan 检查——在默认姿态下,永远不做 Terraform plan、不做 apply、不访问 state。如果某个特定 workflow 被明确批准出于某种 CI 目的需要 AWS 访问权限,它将通过 **GitHub OIDC** 联合到一个范围受限的 IAM role(IAM 角色)进行认证——该角色范围限定于那个 CI 目的,而不是 plan/apply/state。
4. **HCP Terraform** —— **专门**负责 Terraform 的 Plan(计划)、Apply(应用)与 State(状态)。此流水线中没有任何其他参与方执行 Terraform 的 plan 或 apply。它通过 **HCP Terraform OIDC**(动态 provider 凭据,dynamic provider credentials)联合到一个范围受限的 IAM role 来向 AWS 认证。这是流水线中唯一预期会持有足以真正变更基础设施的宽泛 AWS 权限的参与方。
5. **AWS** —— 由此产生的基础设施状态。在本 ADR 中,它不是一个需要管理自身凭据的参与方;上述每一条规则的存在,都是为了控制什么可以被允许触达它。
6. **GitHub OIDC 与 HCP Terraform OIDC 是明确的两个不同身份。** 它们绝不能共享同一个 AWS IAM role——没有公共的"Administrator Role"(管理员角色),也没有在一个角色上同时接受两个 OIDC provider 的 trust policy(信任策略)。每一方各得其自己的角色,与第 3、4 点中互不重叠的职责相对应:GitHub Actions 的角色永远不会被赋予 plan/apply/state 的范围,而 HCP Terraform 的角色永远不会被赋予任意 CI 任务的范围。

关于本 ADR 所确立的完整常设规则集,参见 `standards/security/identity-boundary.md`——本 ADR 是决策记录,而那份文档是可强制执行的标准。

## Consequences(后果)

- 每个项目仓库自己的 OIDC/后端 ADR(例如 `devops-terraform-jenkins-eks` 的 ADR-0002/ADR-0003)都应把本 ADR 视为其所实现的全组织基线,而非一个独立、相互竞争的决策。
- **本 ADR 不创建任何 AWS 资源。** 它确立的是边界;实际的 IAM role、trust policy(信任策略)与 permission boundary(权限边界)按项目实现(例如 `devops-terraform-jenkins-eks` 的 `bootstrap/github-oidc/`),并对照本标准进行评审。
- 任何未来提出的、要给 OpenClaw 或 Claude Code 授予常驻 AWS 凭据、或让 GitHub Actions 与 HCP Terraform 共享一个角色的提案,都属于对本 ADR 的偏离,需要它自己的、取代性的(superseding)ADR——而不是一个悄悄开的例外。

## Open questions(尚待解决的问题)

- 每个参与方确切的 IAM role 名称与 permission boundary(权限边界)留给各项目自己的 bootstrap 工作。`devops-terraform-jenkins-eks` ADR-0003 已经把 `WCDTerraformLabRole`/`WCDTerraformProdPlanRole`/`WCDTerraformProdApplyRole` 命名为该仓库中 HCP-Terraform 一侧身份的起点——本 ADR 本身不创建也不命名任何 AWS 资源。
- 是否真的会有某个 GitHub Actions workflow 最终需要一个 AWS 角色,这在各项目层面仍是未定的(默认是不需要——仅 CI、无凭据的 `fmt`/`validate`/lint/security-scan)。`devops-terraform-jenkins-eks` ADR-0003 就该仓库具体地把这一点标记为未解决;在这里它也作为组织层面的一个尚待解决的问题被继承下来。无论答案如何,Terraform 的 plan/apply/state 都专属于 HCP Terraform 一侧——这一部分是已定的,而非未定的。
- Jenkins(在它仍然存在的地方,例如 `devops-terraform-jenkins-eks` 的 `part1-jenkins-from-terraform`)是否适用同样的 OIDC 模型,还是需要一种不同的机制(例如 EC2 instance profile,即 EC2 实例配置文件),这超出本 ADR 的范围,并按项目单独跟踪。

## References(参考资料)

- `devops-terraform-jenkins-eks`:`docs/decisions/ADR-0002-terraform-state.md`、`docs/decisions/ADR-0003-github-oidc.md`
- `standards/security/identity-boundary.md`(本仓库)
