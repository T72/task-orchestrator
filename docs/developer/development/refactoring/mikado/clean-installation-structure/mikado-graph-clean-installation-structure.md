# Mikado Dependency Graph: Clean Installation Structure

## Current Discovery State

**IMPORTANT**: This graph shows the planned dependencies based on analysis. It will evolve as we discover actual blockers during implementation.

## Visual Representation

```mermaid
graph TD
    Goal[GOAL: Clean Installation Structure]
    
    %% Phase 1: Foundation
    Goal --> P1.1[1.1: Analyze Package Structure]
    P1.1 --> P1.2[1.2: Create Directory Structure]
    P1.2 --> P1.3[1.3: Update tm Wrapper]
    
    %% Phase 2: Core Implementation
    P1.3 --> P2.1[2.1: Reorganize Python Modules]
    P2.1 --> P2.2[2.2: Update Internal Imports]
    P2.1 --> P2.3[2.3: Move Config Files]
    P2.2 --> P2.4[2.4: Create Migration Script]
    P2.3 --> P2.4
    
    %% Phase 3: Testing
    P2.4 --> P3.1[3.1: Test Core Commands]
    P3.1 --> P3.2[3.2: Test Migration]
    P3.1 --> P3.3[3.3: Test Fresh Install]
    P3.3 --> P3.4[3.4: Update Packaging]
    
    %% Phase 4: Documentation
    P3.4 --> P4.1[4.1: Update Documentation]
    P4.1 --> P4.2[4.2: Update .gitignore]
    P4.2 --> P4.3[4.3: Create Release]
    
    classDef goal fill:#4CAF50,stroke:#333,stroke-width:3px;
    classDef planned fill:#FFA500,stroke:#333,stroke-width:2px;
    classDef attempting fill:#feca57,stroke:#333,stroke-width:2px;
    classDef completed fill:#00d2d3,stroke:#333,stroke-width:2px;
    classDef blocked fill:#ff6b6b,stroke:#333,stroke-width:2px;
    
    class Goal goal;
    class P1.1,P1.2,P1.3,P2.1,P2.2,P2.3,P2.4,P3.1,P3.2,P3.3,P3.4,P4.1,P4.2,P4.3 planned;
```

## Discovery Log

| Attempt # | What We Tried | What Blocked Us | Prerequisite Added | Status |
|-----------|--------------|-----------------|-------------------|---------|
| - | Planning phase | - | Initial dependencies mapped | Planned |

## Node Status Legend

- 🎯 **Goal** (Green border) - The main objective
- 🟠 **Planned** (Orange) - Dependencies identified through analysis
- 🟡 **Attempting** (Yellow) - Currently trying to implement
- 🟢 **Completed** (Cyan) - Successfully implemented
- 🔴 **Blocked** (Red) - Discovered blocker during implementation
- ⚫ **Reverted** (Gray dashed) - Attempted but reverted

## Critical Path Analysis

**Shortest path to completion:**
1. Analyze structure (1.1)
2. Create directories (1.2)
3. Update wrapper (1.3)
4. Reorganize modules (2.1)
5. Update imports (2.2)
6. Create migration (2.4)
7. Test commands (3.1)
8. Update packaging (3.4)
9. Create release (4.3)

**Parallel work opportunities:**
- Tasks 2.2 and 2.3 can be done in parallel after 2.1
- Tasks 3.2 and 3.3 can be done in parallel after 3.1
- Documentation (4.1, 4.2) can start early

## Mikado Process Tracking

- **Current Phase**: Planning Complete
- **Next Action**: Start Phase 1 - Analyze package structure
- **Green State**: Current working installation
- **Estimated Total Time**: 10.25 hours

## Update Instructions

1. Update node colors as tasks are attempted/completed
2. Add discovered dependencies if blockers found
3. Document attempts in Discovery Log
4. Mark completed tasks with cyan color
5. Update time estimates based on actual work