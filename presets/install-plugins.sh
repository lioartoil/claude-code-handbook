#!/usr/bin/env bash
set -euo pipefail

# Claude Code Handbook — Plugin Preset
# Installs the full plugin stack used in this handbook.
# Usage: bash presets/install-plugins.sh

MARKETPLACE="claude-plugins-official"

echo "Installing Claude Code plugins..."

# ── Core Workflow ─────────────────────────────────────────────
# Planning, brainstorming, TDD, debugging, and execution skills
claude plugin install "superpowers@${MARKETPLACE}"
# Create and iterate on custom skills
claude plugin install "skill-creator@${MARKETPLACE}"
# Interactive HTML playgrounds for visual exploration
claude plugin install "playground@${MARKETPLACE}"
# Build Claude Agent SDK apps
claude plugin install "agent-sdk-dev@${MARKETPLACE}"
# Analyze and recommend Claude Code automations
claude plugin install "claude-code-setup@${MARKETPLACE}"

# ── Code Review & Quality ────────────────────────────────────
# Multi-agent PR review with confidence scoring
claude plugin install "code-review@${MARKETPLACE}"
# Specialized PR review agents (tests, types, errors, comments)
claude plugin install "pr-review-toolkit@${MARKETPLACE}"
# Code simplification and refactoring
claude plugin install "code-simplifier@${MARKETPLACE}"
# OWASP-informed security guidance
claude plugin install "security-guidance@${MARKETPLACE}"

# ── Git & Documentation ──────────────────────────────────────
# Commit, push, and PR workflows
claude plugin install "commit-commands@${MARKETPLACE}"
# Audit and improve CLAUDE.md files
claude plugin install "claude-md-management@${MARKETPLACE}"
# Guided feature development with architecture focus
claude plugin install "feature-dev@${MARKETPLACE}"

# ── Language Support (LSP) ───────────────────────────────────
# TypeScript/JavaScript language server
claude plugin install "typescript-lsp@${MARKETPLACE}"
# Go language server
claude plugin install "gopls-lsp@${MARKETPLACE}"

# ── External Integrations ────────────────────────────────────
# Up-to-date library documentation via Context7
claude plugin install "context7@${MARKETPLACE}"
# Microsoft/Azure documentation lookup
claude plugin install "microsoft-docs@${MARKETPLACE}"
# Session state persistence across conversations
claude plugin install "remember@${MARKETPLACE}"
# AI-first project design analysis
claude plugin install "ai-firstify@${MARKETPLACE}"

# ── Frontend ─────────────────────────────────────────────────
# Production-grade frontend interface design
claude plugin install "frontend-design@${MARKETPLACE}"

# ── Specialized ──────────────────────────────────────────────
# Autonomous iteration framework
claude plugin install "ralph-loop@${MARKETPLACE}"
# Multi-agent orchestration patterns
claude plugin install "atomic-agents@${MARKETPLACE}"
# Airflow, dbt, and data pipeline workflows
claude plugin install "data-engineering@${MARKETPLACE}"
# Hugging Face model training, datasets, and deployment
claude plugin install "huggingface-skills@${MARKETPLACE}"

# ── Terminal Integration ─────────────────────────────────────
# Warp terminal notifications (separate marketplace)
claude plugin install "warp@claude-code-warp"

echo ""
echo "Done. Installed 24 plugins."
echo "Run 'claude plugin list' to verify."
