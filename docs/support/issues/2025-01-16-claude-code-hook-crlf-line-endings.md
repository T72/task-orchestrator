# Issue Report Template

## Date: 2025-01-16
## Version: 2.7.1-internal

## Issue Summary
Claude Code hook scripts created on Windows systems with CRLF line endings fail with "syntax error: unexpected end of file" when executed in WSL environments, causing status code 127 errors and breaking Task Orchestrator enforcement.

## Category
- [ ] bug
- [x] performance
- [x] compatibility
- [ ] agent-coordination

## Priority
- [ ] Critical
- [ ] High
- [x] Medium
- [ ] Low

## Steps to Reproduce
1. Create Task Orchestrator enforcement hook in Claude Code on Windows system
2. Configure hook in `.claude/settings.local.json` with PreToolUse matcher
3. Attempt to use Task tool in WSL environment
4. Hook fails with status code 127 and "not found" error (misleading)
5. Running `bash -n hook.sh` reveals actual syntax error from CRLF line endings

## Expected vs Actual
**Expected**: Hook should execute successfully in WSL environment regardless of where it was created
**Actual**: Hook fails with misleading "not found" error, actual issue is CRLF line endings causing syntax errors

## Error Messages
```
PreToolUse:Task [/path/to/hook.sh] failed with non-blocking status code 127:
/bin/sh: 1: /path/to/hook.sh: not found

# When investigating with bash -n:
hook.sh: line 62: syntax error: unexpected end of file
```

## Environment Details
- **System**: Windows 11 + WSL2 
- **Claude Code**: Running in WSL environment
- **File Location**: Windows D:\ drive (mounted as /mnt/d in WSL)
- **Hook Creation**: Created via Claude Code (which runs in WSL but files stored on Windows)

## Root Cause
Hook scripts get Windows CRLF line endings when created/edited, but WSL bash expects Unix LF line endings.

## Current Workaround
```bash
# Fix line endings manually
sed -i 's/\r$//' /path/to/hook.sh
```

## Suggested Solutions

### 1. Documentation Enhancement
Add section to Task Orchestrator documentation about WSL compatibility:
- Mention CRLF line ending issues
- Provide `sed -i 's/\r$//'` fix command
- Include in troubleshooting guide

### 2. Hook Creation Best Practices
Provide guidance for Claude Code users:
- Always run line ending fix after creating hooks
- Consider adding to hook templates/examples

### 3. Enhanced Error Reporting
Current "not found" error is misleading - actual issue is syntax error from line endings. Consider:
- Better error detection in hook execution
- More descriptive error messages
- Automatic line ending detection/fixing

## Impact
- **User Experience**: Confusing error messages delay problem resolution
- **Cross-Platform**: Affects all Windows + WSL Task Orchestrator users
- **Claude Code Integration**: Impacts users integrating Task Orchestrator with Claude Code

## Business Value
Fixing this improves:
- User adoption in mixed Windows/WSL environments
- Time-to-productivity for new users
- Documentation completeness for cross-platform scenarios

---
*Save as: docs/support/issues/2025-01-16-claude-code-hook-crlf-line-endings.md*