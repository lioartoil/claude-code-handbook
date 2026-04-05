# Agents

Custom subagents and Agent Teams for Claude Code. See [`agents/README.md`](agents/README.md) for the full guide.

## Subagents

Subagents are autonomous workers that run in isolated context windows. They report results back to the parent — they never talk to each other.

### Agent Definition Format

```yaml
---
name: my-agent
description: What it does and when to delegate to it
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: inherit
skills:
  - pr-review
memory: user
---

System prompt for the agent goes here.
```

### Frontmatter Reference

| Field              | Required | Description                                                    |
| ------------------ | -------- | -------------------------------------------------------------- |
| `name`             | Yes      | Lowercase identifier with hyphens                              |
| `description`      | Yes      | When Claude should delegate to this agent                      |
| `tools`            | No       | Tool allowlist (inherits all if omitted)                       |
| `disallowedTools`  | No       | Tools to deny from inherited list                              |
| `model`            | No       | `sonnet`, `opus`, `haiku`, or `inherit` (default)              |
| `skills`           | No       | Skills to preload into agent context                           |
| `memory`           | No       | `user`, `project`, or `local` for persistent learning          |
| `isolation`        | No       | `worktree` for isolated git worktree                           |
| `maxTurns`         | No       | Max agentic turns before stop                                  |
| `permissionMode`   | No       | `default`, `acceptEdits`, `auto`, `plan`                       |
| `effort`           | No       | `low`, `medium`, `high`, `max`                                 |
| `hooks`            | No       | Lifecycle hooks scoped to this agent                           |
| `mcpServers`       | No       | Scoped MCP servers (inline or reference)                       |
| `background`       | No       | `true` to always run as background task                        |
| `initialPrompt`    | No       | Auto-submitted first turn when running via `--agent`           |

### Design Principles

1. **Least privilege** — only grant tools the agent needs
2. **Read-only by default** — review/analysis agents should never have Write/Edit
3. **Skill binding** — preload domain knowledge via `skills:` instead of repeating it
4. **Structured output** — define exact output format so the parent can parse results

### Included Agents

| Agent            | Purpose               | Tools                  | Skills    |
| ---------------- | --------------------- | ---------------------- | --------- |
| `code-reviewer`  | PR review specialist  | Read, Grep, Glob, Bash | pr-review |
| `sprint-planner` | Sprint coordination   | Read, Grep, Glob, Bash | —         |

### Usage

```
# Invoke a specific agent
Agent(subagent_type="code-reviewer", prompt="Review PR #123")

# Multiple agents in parallel (used by /orchestrate-review)
Agent(subagent_type="code-reviewer", prompt="Review security...")
Agent(subagent_type="code-reviewer", prompt="Review performance...")
```

### Installation

Copy agent `.md` files to `~/.claude/agents/` (global) or `.claude/agents/` (project-level).

---

## Agent Teams (Experimental)

Agent Teams (v2.1.32+) are multiple independent Claude Code sessions that coordinate through shared task lists and peer-to-peer messaging. Unlike subagents, teammates can talk to each other.

### Subagents vs Agent Teams

| Feature                          | Subagents        | Agent Teams       |
| -------------------------------- | ---------------- | ----------------- |
| Teammates talk to each other     | No               | Yes               |
| Shared task list with deps       | No               | Yes               |
| Independent context windows      | Yes              | Yes               |
| Token cost                       | Lower (summary)  | Higher (full)     |
| Work is independent              | Yes              | Yes               |
| Debating / competing hypotheses  | No               | Yes               |
| Experimental                     | No               | Yes               |

**Rule of thumb:** Use subagents when only the result matters. Use Agent Teams when teammates need to coordinate, challenge each other, or self-assign work.

### Setup

Enable in `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Then spawn naturally:

```
Create an agent team with 3 specialists:
- security-reviewer: Focus on auth and input validation
- performance-specialist: Focus on query optimization and caching
- test-engineer: Focus on coverage and edge cases
```

### Display Modes

| Mode          | Terminal         | Navigation                          |
| ------------- | ---------------- | ----------------------------------- |
| **In-process**| Any terminal     | `Shift+Down` to cycle teammates     |
| **Split pane**| tmux or iTerm2   | Click pane to interact              |

### Shared Task Lists

Tasks support dependency tracking and self-claiming:

```
Break this into 5 independent tasks. Create a team with 3 teammates.
They should claim tasks and work independently.
```

- Teammates self-claim pending tasks
- File locking prevents simultaneous claims
- Dependent tasks auto-unblock when blockers complete
- Target 5-6 tasks per teammate

### Peer-to-Peer Messaging

**`message`** — send to one teammate:
```
Message the security reviewer: "Found a potential injection. Can you verify?"
```

**`broadcast`** — send to all teammates (use sparingly — costs scale with team size):
```
Broadcast: "Schema changed. Recheck your assumptions."
```

### Coordination Patterns

**Lead-orchestrated** — Lead creates tasks, assigns work, synthesizes findings:
```
Review PR #142 with 3 specialists. After all finish, summarize consensus.
```

**Self-coordinated** — Teammates claim tasks independently, message each other:
```
Break this refactoring into 5 modules. Teammates should claim and work.
Message each other if they discover shared abstractions.
```

**Competing hypotheses** — Teammates investigate different theories, debate:
```
App crashes after one message. Spawn 3 teammates with different hypotheses.
Have them try to disprove each other. Report consensus.
```

### File Conflict Prevention

No two teammates should edit the same file simultaneously. Design tasks with clear file ownership:

```
Good:
  Task 1: Implement auth module (auth.py)
  Task 2: Implement users module (users.py)
  Task 3: Integration tests (test_integration.py) — depends on 1, 2

Bad:
  Task 1: Refactor handlers (handler.py) — Teammate A
  Task 2: Add endpoints (handler.py) — Teammate B  ← CONFLICT
```

### Quality Gate Hooks

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          { "type": "command", "command": "./scripts/check-output.sh" }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          { "type": "command", "command": "./scripts/validate-tests.sh" }
        ]
      }
    ]
  }
}
```

- **TeammateIdle** — fires when teammate finishes. Exit 2 to keep them working.
- **TaskCreated** — fires before task creation. Exit 2 to block.
- **TaskCompleted** — fires before marking done. Exit 2 to reject.

### Limitations

- **Experimental** — disabled by default, subject to change
- **No session resume** — `/resume` doesn't restore teammates; respawn after resuming
- **No nested teams** — teammates cannot spawn their own teams
- **One team per session** — clean up before creating a new team
- **Permissions set at spawn** — teammates inherit lead's permission mode
- **No split panes in VS Code** — use in-process mode or native terminal with tmux
