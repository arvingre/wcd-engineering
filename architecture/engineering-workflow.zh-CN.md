> **中文翻译版** · 英文正本以 `engineering-workflow.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD 工程工作流(Engineering Workflow)

## 目的(Purpose)

这是整个 WCD Engineering OS 的默认工作流 —— 每一项工程任务都会经历的那一套生命周期(lifecycle),从最初的想法到最终归档的记录,无论它涉及哪个仓库,也无论由哪个 AI agent(或人类)来完成工作。`docs/roadmap.md` 排定 *要做什么*(what);本文件定义每一个 Plan(计划)*如何*(how)从头走到尾。人类和 AI agent 都遵循它 —— 两者都没有另一条更快的独立路径。

本文件对 `policies/ai-pull-request-policy.md`(PLAN-0004)中已经确立的 PR 机制进行了泛化并赋予其完整形态 —— 那份策略是下文 Stage 3–8(第 3–8 阶段)在 Git 层面的切片;本文件则是围绕它的整个生命周期,包括分支存在之前发生了什么,以及 PR 合并之后发生了什么。

## 生命周期(Lifecycle)

```
Idea
  │
  ▼
Plan
  │
  ▼
Feature Branch
  │
  ▼
Draft PR
  │
  ▼
Architecture Review   ─── Gate 1
  │
  ▼
Implementation Review ─── Gate 2 (includes Security Review where applicable)
  │
  ▼
Human Approval         ─── Gate 3
  │
  ▼
Merge                  ─── Human only
  │
  ▼
Validation
  │
  ▼
Memory Update
  │
  ▼
Close
```

一个尚未满足其 Exit Criteria(退出条件)的阶段不会推进到下一阶段 —— 参见 `## Review Gates`。如果一个 Plan 被放弃或被取代,它也可以从任何较早的阶段直接进入 **Close**(关闭)(参见 `docs/roadmap.md` 中的 `Closed` 状态)—— 只要 Memory Update(记忆更新)仍然记录了它,这就是一种有效的结果,而不是对生命周期的违反。

### 阶段详解(Stage detail)

下文每个阶段都会说明其 Purpose(目的)、Owner(负责方)、Input(输入)、Output(输出)和 Exit Criteria(退出条件,即下一阶段能够开始之前必须成立的条件)。

#### 1. Idea(想法)

| | |
|---|---|
| Purpose | 在做出任何正式承诺之前,捕捉一个已观察到的缺口、请求或需求。 |
| Owner | 人类或 OpenClaw |
| Input | 一个 Roadmap 上的缺口、一个用户请求,或来自先前某次 Review 或 Validation 的发现。 |
| Output | 一份粗略的问题陈述 —— 尚不是正式的 Plan。 |
| Exit Criteria | 该想法足够具体,可以据此撰写一份 Plan。此时尚不存在任何分支、代码或基础设施变更 —— 一个 Idea 并不构成继续推进的授权。 |

#### 2. Plan(计划)

| | |
|---|---|
| Purpose | 在任何实现开始之前,把一个 Idea 转化为一份结构化、有边界的承诺,让所有人都能先行审阅。 |
| Owner | OpenClaw 起草;人类确认范围。 |
| Input | 一个 Idea。 |
| Output | 一份结构化的 Plan —— 目标、范围、任务、约束、交付物 —— 并在 `docs/roadmap.md` 中预留一个 `PLAN-XXXX` 编号。 |
| Exit Criteria | 范围、约束和交付物足够明确,以至于 Feature Branch(特性分支)工作可以开始,而无需重新争论什么在范围内、什么在范围外。此时尚不存在任何实现 —— 一份 Plan 是文档,不是代码。 |

#### 3. Feature Branch(特性分支)

| | |
|---|---|
| Purpose | 给这份 Plan 一个隔离的地方来进行实现,不触碰任何共享分支。 |
| Owner | Claude Code(或被指派做实现的任一 agent/人类)。 |
| Input | 一份已确认的 Plan。 |
| Output | 一个 `feature/*` 分支,从最新的默认/集成分支创建,并已提交实现工作。 |
| Exit Criteria | 该分支包含对这份 Plan 范围的一个完整、自洽的实现 —— 不是半成品状态 —— 已准备好以 PR 形式打开。没有任何内容被直接提交或推送到 `main`/`lab`。 |

#### 4. Draft PR(草稿 PR)

