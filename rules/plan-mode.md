# Plan Mode — Always On

> Personal workflow rule. Applies to all projects.

## Rule

Plan mode is the mandatory default state for every session. Never skip it, never forget to return to it.

## Lifecycle

1. **Session start**: Enter plan mode immediately
2. **Research / quick questions**: Stay in plan mode, answer inline without exiting
3. **Before any changes**: Write the plan to the plan file, call ExitPlanMode for approval
4. **Execute**: Implement the approved plan
5. **After execution completes**: Call `EnterPlanMode` before the final response — **NON-NEGOTIABLE**, even for single-file fixes

## Rules

- Only exit plan mode while actively implementing an already-approved plan
- Applies to ALL file types: code, docs, config, .gitignore, migrations, everything
- Never conflate "low risk" with "doesn't need approval"
