> **中文翻译版** · 英文正本以 `VISION.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# WCD Engineering Vision(WCD 工程愿景)

在写更多代码之前,先重置项目方向。

WCD 的目标**不是**再造一个 AI 聊天应用。
目标**不是**再造一个通用的 Agent 框架。
目标**不是**与 Claude Code、OpenHands、OpenClaw、AutoGen 或 LangGraph 竞争。

只要有可能,我们就复用它们。

## What problem are we solving?(我们要解决什么问题?)

今天的 AI 产品大多是任务执行器:

```
Human
  │
  ▼
Prompt
  │
  ▼
AI
  │
  ▼
Task Finished
  │
  ▼
End
```

我们的目标不同。我们希望 AI 成为一名长期运行的工程员工:

```
Human
  │
  ▼
Goal
  │
  ▼
AI
  │
  ▼
Planning
  │
  ▼
Execution
  │
  ▼
Verification
  │
  ▼
Memory
  │
  ▼
Continue Working
  │
  ▼
Finish
```

AI 应当持续工作,而不是等待下一个 prompt。

## Philosophy: Employee, not Agent(理念:员工,而非智能体)

不要构建一个 Agent。构建一名 Employee(员工)。

一名 Employee 拥有:

- 目标(Goals)
- 职责(Responsibilities)
- 记忆(Memory)
- 决策能力(Decision making)
- 持续工作(Continuous work)
- 从既往工作中学习(Learning from previous work)

Agent 通常完成一个任务。Employee 拥有一份工作(job)。

## Do not reinvent execution(不要重新发明执行)

执行能力已经存在了——Claude Code、OpenHands、OpenClaw、GitHub Actions、Kubernetes Jobs、Terraform、`kubectl`。这些都是执行引擎。WCD 编排(orchestrate)它们,而不是替换它们。

## WCD Responsibilities(WCD 的职责)

WCD 恰好拥有**四个组件**——Goal、Decision、Verification、Organization Memory。**Continuous Loop 是连接它们的机制,而不是与它们并列的第五个组件。**

(这修正了本 Vision 的一份早期草稿:那份草稿把 Continuous Loop 列为四个被拥有的事物之一,却完全遗漏了 Verification。事实证明 Verification 是过于薄弱的一环——"验证究竟意味着什么,以及验证失败时会发生什么"——不能让它悬而未定,因此它被提升为一等组件;而 Loop 被降级为对其他四者进行排序编排的机制。)

### 1. Goal

应该做什么?每个 Goal 都必须携带它自己的验证标准(verification criteria)——这正是 Verification 之后所要对照检查的依据。

来源:

- Human(人工)——直接提交。
- Monitoring / Alerts(监控 / 告警)——某个告警触发,自动生成一个 Goal。
- Scheduler(调度器)——一个周期性 Goal(例如 Daily Kubernetes Health Check)按节奏触发。
- Memory-driven(记忆驱动)——Organization Memory 从某个反复出现的模式中浮现出一个预防性 Goal。

**学习闭环(Learning loop):**

```
Alert / Schedule / Human
        │
        ▼
   Goal Engine
        │
        ▼
Decision → Execution → Verification
        │
        ▼
  Organization Memory
        │
        ▼
   (writes back to) Goal Engine's own rules
```

具体学到了什么:

- **Alert → Goal 映射**——哪个 Goal 模板实际上解决了哪一类 Alert;强化有效的,淘汰无效的。
- **优先级规则(Priority rules)**——反复出现的模式(例如"凌晨 2 点的 PVC 故障总是升级给人工")被提升为一条常驻的优先级规则。
- **误报过滤(False-alarm filtering)**——某一类 Alert 在最近 10 次中都在 5 分钟内自愈,便为其设置一个"先观察再生成 Goal"的延迟,而非立即生成 Goal。
- **Goal 依赖发现(Goal dependency discovery)**——如果 Goal B 总是在 Goal A 之后运行,那就把它变成一条显式依赖。

此学习闭环的 MVP 分步安排——不要在第一天就构建自动学习:

1. 手工规则(硬编码的 Alert → Goal 映射)。
2. Memory 开始记录每个 Goal 的结果,暂不做学习。
3. 一个周期性 Goal(`Weekly: Review Memory and Update Rules`)让一个 LLM 分析累积的 Memory,并提出规则更新供人工评审。

### 2. Decision

接下来应该发生什么——Continue(继续)?Retry(重试)?Rollback(回滚)?Escalate(升级)?Wait for approval(等待审批)?永远不要盲目重试;每个决策都必须是可解释的。

**这与 `decision/decision-engine.md` 中的 Decision Engine 是不同的层。** 那份文档管辖的是针对 wcd-engineering 与各项目仓库自身演进的 Git/PR 生命周期决策(Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer),并且是刻意、永久地仅限人工的——见 `policies/ai-pull-request-policy.md`。本处所描述的 Decision 组件,管辖的是 Employee **在执行某个 Goal 期间**自身的运行时判断(例如,在一次 Daily Kubernetes Health Check 运行进行到一半时,决定是否重试一个不稳定的检查)。**这两个 Decision 层绝不可混为一谈,而且下文描述的运行层尚未实现,也尚未与已经合并的 Git 生命周期 Decision Engine 进行协调对齐**——那次协调对齐是 PLAN-0006 Bootstrap 的前置条件,而非事后补充。

触发点——Decision 层在四个时刻被咨询:

1. Goal 启动之前——产出一份执行计划。
2. 每一个执行步骤之后——继续 / 调整 / 停止?
3. 一次 Verification 结果之后——PASS 则继续,WARN 则分诊(triage),FAIL 则回到 Decision。
4. 发生异常时——超时、权限不足、资源未找到。

可能的决策:`Continue`、`Retry`(由 Memory 提供依据,绝不盲目)、`Rollback`、`Escalate`、`Wait`、`Cancel`。

**三层结构:**

```
Layer 1: Policy (hard rules, cannot be bypassed)
  → "delete in production" → must Escalate
  → "3 consecutive failures" → must Escalate, no more Retry

