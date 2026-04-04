#!/bin/bash
# Setup script: Block macOS keychain access from Claude Code
# CSOC Policy (Feb 20, 2026) — portable, runs on any machine
# Usage: bash ~/.claude/hooks/setup-keychain-block.sh
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo "=== Claude Code Keychain Block Setup ==="
echo "Home: $HOME"
echo ""

# Prerequisites
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq"
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "ERROR: $SETTINGS not found. Run Claude Code at least once first."
  exit 1
fi

# 1. Create hook script
mkdir -p "$HOOKS_DIR"
cat > "$HOOKS_DIR/block-keychain.sh" << 'HOOKEOF'
#!/bin/bash
# Block macOS keychain access — CSOC policy (Feb 20, 2026)
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if echo "$command" | grep -qiE 'security\s+(dump-keychain|find-generic-password|find-internet-password|delete-generic-password|add-generic-password|delete-keychain)'; then
  echo '{"reason": "BLOCKED: macOS keychain access is prohibited per CSOC policy. Use environment variables ($JIRA_API_TOKEN, $GITHUB_TOKEN) or CLI built-in auth (gh auth, jira CLI) instead."}' >&2
  exit 2
fi
exit 0
HOOKEOF
chmod +x "$HOOKS_DIR/block-keychain.sh"
echo "[1/3] Created $HOOKS_DIR/block-keychain.sh"

# 2. Patch settings.json — add deny rule + hooks
TEMP=$(mktemp)

# Add "Bash(security:*)" to deny array (idempotent)
jq '
  .permissions.deny = (
    (.permissions.deny // [])
    | if any(. == "Bash(security:*)") then . else . + ["Bash(security:*)"] end
  )
' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"

# Add hooks.PreToolUse (idempotent — check if already has keychain hook)
HOOK_CMD="bash $HOME/.claude/hooks/block-keychain.sh"
HAS_HOOK=$(jq --arg cmd "$HOOK_CMD" '
  .hooks.PreToolUse // [] | any(.hooks[]?.command == $cmd)
' "$SETTINGS")

if [ "$HAS_HOOK" = "false" ]; then
  jq --arg cmd "$HOOK_CMD" '
    .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": $cmd,
        "timeout": 5
      }]
    }])
  ' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"
fi
echo "[2/3] Patched $SETTINGS (deny rule + PreToolUse hook)"

# 3. Add Security Restrictions to CLAUDE.md (if not already present)
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q "NEVER Access macOS Keychain" "$CLAUDE_MD"; then
    # Insert after "Mentorship Mindset" line (end of Core Rules)
    SECTION='
## Security Restrictions

> **CSOC Policy** (February 20, 2026): Following EDR alert from CSOC team.

### NEVER Access macOS Keychain

- **NEVER** run `security dump-keychain`, `security find-generic-password`, `security find-internet-password`, or ANY `security` subcommand
- This is blocked at both the permission layer (`deny: ["Bash(security:*)"]`) and hook layer (`PreToolUse`)
- **For credentials**: Use environment variables (`$JIRA_API_TOKEN`, `$GITHUB_TOKEN`) or `gh auth token` / `jira` CLI built-in auth
- **Reason**: Triggers EDR alerts, flagged as security risk by CSOC team (the SOC team)
'
    echo "$SECTION" >> "$CLAUDE_MD"
    echo "[3/3] Added Security Restrictions to $CLAUDE_MD"
  else
    echo "[3/3] Security Restrictions already in $CLAUDE_MD (skipped)"
  fi
else
  echo "[3/3] WARNING: $CLAUDE_MD not found — add Security Restrictions manually"
fi

echo ""
echo "=== Done! Restart Claude Code to activate. ==="
echo ""
echo "Verify:"
echo "  1. grep 'security' $SETTINGS"
echo "  2. cat $HOOKS_DIR/block-keychain.sh"
echo "  3. grep 'Keychain' $CLAUDE_MD"
