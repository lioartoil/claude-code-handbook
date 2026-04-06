---
name: sync-claude
description: Use when syncing Claude Code config between machines. Subcommands push, pull, status, bootstrap. Templates paths, redacts tokens, propagates memory.
argument-hint: "[push|pull|status|bootstrap]"
disable-model-invocation: true
---

# /sync-claude

Cross-machine sync between live `~/.claude/` config and the repo backup in `lead-software-engineer/claude/`.

## Usage

```
/sync-claude              # Show sync status (default)
/sync-claude status       # Same as above
/sync-claude push         # Live → repo (template paths, export memory/crons)
/sync-claude pull         # Repo → live (expand paths, import memory, offer crontab)
/sync-claude bootstrap    # First-time setup on a new machine
```

Legacy aliases: `live-to-repo` = `push`, `repo-to-live` = `pull`.

## Prompt

Synchronize Claude Code configuration across machines. Follow these steps precisely:

### Step 1: Auto-Detect Repo Path

```bash
REPO_CLAUDE=""
for d in $(find ~/workspace -maxdepth 4 -type d -name "lead-software-engineer" 2>/dev/null); do
  [ -f "$d/claude/CLAUDE.md" ] && REPO_CLAUDE="$d/claude" && break
done
echo "Repo backup: ${REPO_CLAUDE:-NOT FOUND}"
```

If not found, stop and tell the user. Set `LIVE=~/.claude`.

### Step 2: Determine Mode

Parse `$ARGUMENTS`. Map: empty/"status" → status, "push"/"live-to-repo" → push, "pull"/"repo-to-live" → pull, "bootstrap" → bootstrap.

### Step 3: Execute Mode

---

#### Status Mode

Show a 4-tier comparison:

```bash
echo "=== Tier 1: Config ==="
for dir in commands skills agents rules templates hooks instincts; do
  live_count=$(find "$LIVE/$dir" -name "*.md" -o -name "*.sh" -o -name "*.json" -o -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
  repo_count=$(find "$REPO_CLAUDE/$dir" -name "*.md" -o -name "*.sh" -o -name "*.json" -o -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
  echo "$dir: live=$live_count repo=$repo_count"
done
for f in CLAUDE.md MEMORY.md lessons.md settings.json; do
  diff -q "$LIVE/$f" "$REPO_CLAUDE/$f" 2>/dev/null || echo "$f: DIFFERS or MISSING"
done

echo ""
echo "=== Tier 2: Scripts & Crons ==="
live_scripts=$(find "$LIVE/scripts" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
repo_scripts=$(find "$REPO_CLAUDE/scripts" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
echo "scripts/: live=$live_scripts repo=$repo_scripts"
[ -f "$REPO_CLAUDE/crontab.txt" ] && echo "crontab.txt: IN REPO" || echo "crontab.txt: NOT IN REPO"

echo ""
echo "=== Tier 3: Project Memory ==="
for proj_dir in "$LIVE"/projects/*/memory; do
  [ -d "$proj_dir" ] || continue
  count=$(find "$proj_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -gt 0 ] || continue
  encoded=$(basename "$(dirname "$proj_dir")")
  echo "$encoded ($count files)"
done
[ -d "$REPO_CLAUDE/project-memory" ] && echo "Repo has project-memory/" || echo "project-memory/: NOT IN REPO"

echo ""
echo "=== Tier 4: Machine Setup ==="
echo "Secrets: $(ls ~/.claude/secrets/ 2>/dev/null | wc -l | tr -d ' ') files"
echo "cspell words: $(jq '.words | length' ~/.config/cspell/cspell.json 2>/dev/null || echo 0)"
echo "Knowledge base symlinks: $(ls -la ~/.claude/knowledge-base/ 2>/dev/null | grep '^l' | wc -l | tr -d ' ')"
```

Present results as a formatted table.

---

#### Push Mode (Live → Repo)

**Tier 1: Config files**