Layer 2: Memory (check history)
  → "has this been seen before? how was it resolved?"
  → found → reuse the successful approach
  → not found → fall through to Layer 3

Layer 3: LLM reasoning
  → judge from current context
  → must output an explainable reason, not just a verdict
```

Policy 不是预先手写的——它是**由 LLM 自身随时间治理**的:

1. 每一次 LLM 决策连同其理由一起记录到 Memory。
2. 一个周期性 Goal(`Weekly Policy Review`)让一个 LLM 分析 Memory 中的 Decision 历史,并将其提炼为规则。
3. 这些规则被写入 `policies/`(YAML/Markdown),纳入版本控制,可供人工评审、可由人工覆盖。
4. 未来的 Decision 先检查 Policy 文件;命中则直接执行,未命中则回落到 Memory,再回落到 LLM 推理,而后者又反馈进下一次 Policy Review。

**升级路径(Escalate path):**

```
Decision Engine → Escalate → OpenClaw Gateway → Telegram / Slack
```

WCD 本身并不拥有通知通道——那被委托给 OpenClaw Gateway,与"不要重新发明执行"保持一致。

### 3. Verification

一个尚未被验证的 Goal 不算完成。

每个 Goal 都把它自己的验证标准作为 Goal 自身的一部分携带:

```yaml
goal:
  name: "Fix CrashLoopBackOff - payment-service"
  verification:
    - type: pod_running
      target: payment-service
      namespace: production
    - type: no_restart
      window: 5m
    - type: service_ready
      target: payment-service
```

- 人工提交的 Goal → 由人工定义标准。
- 告警触发的 Goal → 标准根据 Alert 类型自动推导。
- Memory → 提供在历史上对相似 Goal 已被证明有效的标准。

Verification 自身并不执行检查——它像其他一切那样委托给相同的执行引擎(`kubectl`、AWS CLI、GitHub API),等待一个与所变更内容相称的稳定窗口(stability window),然后对结果做出判定:

```
Execution completes
      │
      ▼
Wait for stability window (per Goal type)
  Kubernetes  → 5m
  Terraform   → 10m
  GitHub PR   → wait for CI
  ArgoCD sync → 3m
  AWS resource → 8m
      │
      ▼
Run verification checks (delegated to kubectl / AWS CLI / GitHub API)
      │
      ▼
Compare against Memory's historical "health snapshot"
      │
      ▼
PASS → record new snapshot to Memory → next Goal
WARN → Decision Engine: continue observing, or Escalate
FAIL → Decision Engine: Retry / Rollback / Escalate
```

稳定窗口存放在 `policies/verification.yaml` 中;LLM 会定期评审 Memory,以检查所配置的窗口是否仍然合适,并提出更新——与 Policy 得到精炼的方式相同。

### 4. Organization Memory

系统的长期学习基底(substrate)——它会写回到其他每一个组件。它不是通用 RAG,也不是向量数据库。

每一个已完成的 Goal 都会写下一条持久的经验记录:

```yaml
incident:
  id: "INC-2026-0722-001"
  trigger: "CrashLoopBackOff alert - payment-service"
  goal: "Investigate and fix payment-service"

  investigation:
    root_cause: "OOMKilled - memory limit too low (256Mi)"
    evidence: ["kubectl logs", "kubectl describe pod"]

  decision_made: "Increase memory limit to 512Mi"
  execution: "kubectl patch + ArgoCD sync"

  verification:
    result: PASS
    stability_window: 5m
    health_snapshot: { pods: running, restarts: 0 }

  lessons_learned:
    - "payment-service OOM triggered by high traffic at 14:00-15:00"
    - "512Mi is sufficient, 1Gi is safe ceiling"

  tags: [kubernetes, oom, payment-service, memory]
