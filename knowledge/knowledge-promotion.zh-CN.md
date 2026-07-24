> **中文翻译版** · 英文正本以 `knowledge-promotion.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 知识提升(Knowledge Promotion)

## 目的

知识提升是介于 Decision(一个原始的、一次性的事件 —— 谁在何时决定了什么)与 Memory(持久的、经过筛选的组织知识)之间的过滤器。本文件正是 `decision/decision-engine.md` 中 `Decision → Knowledge Promotion → Roadmap Update` 链所引用的那个机制:它精确规定了这种过滤是如何工作的 —— 哪些事实属于**Stable Knowledge**(稳定知识)、可以进入组织记忆(Organizational Memory),哪些属于**Temporary Events**(临时事件)、无论由谁来提升都绝不能进入其中。

核心规则,在此陈述一次,以便别处都能回指:**只有 Stable Knowledge 才进入组织记忆。** 一个 Decision 存在这件事本身,并不构成把某样东西写入 Memory 的理由。

## 提升规则(Promotion Rule)

### 进入 Memory(Stable Knowledge,稳定知识)

- 常设规则与政策 —— 例如"AI agent 从不合并"(`policies/ai-pull-request-policy.md`)。
- 具有长期影响的架构决策 —— ADR,以及它们背后的推理。
- 很可能复发的驳回原因 —— 这样同一个异议下次不会被一模一样地重新争论一遍。
- 暂缓条件及其重访触发条件 —— 在该 Plan 仍处于 Deferred 期间。
- 上报*模式* —— 跨多次上报反复出现的主题值得记住;单次一次性事件通常不值得。
- 稳定的身份/归属事实,一旦真正被指派之后(而非 `TBD` 占位符)。
- 已确认、已校验的项目级事实及其理由 —— 例如"选择 EKS 1.35 是因为 1.33 的标准支持将在几天内结束",而不只是那个光秃秃的版本号。
- 跨项目的结构性决策 —— 身份边界、工作流定义,以及本文件自身的这条提升规则。

### 绝不进入 Memory(Temporary Event,临时事件)

- 原始事件日志 —— 单个的时间戳、谁在什么 UI 里、以什么顺序点了什么。
- 进行中的/一次性的任务状态 —— 当前正在处理的一个分支、尚未解决的评审意见、任何几小时内就会变陈旧的东西。
- **原始可变状态,原样复制** —— `git log`/`git blame` 的字面当前输出、一份当前的 PR/issue 列表、当前的文件内容、当前的 CI 结果。把一份活的、正在变化的快照复制进 Memory,只会意味着从源状态往前走的那一刻起,Memory 就开始变陈旧。

  这**并不是**一条禁止提升任何来自查看当前状态之物的规则 —— 知识提升所处理的几乎一切都是这样开始的。区别在于原始状态本身与从中得出的结论之间:**从当前状态推导出来的稳定理由、约束、诠释和已批准的结论,在源状态改变之后仍然有用时,是可以被提升的。**"PR #5 当前有 3 条未决评审意见"是原始可变状态 —— 排除。"PR #5 的评审得出结论:因为 Y,所以 X 必须始终成立"是一个稳定结论,是*从*阅读那个 PR 中*推导出来的* —— 可以纳入,而且在 PR #5 的评论数已经改变、或该 PR 本身已经关闭很久之后,它仍然为真、仍然有用。
- 原始的 CI/构建日志。
- **机密、凭据、令牌 —— 在任何情况下、永远不**,无论其稳定与否。
- Terraform state 的*内容* —— 在这套 Engineering OS 中任何地方,被记录的都只有 workspace *名称*(`architecture/project-registry.md` 已经确立了这一点;知识提升继承了同一条边界,它不放松这条边界)。
- 没有决策内容的一次性闲聊。

**这是强制,而不仅仅是指引:** 提升流水线(Promotion Pipeline,见下文)的 Evaluate(评估)步骤会对照上述两份清单检查每一个候选项。凡是匹配到"绝不进入 Memory"中任何一项的候选项都会被拒绝,不论提升它的人是谁、也不论他有多确信它重要 —— 这份排除清单不是一个繁忙的提升流程可以跳过的建议。

## 提升流水线(Promotion Pipeline)

```
Decision
  │
  ▼
Evaluate
  │
  ▼
Stable?
  │
  ├── No ──▶ Discarded
  │
  └── Yes
        │
        ▼
      Memory
        │
        ▼
      Index
        │
        ▼
      Done
```

*(本 Plan 所规定的图里并没有 **No → Discarded** 这个分支,但为了流水线完整,它是必要的 —— 这里明确补上,而不是留作隐含。)*

1. **Decision** —— 输入:一个来自 `decision/decision-engine.md` 的 Decision(Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer),或者任何其他由一次 Review 或一个 Plan 所浮现、看起来可能属于 Stable Knowledge 的候选事实。
2. **Evaluate** —— 对照上面提升规则的两份清单检查该候选项。
3. **Stable?** —— 是/否的检查点。它不是一个被松散做出的判断 —— 它由 Evaluate 步骤对照规则得出的结果来回答,而不是由该候选项*感觉*上有多重要来回答。
4. **No → Discarded** —— **Discarded 精确地、且仅仅意味着"未提升到 Memory"。它绝不意味着源记录被删除或改写。** 该候选项来源的 Decision、Review 或 PR 仍然一如既往地原样存在于 GitHub 上(`decision/decision-engine.md` 的 Knowledge Promotion 步骤已经确立了这一点)—— Discarded 描述的是知识提升对它做了什么(拒绝把它复制进 Memory),而不是原始证据发生了任何变化。关于这与 Pruning(修剪,即一个事实落到活跃 Memory 之外的另一种方式)有何不同,参见下面的 `## Auditability`。
5. **Yes → Memory** —— 被提升的事实作为一条持久记录写入 Memory。
6. **Index** —— 新的 Memory 条目会从一个索引处被链接,以便日后可被发现,而不只是写入后被遗忘。(这与 Claude Code 自身记忆系统已经遵循的纪律相同:每个记忆文件都会在 `MEMORY.md` 里得到一行指向它 —— 知识提升在组织层面施加同一条索引要求。)
7. **Done.**(完成。)