| | |
|---|---|
| Purpose | 让工作可见、可审阅,同时并不暗示它已经可以合并。 |
| Owner | 完成实现的那一方。 |
| Input | 一个已提交变更的特性分支。 |
| Output | 一个已打开的 **Draft**(草稿)拉取请求,其描述涵盖摘要、范围以及到目前为止验证过的内容。 |
| Exit Criteria | 该 PR 描述向审阅者提供了开始 Architecture Review(架构评审)所需的一切,而无需先提出澄清性问题。它在下文每个阶段中始终保持 Draft 状态 —— 不标记为 ready-for-review 也不合并 —— 直到 Human Approval(人类批准)为止。 |

#### 5. Architecture Review(架构评审)—— Gate 1

| | |
|---|---|
| Purpose | 在投入更多审阅精力于实现细节之前,确认设计契合现有的标准/ADR、停留在 Plan 声明的范围之内,并且不会瓦解身份或角色边界。 |
| Owner | 以审阅者身份行事的人类和/或 OpenClaw —— 绝不能是撰写该 PR 的同一方。 |
| Input | 一个已打开的 Draft PR。 |
| Output | 架构被接受,或被退回并附上所请求的变更。 |
| Exit Criteria | 不再有悬而未决的架构层面异议。PR 作者本人的自我审阅不满足此条件。 |

#### 6. Implementation Review(实现评审)—— Gate 2(包含 Security Review 安全评审)

| | |
|---|---|
| Purpose | 确认实现正确、清晰,并处于 Plan 的约束之内。**Security Review(安全评审)是此 gate 内一项强制性的子检查** —— 不是一个独立的生命周期阶段 —— 只要变更触及 AWS 身份/凭证、IAM、网络暴露面或密钥(secrets)就会触发,用以核实该变更不违反 `standards/security/identity-boundary.md`(不共享凭证、不使用 `AdministratorAccess`、不使用 `0.0.0.0/0` 作为默认值)。 |
| Owner | 以审阅者身份行事的人类和/或 OpenClaw。 |
| Input | 一个已通过 Architecture Review 的 PR。 |
| Output | 实现被接受,或被退回并附上所请求的变更。 |
| Exit Criteria | 不再有悬而未决的实现或安全异议。 |

#### 7. Human Approval(人类批准)—— Gate 3

| | |
|---|---|
| Purpose | 在允许任何内容被合并之前,进行一次最终的、明确的人类签核 —— 区别于上述任何一次 review。 |
| Owner | 仅限人类。 |
| Input | 一个已通过 Architecture Review 和 Implementation Review(在适用之处包含 Security Review)的 PR。 |
| Output | 该 PR 上的一个明确的 Approved(已批准)状态。 |
| Exit Criteria | 一个并非该 PR 作者本人的人类已明确批准它。没有任何 AI agent 会批准它自己或另一个 agent 的 PR —— 批准与合并一样,是一项人类行为。 |

#### 8. Merge(合并)—— 仅限人类

| | |
|---|---|
| Purpose | 把变更落地到共享分支上。 |
| Owner | 仅限人类 —— 没有任何 AI agent 会合并任何东西,永远不会(`policies/ai-pull-request-policy.md`)。 |
| Input | 一个已批准(Approved)的 PR。 |
| Output | 变更落地到 `main`(或该项目的集成分支,例如 `lab`)。 |
| Exit Criteria | 目标分支上存在该合并提交(merge commit)。一个尚未通过 Gate 3 的 PR 永远不会被合并,无论是谁提出请求。 |

#### 9. Validation(验证)

| | |
|---|---|
| Purpose | 确认已合并的变更确实实现了 Plan 所意图的目标 —— 而不仅仅是它干净地合并了。这与每一份 Plan 自己的 Validation 清单已经要求的检查是同一件事(例如 "Registry 可以扩展到 100+ 项目");本阶段就是让那份清单针对真实的、已合并的结果得到确认,而不是继续停留为 Plan 文档里的一种愿望。 |
| Owner | 能够真正核查结果的任一方 —— 对可被机器检查的 Plan(测试、一个 `terraform plan` 差异、链接/结构检查)由 GitHub/CI 负责,对通过人工检视验证的 Plan(大多数文档类 Plan)由人类或 OpenClaw 负责。 |
| Input | 已合并的变更,以及该 Plan 自己的 Validation 清单。 |
| Output | 确认每一条 Validation 标准都已满足,或发现其中某一条未满足。 |
| Exit Criteria | Plan 的 Validation 清单中的每一条标准都被确认为真。一条不通过的标准会阻断 Memory Update —— 它不会被悄悄标记为完成。 |

#### 10. Memory Update(记忆更新)

