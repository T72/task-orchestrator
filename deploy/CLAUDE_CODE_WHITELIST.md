# Task Orchestrator - Claude Code Whitelist Commands

**INTERNAL DOCUMENTATION - For Integration with Claude Code Projects**

## 🔧 Whitelist Configuration

To enable seamless Task Orchestrator operation without confirmation prompts, add these commands to your Claude Code project's whitelist configuration.

### How to Apply Whitelist

Add these commands to your project's Claude Code configuration file or settings:

```bash
# Location: Your project's .claude/config.json or settings
# Add to "whitelisted_commands" array
```

## 📋 Complete Task Orchestrator Whitelist

### Core Task Management Commands
```bash
# Database Operations
./tm init

# Task Creation
./tm add *
./tm add "*"
./tm add "*" -d "*"
./tm add "*" -p *
./tm add "*" --depends-on *
./tm add "*" --file *
./tm add "*" --file *:*
./tm add "*" --file *:*:*

# Task Information
./tm list
./tm list --status *
./tm list --assignee *
./tm list --has-deps
./tm show *

# Task Updates
./tm update * --status *
./tm update * --assignee *
./tm complete *
./tm complete * --impact-review
./tm assign * *
./tm delete *

# Export Operations
./tm export
./tm export --format json
./tm export --format markdown
```

### Multi-Agent Collaboration Commands
```bash
# Collaboration
./tm join *
./tm share * "*"
./tm note * "*"
./tm discover * "*"
./tm sync * "*"
./tm context *

# Notifications
./tm watch
```

### Environment and Testing
```bash
# Environment Variables (these are set, not executed)
export TM_AGENT_ID=*
export TM_DB_PATH=*
export TM_WSL_MODE=*
```

## 📝 Complete Whitelist for Copy-Paste

Here's the complete whitelist in a format ready for your Claude Code configuration:

```json
{
  "whitelisted_commands": [
    "./tm init",
    "./tm add *",
    "./tm list",
    "./tm list --status *",
    "./tm list --assignee *",
    "./tm list --has-deps",
    "./tm show *",
    "./tm update * --status *",
    "./tm update * --assignee *",
    "./tm complete *",
    "./tm complete * --impact-review",
    "./tm assign * *",
    "./tm delete *",
    "./tm export",
    "./tm export --format json",
    "./tm export --format markdown",
    "./tm join *",
    "./tm share * \"*\"",
    "./tm note * \"*\"",
    "./tm discover * \"*\"",
    "./tm sync * \"*\"",
    "./tm context *",
    "./tm watch"
  ]
}
```

## 🎯 Advanced Whitelist (Comprehensive)

For maximum flexibility, use these patterns that cover all parameter combinations:

```json
{
  "whitelisted_commands": [
    "./tm *",
    "*/tm init",
    "*/tm add *",
    "*/tm list*",
    "*/tm show *",
    "*/tm update *",
    "*/tm complete *",
    "*/tm assign *",
    "*/tm delete *",
    "*/tm export*",
    "*/tm join *",
    "*/tm share *",
    "*/tm note *",
    "*/tm discover *",
    "*/tm sync *",
    "*/tm context *",
    "*/tm watch*"
  ]
}
```

## 🔒 Security-Focused Whitelist (Recommended)

For security-conscious environments, use this more restrictive but still functional whitelist:

```json
{
  "whitelisted_commands": [
    "./tm init",
    "./tm add \"*\"",
    "./tm add \"*\" -d \"*\"",
    "./tm add \"*\" -p high",
    "./tm add \"*\" -p medium", 
    "./tm add \"*\" -p low",
    "./tm add \"*\" -p critical",
    "./tm add \"*\" --depends-on *",
    "./tm add \"*\" --file src/*",
    "./tm add \"*\" --file tests/*",
    "./tm add \"*\" --file docs/*",
    "./tm list",
    "./tm list --status pending",
    "./tm list --status in_progress",
    "./tm list --status completed",
    "./tm list --status blocked",
    "./tm list --assignee *",
    "./tm list --has-deps",
    "./tm show *",
    "./tm update * --status pending",
    "./tm update * --status in_progress", 
    "./tm update * --status completed",
    "./tm update * --status blocked",
    "./tm update * --assignee *",
    "./tm complete *",
    "./tm complete * --impact-review",
    "./tm assign * *",
    "./tm delete *",
    "./tm export --format json",
    "./tm export --format markdown",
    "./tm join *",
    "./tm share * \"*\"",
    "./tm note * \"*\"",
    "./tm discover * \"*\"",
    "./tm sync * \"*\"",
    "./tm context *",
    "./tm watch"
  ]
}
```

