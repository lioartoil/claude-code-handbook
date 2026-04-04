# Keychain Access Policy

> Prevent AI coding assistants from accessing macOS Keychain.

## NEVER Access macOS Keychain

- **NEVER** run `security dump-keychain`, `security find-generic-password`, `security find-internet-password`, or ANY `security` subcommand
- Blocked at: deny rule (`Bash(security:*)`) + PreToolUse hook (`block-keychain.sh`) + this instruction
- **For credentials**: Use environment variables (`$JIRA_API_TOKEN`, `$GITHUB_TOKEN`) or `gh auth token` / `jira` CLI built-in auth

**Why**: `security dump-keychain` can trigger EDR alerts and is a real risk vector.
**Resolution**: 3-layer block (deny rule + PreToolUse hook + instruction ban).
