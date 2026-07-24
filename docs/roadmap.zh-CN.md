> **中文翻译版** · 英文正本以 `roadmap.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 工程路线图

## 愿景

`docs/roadmap.md` 是整个 WCD Engineering OS(工程操作系统)唯一的任务调度中心。每一个未来的 Plan(计划)、ADR(架构决策记录)和 PR(拉取请求)都围绕这份路线图来组织。Agent(智能体)在提出新工作之前会先阅读本文件。

## Plan 状态词汇表

- **Draft** — 已预留或已撰写,尚未开分支/开 PR。
- **In Progress** — 实现分支处于活动状态。
- **Review** — Draft PR(草稿 PR)已开启。
- **Approved** — 已评审通过,等待合并。
- **Merged** — PR 已合并到 `main`。这只是一个纯粹的 GitHub 事实,仅此而已 —— **它并不等同于 Completed。** 见 `roadmap/roadmap-engine.md`。
- **Blocked** — 无法推进:存在未解决的外部依赖,或存在等待特定决策者处理的 Escalation(升级)。这不是终态 —— 一旦阻塞条件解除即可恢复。见 `roadmap/roadmap-engine.md`。
- **Escalated** — 因为出现有争议或超出权限范围的判断、无法在常规评审层级解决,而被冻结在当前阶段;一旦某位具名的特定决策者做出裁决,即从中断处恢复。这不是终态。见 `decision/decision-engine.md` 的 Decision State Machine(决策状态机)。
- **Deferred** — 计划本身有效,但某位 Human(人类)决定当前暂不推进。这不是终态 —— 当其复审条件被满足时即可恢复。见 `roadmap/roadmap-engine.md`。
- **Completed** — 包含 `Merged` 所隐含的一切,并且额外要求:合并后的 Validation(验证)已通过、本 Roadmap 已同步、Knowledge Promotion(知识提升)已评估,且不再遗留任何必需的交付物。完整的证据清单见 `roadmap/roadmap-engine.md` 的 `Completion` 转换。
- **Closed** — 未经合并即结束,并记录了原因。
- **Archived** — 在被 Closed 之后,永久移出活动考量范围。重新开启需要一份全新的、明确的正当理由,而非例行操作。见 `roadmap/roadmap-engine.md`。

## Plan 生命周期

```text
Plan -> Draft PR -> Review -> Approved -> Merged -> Memory Updated -> Closed
```

Merged 并不是终点线。在工作在运营层面真正完成之前,Roadmap 和持久化记忆必须先反映出已合并的现实。

## 当前阶段

Engineering OS 的基础已经建立:身份边界、项目注册表、AI PR 策略、路线图、工程工作流、工程循环以及工程记忆都已合并。下一个实现目标是 PLAN-0006 Bootstrap,之后是 PLAN-0007 Agent Roles。

## 已完成的 Plans

| Plan | 标题 | 状态 | 相关 PR |
|---|---|---|---|
| PLAN-0001 | Identity Boundary | Merged | [#1](https://github.com/arvingre/wcd-engineering/pull/1) |
| PLAN-0002 | Project Registry | Merged | [#2](https://github.com/arvingre/wcd-engineering/pull/2) |
| PLAN-0003 | Engineering Roadmap | Merged | [#4](https://github.com/arvingre/wcd-engineering/pull/4) |
| PLAN-0004 | AI Pull Request Policy | Merged | [#3](https://github.com/arvingre/wcd-engineering/pull/3) |
| PLAN-0005 | Engineering Memory | Merged | [#7](https://github.com/arvingre/wcd-engineering/pull/7) |
| FOUNDATION-WORKFLOW | Engineering Workflow | Merged | [#5](https://github.com/arvingre/wcd-engineering/pull/5) |
| FOUNDATION-LOOP | Engineering Loop | Merged | [#6](https://github.com/arvingre/wcd-engineering/pull/6) |
| FOUNDATION-DECISION | Decision Engine | Completed | [#10](https://github.com/arvingre/wcd-engineering/pull/10) |
| FOUNDATION-KNOWLEDGE | Knowledge Promotion | Completed | [#11](https://github.com/arvingre/wcd-engineering/pull/11) |
| FOUNDATION-ROADMAP-ENGINE | Roadmap Engine | Completed | [#12](https://github.com/arvingre/wcd-engineering/pull/12) |

## 进行中

当前没有任何实现类 Plan 处于活动状态。这个状态同步 PR 完成了 PR #3-#7 之后所需的合并后 Roadmap 与 Memory Update(记忆更新)。

## 下一批 Plans

| Plan | 标题 | 状态 |
|---|---|---|
| PLAN-0006 | Bootstrap | Draft |
| PLAN-0007 | Agent Roles | Draft |

## 未来 Plans

| Plan | 标题 | 状态 |
|---|---|---|
| PLAN-0008 | Engineering Standards | Draft |
| PLAN-0009 | Playbooks | Draft |
| PLAN-0010 | Templates | Draft |

## 调度规则

在开启新的 Plan 之前,先完成正在进行的工作。当没有任何 Plan 处于活动状态时,选择 `Next Plans` 中的第一项,除非有人类记录了改变优先级的理由。

## 参考

- `architecture/project-registry.md`
- `architecture/engineering-workflow.md`
- `architecture/engineering-loop.md`
- `architecture/engineering-memory.md`
- `policies/ai-pull-request-policy.md`
