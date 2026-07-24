> **中文翻译版** · 英文正本以 `decision-engine.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 工程决策引擎(Decision Engine)

## 目的

决策引擎把一个人(Human)的决策转化为组织状态变更 —— 即 Memory(记忆)、`docs/roadmap.md` 以及下一个推荐的 Plan(计划)。它是一个**记录与传播层,而非执行层**:它自己从不调用 GitHub API 去合并、关闭或重开任何东西。真正的动作由人(在 GitHub 上手动操作)或 GitHub 自身的自动化来执行;决策引擎的工作从该动作*已知发生之后*才开始,把一个决策的原始事实转化为持久的、结构化的状态。

这是 `architecture/engineering-workflow.md` 中第 10 阶段(Memory Update,记忆更新)背后更深层的机制 —— 那一阶段只说记忆会在合并之后被更新;本文件则精确定义了这种更新是*如何*发生的,并且覆盖人所能做出的每一种决策,而不仅仅是"已合并(merged)"。

**范围说明(`adr/ADR-0006`):** 下文的八种决策类型,以及"从不由 AI agent 生成或自我执行"这一表述,专指 Git/PR/Plan 生命周期 —— 而非 AI agent 曾做出的每一个判断。`VISION.md` 中的 Decision 组件描述的是一个独立的、尚未实现的运维决策层(Operational Decision Layer),它在*某个 Goal(目标)执行过程中*自主决定 Continue/Retry/Rollback/Escalate/Wait/Cancel(继续/重试/回滚/上报/等待/取消)(例如在一次 Kubernetes 健康检查的运行中途)—— 这是一个与此处八种类型互不相交的动作空间。关于两者之间的边界,参见 `adr/ADR-0006-operational-vs-git-lifecycle-decisions.md`。

## 决策类型(Task 1)

共八种决策类型。每一种都是由人做出、并由决策引擎记录的判断,从不由 AI agent 生成或自我执行(AI agent 可以*提议* —— 参见 `architecture/engineering-workflow.md` 第 5–6 阶段的评审意见 —— 但提议不等于决策)。

- **Approve**(批准)
- **Reject**(驳回)
- **Merge**(合并)
- **Close**(关闭)
- **Reopen**(重开)
- **Archive**(归档)
- **Escalate**(上报)
- **Defer**(暂缓)

## 决策细节(Task 2)

下面每一种决策类型都列出其触发条件(Trigger)、输入(Input)、输出(Output)和下一步动作(Next Action)。

#### Approve(批准)

| | |
|---|---|
| Trigger | 一位评审者(在 Gate 1–2 上是人或 OpenClaw;在 Gate 3 上仅限人,依据 `architecture/engineering-workflow.md`)在 PR/Plan 当前所处的 gate 上明确批准它。 |
| Input | 一个停在 Review(评审)或 Human Approval(人工批准)gate 上、且没有未决异议的 PR/Plan。 |
| Output | 该 gate 的状态翻转为已通过(passed)。 |
| Next Action | Knowledge Promotion(知识提升)记录谁批准、在哪个 gate、以及何时批准。如果这是最后一个 gate(Human Approval),Roadmap Update(路线图更新)将该 Plan 标记为可以 Merge —— 决策引擎不会去合并它。 |

#### Reject(驳回)

| | |
|---|---|
| Trigger | 一位评审者判定该 PR/Plan 不满足当前 gate 的标准。 |
| Input | 一个处于 Review 或 Human Approval gate、且带有明确异议的 PR/Plan。 |
| Output | 该 gate 保持未通过;Plan 退回到实现阶段,而不是向前推进。 |
| Next Action | Knowledge Promotion 记录驳回原因,专门是为了让同一个异议不会在下一轮里被一模一样地重新争论一遍。Roadmap Update 让该 Plan 保持在 `In Progress`(或 `Review` 并附带要求修改)—— 绝不会被悄悄推进。 |

#### Merge(合并)

| | |
|---|---|
| Trigger | 一位人在 GitHub 上对一个已 Approved 的 PR 点击合并(依据 `policies/ai-pull-request-policy.md` —— 仅限人工,并且是在 GitHub 上手动执行,绝不由决策引擎执行)。 |
| Input | 一个 Approved 的 PR 已被合并这一既成事实。 |
| Output | 决策引擎观察并记录此事 —— 它不执行合并。 |
| Next Action | Knowledge Promotion 记录已合并的变更及其内容。Roadmap Update 把该 Plan 的那一行移到 `Merged`。 |

#### Close(关闭)

| | |
|---|---|
| Trigger | 要么是正常路径(已合并并已 Validated 校验,依据 `architecture/engineering-workflow.md` 第 9–11 阶段),要么是由人做出的提前关闭决策(被放弃或被取代)。 |
| Input | 一个准备结束的 Plan;如果是提前关闭,则附带原因。 |
| Output | 该 Plan 的状态变为 `Closed`。 |
| Next Action | Knowledge Promotion 记录它*为何*关闭 —— 已合并并完成,与被放弃/被取代,是不同的知识,二者日后必须保持可区分。Roadmap Update 把它移出活跃表格。 |

#### Reopen(重开)

| | |
|---|---|
| Trigger | 一位人判定某个 `Closed` 或 `Archived` 的 Plan 需要重新变为活跃状态 —— 需求重新浮现,或者早先的关闭/归档被证明为时过早。 |
| Input | 一个 `Closed` 或 `Archived` 的 Plan,以及重开的明确原因。 |
| Output | 该 Plan 的状态回到某个活跃状态 —— 如果已有实现可以恢复则为 `In Progress`,如果它是在评审中途关闭的则为 `Review` —— 由重开它的人来决定。 |
| Next Action | Knowledge Promotion 记录它被重开以及原因 —— 一个被多次重开的 Plan 本身就是一个值得日后浮现的信号(参见 `architecture/engineering-loop.md` 的 Risk 输出)。Roadmap Update 把它移回某个活跃表格。 |

#### Archive(归档)

| | |
|---|---|
| Trigger | 一位人判定某个 `Closed` 的 Plan 应当永久移出活跃考量范围 —— 这有别于 Close,后者仍会出现在普通历史中并可以常规地重开。 |
| Input | 一个 `Closed` 的 Plan。 |
| Output | 该 Plan 的状态变为 `Archived` —— 仅作历史记录保留,与 `architecture/project-registry.md` 自身对 `Archived` 项目状态的定义相呼应("不再维护,仅供参考保留;在未先确认应当解除归档之前,不要在此提议新工作")。 |
| Next Action | Knowledge Promotion 记录归档决策及原因。Roadmap Update 把它从每一个活跃表格中移除,只留下一个历史引用。重开一个 `Archived` 的 Plan 是可能的,但需要一次专门的、全新且明确的 Reopen 决策 —— 绝不会像重开一个仅仅是 `Closed` 的 Plan 那样被当作常规操作。 |

#### Escalate(上报)

| | |
|---|---|
| Trigger | 一位评审者 —— 或由决策引擎自身知识所浮现出的某个模式,例如某个 Plan 因搁置过久而被 `architecture/engineering-loop.md` 标记为 Risk —— 判定该 Plan/PR 无法在正常评审层级上解决(反馈相互冲突,或该判断超出了某位评审者的权限)。 |
| Input | 一个卡住或存在争议的 Plan/PR。 |
| Output | 该 Plan 被标记为 `Escalated` —— 在一位特定的、被指名的决策者解决它之前,它不会通过其正常的 gate 向前推进。 |
| Next Action | Knowledge Promotion 记录该次上报及原因。Roadmap Update 把它显著地浮现出来 —— 放在下一份工程报告(Engineering Report)的 Risk 部分,而不是让它悄无声息地停在 `In Progress`/`Review`。 |

#### Defer(暂缓)

| | |
|---|---|
| Trigger | 一位人(或 OpenClaw,须经人工确认)判定某个 Plan 是有效的,但当下不应推进 —— 不是被驳回,不是被关闭,只是现在不做。 |
| Input | 一个处于任何 Merge 之前阶段的 Plan,以及一个明确原因,并在已知的情况下附带一个重新考虑它的条件。 |
| Output | 该 Plan 的状态变为 `Deferred` —— 暂停,既不推进也不关闭。 |
| Next Action | Knowledge Promotion 记录暂缓原因和重访条件。Roadmap Update 把它从 `In Progress`/`Next Plans` 移入一个搁置区,这样在重访条件满足之前,`architecture/engineering-loop.md` 的"Recommend Next Plan"(推荐下一个计划)步骤就不会每次运行都重新建议它。 |

## Decision → Knowledge Promotion → Roadmap Update(Task 3)

```
Decision
  │
  ▼
