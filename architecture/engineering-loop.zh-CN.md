> **中文翻译版** · 英文正本以 `engineering-loop.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 工程循环(Engineering Loop)

## 目的(Purpose)

Engineering Loop(工程循环)是让 WCD Engineering OS 保持方向感的那个循环往复的周期:跨每一个项目读取当前状态、产出一份报告、推荐下一步该做什么,然后停下 —— 从不自行对该推荐采取行动。**OpenClaw 默认运行这个 Loop。** 它是只读检视加一份报告;其中没有任何环节会自行合并一个 PR、apply Terraform,或启动实现。

## 谁运行它(Task 5)(Who runs this (Task 5))

**OpenClaw 运行 Engineering Loop。** 这是 OpenClaw 的默认、常设职责之一(参见 `architecture/engineering-workflow.md` 的 Roles:"Planning, memory, review")。

**Claude Code 不运行这个 Loop。** Claude Code 的角色仅是 Implementation(实现)—— 它被调用来处理一份特定的、已批准的 Plan(`architecture/engineering-workflow.md` 的 Stage 3,"Feature Branch"),而不是来决定接下来该做什么。Loop 的 "Recommend Next Plan"(推荐下一份 Plan)输出(下文 Step 9)最终会把一份 Plan 交给 Claude Code 去实现 —— Claude Code 位于 Loop 的下游,永远不是它的一个参与者。

## Loop 步骤(Task 1)(Loop steps (Task 1))

```
Read Project Registry
  │
  ▼
Read Roadmap
  │
  ▼
Read Active Plans
  │
  ▼
Inspect GitHub
  │
  ▼
Inspect Open PRs
  │
  ▼
Inspect HCP Terraform
  │
  ▼
Inspect CI
  │
  ▼
Generate Engineering Report
  │
  ▼
Recommend Next Plan
  │
  ▼
Wait Human Decision
```

1. **Read Project Registry(读取项目登记表)** —— `architecture/project-registry.md`:存在哪些项目,以及它们的 Status(状态)、Owner(负责方)、Local Path(本地路径)、Repository(仓库)和 Related ADR/Standards(相关 ADR/标准)。这是该循环判断在后续每一步中要检视 *哪些* 仓库和工作区(workspace)的起点 —— 下文没有任何内容被硬编码到某一个项目上。
2. **Read Roadmap(读取路线图)** —— `docs/roadmap.md`:Current Phase(当前阶段),以及每一个 `PLAN-XXXX` 在 Completed/In Progress/Next/Future 各类别下的状态。
3. **Read Active Plans(读取活跃计划)** —— 当前处于 `In Progress`/`Review`/`Approved`(尚未 `Merged`/`Closed`)的那些 Plan:读取它们实际的 PR 内容和描述,而不仅仅是 Roadmap 上那一行状态,以便捕捉 Roadmap 所述与真实发生之间的漂移(drift)。
4. **Inspect GitHub(检视 GitHub)** —— 对来自 Project Registry 的每一个仓库:当前默认/集成分支的状态、近期提交,以及自上次 Loop 运行以来是否有任何变动。只读。
5. **Inspect Open PRs(检视开放的 PR)** —— 对每一个仓库:列出开放的 Draft PR(来自任何 AI agent 或人类)、它们的 `architecture/engineering-workflow.md` gate 状态(Architecture Review / Implementation Review / Approval)、存续时长(age),以及它们是否已停滞(stalled)。只读 —— 从不评论、批准或合并。
6. **Inspect HCP Terraform(检视 HCP Terraform)** —— 对 Project Registry 中带有 `HCP Terraform Workspace` 字段的每一个项目:通过实际可用的任何只读访问方式(由人类审阅 HCP Terraform 自身的 UI/API,或在明确配置了一个受限只读 token 时使用该 token —— OpenClaw 默认没有任何 AWS 或 HCP Terraform 凭证,依据 `standards/security/identity-boundary.md`,本步骤也从不假定它有),查看工作区的运行历史以及 state 是否存在。**从不触发、plan 或 apply 一次运行** —— 仅限检视。
7. **Inspect CI(检视 CI)** —— 对每一个开放的 PR:实际的检查结果(`fmt`/`validate`/lint/security-scan,或某个项目的等价物),而不仅仅是该 PR 的 Draft/非 Draft 标签。
8. **Generate Engineering Report(生成工程报告)** —— 把 Step 1–7 综合成一份跨每一个项目的结构化状态快照:哪些进展正常、哪些被阻塞、哪些已陈旧、哪些有风险。参见 `## Loop Outputs`。
9. **Recommend Next Plan(推荐下一份计划)** —— 结合该 Report 与 Roadmap 的 `Next Plans` 表格,提议要么启动某个特定的 `PLAN-XXXX`,要么 —— 如果该 Report 浮现出一个阻塞项(一个停滞的 PR、一个未通过的 gate、一份陈旧的 Active Plan)—— 建议先解决那个问题,而不是启动新工作。
10. **Wait Human Decision(等待人类决定)** —— Loop 在此停下。它不会打开分支,不会把被推荐的 Plan 指派给 Claude Code,也不会自行做任何其他事情 —— 这与 `architecture/engineering-workflow.md` 中每一个 gate 所遵循的 "没有人类决定就没有任何东西推进" 原则相同。

## Loop 频率(Task 2)(Loop Frequency (Task 2))

