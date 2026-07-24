> **中文翻译版** · 英文正本以 `roadmap-engine.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD Roadmap Engine(路线图引擎)

## 目的

Roadmap Engine 将 Human Decisions(人类决策)以及 Knowledge Promotion(知识提升)的产出转化为组织状态 —— 即每个 Plan 当前处在哪个位置 —— 并推荐接下来应该做什么。它正是那块闭合了 `architecture/engineering-loop.md` 在 "Wait Human Decision"(等待人类决策)处留下缺口的拼图:本文件描述的,就是在人类做出某项决定与循环下一次运行接手其后果之间所发生的事情。

与 `decision/decision-engine.md` 一样,Roadmap Engine 是一个 **状态追踪层,而非执行层。** 它从不调用 GitHub API,从不开分支或开 PR,也从不把工作指派给某个 Agent。它唯一的产出是一份推荐以及一份更新后的 Roadmap 状态;是否据此采取行动,由 Human 决定。

## Roadmap State 与 Decision State —— 并非同一个概念

**Decision State(决策状态)是一个事件。Roadmap State(路线图状态)是一种持续存在的状况。**

`decision/decision-engine.md` 定义了八种 Decision 类型 —— Approve、Reject、Merge、Close、Reopen、Archive、Escalate、Defer —— 每一种都是 Human 所执行的一次瞬时动作。一个 Decision 在某个时间点发生一次,随即结束。

Roadmap State 则是一个 Plan 在两次 Decision *之间* 所处的状态 —— 它会一直持续,直到下一个 Decision 将其改变。同一个 Decision 甚至可能因上下文不同而产生不同的 Roadmap State(见下文 `## Transition Rules` 中的 `Reject`,它可能落到 `Closed`,也可能落到 `Blocked`)。把两者混为一谈 —— 把"这个 Decision 是 Defer"和"这个 Roadmap State 是 Deferred"当作可以互换的事实 —— 恰恰会丢失状态机所需要的信息:一个 Plan *为什么* 处于某个状态,而不仅仅是它处于该状态这件事。

## Roadmap State 模型(Task 1)

| State | 含义 |
|---|---|
| **Draft** | Plan 已撰写,尚未开分支/开 PR。 |
| **In Progress** | 实现分支处于活动状态。 |
| **Review** | Draft PR 已开启,处于 Architecture Review(架构评审)或 Implementation Review(实现评审)中。 |
| **Approved** | 已通过 Human Approval(人类批准),但尚未合并。 |
| **Merged** | PR 已合并到 `main`(或某个项目的集成分支)。这只是一个纯粹的 GitHub 事实 —— 仅此而已。尚未达到 Completed。 |
| **Blocked** | 无法推进 —— 或是存在未解决的外部依赖,或是存在等待特定决策者处理的 Escalation。这不是终态(见 `## Transition Rules`)。 |
| **Deferred** | 计划有效,但某位 Human 决定当前暂不推进。这不是终态 —— 当其复审条件被满足时即可恢复。 |
| **Completed** | 包含 `Merged` 所隐含的一切,**并且额外要求**:合并后的 Validation 已通过(`architecture/engineering-workflow.md` Stage 9)、`docs/roadmap.md` 已同步、Knowledge Promotion 已评估,且不再遗留任何必需的交付物。确切的证据清单见 `## Transition Rules` 的 `Completion` 一行。 |
| **Closed** | 已结束 —— 或是正常结束(在 Completed 之后),或是提前结束(被放弃/被取代)。 |
| **Archived** | 永久移出活动考量范围。重新开启需要一份全新的、明确的正当理由,而非例行操作。 |

**`Merged` 与 `Completed` 并非同义词。** 一个 PR 可能会在 `Merged` 状态停留一段时间,才把 Completion 证据完全满足 —— 代码已经落地,但组织层面的记账工作(Validation、Roadmap 同步、Knowledge Promotion)还没跟上。把"已合并"自动理解为"已完成"正是本次对账(reconciliation)要弥合的缺口;`docs/roadmap.md` 的词汇表现在把这两个状态清晰地分开承载(见 `## Roadmap Vocabulary Update`)。

