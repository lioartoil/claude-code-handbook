---
paths:
  - '**/*.go'
---

# Go Conventions (Backend / BFF)

- **Function length**: max 50 lines per function body (count actual lines, do not estimate)
- **File size**: max 400 lines (warning at 300)
- **Package name**: max 10 characters, lowercase, no underscores
- **Package alias**: max 10 characters when importing
- **Import grouping**: stdlib | external | internal (separated by blank lines)
- **Error wrapping**: use `fmt.Errorf("context: %w", err)` — never discard errors silently
- **Magic values**: extract string/number literals to named constants
- **Naming**: exported = PascalCase, unexported = camelCase; max 5 words / 20 chars
- **Interface naming**: `Reader`, `Writer`, `Handler` — no `I` prefix
- **Test co-location**: `_test.go` files in same package
- **Cyclomatic complexity**: max 15 per function
- **Nesting depth**: max 3 levels