Knowledge Promotion
  │
  ▼
Roadmap Update
```

**一个 Decision 从不直接写入 Memory。** Knowledge Promotion 有意地夹在两者之间:一个原始决策的每一个细节(谁点了什么、在哪个时间戳、在哪个 UI 里)并非都值得作为持久记忆保留 —— 其中大部分是一次性的事件日志。Knowledge Promotion 正是那个判断步骤,它决定一个 Decision 里有哪些内容真正值得作为一条常设事实提升进 Memory(一个日后会复发的驳回原因、一个日后必须核对的暂缓条件、一个值得关注的上报模式),而哪些可以只作为 PR/决策本身上的临时记录留存。这与 Claude Code 自身记忆系统所遵循的纪律如出一辙 —— 保存规则和稳定的决策,而非一次性状态 —— 只不过此处把它应用在组织层面,而非单次会话层面。

只有在 Knowledge Promotion *决定了*什么是持久的*之后*,Roadmap Update 才会发生 —— 路线图反映的是已提升的知识,而非原始决策。这正是为什么这条链是 Decision → Knowledge Promotion → Roadmap Update,而不是直接的 Decision → Roadmap Update:跳过提升步骤会意味着路线图积累的是噪声,而非经过筛选的状态。

**与 `architecture/engineering-workflow.md` 第 10 阶段(Memory Update)的关系:** 那一阶段把"Memory Update"描述为一个同时也覆盖 Roadmap 状态的单一步骤。本文件专门针对 Decision 这一产物,对同一片领域做了更深入的说明 —— Knowledge Promotion *就是*第 10 阶段中"Memory"那一半得以填充的机制,而它的输出随后驱动"Roadmap"那一半。这两份文件描述的是同一个机制在两个详略层次上的呈现,而非两个不同的机制。

## 决策状态机(Decision State Machine)(Task 4)

它与 `architecture/engineering-workflow.md` 中十一阶段的生命周期是组合关系,而非替代关系 —— 那个生命周期是设定好的路径;这个状态机在其之上补充了决策所能产生的分支(`Deferred`、`Escalated`、`Archived`,以及反向的 `Reopen`)。

```
Draft ──▶ In Progress ──▶ Review ──▶ Approved ──▶ Merged ──▶ Closed ──▶ Archived
              ▲              │           │                     │           │
              │         Reject/Defer   Reject                Reopen ◀──────┘
              │              │           │                     │
              └──────────────┴───────────┴─────────────────────┘
                                    (Escalate: freezes the current
                                     state until a named decision-
                                     maker resolves it, then resumes
                                     from where it was)
