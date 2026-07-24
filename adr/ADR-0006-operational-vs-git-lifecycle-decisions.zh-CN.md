> **中文翻译版** · 英文正本以 `ADR-0006-operational-vs-git-lifecycle-decisions.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# ADR-0006: 运营决策层 vs. Git 生命周期决策引擎(Operational Decision Layer vs. Git-Lifecycle Decision Engine)

**Status:** Adopted(已采纳)— 2026-07-22,通过 PR #15(`feature/decision-layer-reconciliation`)合并。提议与采纳在同一天完成;按本 ADR 自身的规则,状态在合并时转为 Adopted。

## Context(背景)

`VISION.md`(通过 PR #14 合并)将 **Decision(决策)** 组件定义为 WCD 所拥有的四样东西之一:一个三层结构(Policy 文件 → Memory → LLM 推理),它在 Employee 正在执行一个 Goal 期间自主决定 `Continue` / `Retry` / `Rollback` / `Escalate` / `Wait` / `Cancel`——只有通过 `Escalate` 路径(Decision Engine → OpenClaw Gateway → Telegram/Slack)才会把 Human(人类)拉进来。

`decision/decision-engine.md`(已经处于 Completed 状态,PR #10)也把自己称为"the Decision Engine(决策引擎)",定义了八种决策类型——Approve、Reject、Merge、Close、Reopen、Archive、Escalate、Defer——并明确指出"它们中的每一个都是 Human 的判断裁量……绝不由 AI agent 生成或自行应用。"

并排来读,这两者看起来像是直接矛盾:一个说 Employee 自己做决定,另一个说 AI agent 从不做决定。VISION.md 自己已经明确把这一点标记为一个尚待调和(reconciliation)的开放事项,并把它命名为 PLAN-0006 Bootstrap 的前提条件,而非事后补救。根据 2026-07-22 的一项直接的人类决定,凡是 VISION.md 与某份现有文档在同一动作空间(action space)上确实发生冲突之处,以 VISION.md 为准——本 ADR 是这条决胜规则(tie-breaker)的首次应用。

## Decision(决策)

1. **这是覆盖在两个互不相交的动作空间之上的两个不同的 Decision 层——而不是一份文档与另一份相互矛盾。**

   - **Git 生命周期决策引擎(Git-Lifecycle Decision Engine)**(`decision/decision-engine.md`,本 ADR 不作改动)—— 针对 Plan 与 PR,决定 Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer,适用于 `wcd-engineering` 以及每一个项目仓库。始终是 Human 的判断裁量,没有例外,依据 `policies/ai-pull-request-policy.md`。
   - **运营决策层(Operational Decision Layer)**(VISION.md 的 `### 2. Decision`,尚未实现——那是 PLAN-0006 的任务)—— 在*一个 Goal 执行期间*决定 Continue/Retry/Rollback/Escalate/Wait/Cancel(例如,在一次 Daily Kubernetes Health Check 运行进行到一半时:重试一个不稳定的检查、回滚一个有问题的补丁)。三层的 Policy → Memory → LLM 推理,除 Escalate 之外均为自主。

   Git 生命周期决策引擎的八种类型中,没有一种能映射到诸如"重试这个健康检查"之类的运营动作——这两份文档从来就没有真正在描述同一个决策空间,它们只是都用了"Decision Engine(决策引擎)"这个词。

2. **这两层唯一相交的地方是 Escalate**,而且即便在那里它们也不合并:一次运营层面的 Escalate 产生的是一个面向 Human 的通知(OpenClaw Gateway → Telegram/Slack)。它绝不绕过 Git 生命周期决策引擎——如果 Employee 的运营工作产生了代码或文档改动(例如,来自 Daily Health Check 工作流的一个 Fix PR),该改动仍然要走普通的 feature-branch → Draft PR → Human Merge 路径,不受本 ADR 触碰。

3. **应用决胜规则:** 经过仔细阅读,一旦精确界定范围(第 1 点),就不存在实际冲突——因此本 ADR 不修订、不削弱、也不重新开启已经处于 Completed 状态的 `decision/decision-engine.md`。假如真的发现了实质性的重叠,那么以 VISION.md 的设计为准,`decision-engine.md` 就会需要一次取代性(superseding)的改动;但事实证明这里并不需要。

4. `decision/decision-engine.md` 会加上一处简短的交叉引用(见随附的 diff),指向本 ADR 和 VISION.md,这样未来的读者就不会把它"绝不由 AI agent 生成或自行应用"的措辞误读为一个覆盖所有场合、所有 AI 决策的笼统主张,而它其实特指 Git/PR/Plan 生命周期动作。

5. **本 ADR 不实现运营决策层。** 它只厘定边界。构建它——Policy 文件 schema、Memory 在物理上存放在哪里、LLM 推理的 prompt/循环、稳定窗口(stability windows)——是 PLAN-0006 Bootstrap 的任务,而本 ADR 为其解除了阻塞。

## Consequences(后果)

- PLAN-0006 Bootstrap 可以继续推进,无需再重新争论它的 Decision 层是否与已合并的 Decision Engine 相矛盾。
- 任何未来看起来允许 AI 自主决定某件事的组件,都必须先表明它属于哪一层:Git 生命周期(仅限人类,没有任何例外)或运营(Policy → Memory → LLM,仅在 Escalate 处涉及人类)。一个声称能自主决定某个 Git/PR 动作的组件不在本 ADR 的覆盖范围内,并且依据 `policies/ai-pull-request-policy.md` 仍然被彻底禁止。
- 如果未来某个案例无法被干净利落地归入某一层,那就是一个信号,说明本 ADR 的边界需要通过一次取代性(superseding)ADR 重新审视——而不是一个把两者悄悄糅合在一起的理由。

## Open questions(尚待解决的问题)

- 运营决策层的实际实现(Policy 文件的格式与位置、"Memory"在物理上存放于何处——本 ADR 假定 VISION.md 的 PostgreSQL + Git 两层设计,但并未搭建其中任何部分)完全推迟到 PLAN-0006。
- 一次运营层面的 Escalate 是否也应在 Git 生命周期一侧留下一条轻量记录(例如一个 GitHub Issue)以便可见,还是纯粹留在 Telegram/Slack 通道上,尚未解决——留给 PLAN-0006 决定。

## References(参考资料)

- `VISION.md` —— `## WCD Responsibilities` → `### 2. Decision`,运营决策层设计的来源。
- `decision/decision-engine.md` —— 本 ADR 与之相区分的 Git 生命周期决策引擎,不作改动。
- `policies/ai-pull-request-policy.md` —— 无论运营层如何自主,始终有效的仅限人类的 Git 工作流。
- `docs/roadmap.md` —— PLAN-0006 Bootstrap,由本 ADR 解除阻塞。