| | |
|---|---|
| Purpose | 确保下一次 agent 会话(或 Loop 运行 —— 参见 `architecture/engineering-loop.md`)从实际为真的状态出发,而不是重新去发现它。 |
| Owner | OpenClaw。 |
| Input | 一个已验证、已合并的变更。 |
| Output | 反映新现实的已更新记忆 —— 项目状态、阶段、既有决策 —— **并且**将该 Plan 在 `docs/roadmap.md` 中的状态/表格位置更新为一致(例如 `Review` → `Merged`)。Roadmap 状态是 Engineering-OS 记忆的一种形式,因此它作为本阶段的一部分被记录,而不是作为一个独立阶段。 |
| Exit Criteria | 记忆和 `docs/roadmap.md` 都反映已验证、已合并的状态 —— 不早于此,也绝不写入一个尚不为真的状态。 |

#### 11. Close(关闭)

| | |
|---|---|
| Purpose | 给每一份 Plan 一个确定的、已记录的终点 —— 无论它是否合并。 |
| Owner | OpenClaw 记录它;人类可以从任何较早的阶段指示提前关闭。 |
| Input | 一份已完成 Memory Update 的 Plan(正常路径),或人类在任何较早阶段决定放弃/取代一份 Plan(提前关闭路径)。 |
| Output | 在 `docs/roadmap.md` 中将该 Plan 的状态设为 `Closed`,如果是提前关闭则附上一行原因。 |
| Exit Criteria | 该 Plan 有一个最终状态。没有 Plan 会被无限期地停留在 `In Progress`/`Review` 而没有任何东西在跟踪它。 |

## 角色(Roles)

| 角色 | 根本职责 | AWS 身份 |
|---|---|---|
| **Human(人类)** | 最终权威。唯一能执行 Human Approval 和 Merge(以及,依据 `policies/ai-pull-request-policy.md`,Release/Tag/Production)的角色。可以从任何阶段强制提前 Close。 | 自有凭证,而非流水线身份 —— 不在 `standards/security/identity-boundary.md` 的范围之内。 |
| **OpenClaw** | 规划、记忆、评审。起草 Plan,在 Gate 1–2 与人类一同或代替人类进行评审,为基于检视的 Plan 确认 Validation,在合并后更新 Memory(包括 Roadmap 状态)。 | 默认没有。 |
| **Claude Code** | 实现。把一份已批准的 Plan 变成一个 Feature Branch 和 Draft PR,在 Gate 1–2 响应评审反馈。 | 默认没有。 |
| **GitHub** | 分支、PR、评审和合并门控(merge gating)的记录系统(system of record)。通过 GitHub Actions 运行 CI(`fmt`/`validate`/lint/security-scan,且仅在某个特定的、经明确批准的 workflow 下才会超出这些)—— 包括可被机器检查的 Validation —— 并以机械方式强制:没有所需的评审状态就无法发生 Merge。 | GitHub OIDC,仅限 CI,且仅在某个给定 workflow 已获明确批准时。 |
| **HCP Terraform** | 对于其实现触及某个项目仓库中由 Terraform 管理的基础设施的 Plan:仅负责 Terraform Plan、Apply 和 State。**有条件,而非普适** —— 一个不触及 Terraform 的 Plan(包括本仓库中的每一份 Plan,本仓库并无任何 Terraform)永远不会调用这一角色。 | HCP Terraform OIDC。 |

与 `standards/security/identity-boundary.md` 相同的不重叠规则:GitHub 的角色绝不延伸到 Terraform plan/apply/state,HCP Terraform 的角色也绝不延伸到任意的 CI 任务。

### Stage → role 速查(Stage → role quick reference)

| Stage(阶段) | 负责角色 |
|---|---|
| Idea | 人类或 OpenClaw |
| Plan | OpenClaw(起草),人类(确认) |
| Feature Branch | Claude Code |
| Draft PR | Claude Code |
| Architecture Review | 人类和/或 OpenClaw |
| Implementation Review(+ Security Review) | 人类和/或 OpenClaw |
| Human Approval | 人类 |
| Merge | 仅限人类 |
| Validation | GitHub(自动化)或人类/OpenClaw(检视) |
| Close | OpenClaw 记录;人类可强制提前 |

GitHub 和 HCP Terraform 不像上述四个 actor(参与者)角色那样被"指派"到某个阶段 —— GitHub 是 Stage 3–9 在其上执行的基底(substrate),而 HCP Terraform 只在某个给定 Plan 的实现确实需要它时才被激活。

