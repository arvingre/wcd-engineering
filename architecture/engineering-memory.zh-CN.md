> **中文翻译版** · 英文正本以 `engineering-memory.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 工程记忆(Engineering Memory)

## 目的

工程记忆(Engineering Memory)是持久化的组织记录,供 OpenClaw 和其他获授权的 AI 代理使用,使其能够延续工作,而无需在每个会话中重新发现相同的事实。它记录已核实的工程现实:决策、事故、运行手册(runbook)、经验教训、模式(pattern)、项目状态,以及支撑它们的证据。

记忆不是对话记录的归档,也不是模型输出的无限制堆放。一条记录只有在结构化、可追溯、保持最新,并有已批准来源(如已合并的 PR、已采纳的 ADR、事故证据、经验证的运行手册,或明确的人工决策)支撑时,才成为组织记忆。

本文件为整个 WCD 工程操作系统(Engineering OS)定义记忆模型。项目仓库可以保留项目专有的记忆,但它们遵循本文所定义的相同记录类型、生命周期、来源(provenance)规则和更新规则。

## 设计原则

1. **先证据,后结论。** 每一条持久化的论断都链接到确立它的来源。
2. **当前事实必须明确。** 已被取代和已过时的记录仍保持可追溯,但绝不会被当作当前内容呈现。
3. **记忆是结构化的。** 代理不得依赖冗长的聊天历史或无限增长的 Markdown 文件。
4. **验证之后再写入。** 拟定的发现在被接受的事件授权其提升(promote)为持久记忆之前,始终只是工作上下文(working context)。
5. **项目隔离。** 项目专有的事实保持在其项目范围内,除非有意提升为组织级记忆。
6. **无密钥。** 凭据、令牌、私钥、原始敏感载荷和 Terraform state 永远不得进入工程记忆。
7. **人的权威始终是最终的。** AI 代理可以在已核实的事件之后起草和更新记录,但不得凭空捏造审批,也不得提升有争议的结论。

## 记忆分层

工程记忆分为四层,以便代理只加载当前任务所需的上下文。

| 层 | 目的 | 典型内容 | 加载行为 |
|---|---|---|---|
| Working Context(工作上下文) | 为一个活跃的 Plan 或调查提供临时上下文 | 假设、任务笔记、不完整的证据 | 仅为活跃任务加载;关闭后删除或归档 |
| Project Memory(项目记忆) | 关于单个项目的持久事实 | 项目状态、活跃约束、项目决策、项目事故、运行手册 | 在读取 `architecture/project-registry.md` 并选定项目后加载 |
| Organizational Memory(组织记忆) | 可跨项目复用的知识 | 工程标准、跨项目模式、运作规则、共享经验教训 | 按主题加载,而非全量加载 |
| Evidence Archive(证据档案) | 不可变或仅追加的来源引用 | PR、ADR、事故记录、CI 报告、Terraform run 引用 | 仅在需要验证或审计时检索 |

各层彼此相关,但不可互换。Working Context 可能包含未经验证的想法。Project Memory 和 Organizational Memory 只包含已提升的记录。Evidence Archive 是证明层,而非摘要层。

## 记录类型

工程记忆使用六种持久记录类型。

### 1. Decision(决策)

一条决策记录一项持久的工程选择及其当前状态。

必填字段:

- `id`:稳定标识符,例如 `DEC-0001`
- `scope`:组织或项目名称
- `title`
- `status`:Proposed、Adopted、Superseded、Rejected
- `decision`
- `rationale`
- `constraints`
- `source`:ADR、已批准的 PR,或明确的人工决策
- `effective_at`
- `supersedes` / `superseded_by`(在适用时)

当存在 ADR 时,ADR 仍是权威的设计工件。Decision 记忆记录是简洁的运营索引,告诉代理哪个 ADR 是当前有效的,以及它确立了什么规则。

### 2. Incident(事故)

一条事故记录一次观察到的失败、它的证据、影响、响应,以及已核实的结果。

必填字段:

- `id`:例如 `INC-2026-0001`
- `project`
- `started_at` 和 `resolved_at`
- `severity`
- `symptoms`
- `impact`
- `evidence_refs`
- `root_cause`:confirmed(已确认)、suspected(疑似)或 unknown(未知)
- `mitigation`
- `permanent_fix`
- `related_prs`
- `lessons`
- `status`:Open、Monitoring、Resolved、Closed

原始日志和指标载荷保留在证据系统中。记忆存储经核实的摘要和引用。

### 3. Runbook(运行手册)

一条运行手册记录一项经验证的运维流程。

必填字段:

- `id`:例如 `RUN-0001`
- `scope`
- `trigger`
- `preconditions`
- `steps`
- `verification`
- `rollback`
- `risk_level`
- `owner`
- `last_validated_at`
- `source`
- `status`:Draft、Validated、Deprecated

一份运行手册在其验证方法明确、且经过人工或一次成功的受控执行验证之前,不被视为可复用。

### 4. Lesson(经验教训)

一条经验教训记录一项已核实的观察,它应影响未来的工作,但尚未成为强制性标准。

必填字段:

- `id`:例如 `LES-0001`
- `scope`
- `observation`
- `evidence_refs`
- `recommended_behavior`
- `confidence`:Low、Medium、High
- `review_after`
- `status`:Active、Promoted、Retired

一条被反复验证的高置信度 Lesson 之后可能被提升为 Pattern、Standard、Runbook 或 ADR。

### 5. Pattern(模式)

一条模式记录在多个已核实案例中出现的、反复发生的问题或可复用的解决方案。

必填字段:

- `id`:例如 `PAT-0001`
- `scope`
- `name`
- `signal`
- `conditions`
- `known_causes`
- `recommended_response`
- `evidence_refs`:至少两个独立案例,除非有人工明确批准的例外
- `confidence`
- `status`:Candidate、Validated、Deprecated

模式不得由单一的推测性事故创建。Lesson 与 Pattern 的区分可防止过早的泛化。

### 6. Project State(项目状态)

Project State 是针对已注册项目的紧凑型当前状态记录。

必填字段:

- `project`
- `current_phase`
- `active_plans`
- `open_risks`
- `current_constraints`
- `latest_release_or_baseline`
- `last_verified_at`
- `source_refs`

`architecture/project-registry.md` 仍是全系统级的入口点。Project State 以运营中不断变化的信息对其进行补充,并且绝不得默默地与 Registry 相矛盾。

## 存储布局

默认的仓库布局为:

```text
memory/
  organization/
    decisions/
    lessons/
    patterns/
    runbooks/
  projects/
    <project-name>/
      state.md
      decisions/
      incidents/
      lessons/
      patterns/
      runbooks/
  archive/
