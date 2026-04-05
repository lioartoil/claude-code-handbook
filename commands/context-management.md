# Context Management

Guide for managing context effectively during long coding sessions.

## When to Act

Run `/context` to check current utilization. Act based on these thresholds:

| Utilization | Action                                                |
| ----------- | ----------------------------------------------------- |
| < 60%       | Keep working                                          |
| 60-70%      | Manual `/compact` with custom instructions (ideal)    |
| 70-80%      | Auto-compact may fire — you should have acted already |
| > 80%       | Consider `/clear` if switching tasks                  |

## /compact vs /clear vs /resume

```
Need to free context?
├── Continuing the same task?
│   └── /compact [instructions] — summarizes old context, preserves direction
├── Switching to an unrelated task?
│   └── /clear — wipes conversation, keeps CLAUDE.md and memory
├── Already compacted 2-3 times?
│   └── /clear — repeated compaction degrades summary quality
└── Resuming a previous session?
    └── /resume [session] — restores full conversation history
```

## Custom Compact Instructions

Never run bare `/compact`. Always tell Claude what to preserve:

**Debugging session:**

```
/compact preserve the stack trace from the auth error, all modified files, and the hypothesis that the token refresh is racing with the session check
```

**Refactoring session:**

```
/compact preserve the list of files migrated, remaining files to migrate, and the schema changes in src/graphql/
```

**Test-fixing session:**

```
/compact preserve which tests pass, which fail, the exact error messages, and the fix attempted in user-service.ts
```

**Persistent compact instructions** (add to CLAUDE.md):

```markdown
# Compact Instructions

When compacting, always preserve:

- All modified file paths with specific changes made
- Current test results (pass/fail, exact error messages)
- The current task and remaining TODO items
- Architectural decisions made and their reasoning
```

## What Survives

| Content              | /compact   | /clear | New session |
| -------------------- | ---------- | ------ | ----------- |
| CLAUDE.md            | Yes        | Yes    | Yes         |
| Auto memory          | Yes        | Yes    | Yes         |
| Settings & hooks     | Yes        | Yes    | Yes         |
| Conversation history | Summarized | No     | No          |
| Tool outputs         | No         | No     | No          |
| Session permissions  | Yes        | Reset  | Reset       |

## PostCompact Hook

Re-inject critical context after compaction using a `SessionStart` hook with `compact` matcher:

**settings.json:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "cat <<'EOF'\nMANDATORY: Re-read CLAUDE.md before proceeding.\nConfirm you have reloaded all project rules.\nEOF"
          }
        ]
      }
    ]
  }
}
```

The hook fires after compaction completes. Its stdout is injected as context, reminding Claude to reload project rules that may have been lost in summarization.

## Token Optimization

**Highest-impact actions:**

1. **Create `.claudeignore`** — exclude `node_modules/`, `dist/`, `build/`, `*.log`, test fixtures
2. **Keep CLAUDE.md under 200 lines** — use `@imports` and `.claude/rules/` for longer instructions
3. **Use `paths:` scoping on rules** — language-specific rules only load when editing matching files
4. **Delegate to subagents** — subagents get fresh context windows, don't bloat yours
5. **Commit at logical checkpoints** — then reference the commit instead of re-reading files
6. **Request concise output** — "show only changed lines, not the full file"

## Session Lifecycle

```
Start → Plan Mode → Work → /compact at 60% → Work → /compact again
                                                        ↓
                                              Quality degrading?
                                              ├── YES → /session-handoff then /clear
                                              └── NO → Continue working
```

For structured session handoffs, use `/session-handoff` to capture context before `/clear`.
