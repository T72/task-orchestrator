# Task Orchestrator API Documentation

## Overview

The Task Orchestrator API provides programmatic access to task management functionality, including the powerful Core Loop features introduced in v2.3.

## API References

### Core Loop API (v2.3)
- **[Core Loop API Reference](core-loop-api-reference.md)** - Complete API documentation for Core Loop features
  - TaskManager enhanced methods
  - Configuration management
  - Migration system
  - Criteria validation
  - Metrics and analytics

### Legacy API (v2.2 and earlier)
- **[Basic Task Management](basic-task-api.md)** - Original task CRUD operations
- **[Dependency Management](dependency-api.md)** - Task dependency handling
- **[Collaboration Features](collaboration-api.md)** - Team coordination APIs

## Quick Start

```python
from task_orchestrator import TaskManager

# Initialize with Core Loop features
tm = TaskManager()

# Create task with success criteria
task_id = tm.add(
    title="Implement feature",
    criteria='[{"criterion":"Tests pass","measurable":"true"}]',
    estimated_hours=8
)

# Track progress
tm.progress(task_id, "50% complete")

# Complete with validation
tm.complete(task_id, validate=True, actual_hours=7.5)

# Add feedback
tm.feedback(task_id, quality=5, timeliness=5)
```

## Integration Guides

- **[CI/CD Integration](../integrations/ci-cd-integration.md)** - Automate with build pipelines
- **[Claude Code Integration](../integrations/claude-code-integration.md)** - AI-assisted development
- **[External Systems](../integrations/external-systems.md)** - Connect with other tools

## Development Resources

- **[Extension Guide](../extending/extending-core-loop.md)** - Create custom validators and plugins
- **[Testing Guide](../testing/testing-core-loop.md)** - Test Core Loop integrations
- **[Performance Guide](../performance/performance-guide.md)** - Optimize for scale

## Support

- **[Troubleshooting](../../guides/troubleshooting.md)** - Common issues and solutions
- **[Migration Guide](../../migration/v2.3-migration-guide.md)** - Upgrade from v2.2
- **[GitHub Issues](https://github.com/T72/task-orchestrator/issues)** - Report bugs and request features

## Version Compatibility

| Version | Core Loop | Python | Notes |
|---------|-----------|--------|-------|
| v2.3+ | ✅ Full | 3.8+ | Latest with all features |
| v2.2 | ❌ None | 3.8+ | Legacy task management |
| v2.1 | ❌ None | 3.7+ | Deprecated |

---

*Last updated: 2025-08-20*