```

每条持久记录存储在各自的文件中。禁止使用大型的仅追加文件,因为它们加载成本高、难以审查,且并发更新时不安全。

推荐的文件名:

```text
DEC-0001-short-title.md
INC-2026-0001-short-title.md
RUN-0001-short-title.md
LES-0001-short-title.md
PAT-0001-short-title.md
```

## 记录生命周期

所有持久记录都遵循以下生命周期:

```text
Observed
  -> Drafted
  -> Verified
  -> Active
  -> Superseded / Deprecated / Retired
  -> Archived
```

- **Observed(已观察)**:证据存在,但尚未写入记忆记录。
- **Drafted(已起草)**:代理或人工已创建结构化的候选记录。
- **Verified(已验证)**:记录已对照其来源证据核对。
- **Active(生效)**:该记录可供代理安全地用作当前上下文。
- **Superseded / Deprecated / Retired(已取代 / 已弃用 / 已退役)**:记录仍可追溯,但不再是当前指导。
- **Archived(已归档)**:为审计与历史而保留;从常规检索中排除。

任何代理都不得从 Observed 直接跳到 Active。

## 提升(Promotion)规则

一次记忆写入必须有一个提升触发条件。

| 触发条件 | 记忆操作 |
|---|---|
| PR merged(已合并) | 更新受影响的 Project State;仅当已合并的变更支持时,才新增或更新 Decision、Runbook、Lesson 或 Pattern |
| ADR adopted(已采纳) | 创建或更新相应的 Decision 记录 |
| Incident resolved(事故已解决) | 创建或最终确定 Incident;起草 Lesson;仅在有足够的反复证据时才提升 Pattern |
| Human decision(人工决策) | 记录该决策及其确切范围;尽可能链接对应的对话、issue 或 PR |
| Runbook 成功验证 | 将 Runbook 标记为 Validated 并更新 `last_validated_at` |
| Standard 变更 | 取代相冲突的记忆并更新受影响的 Project State 记录 |

PR 的开启、模型的建议、CI 失败,或未经确认的假设,都不足以创建 Active 的持久记忆。

## 更新责任归属

| 操作 | 责任方 |
|---|---|
| 起草候选记录 | OpenClaw、其他被指派的代理,或人工 |
| 验证证据与范围 | OpenClaw 审查者和/或人工;绝不仅依赖起草该记录的代理 |
| 提升为 Active | OpenClaw 在经过已核实的触发之后,或由人工直接进行 |
| 取代或退役 | OpenClaw 在被接受的来源变更之后,或由人工进行 |
| 归档 | OpenClaw 按照保留策略进行 |
| 解决冲突 | 人工 |

这遵循工程工作流(Engineering Workflow):在 Merge 之后,OpenClaw 在 Roadmap Update 和 Close 之前先执行 Memory Update。

## 检索协议

代理必须按以下顺序检索记忆:

1. 读取 `architecture/project-registry.md`。
2. 确定项目与任务范围。
3. 读取该项目的 `state.md`。
4. 仅按主题或标识符检索相关的 active 状态 Decision、Runbook、Lesson 和 Pattern。
5. 仅在验证某一论断、审查冲突,或做出高风险决策时,才打开来源证据。
6. 忽略 Draft、Superseded、Deprecated、Retired 和 Archived 记录,除非任务明确需要历史信息。

每当某条记录对结果有实质影响时,代理必须在 Plan、PR 描述、审查、RCA(根因分析)报告和建议中引用记忆记录的 ID。

## 冲突与过时处理

当两条记录相冲突时:

1. 优先采用来源类型更权威的记录:已采纳的 ADR 或明确的人工决策优先于 Lesson 或 Pattern。
2. 优先采用 Active 状态,而非非 Active 状态。
3. 仅当较新的生效来源明确取代了较旧的记录时,才优先采用它。
4. 不要仅凭日期推断取代关系。
5. 若权威关系仍不明确,停止推进并请求人工决策。

每条 Project State 记录都必须包含 `last_verified_at`。含有时效性运营事实的记录必须包含 `review_after`。超过该日期不会自动使记录失效,但会将记录标记为过时,并阻止代理将其视为高风险操作的充分证据。

## 记忆更新流程

在一个经批准的变更合并之后,OpenClaw 执行以下读/写循环:

1. 读取已合并的 PR、最终审查状态、关联的 Plan、受影响的 ADR 和已更改的文件。
2. 确定哪些现有记忆记录受到影响。
3. 起草最小必要的更新。
4. 对照已合并或已批准的证据,验证每一处变更的论断。
5. 在 `feature/memory-*` 分支上更新或创建记录。
6. 当更新内容重大、有争议、跨项目,或改动了 Decision、Pattern、Runbook 或组织规则时,开启一个 Draft PR。
7. 对于纯机械性的 Project State 刷新,一旦仓库的已批准自动化策略存在,则遵循该策略;在此之前,使用 Draft PR。
8. 在人工合并之后,更新 `docs/roadmap.md` 并关闭该 Plan。

记忆更新不得绕过 AI Pull Request Policy(AI 拉取请求政策)。AI 代理绝不直接向 `main` 提交,也绝不合并自己的记忆变更。

## 学习循环

工程记忆支持学习,但不会自动改写组织规则。

```text
Incident / Review / Delivery result
  -> Lesson candidate
  -> repeated evidence
  -> Pattern candidate
  -> validation
  -> Runbook / Standard / ADR proposal
  -> human approval
  -> active organizational rule