```

两层存储:**PostgreSQL**(结构化、可查询)+ **Git**(人类可读——`decisions/`、`policies/`)。目标是:永不重复调查同一个问题两次。

## Continuous Loop (mechanism, not a component)(持续循环——机制,而非组件)

Employee 绝不会在完成一个 Goal 后停下来。

```
Goal Queue (priority-ordered)
        │
        ▼
Take next Goal
        │
        ▼
Decision Engine → build execution plan
        │
        ▼
Execution (delegated to Claude Code / OpenHands / OpenClaw)
        │
        ▼
Wait for stability window
        │
        ▼
Verification → PASS / WARN / FAIL
        │
FAIL / WARN → back to Decision Engine
PASS
        │
        ▼
Memory Update
        │
        ▼
Decision Engine → Goal done, or continue
        │
        ▼
back to Goal Queue
```

**队列为空时的行为(Queue-empty behavior)**——Employee 有三种状态,绝不会有第四种"已停止"状态:

- 队列中有 Goal → 正常执行。
- 队列为空 → 进入监听模式,等待某个 Alert 或某个调度触发。
- 某个调度触发 → 自动注入一个 Goal(例如 Daily Health Check)。

**并发(Concurrency)**——带冲突检测的有限并行,既不是完全串行,也不是无界并行:

```yaml
conflict_rules:
  - scope: namespace
    max_concurrent: 1
  - scope: terraform_workspace
    max_concurrent: 1
  - scope: global_destructive
    max_concurrent: 1
```

**触发机制(Trigger mechanism)**——一个 Kubernetes CronJob 心跳(每分钟一次)检查 Goal Queue(PostgreSQL);若有 Goal 存在,便启动一个 Kubernetes Job 来执行它,若队列为空则检查是否有到期的调度 Goal,否则休眠直到下一次心跳。所有 CronJob/Job 定义都由 GitOps 管理,并由 ArgoCD 同步。**这个调度器尚不存在**——`architecture/engineering-loop.md` 中的 Engineering Loop 是另一回事:它是 OpenClaw 自己用来巡检*本 meta-repo(元仓库)*的 PR/Roadmap 状态的节奏,而不是本处所描述的 Employee 运行态 Goal Queue 的触发器。

## MVP

忘掉 AI Company OS。忘掉多个部门。忘掉 CEO Agent。忘掉复杂的层级结构。

只构建**一名** Employee。

**名称:** DevOps AI Employee

**职责,仅此而已:**

- Kubernetes
- GitHub
- Terraform
- Jenkins
- ArgoCD
- AWS

## First Workflow(第一个工作流)

只实现**一个**生产工作流:Daily Kubernetes Health Check(每日 Kubernetes 健康检查)。

1. 检查集群状态。
2. 检测故障。
3. 自动调查。
4. 生成一份 RCA(根因分析)。
5. 若安全,生成一个 Fix PR(修复 PR)。
6. 更新 Organization Memory。
7. 等待下一次调度运行。

每日重复。在这一个工作流可靠之前,不要添加更多工作流。

## Success Criteria(成功标准)

当一个人能够提交一个 Goal 然后离开,项目就算成功。AI 应当完成 Plan、Execute、Verify、Document、Commit、Create PR 以及 Update Memory,然后返回 `Completed` 或 `Escalated` 之一——无需持续的人工交互。

## Engineering Rule(工程铁律)

在尝试构建一个 AI 组织之前,先构建一名能够每天可靠地完成一份真实工程工作的 AI Employee。

**在撰写本文时,`docs/roadmap.md` 中那十个 Completed/Merged 的 FOUNDATION 组件,没有一个是这第一个工作流——它们管辖的是本仓库如何演进,而不是 Employee 如何对 Kubernetes 开展工作。** PLAN-0006 Bootstrap——通往上述工作流的真正第一步——仍处于 Draft 状态。本 Vision 自身的 Engineering Rule,正是 roadmap 在添加 PLAN-0011 或更靠后之前应当据以衡量的标准。

## Reference(参考)

- `docs/roadmap.md`、`architecture/project-registry.md`——当前的 Plan 状态,以及接下来该做什么。
- `decision/decision-engine.md`——Git/PR 生命周期 Decision 层,本 Vision 的 Decision 组件与之相区分(见 `## WCD Responsibilities` → `### 2. Decision`)。
- `policies/ai-pull-request-policy.md`——仅限人工的 Git 工作流,每个 AI 智能体(包括正在执行本 Vision 自身 Goal 的那个)都必须遵循。
- `architecture/engineering-loop.md`——OpenClaw 的 meta-repo 巡检节奏,与本 Vision 的 Continuous Loop 触发机制相区分(见 `## Continuous Loop`)。
