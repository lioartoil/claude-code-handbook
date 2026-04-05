# Hooks

Claude Code hooks run before/after tool calls. They add guardrails and automation.

This handbook includes command hooks as executable scripts. This guide covers all 4 hook types with production-grade examples.

## Hook Types at a Glance

| Type        | Execution           | Latency   | Cost          | Best for                         |
| ----------- | ------------------- | --------- | ------------- | -------------------------------- |
| **Command** | Shell script        | <100ms    | $0            | Deterministic rules, file checks |
| **Prompt**  | Single LLM call     | ~200ms    | ~$0.0001/call | Semantic yes/no decisions        |
| **Agent**   | Multi-turn subagent | 5-30s     | ~$0.001-0.01  | Complex codebase verification    |
| **HTTP**    | POST to endpoint    | 100-500ms | $0            | Audit logging, remote policy     |

## Command Hooks

Shell scripts or Node.js scripts. Exit 0 to allow, exit 2 to block.

**This handbook includes:**

| Script              | Trigger          | Purpose                              |
| ------------------- | ---------------- | ------------------------------------ |
| `block-keychain.sh` | PreToolUse:Bash  | Blocks macOS `security` commands     |
| `dedup-hook.mjs`    | PreToolUse:Write | Detects duplicate code before writes |
| `typecheck-hook.sh` | PostToolUse:Edit | TypeScript type checking after edits |

**stdin/stdout protocol:**

```bash
#!/bin/bash
INPUT=$(cat)                                              # JSON on stdin
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path')     # Extract fields
echo "Blocked: $FILE" >&2                                 # Reason on stderr
exit 2                                                    # Exit 2 = block
```

## Prompt Hooks

Single-turn LLM evaluation using Haiku (default). The model returns `{"ok": true}` or `{"ok": false, "reason": "..."}`. No tool access — decisions are based on the hook input data alone.

**When to use:** You need semantic judgment that regex can't handle, but don't need to inspect the codebase.

**Example — Anti-rationalization gate (Stop event):**

Prevents Claude from claiming work is done when it isn't. Catches patterns like "this is a pre-existing issue" or "I'll leave that as a follow-up."

```json
{
  "Stop": [
    {
      "hooks": [
        {
          "type": "prompt",
          "prompt": "Review the assistant's final response. Reject if the assistant is rationalizing incomplete work: claiming issues are 'pre-existing' or 'out of scope', saying 'too many issues' to fix, deferring to unrequested 'follow-ups', listing problems without fixing them, or skipping test/lint failures with excuses. Respond with {\"ok\": false, \"reason\": \"<specific issue>\"} if any pattern applies, otherwise {\"ok\": true}."
        }
      ]
    }
  ]
}
```

**Example — Command safety classifier (PreToolUse):**

Semantically evaluates whether a Bash command is safe, beyond what a blocklist can catch.

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "A Claude Code session is about to run this bash command. Deny if it: deletes files recursively, modifies system directories, runs with sudo, or accesses credentials. Command: $COMMAND. Respond with {\"ok\": true} if safe, {\"ok\": false, \"reason\": \"why\"} if unsafe.",
          "model": "claude-haiku-4-5-20251001",
          "timeout": 5
        }
      ]
    }
  ]
}
```

## Agent Hooks

Multi-turn subagent with tool access (Read, Grep, Glob, Bash — up to 50 turns). Same `{"ok": true/false}` response format as prompt hooks, but can inspect the actual codebase.

**When to use:** You need to verify something against the current state of files, not just the hook input data. More expensive and slower than prompt hooks.

**Example — Test verification before stop:**

Spawns an agent that runs the test suite and blocks if tests fail.

```json
{
  "Stop": [
    {
      "hooks": [
        {
          "type": "agent",
          "prompt": "Verify the work is complete. Run the test suite and check results. Only return {\"ok\": true} if all tests pass. If tests fail, return {\"ok\": false, \"reason\": \"<which tests failed>\"}. $ARGUMENTS",
          "timeout": 120
        }
      ]
    }
  ]
}
```

**Example — Architecture compliance on edits:**

Verifies that changes follow established patterns by reading existing code.

```json
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "agent",
          "prompt": "Read the existing files in the same directory as the file being modified. Verify the proposed change follows the established patterns (naming, structure, error handling). $ARGUMENTS",
          "timeout": 60
        }
      ]
    }
  ]
}
```

## HTTP Hooks

POST event data as JSON to an HTTP endpoint. The endpoint returns the same JSON format as command hooks. Non-2xx responses are non-blocking — to deny a tool call, return 2xx with `permissionDecision: "deny"`.

**When to use:** Centralized audit logging, team-wide policy enforcement, or integration with external services (Slack, PagerDuty, CI/CD).

**Example — Audit logger:**

Sends all Bash commands to a local audit service.

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "http",
          "url": "http://localhost:8080/hooks/audit",
          "headers": {
            "Authorization": "Bearer $AUDIT_TOKEN"
          },
          "allowedEnvVars": ["AUDIT_TOKEN"],
          "timeout": 10
        }
      ]
    }
  ]
}
```

**Example — Slack deploy notification (async):**

Fires a Slack webhook after deploy commands, without blocking.

```json
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "http",
          "if": "Bash(npm run deploy*)",
          "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
          "async": true,
          "timeout": 10
        }
      ]
    }
  ]
}
```

## Advanced: The `if` Field

Available since v2.1.85. Filters hook execution based on tool arguments, not just tool name. More efficient than checking inside the script — the hook process doesn't spawn at all if `if` doesn't match.

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "if": "Bash(rm *)",
          "command": "./hooks/block-destructive.sh"
        },
        {
          "type": "command",
          "if": "Bash(git push *)",
          "command": "./hooks/verify-push.sh"
        }
      ]
    }
  ]
}
```

## Choosing the Right Hook Type

```
Need to enforce a rule?
├── Can it be checked with regex/pattern matching?
│   └── YES → Command hook (deterministic, fast, free)
├── Need semantic judgment on the hook input alone?
│   └── YES → Prompt hook (Haiku, ~$0.0001, ~200ms)
├── Need to read files or run commands to verify?
│   └── YES → Agent hook (multi-turn, ~$0.001-0.01, 5-30s)
└── Need to notify an external service?
    └── YES → HTTP hook (POST, free, 100-500ms)
```
