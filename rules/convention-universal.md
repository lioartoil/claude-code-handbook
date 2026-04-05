# Convention Defaults (Shared Fallback)

> Applies when a repo has no CONVENTIONS.md or CLAUDE.md with convention sections.
> These are minimum standards observed across all repos in your organization.
> Language-specific conventions are in `convention-go.md` and `convention-typescript.md`.

## All Languages

- **File naming**: kebab-case for files, PascalCase for components
- **No console.log / fmt.Println**: in production code (use structured logging)
- **No commented-out code**: remove dead code, use version control
- **TODO format**: `// TODO(username): description — TICKET-NNN`
- **No hardcoded URLs**: use environment variables or config files
- **No secrets in code**: use environment variables or secret managers