## 让 Memory 不至无限增长(validation,校验)

选择性提升(大多数候选项在 Evaluate 时未通过而被 Discarded)相对于原始活动量约束了增长,但仅靠这一点还不够 —— 即便经过过滤,随着时间推移仍不断有更多决策发生,因此一个只追加(append-only)的 Memory 依然会永远增长下去。另有两条规则弥合这个缺口:

1. **Memory 条目是活的记录,就地更新 —— 而非只追加的日志。** 当一个已提升的事实发生变化时(某个项目的 Status 从 `Active` 变为 `Archived`,一个 Defer 条件得到解决),现有的 Memory 条目会被*更新*以反映新的现实,而不是原地不动、在旁边再追加第二条更新的条目。近乎重复的条目是知识提升做错了的迹象,而不是一种可接受的稳态。
2. **不再稳定的已提升事实会被修剪(pruned),而不是任其堆积。** 关于 Pruning 究竟做什么、不做什么,参见紧接下面的 `## Auditability` —— 它不是删除。

合起来:提升规则把 *Temporary Events* 完全挡在外面;就地更新加上修剪,则让 *Stable Knowledge* 本身在其不再真正稳定之后,不至于悄悄变成它自己那种杂乱 —— 而这两种机制都不会摧毁一个已提升事实所依据的证据。

## 可审计性(Auditability)

**Pruning(修剪)意味着从活跃的组织记忆中移除某一项。它不意味着删除或改写该项所依据的源证据 —— 这是两个不同的动作,而知识提升只执行前者。** 一个已提升的 Defer 条件,一旦得到解决,就不再需要留在*活跃* Memory 中 —— 只有最终的稳定结果(该 Plan 最终为何推进或未推进)才需要。一条已提升的 Escalation 记录,只有在它揭示了一个值得记住的*模式*时(依据上文的提升规则),才会在该次上报解决之后继续留存;那个一次性事件本身不需要留在活跃 Memory 中。在每一种情形下,被修剪掉的都是*活跃 Memory 中的那份副本* —— 绝不是它所取材的底层历史。

**历史证据始终可获取,独立于当前活跃 Memory 里有什么,可在以下位置找到:**

- GitHub 的 PR 与评审历史 —— 真实的评审意见、批准和讨论。
- ADR 历史 —— 曾经写过的每一份 ADR,包括被取代的那些(依据标准的 ADR 惯例,ADR 在一份较新的取代它时不会被删除 —— 旧的那份仍然保留,并标记为已被取代)。
- 决策记录(Decision records)—— `decision/decision-engine.md` 中八种决策类型所产生的那些产物。
- Git 历史 —— 对这套 Engineering OS 曾经包含过的每一个文件运行 `git log`/`git blame`。
- 证据存档(Evidence archive)—— 一个持久存储,用于存放任何提升后又被修剪、且不应仅因为离开了活跃 Memory 就彻底从视野中消失的东西。(截至本文件成文时尚未构建;此处将其命名为"提升后又被修剪、但仍可被引用的知识"的预定归宿,作为后续范围追踪,而非本 Plan 要构建的东西。)

**另有两条规则让这一点保持相互连接,而不只是理论上成立:**

- **被取代的知识会链接到取代它的那一个。** 当一个活跃 Memory 条目因其所记录的事实发生变化而被更新时,旧的理解不会被悄无声息、不留痕迹地覆盖 —— 新条目(或旧条目在证据存档中的记录)会带有一个回指,指向它所取代的内容以及为何取代,这样"我们过去为什么会那样认为 X"日后仍可回答,而不会丢失。
- **Memory 清理绝不能摧毁组织的审计历史。** 无论运行就地更新或修剪的是什么流程,它只作用于*活跃 Memory* —— 它绝不触碰 GitHub 的 PR/评审历史、ADR 历史、决策记录或 Git 历史,这些都是这套 Engineering OS 并不拥有其删除权的独立记录系统。

这也正是 **Discarded**(`## Promotion Pipeline` 中的第 4 步)与 **Pruned**(本节)之间精确的区别:Discarded 发生在 Evaluate 时,在任何东西被提升*之前* —— 此时并不存在要移除的活跃 Memory 副本,只有那份未被触动的原始 Decision/Review/PR 记录。Pruned 则发生在某个*已被*提升、之后又不再以其活跃形态有用的东西身上 —— 它在活跃 Memory 中的副本被移除,但(依据上面的规则)它的踪迹仍可通过上面那份历史证据清单被找到。

## 参考(Reference)

- `decision/decision-engine.md` —— 本文件深入规定的 `Decision → Knowledge Promotion → Roadmap Update` 链最初被引入的地方。
- `architecture/engineering-workflow.md` —— 第 10 阶段(Memory Update),本流水线的输出所汇入的那个生命周期阶段。
- `architecture/engineering-loop.md` —— 在其自身的巡检过程中读取已提升的 Memory(Step 1/3)。
- `architecture/project-registry.md` —— `Archived` 状态定义以及本文件提升规则所继承(而非重新定义)的 Terraform-state-content 排除项的来源。
