# CLAUDE.md Multi-File Architecture Guide

**Type**: Implementation Guide  
**Category**: AI Assistant Configuration  
**Status**: Current Best Practice  
**Last Updated**: 2025-08-22

## Purpose

This guide provides the recommended architecture for organizing CLAUDE.md files in development projects, based on proven patterns that achieved 100% MVP completion and 4x-5x velocity improvements.

## Quick Decision Framework

### When to Use Single vs Multiple CLAUDE.md Files

| Project Size | Recommended Pattern | Reasoning |
|-------------|-------------------|-----------|
| **< 1500 lines** | Single CLAUDE.md | Maximum clarity, single source of truth |
| **1500-2500 lines** | Consider splitting | Monitor for pain points |
| **> 2500 lines** | 4-File Pattern | Better relevance and maintenance |
| **> 5000 lines** | Requires splitting | Cognitive overload threshold |

## The 4-File Pattern Architecture

### Recommended Structure

```
project-root/
├── CLAUDE.md                    # Central hub (1200-1500 lines)
├── src/
│   └── CLAUDE.md                # Application code guidance (300-400 lines)
├── scripts/
│   └── testing/
│       └── CLAUDE.md            # Test infrastructure (200-300 lines)
└── docs/
    └── CLAUDE.md                # Documentation guardian (150-200 lines)
```

### File Responsibilities

#### 1. Root CLAUDE.md - Central Command Hub

**Size**: 1200-1500 lines  
**Role**: Primary operational control center

**MUST Contain**:
- **ALL Protected Rules** (never split these)
- Session management protocols
- Agent orchestration patterns
- Core LEAN principles
- Critical project rules
- MVP/release information
- Command execution strategy
- Task Orchestrator configuration
- MCP server configurations
- Global working agreements

**Example Protected Rule**:
```markdown
7. **[PROTECTED RULE - DO NOT MODIFY] PARALLEL AGENT SQUADRON IS DEFAULT BASELINE** - 
   For ANY multi-domain task, ALWAYS deploy the Parallel Agent Squadron pattern (4+ agents) 
   as the default approach. This has been VALIDATED with 4x-5x velocity improvement.
```

#### 2. src/CLAUDE.md - Application Development Guide

**Size**: 300-400 lines  
**Role**: Frontend and application-specific guidance

**Contains**:
- Framework-specific patterns (React/Next.js/Vue/etc.)
- Component development standards
- API route conventions
- State management patterns
- Database client usage (browser-side)
- TypeScript/JavaScript best practices
- UI/UX implementation details
- Styling conventions
- Build configuration notes

**Example Content**:
```markdown
## Component Standards

### Always Use Server Components by Default
- Client components only when needed for interactivity
- Mark with 'use client' directive explicitly
- Server components for data fetching

### Naming Conventions
- Components: PascalCase (UserProfile.tsx)
- Utilities: camelCase (formatDate.ts)
- Constants: UPPER_SNAKE_CASE (API_ENDPOINTS.ts)
```

#### 3. scripts/testing/CLAUDE.md - Test Infrastructure Guide

**Size**: 200-300 lines  
**Role**: Testing and quality assurance guidance

**Contains**:
- Test server operation procedures
- Test execution patterns
- Mock infrastructure guidance
- Coverage requirements and thresholds
- Test-specific utilities and helpers
- Performance benchmarks
- CI/CD test configurations
- Test categorization rules

**Example Content**:
```markdown
## Test Execution Protocol

### Always Use Test Server Bridge
```bash
# NEVER run tests directly in WSL
# ALWAYS use Test Server on port 3456 or 4702
powershell.exe -Command "Invoke-RestMethod -Uri http://localhost:3456/test/start ..."
```

### Coverage Requirements
- Unit Tests: ≥80% line & branch
- Integration Tests: ≥80% line & branch
- API Tests: ≥80% line & branch
```

#### 4. docs/CLAUDE.md - Documentation Structure Guardian

**Size**: 150-200 lines  
**Role**: Protects and enforces documentation organization

**Critical Purpose**: This file serves as a GUARDIAN of your carefully designed documentation structure, ensuring Claude understands and preserves the established patterns.

**Contains**:
- Folder structure rules and enforcement
- Document type classifications
- Placement guidelines for each document type
- Archive procedures and timing
- Naming convention standards
- Document lifecycle management
- What NOT to put in docs

**Example Content**:
```markdown
## Documentation Structure - MUST PRESERVE

### Document Placement Rules

#### Reports (→ developer/reports/)
- Analysis documents and findings
- LEAN matrices and prioritizations
- Test coverage reports
- Performance analyses
- Strategic assessments
- Archive after 3 months or when obsolete

#### Guides (→ developer/guides/)
- How-to documentation
- Implementation guides
- Best practices
- **READ-ONLY** - Never modify directly
- Update only through PR process

#### Protocols (→ protocols/)
- Official procedures
- Formal workflows
- Compliance requirements
- Change only with approval

#### Notes (→ developer/notes/)
- Temporary working notes
- Meeting summaries
- Quick observations
- Delete or promote within 1 week

### NEVER Place in Docs
- Test outputs or logs
- Temporary files
- Build artifacts
- Personal notes
- Code snippets without context
```

## Implementation Strategy

### Phase 1: Assess Current State

1. **Measure current CLAUDE.md**:
   ```bash
   wc -l CLAUDE.md  # Check line count
   ```

2. **Identify pain points**:
   - Session start time > 5 minutes?
   - Finding rules difficult?
   - Domain mixture confusing?

3. **Check for natural boundaries**:
   - Clear src/ specific content?
   - Test-only instructions?
   - Documentation rules scattered?

