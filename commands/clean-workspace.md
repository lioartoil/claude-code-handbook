# /clean-workspace

A general-purpose command to identify and clean up irrelevant files in any project workspace, including temporary files, backups, and other clutter.

## Usage

```
/clean-workspace
```

## Description

This command helps maintain a clean workspace by identifying and removing common types of irrelevant files that accumulate during development. It works across any project type and respects version control systems.

## What it does

1. **Scans for Common Clutter**: Identifies typical temporary and backup files
2. **Respects Version Control**: Checks git/svn/hg status before suggesting deletions
3. **Project-Aware**: Recognizes common project patterns and build artifacts
4. **Safe Cleanup**: Always asks for confirmation before removing files
5. **Provides Summary**: Reports what was cleaned and space recovered

## Prompt

Analyze the current workspace for irrelevant files that can be safely cleaned up. Follow these steps:

1. **Identify Version Control System**:

   ```bash
   # Check for .git, .svn, .hg directories
   # Use appropriate commands (git status, svn status, etc.)
   ```

2. **Scan for Common Irrelevant Files**:

   **Temporary Files**:
   - Editor backups: `*~`, `*.swp`, `*.swo`, `.#*`
   - OS files: `.DS_Store`, `Thumbs.db`, `desktop.ini`
   - Temp files: `*.tmp`, `*.temp`, `*.bak`, `*.backup`
   - Log files: `*.log` (check if needed first)

   **Build Artifacts** (if not in version control):
   - `dist/`, `build/`, `out/`, `target/`
   - `*.pyc`, `__pycache__/`, `*.pyo`
   - `.class` files outside of intended locations
   - Coverage reports: `coverage/`, `*.coverage`, `htmlcov/`

   **Package Manager Artifacts**:
   - `node_modules/` (if not in active use)
   - `.npm/`, `.yarn/`, `.pnpm-store/`
   - `vendor/` (check if needed)
   - Virtual environments: `venv/`, `env/`, `.env/`

   **IDE/Editor Files**:
   - `.idea/` (if not shared)
   - `.vscode/` (check team preferences)
   - `*.iml`, `.project`, `.classpath`

3. **Analyze Each Category**:

   ```markdown
   ## Workspace Cleanup Analysis

   ### Temporary Files (X MB)

   - Safe to remove: [list files]
   - Check first: [list files that might be important]

   ### Build Artifacts (X MB)

   - Can rebuild: [list directories]
   - Might need: [list files to verify]

   ### Large Files Not in Version Control

   - [List files over 10MB not tracked]
   ```

4. **Check for Duplicates**:
   - Files with `(1)`, `(2)`, `copy`, `Copy` in names
   - Multiple versions: `file.v1`, `file.old`, `file.backup`
   - Similar names in same directory

5. **Present Cleanup Plan**:

   ```markdown
   ## Cleanup Summary

   **Total Space to Recover**: X MB

   ### Safe to Delete (X files, X MB)

   - [ ] Temporary files: X files
   - [ ] OS-generated files: X files
   - [ ] Editor backups: X files

   ### Requires Confirmation (X files, X MB)

   - [ ] Build artifacts (can be regenerated)
   - [ ] Large untracked files
   - [ ] Possible duplicates

   ### Recommendations

   - Add X patterns to .gitignore
   - Consider archiving X old files
   - Move X files to proper locations
   ```

6. **Execute Cleanup**:
   - Group deletions by type
   - Use appropriate commands for each OS
   - Provide undo instructions if possible
   - Update .gitignore if patterns found

## Safety Guidelines

- **NEVER delete without confirmation**:
  - Source code files
  - Configuration files
  - Documentation
  - Anything in version control
  - Files modified today

- **ALWAYS preserve**:
  - Active virtual environments
  - Running application files
  - Database files
  - Credentials and secrets

- **BE CAUTIOUS with**:
  - Log files (might be needed for debugging)
  - Cache directories (might slow next run)
  - Build outputs (check build time)

## Cross-Platform Considerations

Detect the operating system and use appropriate commands:

- **Unix/Linux/macOS**: Use `find`, `du`, `rm`
- **Windows**: Use `dir`, `del`, PowerShell commands
- **Version Control**: Prefer VCS commands when applicable

## Example Usage Scenario

```markdown
## Workspace Cleanup Results

Analyzed 1,234 files in current workspace.

### Cleanup Summary

- **15 temporary files** (2.3 MB) - Editor backups and OS files
- **3 build directories** (156 MB) - Can be regenerated
- **8 duplicate files** (5.1 MB) - Copies and old versions
- **1 large log file** (89 MB) - Over 30 days old

**Total recoverable space: 252.4 MB**

### Safe to Delete Now

✓ 15 editor backup files (_~, _.swp)
✓ 3 .DS_Store files
✓ 5 \*.pyc files not in **pycache**

### Requires Your Confirmation

? /build directory (can run 'npm build' to regenerate)
? /old-backup-2024 directory (appears to be old backup)
? debug.log (89 MB, last modified 45 days ago)

Would you like me to:

1. Delete the safe files only
2. Delete safe files and confirmed items
3. Show more details about specific files
4. Cancel cleanup

Please choose an option (1-4):
```

Remember: The goal is to help maintain a clean workspace while ensuring no important files are accidentally removed. When unsure, always err on the side of caution.
