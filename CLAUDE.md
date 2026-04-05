# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **personal engineering handbook** — a curated collection of Claude Code commands, skills, hooks, rules, and templates extracted from real engineering sessions. It is a reference/documentation repository, not an application. There is no build system, no test suite, and no application code.

## Repository Structure

```
commands/     Slash commands — workflows invoked via /command-name
skills/       Auto-activated skills — context-aware behaviors with reference materials
hooks/        Pre/post tool hooks — shell scripts for guardrails and automation
rules/        Auto-loaded rules — always-on constraints (copied to ~/.claude/rules/)
templates/    CLAUDE.md templates for bootstrapping new projects
```

**How they relate:** Rules are always-on constraints. Commands are user-invoked workflows. Skills auto-activate when context matches (e.g., PR review context triggers `pr-review`). Hooks intercept tool calls at the shell level. Templates are standalone starter files for other repos.

## File Formats

### Commands (`commands/*.md`)

Plain markdown. No frontmatter. The filename becomes the slash command name (e.g., `systematic-debugging.md` → `/systematic-debugging`). Dynamic content uses `` `!command` `` syntax to execute shell commands and inline the output.

### Skills (`skills/<name>/SKILL.md`)

YAML frontmatter followed by markdown body:

```yaml
---
name: skill-name
description: >
  When this skill auto-activates (used by Claude for context matching)
context: fork | default
allowed-tools: [Tool1, Tool2]
argument-hint: <required> [optional]
---
```

Each skill may have a `references/` subdirectory with supporting materials (checklists, templates, code patterns) that the skill prompt references.

### Hooks (`hooks/*.sh`, `hooks/*.mjs`)

Executable scripts registered in `~/.claude/settings.json`. Follow the Claude Code hook protocol: exit 0 to allow, exit 2 to block (with reason on stdout). The `.mjs` hook (`dedup-hook.mjs`) uses the `@anthropic-ai/claude-code` SDK.

### Rules (`rules/*.md`)

Plain markdown. No frontmatter. Auto-loaded into every Claude Code session when placed in `~/.claude/rules/`.

## Authoring Conventions

- Commands and rules are self-contained single files
- Skills are directories: `skills/<name>/SKILL.md` with optional `references/` subdirectory
- Hook scripts must be executable (`chmod +x`)
- Use placeholder values (`your-org`, `your-app`, `your-core-lib`, `PROJ-123`, `your-company.atlassian.net`) for org-specific references — users replace these during setup
- Private/personal commands (daily-log, weekly-review, quarterly-review, sprint-status) use restricted file permissions

## Compact Instructions

When compacting, always preserve:

- Which files were modified and the specific changes made
- The current task and remaining steps
- Any decisions made about skill frontmatter, hook configuration, or rule scoping
- Active issues being worked on (issue number and title)

## Validating Changes

No build or test commands exist. To validate:

1. **Syntax**: Ensure markdown renders correctly and YAML frontmatter parses (skills)
2. **Integration**: Copy/symlink the file to `~/.claude/` and invoke it in a Claude Code session
3. **Hooks**: Test with `echo '{"tool_name":"Bash","tool_input":{"command":"test"}}' | ./hooks/your-hook.sh`
