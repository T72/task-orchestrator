# Task Orchestrator - Collaboration Commands Setup

## ⚠️ Important Note

The collaboration commands (`share`, `note`, `discover`, `sync`, `context`, `join`) are **NOT** included in the base `tm` script. They require the enhanced version.

## 🚀 Quick Setup

### Option 1: Use Enhanced Version (Recommended)

```bash
# Use tm_enhanced.py instead of tm
./tm_enhanced.py join task_123
./tm_enhanced.py share task_123 "Progress update"
./tm_enhanced.py note task_123 "Private thought"
```

### Option 2: Replace Base with Enhanced

```bash
# Backup original
cp tm tm_original.py

# Replace with enhanced version
cp tm_enhanced.py tm
chmod +x tm

# Now collaboration commands work
./tm join task_123
./tm share task_123 "Update for team"
```

### Option 3: Create Alias

```bash
# Add to your ~/.bashrc or ~/.zshrc
alias tm="/path/to/task-orchestrator/tm_enhanced.py"

# Now use normally
tm join task_123
tm share task_123 "Status update"
```

## 📋 Available Collaboration Commands

| Command | Syntax | Purpose | Visibility |
|---------|--------|---------|------------|
| `join` | `tm join <task_id>` | Join task collaboration | Creates context |
| `share` | `tm share <task_id> <message>` | Share with team | All agents |
| `note` | `tm note <task_id> <message>` | Private note | Only you |
| `discover` | `tm discover <task_id> <message>` | Critical finding | All (priority) |
| `sync` | `tm sync <task_id> <message>` | Sync point | All agents |
| `context` | `tm context <task_id>` | View all updates | Read-only |

## 🔧 Installation for Projects

When deploying to a project, include the enhanced version:

```bash
# Deploy with collaboration features
cp tm_enhanced.py /your/project/tm
cp -r src/ /your/project/.task-orchestrator/
chmod +x /your/project/tm

# Initialize
cd /your/project
./tm init
```

## 📁 File Structure

When using collaboration commands, these directories are created:

```
.task-orchestrator/
├── tasks.db                    # Task database
├── contexts/                    # Shared team updates
│   ├── context_task123_agent1.md
│   ├── context_task123_agent2.md
│   └── shared_task123.md       # All agents' shared updates
├── notes/                       # Private notes
│   └── notes_task123_agent1.md # Only agent1 sees this
└── archives/                    # Completed task archives
```

## 🎯 Usage Examples

### Example 1: Agent Joins and Works

```bash
# Set agent identity
export TM_AGENT_ID="backend_developer"

# Join task
./tm join task_abc123

# Add private thoughts
./tm note task_abc123 "Need to research JWT libraries"

# Share progress
./tm share task_abc123 "API endpoints complete: /auth/login, /auth/refresh"

# Critical discovery
./tm discover task_abc123 "Security issue: Need rate limiting on login"

# View all context
./tm context task_abc123
```

### Example 2: Orchestrator Monitoring

```bash
export TM_AGENT_ID="orchestrator"

# Create sync point
./tm sync project_001 "Milestone 1: All teams report status"

# Monitor specific task
./tm context task_abc123

# Share project-wide update
./tm share project_001 "Week 1 complete: On track for delivery"
```

## 🐛 Troubleshooting

### "Command not found" Error

If you get errors like:
```
Error: Unknown command 'share'
```

You're using the base `tm` instead of `tm_enhanced.py`. Switch to the enhanced version.

### Missing Collaboration Module

If you see:
```
Warning: Collaboration module not found
```

Ensure the `src/tm_collaboration.py` file is in the correct location:
```bash
# Check file exists
ls -la src/tm_collaboration.py

# Or copy it
mkdir -p src
cp /path/to/tm_collaboration.py src/
```

### Permission Denied

```bash
# Make scripts executable
chmod +x tm_enhanced.py
chmod +x src/tm_collaboration.py
```

## 🔄 Migration from Base to Enhanced

If you've been using the base `tm` and want collaboration features:

1. **Keep existing data** - The database remains compatible
2. **Add enhanced script** - Copy `tm_enhanced.py` to your project
3. **Add collaboration module** - Copy `src/tm_collaboration.py`
4. **Start using** - All existing commands work, plus new ones

```bash
# Your existing commands still work
./tm_enhanced.py add "New task"
./tm_enhanced.py list

# Plus new collaboration commands
./tm_enhanced.py join task_123
./tm_enhanced.py share task_123 "Now with collaboration!"
```

## 📚 Why Separate Implementation?

The collaboration features are implemented separately to:
1. **Maintain backward compatibility** - Base `tm` remains simple
2. **Optional complexity** - Not all projects need collaboration
3. **Modular design** - Easy to extend without breaking core
4. **Gradual adoption** - Teams can migrate when ready

## 🚀 Next Steps

1. Install the enhanced version in your project
2. Set your `TM_AGENT_ID` environment variable
3. Start using collaboration commands
4. Check the [Orchestrator Guide](ORCHESTRATOR-GUIDE.md) for workflow examples

---

**Note**: The documentation has been updated to reflect that collaboration commands require the enhanced version. Make sure your team knows to use `tm_enhanced.py` or properly set up the enhanced version as their main `tm` command.