```

这是记忆工程(Memory Engineering)与学习工程(Learning Engineering)之间的边界:记忆保存已核实的经验;学习则基于该经验,对系统提出受控的变更。

## 安全与隐私

以下内容被禁止:

- 凭据、令牌、私钥、恢复码或密钥值
- Terraform state 或原始的 provider 凭据
- 在脱敏引用已足够时,仍保留的原始客户个人数据
- 含有敏感载荷的无限制生产日志
- 作为持久记忆而复制的私有聊天记录
- 模型的隐藏推理或思维链(chain-of-thought)

应改为存储引用、脱敏证据和已核实的摘要。对私有项目记忆的访问遵循该项目的仓库与身份控制。

## 最小可行实现

当以下基础存在时,PLAN-0005 即视为完成:

1. 本架构文档已获批准。
2. `memory/` 目录结构通过一个独立的实现 Plan 或后续提交引入。
3. 六种记录类型各自都存在一个记录模板。
4. 至少有一个真实的、已合并的变更经过 Memory Update 流程处理。
5. OpenClaw 能够检索 Project State 加上特定主题的记录,而无需加载整棵记忆树。
6. 不存在任何绕过 Draft PR 和人工合并控制的记忆写入路径。

## 非目标

本基础尚未实现:

- 向量数据库或语义搜索服务
- 对每个仓库文件或聊天消息的自动嵌入(embedding)
- 自主的在线训练或模型微调
- 将 Lesson 自动提升为 Pattern 或 Standard
- 集中式的企业审计数据库
- 跨公司共享私有的组织记忆

只有当基于文件的模型被证明不足,且有新的 Plan 定义了迁移、访问控制、成本和审计需求时,才可引入上述内容。

## 参考文献

- `architecture/project-registry.md` — 标识各项目及其权威仓库。
- `architecture/engineering-workflow.md` — 将 Memory Update 定义为必需的合并后阶段。
- `architecture/engineering-loop.md` — 消费先前的发现并产出 Memory Update。
- `docs/roadmap.md` — 安排 PLAN-0005 及后续的实现 Plan。
- `policies/ai-pull-request-policy.md` — 治理每一次由 AI 撰写的记忆变更。
- `standards/security/identity-boundary.md` — 定义记忆不得混淆的身份与凭据边界。
