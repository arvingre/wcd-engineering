> **中文翻译版** · 英文正本以 `GOVERNANCE.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# Governance(治理)

## Ownership(归属)

wcd-engineering 仓库由 WCD 工程治理职能负责。变更必须保持该仓库作为规范、架构指导以及可复用运作规则的唯一真实来源(source of truth)这一角色。

## Who Can Modify Standards(谁可以修改规范)

- 仓库维护者:负责编辑性与组织性的更新
- 领域负责人(domain owner):负责 AWS、Kubernetes、Terraform、安全、存储、备份与 CI 规范
- 在某个 RFC 或 ADR 中被点名的批准人:负责跨团队变更

## Approval Layers(审批层级)

1. 由贡献者撰写草案
2. 领域评审,校验技术正确性与完整性
3. 在适用之处进行安全与运维评审
4. 由指定的维护者或治理负责人做最终批准

## Change Log Expectations(变更日志要求)

- 记录变更了什么
- 记录为何做出该变更
- 记录由谁批准
- 记录采纳的日期
- 记录任何例外或被推迟的事项

## Guardrails(护栏)

- 不要存储密钥
- 不要存储生产 state
- 不要把实现仓库与规范仓库混为一谈
- 对于会影响共享行为的变更,不要绕过正常的评审路径
