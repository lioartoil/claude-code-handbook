# Agents

Custom subagents for Claude Code. Agents are autonomous workers with restricted tool access.

## What Are Agents?

Agents are markdown files with YAML frontmatter that define specialized subagents. They are invoked via the `Agent` tool with `subagent_type` matching the agent's `name` field.

## Agent Format

```yaml
---
name: my-agent            # Unique identifier, used as subagent_type
description: What it does # Shown in agent selection
tools: Read, Grep, Bash   # Allowed tools (comma-separated)
disallowedTools: Write     # Explicitly blocked tools
model: inherit             # inherit from parent, or specify model
skills:                    # Auto-load these skills into agent context
  - pr-review
memory: user               # Access user memory (optional)
---

System prompt for the agent goes here.
```

## Key Design Principles

1. **Least privilege** — Only grant tools the agent needs. Use `disallowedTools` to explicitly block dangerous tools.
2. **Read-only by default** — Review and analysis agents should never have Write/Edit access.
3. **Skill binding** — Pre-load domain knowledge via the `skills:` field instead of repeating it in the prompt.
4. **Structured output** — Define the exact output format so the parent can parse results.

## Included Agents

| Agent | Purpose | Tools | Skills |
|-------|---------|-------|--------|
| `code-reviewer` | PR review specialist | Read, Grep, Glob, Bash | pr-review |
| `sprint-planner` | Sprint coordination | Read, Grep, Glob, Bash | — |

## Installation

Copy the agent `.md` files to `~/.claude/agents/` (global) or `.claude/agents/` (project-level).

## Usage

```
# From a slash command or skill
Agent(subagent_type="code-reviewer", prompt="Review PR #123 in repo org/app")

# Multiple agents in parallel (for /orchestrate-review)
Agent(subagent_type="code-reviewer", prompt="Review security aspects...")
Agent(subagent_type="code-reviewer", prompt="Review performance aspects...")
```