### Phase 2: Plan the Split (If Needed)

1. **Create extraction list**:
   - Mark sections for each target file
   - Ensure no protected rules are moved
   - Maintain cross-references

2. **Validate completeness**:
   ```markdown
   - [ ] All protected rules stay in root
   - [ ] No duplicate instructions
   - [ ] Clear inheritance model
   - [ ] Each file has clear purpose
   ```

### Phase 3: Execute the Split

1. **Create new CLAUDE.md files**:
   ```bash
   touch src/CLAUDE.md
   touch scripts/testing/CLAUDE.md
   touch docs/CLAUDE.md
   ```

2. **Add headers to each**:
   ```markdown
   # CLAUDE.md - [Domain] Specific Guidance
   
   **Parent**: /CLAUDE.md (inherits all rules)
   **Scope**: [Specific domain focus]
   **Priority**: Domain-specific overrides general
   ```

3. **Extract relevant sections**:
   - Move domain-specific content
   - Keep general rules in root
   - Add cross-references

### Phase 4: Validate and Refine

1. **Test with real tasks**:
   - Development task → Check src/ guidance helps
   - Test execution → Check scripts/testing/ guidance helps
   - Documentation → Check docs/ guardian works

2. **Monitor metrics**:
   - Session efficiency
   - Rule finding speed
   - Mistake frequency

## Inheritance Model

### How Multiple CLAUDE.md Files Work Together

```
Root CLAUDE.md (Base Layer)
    ↓ inherits
src/CLAUDE.md (Overrides for source code)
scripts/testing/CLAUDE.md (Overrides for testing)
docs/CLAUDE.md (Overrides for documentation)
```

**Rules**:
1. **Child inherits parent**: All root rules apply unless overridden
2. **Specific beats general**: Domain file rules override root
3. **Explicit wins**: Clear instructions beat assumptions
4. **Protected never moves**: Protected rules only in root

## Success Metrics

### Indicators You've Got It Right

✅ **Good Signs**:
- Session start < 2 minutes
- Finding rules quickly
- Fewer repeated mistakes
- Clear domain boundaries
- No conflicting instructions

❌ **Warning Signs**:
- Duplicate rules across files
- Confusion about which file to check
- Protected rules split up
- Files > 500 lines (except root)
- More than 5 CLAUDE.md files total

## Common Pitfalls to Avoid

### 1. Over-Fragmentation
**Problem**: Creating 10+ CLAUDE.md files  
**Solution**: Stick to 4-file pattern maximum

### 2. Splitting Protected Rules
**Problem**: Moving protected rules from root  
**Solution**: ALL protected rules stay in root, no exceptions

### 3. Forgetting Guardian Role
**Problem**: Not creating docs/CLAUDE.md  
**Solution**: docs/CLAUDE.md protects documentation structure

### 4. Unclear Boundaries
**Problem**: Same topic in multiple files  
**Solution**: Each file has distinct, non-overlapping scope

### 5. No Inheritance Declaration
**Problem**: Not stating parent-child relationship  
**Solution**: Every child CLAUDE.md declares its parent

## Migration Checklist

When moving from single to multi-file:

- [ ] Current CLAUDE.md exceeds 2500 lines
- [ ] Clear domain boundaries identified
- [ ] Protected rules marked in root
- [ ] Extraction plan documented
- [ ] Each file purpose defined
- [ ] Inheritance model declared
- [ ] Headers added to each file
- [ ] Cross-references included
- [ ] Testing completed
- [ ] Metrics baselined

## Example: Well-Structured docs/CLAUDE.md

```markdown
# CLAUDE.md - Documentation Structure Guardian

**Parent**: /CLAUDE.md (inherits all global rules)
**Purpose**: Protect and enforce documentation organization
**Critical**: This file ensures documentation consistency

## Documentation Hierarchy

### Folder Structure (MUST PRESERVE)
```
docs/
├── developer/
│   ├── reports/      # Analysis, LEAN matrices, findings
│   ├── guides/       # How-to guides (READ-ONLY)
│   ├── notes/        # Temporary (<1 week)
│   └── reference/    # API docs, configurations
├── protocols/        # Official procedures
└── specifications/   # Requirements, features
```

## Placement Rules

### What Goes Where

| Document Type | Location | Lifecycle |
|--------------|----------|-----------|
| LEAN Analysis | developer/reports/ | Archive after 3 months |
| Test Results | developer/reports/ | Archive when obsolete |
| How-To Guide | developer/guides/ | Update via PR only |
| Meeting Notes | developer/notes/ | Delete after 1 week |
| API Reference | developer/reference/ | Update with code |

## Enforcement

### Before Creating Any Document

1. Does it belong in docs/?
2. Which specific subfolder?
3. What's the lifecycle?
4. What's the naming convention?

### Red Flags (STOP if you see these)

- Creating .md files in root
- Mixing reports with guides
- Modifying READ-ONLY guides directly
- Keeping notes > 1 week
- Wrong naming conventions
```

## Conclusion

The 4-file pattern (root + src + scripts/testing + docs) provides optimal balance between:
- **Clarity**: Each file has clear purpose
- **Maintenance**: Manageable file sizes
- **Relevance**: Domain-specific guidance
- **Protection**: Documentation structure preserved

Start with single CLAUDE.md, evolve to 4-file pattern when needed, never exceed 5 files total.

## References

- [Task Orchestrator Template](./task-orchestrator-claude-md-template.md)
- [Multi-Agent Orchestration Template](./multi-agent-orchestration-claude-md-template.md)
- [Protected Rules Strategy](./protected-rules-strategy-claude-md-template.md)