# Commands

Slash commands for Claude Code. Copy to `~/.claude/commands/` (global) or `.claude/commands/` (project).

## Usage

```
/command-name [arguments]
```

## Index

### Workflow Design
| Command | Description |
|---------|-------------|
| `/shape-problem` | Transform ambiguous requirements into structured problem definitions |
| `/explore-solution` | Generate 2-3 solution approaches before committing to one |
| `/context-brief` | Assemble context for a task from JIRA, GitHub, GCP, and codebase |

### Debugging
| Command | Description |
|---------|-------------|
| `/systematic-debugging` | Structured debugging: observe, hypothesize, test, fix |
| `/root-cause-tracing` | Trace bugs backward through call chain to root cause |

### Code Review
| Command | Description |
|---------|-------------|
| `/review-and-comment` | Full PR review with inline GitHub comments (primary) |
| `/orchestrate-review` | Multi-agent parallel review for large/risky PRs (>300 lines, auth/payment) |
| `/owasp-security` | OWASP Top 10:2025 security-focused review |

### TDD & Implementation
| Command | Description |
|---------|-------------|
| `/test-driven-development` | TDD workflow with anti-rationalization guide |

### Sprint & Task Management
| Command | Description |
|---------|-------------|
| `/optimize-subtasks` | Analyze subtask breakdown and suggest consolidation |
| `/jira-sync` | Sync JIRA tickets to local documentation |
| `/promote-env` | Environment promotion PR workflow (develop -> sit -> uat -> prod) |

### Tracking
| Command | Description |
|---------|-------------|
| `/daily-log` | Create/update daily task log (accomplishments, blockers, plans) |
| `/weekly-review` | Weekly summary with metrics and trends |
| `/quarterly-review` | Review quarterly goals/OKRs and update progress |
| `/sprint-status` | Check sprint progress, burndown, velocity |
| `/review-metrics` | Analyze PR review effectiveness (acceptance rate, false positives) |

### Session & Workspace
| Command | Description |
|---------|-------------|
| `/session-handoff` | Capture session context for CLAUDE.md handoff |
| `/clean-workspace` | Find and clean temp files, build artifacts, duplicates |
| `/sync-claude` | Bidirectional sync between live ~/.claude/ and repo backup |

### Meta
| Command | Description |
|---------|-------------|
| `/skill-creator` | Guide for creating new Claude Code skills or commands |