```

| Current State | Decision | Next State |
|---|---|---|
| Review | Approve(非最终 gate) | Review(下一个 gate) |
| Review | Approve(最终 gate —— Human Approval) | Approved |
| Review | Reject | In Progress |
| Review | Defer | Deferred |
| Review | Escalate | Escalated(解决后回到 Review 恢复) |
| Approved | Merge | Merged |
| Approved | Reject | In Progress(罕见 —— 在合并实际发生之前撤销批准) |
| Merged | Close | Closed |
| Draft / In Progress / Review / Approved | Close | Closed(提前关闭 —— 参见 `architecture/engineering-workflow.md` 第 11 阶段) |
| Closed | Reopen | In Progress 或 Review |
| Closed | Archive | Archived |
| Archived | Reopen | In Progress(需要一次全新且明确的理由 —— 非常规操作) |
| Deferred | (重访条件满足) | Review 或 In Progress,取决于它离开时所处的状态 |
| Escalated | (被指名的决策者解决它) | Review 或 Approved,取决于它离开时所处的状态 |

**关于 `docs/roadmap.md` 状态词汇表的说明:** 路线图当前的状态列表为 `Draft`/`In Progress`/`Review`/`Approved`/`Merged`/`Closed`。本状态机新增了 `Deferred`、`Escalated` 和 `Archived` 作为一个 Decision 能够产生的状态。这在本文件所需要的与 `docs/roadmap.md` 当前所记录的之间,存在一个真实的缺口 —— 此处如实标记出来,而非悄悄绕过;把路线图自身的词汇表与本文件相互对齐,留作后续工作,不在本 PR 中展开(超出范围 —— 参见 Constraints 约束)。

## 设计意图(validation,校验)

- **决策驱动 Memory、Roadmap 和 Next Plan —— 从不直接驱动 GitHub。** 上文每一种决策类型的 Next Action 都以 Knowledge Promotion 和 Roadmap Update 结束,从不以"决策引擎执行某个 GitHub 动作"结束。真正的 GitHub 侧动作(合并、关闭、重开)总是已经发生过了,由一位人执行,发生在决策引擎的 Next Action 运行之前。
- 每一种决策类型的 Output 都是一次**状态变更**,而非一次**对 GitHub 的副作用** —— 本文件定义的是组织知识发生了什么,而非哪些按钮被点击了。

## 参考(Reference)

- `architecture/engineering-workflow.md` —— 本状态机的"happy path"(理想路径)所遵循的十一阶段生命周期,其中第 10 阶段(Memory Update)的说明比本文件浅。
- `architecture/engineering-loop.md` —— Escalate/Defer 标记预期会在此处作为 Risk 浮现,以及读取 Roadmap 状态来 Recommend Next Plan(推荐下一个计划)的地方。
- `docs/roadmap.md` —— 本文件所扩展的状态词汇表(参见上面的说明)。
- `architecture/project-registry.md` —— 本文件的 `Archive` 决策在 Plan 层面所呼应的 `Archived` 项目状态定义。
- `policies/ai-pull-request-policy.md` —— 为什么 Merge 始终是一个由人执行、而决策引擎只做观察的 GitHub 动作。
