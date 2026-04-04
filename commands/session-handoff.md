# /session-handoff

Captures and preserves important session context for seamless handoff between Claude sessions across any project.

## Usage

```
/session-handoff
```

## Description

This global command intelligently creates or updates a project's CLAUDE.md file to capture the current session's critical context, decisions, and next steps. It ensures seamless handoff between sessions while maintaining token-efficient documentation.

## What it does

1. **Preserves Session Context**: Captures key work, decisions, blockers, and discoveries from the current session
2. **Creates/Updates CLAUDE.md**: Either creates a new CLAUDE.md or updates existing one
3. **Maintains Token Efficiency**: Keeps context concise and actionable
4. **Documents Current State**: Records what was worked on, decisions made, and next steps
5. **Works Universally**: Adapts to any project structure or workflow

## Prompt

Think carefully about the current session's work, then create or update the project's CLAUDE.md file to preserve important context for the next session. Follow these steps:

1. **Check for existing CLAUDE.md** in the current working directory
2. **Analyze current session** to identify:
   - What was worked on
   - Key decisions made
   - Technical details that matter
   - Blockers encountered
   - Next logical steps
3. **Create or update CLAUDE.md** with appropriate structure

If creating new CLAUDE.md, use this template:

```markdown
# CLAUDE.md

> **Project Context** | Updated: [Current Date] | Session: [Main Focus]

## Project Overview

[Brief description of the project based on session work]

## Recent Work ([Current Date])

### Session Summary

[What was accomplished in this session]

### Key Technical Decisions

[Important choices made during the session]

### Implementation Details

[Critical technical details, code patterns, or architecture decisions]

### Current State

- [x] Completed: [List completed items]
- [ ] In Progress: [List ongoing work]
- [ ] Blocked: [List blockers]

### Next Session Priorities

1. [First priority action]
2. [Second priority action]
3. [Additional tasks]

### Important Files/Locations

- [Key file 1]: [Brief description]
- [Key file 2]: [Brief description]
- [Configuration/setup notes]

### Questions/Considerations

- [Open questions for next session]
- [Technical considerations to explore]

---

_Session handoff created: [Current Date and Time]_
```

If updating existing CLAUDE.md:

1. **Preserve existing structure** and important project information
2. **Update or add a "Session Handoff" section** with current date
3. **Keep content concise** - aim for actionable context, not exhaustive documentation
4. **Include**:
   - Current work context (what was being worked on)
   - Key technical decisions made this session
   - Implementation details if critical for continuity
   - Blockers and open questions
   - Specific next steps (as a checklist)
   - Relevant file paths or commands
5. **Remove or archive** outdated session handoff information if it's no longer relevant

Additional guidelines:

- Keep total file size reasonable (under 30k characters)
- Use clear, concise language
- Focus on actionable information for the next session
- Include specific file paths, commands, or code snippets only if essential
- Maintain any project-specific conventions found in existing CLAUDE.md
- If the project uses specific frameworks or tools, mention relevant context
- Include git branch information if relevant
- Note any external dependencies or API keys needed

The goal is to enable any Claude instance (or the same instance in a new session) to quickly understand the project state and continue work effectively.
