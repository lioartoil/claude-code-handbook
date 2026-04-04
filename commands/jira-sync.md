# /jira-sync

You are a technical project coordinator synchronizing JIRA ticket data into structured local documentation for sprint planning and team reference.

## Before Syncing

Think through before executing:

1. **Does the target directory already exist?** Don't overwrite human-authored content.
2. **Is this a re-sync or first sync?** If files exist, preserve custom sections.
3. **What level of detail is appropriate?** Epic = directory tree; Bug = single file.

Sync JIRA tickets to local documentation structure.

## Usage

```
/jira-sync <ticket-id>              # Single ticket
/jira-sync <project> sprint:<num>   # All tickets in sprint
/jira-sync <project> jql:<query>    # Custom JQL query
```

## Examples

```
/jira-sync PROJ-794                          # Single ticket
/jira-sync PROJ sprint:3                     # All tickets in Sprint 3
/jira-sync PROJ sprint:25.12                 # All tickets in Sprint 25.12
/jira-sync PROJ jql:"assignee = currentUser()" # Custom query
```

## Instructions

### 1. Parse Arguments

- Single ticket: Direct ticket ID (e.g., PROJ-794)
- Sprint search: `<project> sprint:<number>`
- JQL search: `<project> jql:<query>`

### 2. Fetch JIRA Data

For single ticket:
```bash
jira view <ticket-id> -t debug
```

For sprint search:
```bash
jira list --query 'project = <project> AND sprint = "<project> Sprint <number>"'
```

For JQL search:
```bash
jira list --query '<custom-jql>'
```

### 3. Extract Key Information

From debug output, extract:
- **Core fields**: summary, description, status, priority, issuetype
- **Dates**: created, updated, duedate
- **People**: reporter, assignee
- **Agile**: sprint info, story points
- **Custom fields**: Look for patterns like:
  - Acceptance Criteria
  - Definition of Done
  - Business Value
  - Technical Requirements
- **Comments**: Questions, clarifications, decisions

### 4. Determine Directory Structure

```
<project-root>/
├── docs/
│   └── jira/
│       └── <ticket-id>/
│           ├── README.md
│           ├── requirements.md
│           ├── technical-design.md
│           └── notes.md
├── user-stories/        # If exists, use this instead
│   └── <sprint>/
│       └── <ticket-id>-<title>/
```

### 5. Generate Documentation

#### README.md Structure

```markdown
# [STATUS] <ticket-id>: <summary>

> **Status**: <status> | **Priority**: <priority> | **Sprint**: <sprint>
> **Reporter**: <reporter> | **Created**: <date>

## Description

<description from JIRA>

## Acceptance Criteria

<from custom field or comments>

## Definition of Done

<from custom field or standard template>

## Technical Notes

<extracted from comments or empty for filling>

## Questions/Blockers

<from comments or identified gaps>

## Updates

<comment history summary>
```

### 6. Handle Special Cases

- **Epics**: Create subdirectory for child stories
- **Subtasks**: Nest under parent story
- **Linked Issues**: Note relationships
- **Attachments**: List with descriptions

### 7. Smart Updates

If files exist:
- Preserve sections marked with `<!-- CUSTOM -->` 
- Update JIRA-sourced sections
- Add new fields if found
- Note last sync timestamp

### 8. Output Summary

```
Synced: PROJ-794 ✓
  Created: README.md, requirements.md
  Updated: technical-design.md
  Preserved: custom-notes.md
```

## Configuration Detection

Check for project-specific patterns:
- `.jira-sync.json` for field mappings
- Existing directory structures
- Project type indicators (user-stories/, docs/, etc.)

## Error Handling

- No JIRA access: "Check JIRA authentication with 'jira login'"
- Ticket not found: "Ticket XXX-NNN not found"
- No permission: "No access to ticket XXX-NNN"
- Parse errors: Show raw field, ask for manual review

## Advanced Features

### Custom Field Mapping

If `.jira-sync.json` exists:
```json
{
  "fieldMappings": {
    "customfield_12362": "acceptanceCriteria",
    "customfield_12428": "definitionOfDone"
  },
  "directories": {
    "stories": "user-stories/sp{sprint}-implementation",
    "docs": "docs/jira/{ticket}"
  }
}
```

### Sprint Detection

- Extract from customfield sprint data
- Parse sprint number from name
- Handle multiple sprint formats

### Auto-categorization

Based on:
- Issue type (Story, Bug, Task)
- Labels (frontend, backend, etc.)
- Component (UI, API, etc.)

## Best Practices

1. Always use debug mode for complete data
2. Preserve human-added content
3. Track sync metadata
4. Handle field variations gracefully
5. Provide clear sync status output