## 🚀 Quick Setup Instructions

### Method 1: Project Configuration File
```bash
# Add to your project's .claude/config.json
{
  "whitelisted_commands": [
    "./tm *"  // Simple catch-all approach
  ]
}
```

### Method 2: Environment Variable  
```bash
# Set in your environment
export CLAUDE_WHITELIST_COMMANDS="./tm *"
```

### Method 3: Claude Code Settings
```bash
# In Claude Code interface:
# Settings > Security > Whitelisted Commands
# Add: ./tm *
```

## 📋 Pattern Explanation

| Pattern | Matches | Security Level |
|---------|---------|---------------|
| `./tm *` | All tm commands | Low - Most permissive |
| `./tm init` | Exact command only | High - Most restrictive |
| `./tm add "*"` | Add with quoted params | Medium - Balanced |
| `*/tm *` | From any directory | Low - Very permissive |

## 🎯 Recommended Configuration by Environment

### Development Environment (Recommended)
```json
{
  "whitelisted_commands": [
    "./tm *"
  ]
}
```
**Rationale:** Full functionality, maximum productivity

### Staging Environment
```json
{
  "whitelisted_commands": [
    "./tm init",
    "./tm add \"*\"",
    "./tm list*",
    "./tm show *",
    "./tm update *",
    "./tm complete *",
    "./tm join *",
    "./tm share * \"*\"",
    "./tm context *",
    "./tm watch"
  ]
}
```
**Rationale:** Core functionality with some restrictions

### Production Environment (If Used)
```json
{
  "whitelisted_commands": [
    "./tm list",
    "./tm show *",
    "./tm export --format json",
    "./tm watch"
  ]
}
```
**Rationale:** Read-only operations only

## 🔍 Testing Your Whitelist

After configuring the whitelist, test with these commands:

```bash
# Basic operations
./tm init
./tm add "Test task"
./tm list

# Multi-agent operations  
export TM_AGENT_ID="test_agent"
TASK=$(./tm add "Whitelist test" | grep -o '[a-f0-9]\{8\}')
./tm join $TASK
./tm share $TASK "Testing whitelist configuration"
./tm context $TASK

# Verify no confirmation prompts appear
```

## 🛡️ Security Considerations

### Safe Patterns
✅ `./tm *` - Limits to tm executable  
✅ `./tm add "*"` - Allows quoted parameters  
✅ `./tm list --status *` - Specific command with parameters  

### Potentially Unsafe Patterns (Avoid)
❌ `* *` - Too broad, matches everything  
❌ `bash *` - Allows arbitrary bash commands  
❌ `python *` - Allows arbitrary Python execution  

### Best Practices
1. **Test thoroughly** - Verify commands work without prompts
2. **Start restrictive** - Add permissions as needed
3. **Regular review** - Audit whitelist periodically
4. **Environment-specific** - Different rules for different environments

## 📞 Support

If you encounter issues with the whitelist configuration:

1. **Check syntax** - Ensure JSON is valid
2. **Test patterns** - Verify commands match your usage
3. **Review logs** - Check Claude Code logs for rejected commands
4. **Submit issues** - Use `docs/support/issues/` (see `docs/support/README.md` for template)

---

## 📋 Integration Checklist

- [ ] Choose appropriate whitelist level for your environment
- [ ] Add commands to Claude Code configuration
- [ ] Test basic Task Orchestrator operations
- [ ] Verify no confirmation prompts appear
- [ ] Test multi-agent coordination
- [ ] Document configuration for team

---

**This whitelist enables seamless Task Orchestrator integration with Claude Code for maximum multi-agent coordination efficiency.**