### 状态链(理想路径)

```
Draft → In Progress → Review → Approved → Merged → Completed → Closed → Archived
```

`Blocked` 和 `Deferred` 并不是这条线上的点 —— 它们是任何"尚未 Merged"的状态都可以进入、随后再离开的分支,具体见下文 `## Transition Rules`。

## Roadmap Inputs(输入,Task 2)

| Input | Roadmap Engine 从中读取的内容 |
|---|---|
| **Human Decision** | Decision 本身(类型、目标、原因)—— 大多数状态转换的直接触发因素。 |
| **Knowledge Promotion Result** | `knowledge/knowledge-promotion.md` 从该 Decision 中提升出来的任何内容 —— 即应当随 Roadmap 条目一同保留的持久化理由,而不仅仅是那个光秃秃的状态变化。 |
| **Current Roadmap** | `docs/roadmap.md` 中该 Plan 现有的状态 —— 任何转换都是相对于该 Plan 当前所处位置而言的。 |
| **Project Registry** | `architecture/project-registry.md` —— 某个 Plan 属于哪个项目,以及该项目自身的 Status,用于交叉核对(例如,不要为一个 `Archived` 项目推荐新工作)。 |
| **Dependency State** | `depends_on`/`blocked_by`/`unblocks`/`supersedes` 关系图 —— 见 `## Dependency Handling`。 |
| **GitHub Merge State** | 某个 PR 在 GitHub 上是否确实已合并 —— Roadmap Engine 会去确认这一点,而不是假定一个 Merge Decision 就意味着已合并(Decision 记录的是某个 Human 执行了合并;这个 Input 用于核实合并是真实发生的)。 |

## Transition Rules(转换规则,Task 3)

| Decision | 触发条件 | 前置条件 | 当前状态 | 下一状态 | 所需证据 |
|---|---|---|---|---|---|
| **Approve** | 某位评审者(在最终关卡处只能是 Human)在当前关卡批准该 PR。 | 该关卡处没有未解决的异议。 | Review | Approved | 那条 Approve Decision 记录 —— 谁批准的、在哪个关卡批准的。 |
| **Merge** | 某位 Human 在 GitHub 上合并了已 Approved 的 PR(Roadmap Engine 只是观察这件事,从不亲自执行)。 | GitHub Merge State 确认该 PR 确实已合并。 | Approved | **Merged** | 那条 Merge Decision 记录 **以及** 已确认的 GitHub Merge State —— 二者缺一不可。这只确立 `Merged`,而非 `Completed` —— 见下文 `Completion`。 |
| **Completion** *(并非 Decision Engine 的一种类型 —— 见下方说明)* | Roadmap Engine 评估某个 `Merged` Plan 的完成证据是否已被完全满足。 | 下方 Completion 证据中的全部五项。 | Merged | Completed | GitHub 合并已确认;合并后的 Validation 已通过;`docs/roadmap.md` 已同步;Knowledge Promotion 已评估;不再遗留任何必需的交付物。是全部五项,而非其中一部分。 |
| **Close** | 一次 Close 决策,可以是正常的(在 Completed 之后),也可以是提前的(被放弃/被取代)。 | Completed(正常路径),或任何更早的状态附带一个明确的提前关闭原因。 | Completed,或任何"尚未 Completed"的状态 | Closed | 那条 Close Decision 记录,若为提前关闭则附带原因。 |
| **Reject** | 某位评审者判定该 PR/Plan 无法按当前范围推进。 | 一个明确的驳回原因。 | Review 或 Approved | 如果原因意味着当前方法/范围无效(需要一个全新的 Plan,而非一次修复),则为 **Closed** —— 如果原因是一个外部的、可解决的依赖或前置条件,则为 **Blocked**。 | 那条带有原因的 Reject Decision 记录 —— 决定落到两个下一状态中的哪一个,取决于原因本身,而不仅仅取决于 Reject 这个决策。 |
| **Defer** | 某位 Human(或 OpenClaw,须经 Human 确认)判定该 Plan 有效但当前不应推进。 | 一个明确的原因,以及在已知时给出的复审条件。 | Draft、In Progress、Review 或 Approved | Deferred | 那条带有原因和复审条件的 Defer Decision 记录。 |
| **Escalate** | 某位评审者,或 `architecture/engineering-loop.md` 的 Risk 输出所暴露出的某种模式,判定该 Plan 无法在常规评审层级解决。 | 该 Plan 卡在某个关卡处。 | Review 或 Approved | Blocked | 那条带有原因的 Escalate Decision 记录。 |
| **Archive** | 某位 Human 决定某个 `Closed` Plan 应当永久移出活动考量范围。 | 该 Plan 处于 Closed。 | Closed | Archived | 那条带有原因的 Archive Decision 记录。 |
| **Reopen** | 某位 Human 决定某个 `Closed` 或 `Archived` Plan 需要重新变为活动状态。 | 一个明确的原因。 | Closed 或 Archived | In Progress | 那条带有原因的 Reopen Decision 记录。(始终经由 In Progress 路由,即便原本是在 Review 阶段关闭的 —— 重新开启会在恢复评审前重新验证,而不是假定旧的评审状态仍然有效。) |

