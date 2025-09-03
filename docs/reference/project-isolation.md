# Project Isolation in Task Orchestrator

## Status: Implemented
## Last Verified: August 23, 2025
Against version: v2.7.1

## Overview
Task Orchestrator now uses **project-local databases** by default to ensure complete isolation between different projects. This prevents task contamination and maintains project boundaries.

## Database Location

### Default Behavior (v2.7.1+)
- Database location: `./.task-orchestrator/tasks.db` (in current working directory)
- Each project maintains its own separate task database
- No cross-project contamination

### Previous Behavior (v2.7.1 and earlier)
- Database location: `~/.task-orchestrator/tasks.db` (in user home directory)  
- All projects shared the same global database
- Led to task bleeding between projects

## Migration Guide

### For Existing Projects
If you have tasks in the global database that belong to a specific project:

1. **Export tasks from global database:**
   ```bash
   cd /path/to/your/project
   TM_DB_PATH=~/.task-orchestrator ./tm export --format json > my_tasks.json
   ```

2. **Initialize project-local database:**
   ```bash
   ./tm init
   ```

3. **Import tasks (if needed):**
   ```bash
   # Manual import - edit my_tasks.json to keep only relevant tasks
   # Then re-add them using ./tm add commands
   ```

### For New Projects
Simply run `./tm init` in your project directory. A local `.task-orchestrator/` directory will be created.

## Configuration Options

### Environment Variables

- **TM_DB_PATH**: Override database location
  ```bash
  # Use specific path
  export TM_DB_PATH=/custom/path/.task-orchestrator
  
  # Use old global behavior (not recommended)
  export TM_DB_PATH=~/.task-orchestrator
  ```

- **TM_AGENT_ID**: Set specific agent identifier
  ```bash
  export TM_AGENT_ID=my-custom-agent
  ```

## Benefits of Project Isolation

1. **Clean Separation**: Each project's tasks remain completely separate
2. **Version Control**: Project database can be included in `.gitignore` or tracked
3. **Portability**: Project can be moved/cloned with its task history
4. **Testing**: Test tasks don't pollute production projects
5. **Multi-Project**: Work on multiple projects simultaneously without confusion

## Directory Structure

```
your-project/
├── .task-orchestrator/       # Project-local orchestration data
│   ├── tasks.db             # SQLite database with project tasks
│   ├── contexts/            # Shared context files
│   ├── notes/               # Agent private notes
│   ├── archives/            # Archived tasks
│   ├── backups/             # Database backups
│   ├── logs/                # Error and debug logs
│   └── telemetry/           # Usage metrics
├── .claude/
│   └── hooks/               # Claude Code hooks
└── src/                     # Your project source
```

## Best Practices

1. **Add to .gitignore**: Include `.task-orchestrator/` in your `.gitignore`:
   ```gitignore
   # Task Orchestrator local data
   .task-orchestrator/
   ```

2. **Initialize Early**: Run `./tm init` when starting a new project

3. **Regular Backups**: The system auto-creates backups, but consider external backups for critical projects

4. **Clean Separation**: Don't share task databases between projects

## Troubleshooting

### "No tasks found" after update
- You may be looking at a new project-local database
- Check if tasks exist in global database: `TM_DB_PATH=~/.task-orchestrator ./tm list`

### Want to share tasks between projects
- Use the export/import functionality
- Or set `TM_DB_PATH` to a shared location (not recommended)

### Database locked errors
- Ensure only one instance of Task Orchestrator runs per project
- Check for stale lock files in `.task-orchestrator/`

## Version History

- **v2.7.1**: Switched to project-local databases by default
- **v2.7.1**: Last version using global database
- **v2.7.1**: Initial multi-agent coordination support