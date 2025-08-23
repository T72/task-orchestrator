# Migration Guide: v2.3 to v2.4 - Project Isolation

## Status: Guide
## Last Verified: August 23, 2025
Against version: v2.6.0

## Overview
Version 2.4 changes the default database location from global (`~/.task-orchestrator`) to project-local (`./.task-orchestrator`). This guide ensures smooth migration without disrupting existing work.

## Key Change
- **v2.3 and earlier**: Global database at `~/.task-orchestrator/tasks.db`
- **v2.4+**: Project-local database at `./.task-orchestrator/tasks.db`
- **Compatibility**: Full backward compatibility via `TM_DB_PATH` environment variable

## Migration Scenarios

### Scenario 1: Keep Using Global Database (No Changes Needed)

**For projects actively using the global database (like RoleScoutPro):**

```bash
# Option A: Set globally in your shell profile
echo 'export TM_DB_PATH=~/.task-orchestrator' >> ~/.bashrc
source ~/.bashrc

# Option B: Set per-project using direnv
echo 'export TM_DB_PATH=~/.task-orchestrator' >> .envrc
direnv allow

# Option C: Set per-session
export TM_DB_PATH=~/.task-orchestrator
```

**Result**: Everything continues working exactly as before.

### Scenario 2: Migrate Specific Project to Local Database

**When ready to migrate a project:**

1. Export existing tasks (optional):
```bash
# Save current tasks
TM_DB_PATH=~/.task-orchestrator tm export --format json > tasks_backup.json
```

2. Switch to project-local:
```bash
# Remove the environment variable for this project
unset TM_DB_PATH

# Initialize local database
tm init

# Verify using local database
tm list  # Should be empty or show only project tasks
```

3. Import relevant tasks (optional):
```bash
# Manually review tasks_backup.json and re-add relevant ones
tm add "Migrated task 1"
tm add "Migrated task 2"
```

### Scenario 3: New Projects (Automatic Isolation)

**New projects automatically use project-local databases:**

```bash
cd /path/to/new/project
tm init  # Creates ./.task-orchestrator/
tm add "First task"  # Stored locally
```

## Quick Decision Tree

```
Are you actively using Task Orchestrator in this project?
├─ YES: Do you need the existing tasks?
│   ├─ YES: Set TM_DB_PATH=~/.task-orchestrator
│   └─ NO: Use new project-local database
└─ NO: Use new project-local database (default)
```

## Environment Variable Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `TM_DB_PATH` | Override database location | `~/.task-orchestrator` or `/custom/path` |
| `TM_AGENT_ID` | Set specific agent ID | `my-agent` |
| `TM_TEST_MODE` | Legacy test mode flag | `1` (deprecated, use TM_DB_PATH) |

## Verification Commands

```bash
# Check which database you're using
python3 -c "
import os
from pathlib import Path
db_path = Path(os.environ.get('TM_DB_PATH', './.task-orchestrator'))
print(f'Using database at: {db_path.resolve()}')
"

# Count tasks in global database
TM_DB_PATH=~/.task-orchestrator tm list | wc -l

# Count tasks in local database  
unset TM_DB_PATH && tm list | wc -l
```

## Best Practices

### For Active Development Projects
1. **Don't migrate mid-sprint** - Wait for a natural break
2. **Export tasks first** - Always backup before migration
3. **Communicate with team** - Ensure everyone knows about the change
4. **Use environment files** - `.envrc` or `.env` for project-specific settings

### For New Projects
1. **Start fresh** - Let project use local database by default
2. **Add to .gitignore** - Include `.task-orchestrator/` 
3. **Document choice** - Note in README if using non-default settings

### For CI/CD
```yaml
# GitHub Actions example
env:
  TM_DB_PATH: ./.task-orchestrator  # Ensure isolation in CI
```

## Rollback Plan

If you need to revert to v2.3 behavior globally:

```bash
# Add to ~/.bashrc or ~/.zshrc
export TM_DB_PATH=~/.task-orchestrator

# This makes v2.4+ behave exactly like v2.3
```

## FAQ

**Q: Will I lose my tasks when upgrading?**
A: No. Set `TM_DB_PATH=~/.task-orchestrator` to keep using the global database.

**Q: Can I share tasks between projects?**
A: Yes. Point multiple projects to the same `TM_DB_PATH`.

**Q: What happens if I don't set TM_DB_PATH?**
A: v2.4+ uses project-local database (`./.task-orchestrator/`).

**Q: Can I migrate gradually?**
A: Yes. Each project can migrate independently when ready.

## Support

For issues or questions:
1. Check existing tasks: `TM_DB_PATH=~/.task-orchestrator tm list`
2. Verify configuration: `echo $TM_DB_PATH`
3. Review this guide
4. Open an issue if needed