## 评审门(Review Gates)

四个门,按顺序排列。**一个尚未通过某个 gate 的 Plan 不能进入下一阶段 —— 不因紧急、自信,或看起来微小的变更而有例外。**

1. **Architecture Review**(Stage 5)—— 设计是否契合、是否停留在范围内、是否尊重现有的身份/角色边界?
2. **Implementation Review**(Stage 6)—— 实现是否正确并处于 Plan 的约束之内?
3. **Security Review** —— 不是一个独立阶段;是 Implementation Review 内部的一项强制性子检查,只要变更触及 AWS 身份、IAM、网络暴露面或密钥就必须进行。
4. **Human Approval Gate**(Stage 7)—— 最终的人类签核,仅在 Gate 1–2(以及在适用之处的 Gate 3)已通过之后。

## 制品与可追溯性(Artifacts and traceability)

每一份 Plan 都会产出六种制品类型中的某个子集,每一种都回链到它之前的那一种,从而任何一件制品都可以被追溯回启动它的那个 Idea:

| 制品(Artifact) | 产出于 | 是否总是产出? |
|---|---|---|
| **Plan** | Stage 2 | 总是 |
| **PR** | Stage 4 | 总是 |
| **ADR** | Stage 5,当 Architecture Review 判定该 Plan 做出了一个具有持久影响的决策时(依据 `CONTRIBUTING.md` 自身关于何时使用 ADR 的定义) | 有条件 |
| **Review** | Stage 5–7(PR 上的评审评论/记录) | 总是 |
| **Memory** | Stage 10 | 总是 |
| **Roadmap** | Stage 2(预留)和 Stage 10(作为 Memory Update 的一部分被更新) | 总是 |

**取自本仓库自身历史的一个实例:** `PLAN-0001`(Plan) → `PR #1`(PR) → `ADR-0005`(ADR,因为它是一个具有持久性的身份边界决策) → `PR #1` 上的评审评论(Review) → 本次会话的记忆更新(Memory) → `docs/roadmap.md` 中 `PLAN-0001` 的那一行,状态为 `Merged`(Roadmap,作为同一个 Memory Update 阶段的一部分被记录)。每一处链接都是一个直接引用(一个 PR 编号、一个 ADR 文件名、一个 `PLAN-XXXX` 编号)—— 而非转述 —— 因此从 Roadmap 条目追溯回最初的 Idea 永远不需要凭记忆重建历史。

## 设计意图(验证)(Design intent (validation))

- **适用于每一个项目,而不只是本仓库。** 上文没有任何内容是 `wcd-engineering` 专属的 —— 一个项目仓库(例如 `devops-terraform-jenkins-eks`)遵循同样的十一个阶段、同样的四个门、同样的角色;仅有 Feature Branch 的基分支(那里是 `lab`,这里是 `main`)、HCP Terraform 是否激活,以及 "Validation" 检查什么(那里是冒烟测试,这里是文档检视)因项目而异。
- **支持多个 AI agent。** 角色由功能定义(规划/记忆/评审 vs. 实现 vs. CI vs. Terraform 执行),而非通过点名某个特定 agent —— 一个新 agent 嵌入到一个既有角色中,而不需要新增一个角色。
- **不依赖 Terraform。** HCP Terraform 明确是有条件的(参见 Roles)—— 本文件自身,以及任何仅涉及文档的 Plan,永远不会调用它。
- **可扩展。** 新的阶段、门、角色或制品类型可以通过扩展上面的表格来添加,而不会破坏既有的 `PLAN-XXXX` 记录 —— 本文件描述的是流程,而非任何特定 Plan 的内容,因此它不需要在每次向 `docs/roadmap.md` 添加一份新 Plan 时都随之改动。

## 参考(Reference)

- `docs/roadmap.md` —— 排定 *存在哪些* Plan 及其状态;本文件定义每一份 Plan *如何*走完其生命周期。
- `policies/ai-pull-request-policy.md` —— Stage 3–8 背后的 Git 机制细节(分支/PR 规则、对 AI agent 禁止/允许的内容、仅限人类的行为)。
- `standards/security/identity-boundary.md`、`adr/ADR-0005-terraform-execution-identity.md` —— Architecture Review 和 Security Review 子检查所强制执行的身份规则。
- `architecture/project-registry.md` —— 追踪一个项目自身阶段/状态(区别于本仓库的 Plan 状态)的地方。
- `architecture/engineering-loop.md` —— 读取本工作流 Stage 10 所产生的 Memory/Roadmap 状态的那一方。
