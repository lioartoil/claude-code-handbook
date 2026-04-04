# Skill Creator

Guide the creation of a new Claude Code skill or command.

Skill purpose: $ARGUMENTS

---

## Skill vs Command Decision

| Type | Location | Invocation | Best For |
|------|----------|-----------|----------|
| **Command** | `.claude/commands/*.md` | `/command-name` | User-triggered workflows, one-off tasks |
| **Skill** | `~/.claude/skills/*/SKILL.md` | Auto-activated by context | Reference material, always-available knowledge |

**Rule of thumb:** If the user needs to explicitly trigger it → Command. If it should always be available → Skill.

### Description Formula (from Anthropic Guide)

```
[What it does] + [When to use it] + [Key capabilities]
```

**Example**: "Comprehensive PR code review with subagent isolation. Use when reviewing pull requests, analyzing code changes, or conducting follow-up reviews."

### Negative Triggers

Add to SKILL.md frontmatter when needed to prevent false activation:

```yaml
negative-triggers:
  - "don't review"
  - "skip review"
```

---

## Command Structure (`.claude/commands/*.md`)

```markdown
# Command Title

Brief description of what this command does.

Input: $ARGUMENTS

---

## Workflow

1. Step 1
2. Step 2
3. Step 3

## Output Format

- Expected output structure
```

### Our Conventions
- Use `$ARGUMENTS` for user input
- Support options: `--dry-run`, `--debug`, etc.
- Include a `---` separator between header and body
- Keep under 200 lines (respect context window)
- Use imperative voice for instructions

---

## Skill Structure (`~/.claude/skills/*/SKILL.md`)

```yaml
---
name: skill-name
description: One-line description (shown in metadata, always loaded)
---
```

```markdown
# Skill Body

Instructions loaded when skill activates.

## When to Apply

Describe trigger conditions.

## Core Knowledge

The essential reference material.
```

### Progressive Disclosure (3 Levels)

| Level | What | When Loaded | Size Target |
|-------|------|-------------|-------------|
| 1. Metadata | `name` + `description` in frontmatter | Always | 1-2 lines |
| 2. SKILL.md body | Core instructions | When skill triggers | < 500 lines |
| 3. Bundled resources | `references/`, `scripts/`, `assets/` | On demand | Unlimited |

**Key:** SKILL.md body should be concise. Move detailed reference material to `references/` subdirectory.

### Optional Directories

```
~/.claude/skills/my-skill/
  SKILL.md              # Required — frontmatter + instructions
  references/           # Optional — detailed docs loaded on demand
    api-reference.md
    examples.md
  scripts/              # Optional — executable code for deterministic tasks
    validate.sh
  assets/               # Optional — templates, boilerplate
    template.go
```

---

## Scope Decision (Global vs Project)

| Scope | Location | Use When |
|-------|----------|----------|
| **Global** | `~/.claude/commands/` or `~/.claude/skills/` | Useful across all projects |
| **Project** | `.claude/commands/` or `.claude/skills/` | Specific to this repository |

---

## Creation Workflow

1. **Define purpose** — what problem does this skill/command solve?
2. **Choose type** — command vs skill (see decision table above)
3. **Choose scope** — global vs project
4. **Write the file** — follow the structure templates above
5. **Test** — invoke the command or trigger the skill
6. **Iterate** — refine based on real usage

## Process

1. Based on the purpose in $ARGUMENTS, determine the right type and scope
2. Draft the command/skill content
3. Create the file in the appropriate location
4. Test with a sample invocation
