> **中文翻译版** · 英文正本以 `aws-eks-platform.md` 为准。本文件为方便阅读的翻译,如与正本冲突,一律以英文正本为准。

# AWS EKS Platform

## 参考实现(Reference Implementation)

- Repository: `Arvingrep/devops-terraform-jenkins-eks`
- Local path: `/Users/arvin/Documents/devops/repositories/infrastructure/devops-terraform-jenkins-eks`

## 参考仓库中已有的设计文档

此处仅列出路径。它们的内容保留在实现仓库中。

- `docs/eks-capacity-plan.md`
- `docs/eks-node-group-design.md`
- `docs/eks-scheduling-standard.md`
- `docs/eks-storage-design.md`

## 仓库边界(Repository Boundary)

`wcd-engineering` 存放组织级的标准、决策记录和可复用的审查指导。

项目仓库存放实现细节、Terraform 模块,以及工作负载所使用的具体集群设计。

## 说明

- 将本文档用作从标准到实现仓库的映射地图
- 将此处的架构摘要保持在策略与设计层面
- 当审查者需要实现证据时,链接进入项目仓库