```bash
# Directories (recursive, preserve structure)
for dir in commands skills agents rules templates hooks instincts references; do
  if [ -d "$LIVE/$dir" ]; then
    mkdir -p "$REPO_CLAUDE/$dir"
    rsync -av --delete --include="*.md" --include="*.sh" --include="*.json" --include="*.txt" --include="*/" --exclude="*" "$LIVE/$dir/" "$REPO_CLAUDE/$dir/"
  fi
done

# Root files (as-is, no templating needed)
for f in CLAUDE.md MEMORY.md lessons.md; do
  cp "$LIVE/$f" "$REPO_CLAUDE/$f" 2>/dev/null
done

# settings.json — template $HOME paths
sed "s|$HOME|{{HOME}}|g" "$LIVE/settings.json" > "$REPO_CLAUDE/settings.json"
jq . "$REPO_CLAUDE/settings.json" > /dev/null 2>&1 || { echo "ERROR: settings.json templating produced invalid JSON"; exit 1; }

# MCP servers — extract, template paths, redact tokens
jq '{mcpServers: (.mcpServers // {} | to_entries | map(
  if .value.env then .value.env |= with_entries(
    if (.key | test("TOKEN|SECRET|PASSWORD|KEY|CREDENTIAL|USERNAME"; "i"))
    then .value = "{{REDACTED}}"
    else . end)
  else . end
) | from_entries)}' ~/.claude.json | sed "s|$HOME|{{HOME}}|g" > "$REPO_CLAUDE/mcp-servers.json"

# cspell dictionary
cp ~/.config/cspell/cspell.json "$REPO_CLAUDE/cspell.json" 2>/dev/null
```

**Tier 2: Scripts & Crons**

```bash
# Scripts directory
if [ -d "$LIVE/scripts" ]; then
  mkdir -p "$REPO_CLAUDE/scripts"
  rsync -av --delete --include="*.sh" --include="*.md" --include="*.html" --include="*.zip" --include="*/" --exclude="*" "$LIVE/scripts/" "$REPO_CLAUDE/scripts/"
fi

# Export crontab with path templating
crontab -l 2>/dev/null | sed "s|$HOME|{{HOME}}|g" > "$REPO_CLAUDE/crontab.txt"
```

**Tier 3: Project Memory**

```bash
mkdir -p "$REPO_CLAUDE/project-memory"
MEMORY_MAP="[]"

for proj_dir in "$LIVE"/projects/*/memory; do
  [ -d "$proj_dir" ] || continue
  count=$(find "$proj_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -gt 0 ] || continue

  encoded=$(basename "$(dirname "$proj_dir")")
  # Strip home-prefix to get workspace-relative path
  # Encoded format: -Users-username-workspace-org-repo
  # Match against actual workspace dirs to resolve correctly
  matched=""
  home_prefix="-$(echo "$HOME" | tr '/' '-' | sed 's/^-//')-workspace-"
  remainder="${encoded#$home_prefix}"

  # Try each workspace org/repo combination
  for ws_dir in "$HOME"/workspace/*/*; do
    [ -d "$ws_dir" ] || continue
    ws_relative="${ws_dir#$HOME/workspace/}"
    test_encoded="-$(echo "$HOME/workspace/$ws_relative" | tr '/' '-' | sed 's/^-//')"
    if [ "$test_encoded" = "$encoded" ]; then
      matched="$ws_relative"
      break
    fi
  done

  if [ -n "$matched" ]; then
    dest="$REPO_CLAUDE/project-memory/$matched"
    mkdir -p "$dest"
    rsync -av --delete --include="*.md" --include="*/" --exclude="*" "$proj_dir/" "$dest/"
    MEMORY_MAP=$(echo "$MEMORY_MAP" | jq --arg rel "$matched" --arg enc "$encoded" --argjson count "$count" \
      '. + [{"workspace_relative": $rel, "source_encoded": $enc, "file_count": $count}]')
  fi
done
```

**Tier 4: Generate sync-manifest.json**

```bash
# Secrets manifest (names + descriptions, never content)
SECRETS_MANIFEST="[]"
for f in $(ls ~/.claude/secrets/ 2>/dev/null); do
  SECRETS_MANIFEST=$(echo "$SECRETS_MANIFEST" | jq --arg name "$f" '. + [{"name": $name}]')
done

# Knowledge base links
KB_LINKS="[]"
if [ -d "$LIVE/knowledge-base" ]; then
  for link in "$LIVE"/knowledge-base/*; do
    [ -L "$link" ] || continue
    name=$(basename "$link")
    target=$(readlink "$link")
    templated=$(echo "$target" | sed "s|$HOME|{{HOME}}|g")
    KB_LINKS=$(echo "$KB_LINKS" | jq --arg name "$name" --arg target "$templated" \
      '. + [{"name": $name, "target_template": $target}]')
  done
fi

# MCP packages
MCP_PACKAGES='[
  {"name": "mcp-local-rag", "install": "npm install -g mcp-local-rag"},
  {"name": "@upstash/context7-mcp", "install": "npx (auto)"},
  {"name": "@playwright/mcp", "install": "npx (auto)"}
]'

# Build manifest
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg hostname "$(hostname)" \
  --arg username "$(whoami)" \
  --arg home "$HOME" \
  --argjson memory "$MEMORY_MAP" \
  --argjson secrets "$SECRETS_MANIFEST" \
  --argjson kb "$KB_LINKS" \
  --argjson mcp "$MCP_PACKAGES" \
  '{
    version: 2,
    last_push: {timestamp: $ts, hostname: $hostname, username: $username, home: $home},
    project_memory_map: $memory,
    secrets_manifest: $secrets,
    knowledge_base_links: $kb,
    mcp_packages: $mcp
  }' > "$REPO_CLAUDE/sync-manifest.json"

echo "Push complete. Run 'git diff --stat' to review changes."
```

