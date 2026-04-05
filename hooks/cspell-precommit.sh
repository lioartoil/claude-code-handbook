#!/usr/bin/env bash
# cSpell precommit hook — Claude-powered spelling validation
# Trigger: PreToolUse:Bash with if: "Bash(git commit*)"
#
# Runs cspell on staged files before commit. If unknown words are found,
# denies the commit with structured context so Claude can decide per-word:
#   - Fix typo in source file
#   - Add legitimate term to cspell.json words
#   - Add path to cspell.json ignorePaths
#   - Add pattern to cspell.json ignoreRegExpList
#   - Rename variable/identifier in source

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')
cd "$CWD" || exit 0

# Get staged files only
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

# Run cspell on staged files, capture output
CSPELL_OUTPUT=$(npx cspell lint --no-progress --no-summary $STAGED 2>&1) || true

if [ -z "$CSPELL_OUTPUT" ]; then
  exit 0
fi

# Count issues
ISSUE_COUNT=$(echo "$CSPELL_OUTPUT" | wc -l | tr -d ' ')

# Build structured context for Claude
CONTEXT="cSpell found ${ISSUE_COUNT} unknown word(s) in staged files. For each word below, decide the appropriate action:

- **Typo**: Fix the spelling in the source file
- **Legitimate term**: Add to cspell.json \`words\` array (sorted, deduplicated)
- **File to exclude**: Add to cspell.json \`ignorePaths\` array
- **Pattern to exclude**: Add to cspell.json \`ignoreRegExpList\` array
- **Variable to rename**: Rename the identifier in the source file

Issues:
${CSPELL_OUTPUT}

After fixing all issues, stage the changes and retry the commit."

# Deny commit with structured feedback
jq -n --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $ctx
  }
}'
