---
name: context-management
description: Use during long sessions when the context window fills up. Manages token budget, suggests compaction, identifies what to drop.
---

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

## Context Rot Mitigations

LLM performance degrades non-uniformly as context grows. Apply these patterns when writing `/compact` instructions, structuring CLAUDE.md, or handling tool outputs.

### 1. Bookend Critical Information

Liu et al. 2023 ("Lost in the Middle") shows U-shaped attention: both **start** and **end** positions outperform the middle. Anthropic's official long-context guidance: place long reference docs at the TOP of the prompt, query/instructions at the END (queries at the end can improve quality up to 30%).

For `/compact`: list preservation targets at the start, then end with the current task statement.

```
/compact PRESERVE: working solution in auth.go (token refresh fix). PRESERVE: failing test names in auth_test.go. NOW: continue fixing the remaining 3 tests in session_test.go.
```

### 2. Drop Distractors Explicitly

Distractor interference is the dominant degradation mode — topically-related but stale info hurts MORE than unrelated info. Explicitly DROP failed approaches when compacting.

```
/compact PRESERVE: working solution. DROP: the 3 approaches we tried earlier (mocking, retry loop, custom interceptor — all rejected).
```

For unrelated task switches, prefer `/clear` over `/compact` (see threshold table above).

### 3. Use XML Tags, Not `[CRITICAL]` Markers

Anthropic's Claude 4.6 docs explicitly warn against aggressive emphasis language: *"Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'"* — overtriggering is now a real failure mode.

For emphasis, use XML structural tags treated as delineators rather than amplifiers:

```markdown
<critical_facts>
- The token refresh runs on a 5-minute interval
- Sessions expire after 30 minutes of inactivity
</critical_facts>
```

NOT: `[CRITICAL] The token refresh runs on a 5-minute interval`

### 4. Itemized Lists for Compact Targets

For `/compact` preservation targets, use itemized labels with clear directives. Avoid narrative scaffolding ("first... second... then..."):

**Bad:**
```
/compact first preserve the file list, then the test results, and finally make sure to keep the architectural decision about using a queue
```

**Good:**
```
/compact PRESERVE: [files] auth.go, session.go [tests] all 3 failing in auth_test.go [decision] use Redis-backed queue (not in-memory)
```

(Note: for general context structure outside `/compact`, Anthropic recommends XML tags or markdown headers — both are equally supported.)

### 5. Layer Hierarchy

Authority order: **system prompt (CLAUDE.md) > user messages > tool results.** Critical project knowledge belongs in CLAUDE.md, not in conversation history that can be compacted away. (Source: affaan-m/everything-claude-code, 139K stars)

If you find yourself repeating the same context across `/compact` calls, that's a signal to move it to CLAUDE.md.

### Sources & Open Questions

- [Chroma context rot research](https://www.trychroma.com/research/context-rot) — the original paper
- [Anthropic long-context tips (Claude 4.6)](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/long-context-tips) — official guidance
- [Liu et al. 2023 "Lost in the Middle"](https://arxiv.org/abs/2307.03172) — U-shape attention
- [Anthropic effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — compaction patterns
- [Hamel Husain's reading of Chroma](https://hamel.dev/notes/llm/rag/p6-context_rot.html) — **disputes** the position-based mitigation, claiming Chroma "found no consistent performance advantage for any particular position." Verify directly before relying on position-based fixes alone.

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