After running, show a summary table of what was synced per tier.

---

#### Pull Mode (Repo → Live)

**Read manifest**

```bash
[ -f "$REPO_CLAUDE/sync-manifest.json" ] && echo "Manifest found" || echo "WARNING: No sync-manifest.json — run push on source machine first"
```

**Tier 1: Config files**

```bash
# Directories
for dir in commands skills agents rules templates hooks instincts references; do
  if [ -d "$REPO_CLAUDE/$dir" ]; then
    mkdir -p "$LIVE/$dir"
    rsync -av --include="*.md" --include="*.sh" --include="*.json" --include="*.txt" --include="*/" --exclude="*" "$REPO_CLAUDE/$dir/" "$LIVE/$dir/"
  fi
done

# Root files (as-is)
for f in CLAUDE.md MEMORY.md lessons.md; do
  cp "$REPO_CLAUDE/$f" "$LIVE/$f" 2>/dev/null
done

# settings.json — expand {{HOME}} to local $HOME
sed "s|{{HOME}}|$HOME|g" "$REPO_CLAUDE/settings.json" > "$LIVE/settings.json"
jq . "$LIVE/settings.json" > /dev/null 2>&1 || echo "ERROR: settings.json expansion produced invalid JSON"

# MCP servers — expand paths, skip {{REDACTED}} values, merge into live .claude.json
REPO_MCP=$(sed "s|{{HOME}}|$HOME|g" "$REPO_CLAUDE/mcp-servers.json")
# Filter out REDACTED entries before merging
CLEAN_MCP=$(echo "$REPO_MCP" | jq '.mcpServers | to_entries | map(
  if .value.env then .value.env |= with_entries(select(.value != "{{REDACTED}}"))
  else . end
) | from_entries')
# Merge: repo servers + existing live servers (live wins on conflict for existing keys)
jq --argjson repo "$CLEAN_MCP" '.mcpServers = ($repo + (.mcpServers // {}))' ~/.claude.json > /tmp/claude-json-merged.json
cp /tmp/claude-json-merged.json ~/.claude.json
rm -f /tmp/claude-json-merged.json

# cspell dictionary
if [ -f "$REPO_CLAUDE/cspell.json" ]; then
  mkdir -p ~/.config/cspell
  cp "$REPO_CLAUDE/cspell.json" ~/.config/cspell/cspell.json
fi
```

**Tier 2: Scripts & Crons**

```bash
# Scripts
if [ -d "$REPO_CLAUDE/scripts" ]; then
  mkdir -p "$LIVE/scripts"
  rsync -av --include="*.sh" --include="*.md" --include="*.html" --include="*.zip" --include="*/" --exclude="*" "$REPO_CLAUDE/scripts/" "$LIVE/scripts/"
  chmod +x "$LIVE"/scripts/*.sh 2>/dev/null
fi

# Crontab — show diff and ask before importing
if [ -f "$REPO_CLAUDE/crontab.txt" ]; then
  EXPANDED_CRONTAB=$(sed "s|{{HOME}}|$HOME|g" "$REPO_CLAUDE/crontab.txt")
  echo "=== Crontab diff ==="
  diff <(crontab -l 2>/dev/null) <(echo "$EXPANDED_CRONTAB") || true
  echo ""
  echo "To import: echo the expanded crontab | crontab -"
  echo "Ask the user if they want to import the crontab now."
fi
```

If the user confirms crontab import:
```bash
sed "s|{{HOME}}|$HOME|g" "$REPO_CLAUDE/crontab.txt" | crontab -
echo "Crontab imported."
```

**Tier 3: Project Memory**

