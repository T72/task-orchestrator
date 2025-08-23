# 🔧 Task Orchestrator Support Guide

This guide describes how to provide feedback, report issues, and request features for the Task Orchestrator project.

---

## 📋 How to Provide Feedback

### 🐞 Issues and Bug Reports

Create a new file in the `docs/support/issues/` directory using the following naming format:

**Filename Format:**  
`YYYY-MM-DD_issue-description.md`

**Template:**
```markdown
# Issue Report

**Date:** YYYY-MM-DD  
**Reporter:** Your Name or Team  
**Type:** Bug | Configuration | Performance | Other
**Version:** v2.5.0-internal

## Description
Brief description of the issue

## Environment
- OS: Linux / macOS / Windows / WSL
- Python version: (e.g., 3.8.10)
- Task Orchestrator version: v2.5.0-internal
- Database location: .task-orchestrator/ or custom

## Steps to Reproduce
1. Step 1  
2. Step 2  
3. Step 3  

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Logs/Error Messages
```
Include any relevant logs or error messages
```

## Workaround
If you found a workaround, describe it here

## Additional Context
Any other relevant information (screenshots, related tasks, etc.)
```

---

### 💡 Feature Requests and Feedback

Create a new file in the `docs/support/feedback/` directory using the following naming format:

**Filename Format:**  
`YYYY-MM-DD_feedback-description.md`

**Template:**
```markdown
# Feedback / Feature Request

**Date:** YYYY-MM-DD  
**Submitter:** Your Name or Team  
**Type:** Feature Request | Improvement | Documentation | Other
**Version:** v2.5.0-internal

## Summary
Brief summary of the request

## Description
Detailed description of the proposed change or enhancement

## Use Case
What problem does this solve or opportunity does it unlock?

## Current Workaround
How are you currently handling this need?

## Proposed Solution (if any)
Suggested implementation approach

## Impact Assessment
- Who would benefit from this?
- How critical is this for your workflow?
- Are there alternatives?

## Priority
Low | Medium | High | Critical

## Additional Notes
Any other relevant context, mockups, or examples
```

---

## 📂 Support File Structure

### `docs/support/issues/`
Contains:
- Known issues and their status
- Reported bugs with reproduction steps
- Resolution tracking and workarounds
- Historical issues for reference

### `docs/support/feedback/`
Contains:
- Feature and improvement requests  
- General user feedback and suggestions
- Enhancement proposals with use cases
- Community ideas and discussions

### `docs/support/templates/`
Contains:
- Issue report template
- Feature request template
- Quick feedback forms

---

## 🔄 Support Process

1. **Submit** feedback using the provided templates  
2. **Review** is performed on a rolling basis by the project team  
3. **Response** is provided via edits or status annotations in your submission file  
4. **Resolution** is documented within the respective issue or feedback entry
5. **Updates** are communicated through version releases and CHANGELOG

---

## 🚀 Quick Feedback

For quick feedback without creating a full report, you can also:

1. Add a note to `docs/support/feedback/quick-notes.md`
2. Use the format:
   ```
   **[Date] - [Your Name]**: Your quick feedback here
   ```

---

## 📊 Current Focus Areas

We're particularly interested in feedback about:
- **Project Isolation**: How well does the new project-local database work?
- **Multi-Agent Collaboration**: Share, sync, and context features
- **Performance**: Task operations with large datasets
- **Documentation**: Clarity and completeness of guides
- **Integration**: Working with Claude Code and other AI agents

---

## 🎯 Known Issues (v2.5.0-internal)

Currently tracking:
- Performance optimization for large task lists (>1000 tasks)
- Enhanced error messages for database lock conflicts
- Documentation for advanced hook customization

See `docs/support/issues/` for full list and status.

---

## 📞 Contact

For time-sensitive or critical issues:
- Check existing issues first in `docs/support/issues/`
- For urgent matters, create an issue with "CRITICAL" priority
- Internal team members can directly update status in issue files

---

## 🔗 Helpful Resources

- **Main Documentation**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/README.md`
- **Quick Start Guide**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/docs/guides/quickstart.md`
- **Migration Guide**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/docs/guides/migration-guide.md`
- **API Reference**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/docs/reference/api-reference.md`
- **CHANGELOG**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/CHANGELOG.md`

---

**Thank you for contributing to the improvement of Task Orchestrator!**