**`Completion` 有意不作为 `decision/decision-engine.md` 八种 Decision 类型之一**,而且本文件也不在那里添加第九种(超出本次对账范围 —— 见 Constraints)。合并是一个 Human 的动作(即 `Merge` Decision);变为 `Completed` 则是 Roadmap Engine *针对上述五项清单评估证据*,而不是某个 Human 去点击的另一件独立的事。实践中,仍然由某位 Human(或 OpenClaw)来确认清单已被满足 —— 但这条 Transition Rule 真正依据的,是那份清单,而不是一次离散的批准点击。

**`Blocked` 并不是死胡同。** 有两种不同的 Decision 会落到那里(`Reject` 和 `Escalate`),对应两种不同的原因 —— 用以区分它们的是 Required Evidence(所需证据)那一列,因为状态本身并不说明一个 Plan 为什么被 Blocked。一旦阻塞条件解除(通过 `## Dependency Handling` 追踪),该 Plan 便经由一次全新的普通 Decision 恢复(通常是 `Approve`,或者干脆恢复实现)—— 本文件不需要为"解除阻塞"设一种第九类 Decision;它就是上面那套 Transition Rules,在此前缺失的前置条件被满足后再次应用一遍。

## Next Active Plan Selection(下一个活动 Plan 的选择,Task 4)

按以下顺序:

1. **Approved、Merged,或以其他方式尚未 Completed** —— 完成某件已经过了评审的事情,优先级高于开启任何新工作,无论它是仍在等待合并,还是已经合并、只是在等待 Completion 证据。这能把在制品(work-in-progress)保持在低水平,并且与 `docs/roadmap.md` 现有的 Scheduling rule(调度规则,"在开启新的 Plan 之前先完成正在进行的工作")相符。
2. **依赖已满足** —— 在剩下的项目中,排除任何 `depends_on` 关系图尚未完全解决的项。
3. **无阻塞者** —— 排除任何当前处于 `Blocked` 的项,或 `blocked_by` 某个尚未解决之物的项。
4. **最高优先级** —— 在剩余候选者中,优先选择由 Human 指派的最高优先级。
5. **最小、最可执行的范围** —— 同等优先级候选者之间的决胜规则:优先选择实际最快能完成的那个,以保持循环持续推进。

**Roadmap Engine 在此处唯一的产出是一份 `Recommended Next Plan`(推荐的下一个 Plan)。** 它被明确禁止:

