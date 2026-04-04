# /sync-claude

Bidirectional sync between live `~/.claude/` config and the repo backup in `your-backup-repo/claude/`.

## Usage

```
/sync-claude              # Show sync status (default)
/sync-claude status       # Same as above
/sync-claude live-to-repo # Sync live config → repo backup
/sync-claude repo-to-live # Sync repo backup → live config
```

## Prompt

Synchronize Claude Code configuration between the live `~/.claude/` directory and the repo backup. Follow these steps precisely:

### Step 1: Auto-Detect Repo Path

Find the repo backup directory:

```bash
find ~/workspace -maxdepth 4 -type d -name "your-backup-repo" 2>/dev/null | head -5
```

From the results, find the one that has a `claude/` subdirectory (check with `ls <path>/claude/CLAUDE.md`). Set this as `REPO_CLAUDE="<path>/claude"`. If not found, stop and tell the user.

Set `LIVE=~/.claude`.

### Step 2: Determine Mode

Parse the argument: `$ARGUMENTS`. If empty or "status", run status mode. Otherwise run the specified mode.

### Step 3: Execute Mode

#### Status Mode

Compare each syncable category between `$LIVE` and `$REPO_CLAUDE`. For each, show file count and whether they differ:

```bash
# Compare each category
for dir in commands skills agents rules templates scripts hooks; do
  diff -rq "$LIVE/$dir" "$REPO_CLAUDE/$dir" 2>/dev/null
done
# Compare root files
for f in CLAUDE.md MEMORY.md lessons.md settings.json; do
  diff -q "$LIVE/$f" "$REPO_CLAUDE/$f" 2>/dev/null
done
# Check MCP servers
echo "=== MCP Servers ==="
jq '.mcpServers // {}' ~/.claude.json 2>/dev/null | head -5
ls "$REPO_CLAUDE/mcp-servers.json" 2>/dev/null && echo "Repo has mcp-servers.json" || echo "No mcp-servers.json in repo"
```

Present results as a table showing: Category | Live Files | Repo Files | Status (synced/differs/missing).

#### Live-to-Repo Mode

Copy syncable files from live to repo:

```bash
LIVE=~/.claude
# REPO_CLAUDE detected in Step 1

# Directories (recursive, preserve structure)
for dir in commands skills agents rules templates scripts hooks; do
  if [ -d "$LIVE/$dir" ]; then
    mkdir -p "$REPO_CLAUDE/$dir"
    rsync -av --include="*.md" --include="*.sh" --include="*.txt" --include="*/" --exclude="*" "$LIVE/$dir/" "$REPO_CLAUDE/$dir/"
  fi
done

# Root files
for f in CLAUDE.md MEMORY.md lessons.md settings.json; do
  cp "$LIVE/$f" "$REPO_CLAUDE/$f" 2>/dev/null
done

# Extract MCP servers config (exclude sensitive runtime data)
jq '{mcpServers: .mcpServers}' ~/.claude.json > "$REPO_CLAUDE/mcp-servers.json"

echo "Sync complete. Run 'git diff --stat' to review changes."
```

After running, show a summary table of what was copied/updated.

#### Repo-to-Live Mode

Copy syncable files from repo to live:

```bash
# REPO_CLAUDE detected in Step 1
LIVE=~/.claude

# Directories
for dir in commands skills agents rules templates scripts hooks; do
  if [ -d "$REPO_CLAUDE/$dir" ]; then
    mkdir -p "$LIVE/$dir"
    rsync -av --include="*.md" --include="*.sh" --include="*.txt" --include="*/" --exclude="*" "$REPO_CLAUDE/$dir/" "$LIVE/$dir/"
  fi
done

# Root files
for f in CLAUDE.md MEMORY.md lessons.md settings.json; do
  cp "$REPO_CLAUDE/$f" "$LIVE/$f" 2>/dev/null
done

# Merge MCP servers (additive — don't overwrite existing servers)
if [ -f "$REPO_CLAUDE/mcp-servers.json" ]; then
  echo "MCP servers to merge:"
  cat "$REPO_CLAUDE/mcp-servers.json"
  # Use jq to merge: repo servers + existing live servers (live wins on conflict)
  jq -s '.[0].mcpServers as $repo | .[1] | .mcpServers = ($repo + .mcpServers)' \
    "$REPO_CLAUDE/mcp-servers.json" ~/.claude.json > /tmp/claude-json-merged.json
  cp /tmp/claude-json-merged.json ~/.claude.json
  echo "MCP servers merged into ~/.claude.json"
fi
```

After repo-to-live, ask if the user wants to:
1. Run `setup-knowledge-base.sh` to create knowledge-base symlinks
2. Run `npm install -g mcp-local-rag` if not already installed

Show a summary of what was restored.

### Important Rules

- **NEVER sync**: `.credentials.json`, `secrets/`, `history.jsonl`, `logs/`, `cache/`, `plugins/`, `sessions/`, `tasks/`, `projects/`, `pr-reviews/`
- **MCP config**: Only the `mcpServers` section of `.claude.json` — never the full file
- **settings.json**: Sync as-is (includes `enabledPlugins`)
- **Confirm before overwriting**: If a file in the target is newer than the source, warn the user before overwriting