```bash
if [ -f "$REPO_CLAUDE/sync-manifest.json" ] && [ -d "$REPO_CLAUDE/project-memory" ]; then
  jq -r '.project_memory_map[] | .workspace_relative' "$REPO_CLAUDE/sync-manifest.json" | while read -r rel_path; do
    # Compute local encoded directory name
    local_encoded="-$(echo "$HOME/workspace/$rel_path" | tr '/' '-' | sed 's/^-//')"
    target_dir="$LIVE/projects/$local_encoded/memory"
    source_dir="$REPO_CLAUDE/project-memory/$rel_path"

    if [ -d "$source_dir" ]; then
      mkdir -p "$target_dir"
      rsync -av --include="*.md" --include="*/" --exclude="*" "$source_dir/" "$target_dir/"
      echo "Memory imported: $rel_path → $local_encoded"
    fi
  done
fi
```

**Show summary** of what was restored. Ask if the user wants to run `setup-knowledge-base.sh` to recreate KB symlinks.

---

#### Bootstrap Mode

First-time setup for a new machine. Runs `pull` first, then:

**1. Secrets directory**

```bash
mkdir -p ~/.claude/secrets
chmod 700 ~/.claude/secrets

if [ -f "$REPO_CLAUDE/sync-manifest.json" ]; then
  echo "=== Required Secrets ==="
  jq -r '.secrets_manifest[] | .name' "$REPO_CLAUDE/sync-manifest.json" | while read -r name; do
    if [ -f "$HOME/.claude/secrets/$name" ]; then
      echo "  ✓ $name (exists)"
    else
      touch "$HOME/.claude/secrets/$name"
      chmod 600 "$HOME/.claude/secrets/$name"
      echo "  ✗ $name (placeholder created — populate manually)"
    fi
  done
fi
```

**2. MCP packages**

```bash
if [ -f "$REPO_CLAUDE/sync-manifest.json" ]; then
  jq -r '.mcp_packages[] | select(.install != "npx (auto)") | "\(.name)|\(.install)"' "$REPO_CLAUDE/sync-manifest.json" | while IFS='|' read -r name install_cmd; do
    if command -v "$name" &>/dev/null; then
      echo "  ✓ $name (installed)"
    else
      echo "  ✗ $name — install with: $install_cmd"
      echo "  Ask user if they want to install now."
    fi
  done
fi
```

**3. Knowledge base**

```bash
if [ -f "$REPO_CLAUDE/sync-manifest.json" ]; then
  mkdir -p ~/.claude/knowledge-base
  jq -r '.knowledge_base_links[] | "\(.name)|\(.target_template)"' "$REPO_CLAUDE/sync-manifest.json" | while IFS='|' read -r name target; do
    expanded=$(echo "$target" | sed "s|{{HOME}}|$HOME|g")
    if [ -e "$expanded" ]; then
      ln -sfn "$expanded" "$HOME/.claude/knowledge-base/$name"
      echo "  ✓ $name → $expanded"
    else
      echo "  ✗ $name → $expanded (target does not exist — clone the repo first)"
    fi
  done
fi
```

**4. Crontab** — offer to import (same as pull mode).

**5. Validation checklist**

```bash
echo "=== Bootstrap Validation ==="
[ -f "$HOME/.claude/settings.json" ] && echo "✓ settings.json" || echo "✗ settings.json"
[ -f "$HOME/.claude.json" ] && echo "✓ .claude.json" || echo "✗ .claude.json"
[ -d "$HOME/.claude/hooks" ] && echo "✓ hooks/" || echo "✗ hooks/"
[ -d "$HOME/.claude/commands" ] && echo "✓ commands/" || echo "✗ commands/"
command -v claude &>/dev/null && echo "✓ claude CLI" || echo "✗ claude CLI (install from https://claude.ai/download)"
```

Show the checklist and flag any items that need manual attention.

---

### Important Rules

- **NEVER sync**: `.credentials.json`, `secrets/` contents, `history.jsonl`, `logs/`, `cache/`, `plugins/`, `sessions/`, `tasks/`, `projects/` (except memory), `pr-reviews/`, `state/`, `telemetry/`, `debug/`, `shell-snapshots/`, `file-history/`, `paste-cache/`
- **MCP config**: Only the `mcpServers` section — never the full `.claude.json`
- **MCP tokens**: Always redact on push, skip redacted values on pull
- **settings.json**: Template all `$HOME` occurrences, validate JSON after
- **Crontab**: Always show diff and ask before importing
- **Memory**: Store with workspace-relative paths, reconstruct encoded dirs on pull
- **Confirm before overwriting**: If a local file is newer than the repo version, warn before overwriting
- **Backup before pull**: Create `~/.claude/backups/sync-$(date +%Y%m%d-%H%M%S)/` with files about to be replaced