- 自动启动一个 Plan。
- 自动创建一个分支。
- 自动创建一个 PR。
- 自动指派 Claude Code(或任何 Agent)。

每一份推荐都要等待一个明确的 Human Decision,之后 `architecture/engineering-workflow.md` Stage 3(Feature Branch,特性分支)的工作才会开始 —— 这与本 Engineering OS 里其他每一份文件早已恪守的"没有人类决策,任何事情都不推进"原则如出一辙。

## Dependency Handling(依赖处理,Task 5)

四种关系类型:

| 关系 | 含义 | 示例 |
|---|---|---|
| **depends_on** | 一个一般性的前置条件 —— 在另一个 Plan 完成之前,本 Plan 无法算作 *complete*,但当前不一定正被卡住。 | `FOUNDATION-ROADMAP-ENGINE depends_on PR #10 and PR #11`(本文件自身对 Decision Engine 和 Knowledge Promotion 的依赖 —— 关于为何本组件的标识符是 `FOUNDATION-ROADMAP-ENGINE` 而非 `PLAN-0009`,见 `## Roadmap Vocabulary Update`) |
| **blocked_by** | 一种 *活动的*、即时的阻塞关系 —— 在另一个 Plan 解决之前,本 Plan 实实在在地无法合并或推进。通常用于堆叠式(stacked)PR。 | `PR #4 blocked_by PR #3` |
| **unblocks** | `blocked_by` 的逆向表述,从另一个方向陈述,这样那个进行阻塞的 Plan 自身的记录里就会显示出它所阻挡的一切,而不只是被阻塞 Plan 的记录里显示是什么在阻挡它。 | `PR #3 unblocks PR #4` |
| **supersedes** | 替换,而非排序 —— 本 Plan 使另一个 Plan 变得过时。被取代的那个 Plan 应当被 Closed(其 Close Decision 的原因会引用那个进行取代的 Plan)。 | 一个修订后的 Plan `supersedes` 早先一次针对同一目标、已被放弃的尝试。 |

`depends_on` 与 `blocked_by` 相关但有别:每一个 `blocked_by` 关系都隐含一个 `depends_on` 关系,但并非每一个 `depends_on` 都已经是一个活动的阻塞者(一个 Plan 可以依赖某个在当前生命周期阶段尚未成为硬性阻塞者的东西)。Next Active Plan Selection(Task 4,步骤 2–3)会同时检查二者。

## Closed Loop(闭合循环,Task 6)

```
Registry
  │
  ▼
Engineering Loop
  │
  ▼
GitHub / HCP Terraform / CI
  │
  ▼
Notification
  │
  ▼
Human
  │
  ▼
Decision Engine
  │
  ▼
Knowledge Promotion
  │
  ▼
Roadmap Engine
  │
  ▼
Recommended Next Plan
  │
  ▼
Human Decision
  │
  ▼
Engineering Loop
```

这就是本 Engineering OS 里其他每一份文件都只是其中一环的完整周期:

- **Registry → Engineering Loop → GitHub/HCP Terraform/CI**:`architecture/engineering-loop.md` 的 Steps 1、4–7 —— OpenClaw 读取状态,以只读方式检视一切。
- **CI → Notification → Human**:`architecture/engineering-loop.md` Step 8 的 Engineering Report(工程报告)正是作为一条 Notification 呈现给 Human 的东西 —— 循环生成它,而必须有一位 Human 看到它,后续才会发生任何事情。
- **Human → Decision Engine**:某位 Human 做出八种 Decision 之一;`decision/decision-engine.md` 将其记录下来。
- **Decision Engine → Knowledge Promotion**:`knowledge/knowledge-promotion.md` 从原始 Decision 中过滤出具有持久价值的内容。
- **Knowledge Promotion → Roadmap Engine**:本文件同时消费原始 Decision(上文的 Roadmap Inputs)与被提升出来的内容,并经由 `## Transition Rules` 产出新的 Roadmap State。
- **Roadmap Engine → Recommended Next Plan → Human Decision**:`## Next Active Plan Selection` 的产出,它 —— 一如本系统中其他每一份推荐 —— 都要等待一位 Human,任何事情才会发生。
- **Human Decision → Engineering Loop**:周期重新开始;循环的下一次运行(`architecture/engineering-loop.md` 的 Manual/Daily/Weekly/Release 节奏)从新状态接手。

