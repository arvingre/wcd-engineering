#!/usr/bin/env bash
# bootstrap-wcd.sh
# WCD Engineering workspace bootstrap for a new or re-imaged Mac.
#
# What this does:
#   1. Creates the standard devops directory structure under ~/Documents/devops/
#   2. Clones wcd-engineering (standards and knowledge repository)
#   3. Clones devops-terraform-jenkins-eks (AWS IaC repository)
#
# What this does NOT do:
#   - Install Homebrew, Terraform, AWS CLI, or any other tools
#   - Configure SSH keys or GitHub credentials
#   - Set up OpenClaw or Claude Code
#   - Apply any Terraform or create AWS resources
#
# Prerequisites:
#   - Git installed and configured
#   - SSH key added to GitHub (git@github.com access)
#
# Usage:
#   chmod +x bootstrap-wcd.sh
#   ./bootstrap-wcd.sh

set -euo pipefail

WCD_ROOT="${HOME}/Documents/devops"
GITHUB_USER="Arvingrep"

# ── Directory structure ────────────────────────────────────────────────────────

echo "[bootstrap] Creating WCD directory structure..."

mkdir -p \
  "${WCD_ROOT}/wcd-engineering" \
  "${WCD_ROOT}/repositories/infrastructure" \
  "${WCD_ROOT}/repositories/platform" \
  "${WCD_ROOT}/repositories/applications" \
  "${WCD_ROOT}/repositories/tools" \
  "${WCD_ROOT}/labs" \
  "${WCD_ROOT}/workspace" \
  "${WCD_ROOT}/archive"

echo "[bootstrap] Directory structure ready: ${WCD_ROOT}"

# ── Clone wcd-engineering ──────────────────────────────────────────────────────

WCD_ENG_PATH="${WCD_ROOT}/wcd-engineering"

if [ -d "${WCD_ENG_PATH}/.git" ]; then
  echo "[bootstrap] wcd-engineering already cloned at ${WCD_ENG_PATH}"
  echo "[bootstrap] Pulling latest from origin main..."
  git -C "${WCD_ENG_PATH}" fetch origin
  git -C "${WCD_ENG_PATH}" checkout main
  git -C "${WCD_ENG_PATH}" pull --ff-only origin main
else
  echo "[bootstrap] Cloning wcd-engineering..."
  git clone "git@github.com:${GITHUB_USER}/wcd-engineering.git" "${WCD_ENG_PATH}"
fi

# ── Clone devops-terraform-jenkins-eks ────────────────────────────────────────

INFRA_PATH="${WCD_ROOT}/repositories/infrastructure/devops-terraform-jenkins-eks"

if [ -d "${INFRA_PATH}/.git" ]; then
  echo "[bootstrap] devops-terraform-jenkins-eks already cloned at ${INFRA_PATH}"
  echo "[bootstrap] Pulling latest from origin lab..."
  git -C "${INFRA_PATH}" fetch origin
  git -C "${INFRA_PATH}" checkout lab
  git -C "${INFRA_PATH}" pull --ff-only origin lab
else
  echo "[bootstrap] Cloning devops-terraform-jenkins-eks..."
  git clone "git@github.com:${GITHUB_USER}/devops-terraform-jenkins-eks.git" "${INFRA_PATH}"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "=================================================="
echo " WCD Engineering workspace bootstrap complete."
echo "=================================================="
echo ""
echo " Standards:      ${WCD_ENG_PATH}"
echo " Infrastructure: ${INFRA_PATH}"
echo ""
echo " Next steps:"
echo "   1. Install tools: see bootstrap/mac/ in wcd-engineering"
echo "   2. Set up OpenClaw: see bootstrap/openclaw/README.md"
echo "   3. Configure AWS credentials (aws-vault recommended)"
echo "   4. Configure Claude Code: see bootstrap/claude/"
echo ""
