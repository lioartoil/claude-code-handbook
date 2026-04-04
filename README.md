# Claude Code Handbook

How I work with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — the commands, skills, hooks, and rules I use daily as a lead software engineer.

This repo is my actual working setup, extracted and sanitized from my internal engineering repos. Everything here is battle-tested across 40+ sessions of real work: PR reviews, sprint planning, debugging production incidents, and shipping features.

## What's Inside

```
commands/     20 slash commands — workflows triggered via /command-name
skills/        7 auto-activated skills — context-aware behaviors
hooks/         4 pre/post tool hooks — guardrails and automation
rules/         5 auto-loaded rules — always-on constraints
templates/     CLAUDE.md templates for new projects
```

## Quick Start

### Option 1: Cherry-pick what you need

Copy individual files to your Claude Code config:

```bash
# Commands → ~/.claude/commands/
cp commands/systematic-debugging.md ~/.claude/commands/

# Skills → project .claude/skills/ (or global)
cp -r skills/owasp-security/ .claude/skills/

# Rules → ~/.claude/rules/
cp rules/scope-management.md ~/.claude/rules/

# Hooks → register in ~/.claude/settings.json
cp hooks/block-keychain.sh ~/.claude/hooks/
```

### Option 2: Clone the whole thing

```bash
git clone https://github.com/lioartoil/claude-code-handbook.git

# Symlink what you want
ln -s $(pwd)/claude-code-handbook/commands/systematic-debugging.md ~/.claude/commands/
ln -s $(pwd)/claude-code-handbook/rules/scope-management.md ~/.claude/rules/
```

## Commands

Slash commands are workflows you invoke with `/command-name`. See [`commands/README.md`](commands/README.md) for the full index.

### Highlights

| Command                    | What it does                                                    |
| -------------------------- | --------------------------------------------------------------- |
| `/review-and-comment`      | Full PR review with inline GitHub comments                      |
| `/systematic-debugging`    | Structured debugging with phases (observe → hypothesize → test) |
| `/test-driven-development` | TDD workflow with anti-rationalization guide                    |
| `/root-cause-tracing`      | Trace bugs backward through call chain                          |
| `/owasp-security`          | OWASP Top 10:2025 security review                               |
| `/orchestrate-review`      | Multi-agent parallel PR review for large/risky PRs              |
| `/session-handoff`         | Preserve session context for next conversation                  |
| `/shape-problem`           | Transform ambiguous requirements into structured definitions    |

## Skills

Skills are auto-activated by Claude when relevant context is detected. They're more powerful than commands because they include reference materials and scoring criteria.

| Skill            | Purpose                                                                  |
| ---------------- | ------------------------------------------------------------------------ |
| `owasp-security` | Security review with secure code patterns and agentic AI risks           |
| `pr-review`      | Comprehensive code review with criteria and comment templates            |
| `pr-followup`    | Follow up on PR review comment responses                                 |
| `autoresearch`   | Hill-climbing optimizer for headless review prompts                      |
| `implement`      | Single-shot ticket-to-PR implementation (TDD, pattern scan, self-review) |
| `get-api-docs`   | Fetch API docs before writing integration code                           |
| `verify-pr`      | Full PR verification checklist (build, test, push)                       |

## Rules

Rules are auto-loaded instructions that apply to every session. These are my non-negotiable constraints.

| Rule                     | What it enforces                                              |
| ------------------------ | ------------------------------------------------------------- |
| `scope-management.md`    | PR size limits (200-500 lines target), scope creep prevention |
| `plan-mode.md`           | Mandatory plan-before-execute workflow                        |
| `convention-defaults.md` | Go/TypeScript naming and structure conventions                |
| `code-quality.md`        | cSpell configuration scoping, quality standards               |
| `api-docs.md`            | Always check current docs before writing API code             |
| `security.md`            | Never access macOS Keychain (3-layer block)                   |

## Hooks

Hooks run before/after Claude Code tool calls. They add guardrails and automation.

| Hook                      | Trigger          | Purpose                                   |
| ------------------------- | ---------------- | ----------------------------------------- |
| `block-keychain.sh`       | PreToolUse:Bash  | Blocks `security` keychain commands       |
| `dedup-hook.mjs`          | PreToolUse:Write | Detects duplicate code before file writes |
| `typecheck-hook.sh`       | PostToolUse:Edit | TypeScript type checking after edits      |
| `setup-keychain-block.sh` | Manual           | One-time setup for the keychain block     |

## Templates

CLAUDE.md templates for bootstrapping new projects:

- **`grpc-mono-repo.md`** — For gRPC mono-repo projects with Go backend + Nuxt frontend

## Customization

Most files use placeholder values you should replace:

| Placeholder                  | Replace with                |
| ---------------------------- | --------------------------- |
| `your-org`                   | Your GitHub org name        |
| `your-app`                   | Your main repository name   |
| `your-core-lib`              | Your shared library package |
| `PROJ-123`                   | Your issue tracker prefix   |
| `your-company.atlassian.net` | Your Jira instance          |

## License

MIT
