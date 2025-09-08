# Product Requirements Documents

## Current Version
- **[PRD-SIMPLIFIED-v2.5.md](PRD-SIMPLIFIED-v2.5.md)** - Simplified architecture with PRD parser removal

## Version History

### v2.5 (Current) - Simplified Architecture
- **Status**: In Development
- **Date**: 2025-08-21
- **Key Changes**:
  - Removed PRD parser feature for cleaner architecture
  - Eliminated task contamination issues
  - Focused on core task orchestration capabilities
  - Maintained comprehensive requirements implementation

### v2.4 - Project Isolation & Foundation
- **Status**: Superseded by v2.5
- **Location**: [PRD-PROJECT-ISOLATION-v2.4.md](PRD-PROJECT-ISOLATION-v2.4.md)
- **Key Changes**:
  - Project-local database isolation
  - Enhanced context preservation
  - Foundation architecture implementation

### v2.3 - Core Loop Implementation
- **Status**: Superseded by v2.4
- **Location**: [PRD-CORE-LOOP-v2.3.md](PRD-CORE-LOOP-v2.3.md)
- **Key Changes**:
  - Complete core loop implementation
  - Enhanced testing framework
  - Comprehensive feature development

### v2.0 (Archived) - Hardened Production Version
- **Status**: Superseded by v2.3
- **Location**: [archive/PRD-ULTRA-LEAN-ORCHESTRATION-v2.0.md](archive/PRD-ULTRA-LEAN-ORCHESTRATION-v2.0.md)
- **Key Features**:
  - 247 lines implementation
  - 38 edge case tests
  - 100% requirements traceability
  - Production-ready with bulletproof reliability

### v1.0 (Archived) - Native Orchestration Foundation
- **Status**: Foundation document (referenced by v2.x)
- **Location**: [archive/PRD-NATIVE-ORCHESTRATION-v1.0.md](archive/PRD-NATIVE-ORCHESTRATION-v1.0.md)
- **Key Concepts**:
  - Original vision for native Claude Code integration
  - TodoWrite enhancement strategy
  - Subagent coordination patterns
  - Core architectural requirements

## Architecture Evolution

```
v1.0 Native Foundation
    ├── Defined core architecture
    ├── TodoWrite enhancement strategy
    └── Subagent coordination
         ↓
v2.0 Ultra-Lean Implementation  
    ├── 260→247 lines optimization
    ├── Hook-based orchestration
    └── Comprehensive testing
         ↓
v2.3 Core Loop Implementation
    ├── Complete feature set
    ├── Enhanced testing framework
    └── Requirements traceability
         ↓
v2.4 Project Isolation & Foundation
    ├── Project-local databases
    ├── Context preservation
    └── Foundation architecture
         ↓
v2.5 Simplified Architecture (Current)
    ├── PRD parser removal
    ├── Cleaner orchestration
    └── Focused functionality
```

## Key Architectural Requirements

From the foundational PRD that all versions must respect:

1. **Read-Only Shared Context File**
   - Location: `.claude/context/shared-context.md`
   - Purpose: Coordinate task execution across agents
   - Maintained by: Orchestrating agent

2. **Private Note-Taking Files**
   - Location: `.claude/agents/notes/{agent}-notes.md`
   - Purpose: Persist agent-specific context
   - Maintained by: Individual agents

3. **Shared Notification File**
   - Location: `.claude/notifications/broadcast.md`
   - Purpose: Inter-agent communication
   - Maintained by: Event system

## Implementation Status

| Component | v1.0 | v2.0 | v2.3 | v2.4 | v2.5 |
|-----------|------|------|------|------|------|
| Task Dependencies | Planned | ✅ Implemented | ✅ Enhanced | ✅ Maintained | ✅ Maintained |
| Checkpointing | Planned | ✅ Implemented | ✅ Extended | ✅ Enhanced | ✅ Enhanced |
| PRD Parsing | Planned | ✅ Implemented | ✅ Integrated | ✅ Maintained | ❌ Removed |
| Event Flows | Planned | ✅ Implemented | ✅ Broadcast | ✅ Enhanced | ✅ Enhanced |
| Context Management | ✅ Defined | ⚠️ Missing | ✅ Basic | ✅ Complete | ✅ Complete |
| Project Isolation | ⚠️ Missing | ⚠️ Missing | ⚠️ Missing | ✅ Implemented | ✅ Enhanced |

## Migration Path

### From v2.4 to v2.5
1. Remove PRD parser functionality (already completed)
2. Update hook configurations to exclude PRD parsing
3. Focus on core task orchestration features

### From v2.3 to v2.4  
1. Implement project-local database isolation
2. Create foundation directories:
   ```bash
   mkdir -p .task-orchestrator/context
   mkdir -p .task-orchestrator/notes
   mkdir -p .task-orchestrator/archive
   ```

### Backward Compatibility
- All v2.0 features maintained
- Foundation files created on-demand
- Graceful degradation supported

## Design Principles

1. **Extend, Don't Replace**: Build on Claude Code's native features
2. **Minimal Code**: Maximum value in minimum lines (247 lines)
3. **Foundation First**: Respect core architectural requirements
4. **Test Everything**: 100% coverage with edge cases
5. **Zero Friction**: Works automatically via hooks

## Quick Links

- [Current PRD v2.5](PRD-SIMPLIFIED-v2.5.md)
- [**Complete Requirements Master List**](../../reference/requirements-master-list.md) - All individual requirements with exact text and sources
- [Test Report](../../FINAL-TEST-REPORT.md)
- [Implementation](../../../.claude/hooks/)
- [User Documentation](../../../.claude/CLAUDE.md)