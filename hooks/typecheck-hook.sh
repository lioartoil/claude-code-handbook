#!/bin/bash
# Post-tool-use hook: Run TypeScript type checking after file edits
# Only runs if tsconfig.json exists in the project root

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Only check for edit/write operations on TS/TSX/Vue files
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

if [[ ! "$FILE_PATH" =~ \.(ts|tsx|vue)$ ]]; then
  exit 0
fi

# Find project root (look for tsconfig.json upward)
DIR=$(dirname "$FILE_PATH")
while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/tsconfig.json" ]]; then
    cd "$DIR"
    npx --no-install tsc --noEmit 2>&1 | head -20 >&2
    exit 0
  fi
  DIR=$(dirname "$DIR")
done

# No tsconfig.json found — skip silently
exit 0
