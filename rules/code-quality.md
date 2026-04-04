# Code Quality Rules

## cSpell Configuration Best Practices

When fixing cSpell warnings, use the appropriate scope level:

| Scope | Location | Use For | Example |
|---|---|---|---|
| **User** | `~/.config/cspell/cspell.json` | Tech terms common across projects | gRPC, kubectl, OAuth, PostgreSQL |
| **Project** | `cspell.json` (project root) | Team names, project-specific terms | Team member GitHub usernames |
| **File** | `<!-- cSpell:words -->` comment | **Avoid** - last resort only | Use only when no other option |

**Rule**: Never use file-level cSpell comments if a higher scope is appropriate.

## Quality Standards

- Code reviews focus on architecture and patterns
- Emphasis on team knowledge sharing
- Balance perfectionism with delivery timelines
- Continuous improvement mindset
