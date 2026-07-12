# WCD Project Registry

This registry tracks all active projects, their local paths, GitHub remotes,
integration branches, current phases and high-risk restrictions.

Last updated: 2026-07-12

---

## devops-terraform-jenkins-eks

**Type:** Infrastructure / AWS IaC
**GitHub:** Arvingrep/devops-terraform-jenkins-eks
**Local path:** /Users/arvin/Documents/devops/repositories/infrastructure/devops-terraform-jenkins-eks
**Default integration branch:** lab
**Stable branch:** main
**Standards repository:** /Users/arvin/Documents/devops/wcd-engineering

**Current phase:** Phase 4a completed; preparing Phase 4b minimal EKS Lab foundation

**High-risk restrictions:**
- No automatic merge
- No automatic Production apply
- No automatic Production destroy
- No Terraform state changes without approval
- No IAM privilege expansion without approval
- No EBS/S3/EKS deletion without approval

**Design documents:**
- docs/eks-capacity-plan.md
- docs/eks-node-group-design.md
- docs/eks-scheduling-standard.md
- docs/eks-storage-design.md
