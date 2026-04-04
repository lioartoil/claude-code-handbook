# /promote-env

Execute the comprehensive environment promotion pull request workflow.

## Usage

```
/promote-env [source-branch] [target-branch]
```

**Examples**:

- `/promote-env` - Defaults to develop → sit
- `/promote-env develop sit` - Explicit DEV to SIT
- `/promote-env sit uat` - SIT to UAT promotion
- `/promote-env hotfix/critical prod` - Emergency hotfix

## Workflow Reference

This command executes the comprehensive environment promotion workflow documented in:
`prompts/environment-promotion-pr.md`

## Execution Steps

I will automatically:

1. **Validate** current repository and branches
2. **Analyze** commits and changes between environments
3. **Create** comprehensive promotion PR with:
   - Categorized commit list
   - Related PRs included
   - Testing requirements
   - Deployment notes
   - Rollback plan
4. **Report** PR status and next steps

## Parameters

- **source-branch**: Source environment branch (default: develop)
- **target-branch**: Target environment branch (default: sit)

## Common Promotion Paths

| Command                         | Description                |
| ------------------------------- | -------------------------- |
| `/promote-env develop sit`      | DEV → SIT (standard)       |
| `/promote-env sit uat`          | SIT → UAT (pre-production) |
| `/promote-env uat prod`         | UAT → PROD (release)       |
| `/promote-env hotfix/name prod` | Emergency hotfix           |

## Requirements

- Current directory must be a git repository
- `gh` CLI must be installed and authenticated
- Both source and target branches must exist on remote

## Output

You will receive:

- ✅ PR creation confirmation
- 📊 Commit and file change summary
- 🔗 Direct PR URL
- 🎯 CI status and next steps

---

Think carefully, then execute the environment promotion pull request workflow from `prompts/environment-promotion-pr.md` with the provided parameters (or defaults if not specified).

Follow all phases:

- Phase 1: Validation
- Phase 2: Analysis
- Phase 3: PR Creation
- Phase 4: Post-Creation
- Phase 5: Error Handling

Provide clear, structured output with the PR URL and next steps.
