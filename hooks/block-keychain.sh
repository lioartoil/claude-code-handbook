#!/bin/bash
# Block macOS security/keychain commands — CSOC incident prevention
# Triggered by: PreToolUse hook for Bash tool
# Incident: Feb 18, 2026 — security dump-keychain triggered CSOC EDR alert

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qiE '(security\s+(dump-keychain|find-generic-password|delete-keychain|find-identity|cms|add-generic-password|add-internet-password)|/usr/bin/security)'; then
  echo "BLOCKED: macOS security/keychain commands are prohibited (CSOC policy)"
  exit 2
fi
