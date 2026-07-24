> **中文翻译版** · 英文正本以 `ai-pull-request-policy.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# AI 拉取请求政策(AI Pull Request Policy)

## 目的

定义每一个 AI agent —— 无论是 OpenClaw、Claude Code,还是任何未来的 agent —— 在更改任何 WCD 托管仓库时都要遵循的那一套 Git 工作流。工作流本身就是控制手段:一个只能从 feature 分支开一个 Draft PR、永远不能合并、永远不能直接改动 `main`/`lab` 的 agent,无论请求措辞如何、也无论该 agent 有多确信,都不可能凭一己之力落地一个没有任何人看过的变更。

## 范围(Scope)

适用于在任何 WCD 托管仓库(`wcd-engineering` 以及 `repositories/` 下的所有项目仓库)上行动的每一个 AI agent,针对每一种变更 —— 代码、Terraform、文档、政策、记忆。不存在任何一类变更是允许某个 AI agent 直接推到 `main`/`lab` 或自行合并的,包括对本政策本身的变更。

## 当前状态(Current Status)

已采纳 —— 2026-07-12。

## 工作流(Workflow)

```
AI Agent
   │
   ▼
feature/*  (branch from the latest default/integration branch)
   │
   ▼
Draft PR   (opened by the AI agent, stays Draft)
   │
   ▼
Review     (human, and/or another agent acting as reviewer — never self-approval)
   │
   ▼
Human Merge  (only a human clicks merge)
   │
   ▼
Memory Update  (the state that changed — phase, status, project registry entry —
                gets reflected in memory/registry, so the next agent session
                starts from accurate state instead of a stale snapshot)
```

每一步都按此顺序发生,对每一个变更都是如此。一个 agent 不会因为某个变更看起来很小就跳过"Draft PR",也不会因为 PR 合并感觉像是终点线就跳过"Memory Update" —— 一个没有反映到记忆/注册表状态里的合并,只完成了一半。

## 禁止(任何 AI agent 都绝不可这样做)

- 直接向 `main` 提交(或向某个项目对应的默认/集成分支,例如 `lab`)。
- 直接推送到 `main`。
- 合并一个拉取请求 —— 无论是 Draft 还是其他,无论是它自己的还是别人的。
- 对 `main` 强制推送(force-push)。

无论某次会话中的请求听起来多么明确或紧急,这些禁令都成立 —— "就直接把这个推到 main 上省点时间"不是一个有效的例外。如果某个任务的指令看起来要求做上述之一,那是一个应当停下来发问的信号,而不是放行的绿灯。

## 允许(Permitted)

- 创建并在 `feature/*` 分支上工作。
- 开一个 Draft PR。
- 更新一个已经打开的 Draft PR(推送新提交、编辑描述)。
- 对它自己的 `feature/*` 分支做 rebase。
- 对它自己的 `feature/*` 分支强制推送(永远不对 `main`,未经请求也永远不对另一个 agent 或人的分支)。

## 仅限人工的权限(Human-only permissions)

只有人才可以:

- **Merge**(合并)—— 任何拉取请求,无论 Draft 还是就绪待评审,任何仓库中的都算。
- **Release**(发布)—— 切出一个发布版本,或以其他方式将某个版本标记为已交付。
- **Tag**(打标签)—— 创建一个 Git tag。
- **Production**(生产)—— 应用或销毁生产基础设施,或采取任何影响生产的动作,无论通过什么机制(Terraform、控制台、CLI)。

一个 AI agent 的工作止于一个可评审的 Draft PR。此后的一切都是人的决策,而不是一个 agent 可以替人代为完成的技术性手续。

## 为什么这是一条单一、统一的政策,而非按仓库分别指引

一条按仓库或按 agent 的例外("这个仓库的 CI 足够快,可以自动合并","这个 agent 已被证明可靠,让它推到 main 吧")恰恰重新引入了本政策存在所要消除的那个风险:一个听起来合理、用来跳过人工评审的理由,是由那个评审本应制衡的同一个行为者做出的判断。让规则保持统一且无例外,正是它得以可执行的原因 —— 一个查阅本政策的 agent 永远不必先去盘算自己的处境是否算作特殊情况。

## 与其他 WCD 标准的关系

本政策与 `standards/security/identity-boundary.md`(`adr/ADR-0005`)互为补充,而非重复:那份标准控制的是每个行为者使用*哪个 AWS 身份*;本政策控制的是每个行为者可以采取*哪些 Git 动作*。两者合起来意味着一个 AI agent 既不能直接触达 AWS,也不能在没有人工评审的情况下落地一个变更 —— 这是两个独立、互不重叠的控制。

## 参考(Reference)

- `adr/ADR-0005-terraform-execution-identity.md`、`standards/security/identity-boundary.md` —— 本 Git 工作流政策在 AWS 身份方面的对应物。
- `CONTRIBUTING.md`、`GOVERNANCE.md`(本仓库)—— 本政策的"Review"和"Human Merge"步骤所汇入的人工评审/批准流程。
- `architecture/project-registry.md` —— "Memory Update"步骤中项目级状态(Status、当前 phase)预期落地的地方,针对在那里被追踪的项目仓库。