这个循环中没有任何一步是可选的,且在越过一个 Human 决策点之后没有任何一步是自动的 —— 正是这一性质,使它成为一个 *闭合的* 循环,而不是一条最终仍需人类手动干预并重启的单向流水线。

## Roadmap Vocabulary Update

`docs/roadmap.md` 的 `## Plan status vocabulary` 一节现在按状态链顺序承载了上文 `## Roadmap State model` 中全部十个状态:`Draft`、`In Progress`、`Review`、`Approved`、`Merged`、`Blocked`、`Deferred`、`Completed`、`Closed`、`Archived`。`Merged` 与 `Completed` 在那里被定义为彼此不同的状态,与本文件一致 —— 而不是同义词,本次对账的一个更早版本曾错误地把它们当作同义词。

**组件标识符:** 本文件 —— 即 Roadmap Engine 本身 —— **不是** `PLAN-0009`。`docs/roadmap.md` 的 `PLAN-0009` 槽位属于 `Playbooks`;对现有的 `PLAN-0001`–`PLAN-0010` 重新编号,对任何对账而言都被明确排除在范围之外。那些不属于顺序 `PLAN-XXXX` 编号体系的基础性 Engineering-OS 组件,改用一个 `FOUNDATION-*` 标识符,与 `FOUNDATION-WORKFLOW` 和 `FOUNDATION-LOOP` 已经确立的模式相符:本组件是 `FOUNDATION-ROADMAP-ENGINE`。`docs/roadmap.md` 的 Completed Plans 表现在也承载了 `FOUNDATION-DECISION`(Decision Engine,PR #10)、`FOUNDATION-KNOWLEDGE`(Knowledge Promotion,PR #11)和 `FOUNDATION-ROADMAP-ENGINE`(本文件,PR #12)—— 这三者此前均已合并却没有对应的 Roadmap 行,现已对齐 —— 每一个的状态都是 `Completed` 而非 `Merged`,因为它们各自的四项完成标准均已满足(已合并、已通过评审验证、已出现在 Roadmap 中,且其内容已经反映了 Knowledge Promotion 自身的推理)。

本次对账不会改写 `docs/roadmap.md` 中任何现有的 `PLAN-0001`–`PLAN-0010` 行、状态或历史事实 —— 只做新增。

## 参考

- `architecture/engineering-loop.md` —— 本文件的 Roadmap Inputs 从这里读取(Steps 1–2),以及 "Recommend Next Plan" / "Wait Human Decision"(Steps 9–10)在这里点到了本文件如今完整规定的内容。
- `decision/decision-engine.md` —— 本文件 Transition Rules 所消费的八种 Decision 类型,以及为何 Roadmap Engine 与 Decision Engine 一样,从不直接触及 GitHub。
- `knowledge/knowledge-promotion.md` —— `Decision → Knowledge Promotion → Roadmap Update` 这条链条,本文件是其中的 "Roadmap" 那一半。
- `architecture/engineering-workflow.md` —— 那个十一阶段的 Plan 生命周期,其 Stages 5–9(从 Review 到 Validation)正是本文件的 Roadmap States 所追踪的。
- `architecture/project-registry.md` —— 一个 Plan 的项目上下文的来源,以及那个 `Archived` 项目状态定义,本文件的 `Archived` Roadmap State 在 Plan 层面对其做了镜像。
- `docs/roadmap.md` —— 本引擎所更新的那份 Roadmap;本 Plan 在其中所做的唯一一处改动见上文 `## Roadmap Vocabulary Update`。
