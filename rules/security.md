# Security Policy

> Defense-in-depth for AI coding assistants.

## NEVER Access macOS Keychain

- **NEVER** run `security dump-keychain`, `security find-generic-password`, `security find-internet-password`, or ANY `security` subcommand
- Blocked at: deny rule (`Bash(security:*)`) + PreToolUse hook (`risk-classifier.sh`) + this instruction
- **For credentials**: Use environment variables (`$JIRA_API_TOKEN`, `$GITHUB_TOKEN`) or `gh auth token` / `jira` CLI built-in auth

**Why**: `security dump-keychain` can trigger EDR alerts and is a real risk vector.
**Resolution**: 3-layer block (deny rule + PreToolUse hook + instruction ban).

## Risk Classification (3-Tier)

All Bash commands are classified by `risk-classifier.sh`:

| Tier | Gate | Action | Patterns |
|------|------|--------|----------|
| **HIGH** | Block + audit | `exit 2` | Keychain access, pipe-to-network, TCP/UDP redirects, netcat listeners, encoded transfers |
| **MEDIUM** | Warn + audit | `exit 0` + stderr | Credential file reads, external POST, `chmod 777`, recursive deletes outside `/tmp` |
| **LOW** | Audit only | `exit 0` | Everything else |

**Audit log**: `~/.claude/state/hook-audit.jsonl` — one JSON line per Bash invocation (tier, action, pattern, truncated command).