| 频率 | 何时 | 深度 |
|---|---|---|
| **Manual(按需)** | 按需 —— 有人类要求做一次状态检查,或在启动新工作之前。 | 完整循环(全部 10 步),与任何其他运行相同。 |
| **Daily(每日)** | 一种轻量的常设节奏。 | Step 1–2(Registry + Roadmap)加上对 Step 4–5(GitHub + 开放 PR)的一次快速扫描 —— 足以及早捕捉一个停滞的 PR 或漂移的分支,而无需每次都做较重的 HCP Terraform/CI 检视。 |
| **Weekly(每周)** | 一种用于获得更完整图景的常设节奏。 | 全部 10 步,包括 HCP Terraform 和 CI 检视 —— 一份完整的 Engineering Report。 |
| **Release(发布前后)** | 围绕一次影响 Production(生产环境)的变更。 | 全部 10 步,在 Report 中额外关注 Approval/Merge 状态,以及任何触及 Production 的 Plan(`architecture/engineering-workflow.md` 的 Merge 阶段,仅限人类)。 |

这四种都是受支持的模式,而不是本文件所强制的单一固定时间表 —— 实际运行哪一种(哪些)节奏,是在 OpenClaw 自身调度所在之处做出的运营选择,而不是在这里决定。

## Loop 输入(Task 3)(Loop Inputs (Task 3))

| 输入 | 在何处被消费 | 是否只读? |
|---|---|---|
| Project Registry | Step 1 | 是 |
| Roadmap | Step 2 | 是 |
| ADR | Step 3、8 —— 用以判断一份 Active Plan 的方向是否仍与一个已采纳的决策相符 | 是 |
| Plans | Step 3 | 是 |
| GitHub | Step 4–5 | 是 |
| Terraform(经由 HCP Terraform) | Step 6 | 是 —— 仅限检视,参见上文 Step 6;从不 Plan/Apply |
| Memory | Step 3、8 —— 先前的 Loop 发现和既有决策为当前这一轮提供参考 | 是(同时也是一项 **输出** —— 见下文;Loop 读取先前的 Memory 并写入更新后的 Memory,是一个跨运行的反馈回路) |

## Loop 输出(Task 4)(Loop Outputs (Task 4))

| 输出 | 它是什么 |
|---|---|
| **Engineering Report** | Step 8 的综合结果 —— 一份跨 Registry 中每一个项目的、单一的结构化状态快照。 |
| **Risk(风险)** | 该 Report 浮现出的任何在其成为问题之前需要关注的事项:一个停滞的 PR、一个未通过的 CI 检查、一份卡在 In Progress 超过合理时间窗口的 Plan、Roadmap 状态与实际 PR 状态之间的漂移、一个临近的版本支持截止期限。在 Report 中被明确点出,而不是埋没在一段笼统的摘要里。 |
| **Recommendation(推荐)** | 来自 Step 9 的、Loop 所提议的行动 —— 可以是 "启动某个特定的 Plan" 或 "在启动任何新工作之前先解决这个阻塞项"。 |
| **Next Plan(下一份计划)** | 当 Recommendation 是启动新工作时所推荐的那个特定 `PLAN-XXXX` —— 从 Roadmap 的 `Next Plans` 表格中提取,并与当前的 Active Plans 和 Risks 交叉核对,从而它不会脱离已在进行中的工作而被孤立地推荐。 |
| **Memory Update(记忆更新)** | Loop 自己的收尾行动:记录这一轮发现了什么、推荐了什么,以便下一次 Loop 运行 —— 以及任何接手被推荐 Plan 的 Claude Code Implementation 会话 —— 都能从当前状态出发,而不是重新去发现它。 |

## 设计意图(验证)(Design intent (validation))

- **Multiple Repositories(多仓库)** —— 每一步都由迭代 Project Registry(Step 1)驱动,而非由点名某一个仓库驱动;向 Registry 添加一个新项目就足以让 Loop 开始覆盖它,无需改动本文件。
- **Multiple AI(多 AI)** —— Step 5 检视开放的 PR,无论它们由哪个 agent(Claude Code,或任何未来的 agent)打开;Loop 本身只以 OpenClaw 的身份运行(参见 `## Who runs this`),但它所检视的内容与 agent 无关。
- **Multiple Projects(多项目)** —— 与 Multiple Repositories 相同的机制:由 Registry 驱动,每个条目一个项目,没有固定数量。
- **Multiple Workspaces(多工作区)** —— Step 6 迭代每个项目在 Registry 中自身的 `HCP Terraform Workspace` 字段,而不是假定只有单一工作区;一个没有 Terraform 的项目(比如 `wcd-engineering` 本身)在这一步只是被跳过,而不是 Loop 需要硬编码去处理的一个特例。

## 参考(Reference)

- `docs/roadmap.md` —— 在 Step 2 读取;经由 `architecture/engineering-workflow.md` 的 Stage 10 被更新(作为一份 Plan 自身生命周期的一部分,而非由 Loop 本身更新)。
- `architecture/project-registry.md` —— 在 Step 1 读取;是后续每一步所覆盖的仓库/工作区的事实来源(source of truth)。
- `architecture/engineering-workflow.md` —— Loop 的 "Recommend Next Plan" 输出所汇入的、逐 Plan 的生命周期;也是本 Loop 所尊重的仅限人类的 Merge/Approval 规则(从不自行对其推荐采取行动)被定义之处。
- `standards/security/identity-boundary.md` —— 为什么 Step 6(Inspect HCP Terraform)在构造上就是只读的:OpenClaw 默认没有任何 AWS 或 HCP Terraform 凭证。
