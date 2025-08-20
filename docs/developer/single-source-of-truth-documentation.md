# Single Source of Truth Documentation System

## Overview

This document describes our automated documentation system that ensures database schema documentation never drifts from implementation. The code IS the documentation.

## Philosophy

**Core Principle**: Documentation drift occurs when humans maintain two separate artifacts (code and docs). By generating documentation directly from code, drift becomes impossible.

## How It Works

### 1. Inline Documentation in Code

Developers add `@doc` comments directly in SQL statements:

```python
conn.execute("""
    CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,           -- @doc: 8-character unique ID auto-generated
        title TEXT NOT NULL,            -- @doc: Task description (required, max 500 chars)
        status TEXT DEFAULT 'pending',  -- @doc: pending|in_progress|completed|blocked|cancelled
    )
    -- @table-doc: Core task storage with status tracking
""")
```

### 2. Automatic Extraction

The `scripts/extract-schema.py` script:
- Parses source code for CREATE TABLE statements
- Extracts @doc comments
- Generates markdown documentation
- Outputs formatted database schema docs

### 3. Pre-commit Automation

When `tm_production.py` changes:
- Pre-commit hook runs extraction script
- Documentation updates automatically
- Changes included in same commit

### 4. CI/CD Validation

Pull requests fail if:
- Schema changed without doc comments
- Generated docs don't match committed docs
- Documentation extraction fails

## Implementation Guide

### Adding Documentation

When modifying database schema:

1. **Add @doc comments to columns**:
```python
column_name TEXT,  -- @doc: Description of column purpose
```

2. **Add @table-doc for tables**:
```sql
-- @table-doc: Overall purpose of this table
```

3. **Document constraints**:
```python
-- @doc: Values: pending|in_progress|completed
```

### Running Documentation Generation

#### Manual Generation
```bash
python scripts/extract-schema.py > docs/reference/database-schema-generated.md
```

#### Automatic Generation
```bash
# Install pre-commit hook (one time)
cp scripts/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Now documentation auto-updates on commit
```

### Documentation Tags

| Tag | Purpose | Example |
|-----|---------|---------|
| `@doc:` | Column documentation | `-- @doc: User's email address` |
| `@table-doc:` | Table overview | `-- @table-doc: Stores user accounts` |
| `@constraint:` | Constraint details | `-- @constraint: Must be unique` |
| `@index-doc:` | Index documentation | `-- @index-doc: Speeds up status queries` |
| `@deprecated:` | Mark for removal | `-- @deprecated: Use new_column instead` |

## Benefits

### For Developers
- Write documentation while coding
- No separate documentation step
- Documentation in familiar environment
- Changes tracked in version control

### For Users
- Always accurate documentation
- No confusion from outdated docs
- Clear understanding of constraints
- Implementation details visible

### For Maintainers
- Zero documentation maintenance
- Automatic consistency checks
- Single source of truth
- Reduced support burden

## Comparison with Manual Documentation

| Aspect | Manual Documentation | Single Source of Truth |
|--------|---------------------|------------------------|
| Accuracy | Drifts over time | Always accurate |
| Effort | High (duplicate work) | Low (write once) |
| Location | Separate file | With code |
| Updates | Often forgotten | Automatic |
| Validation | Manual review | Automated checks |

## Extending the System

### Adding New Documentation Types

1. **Define new tag** (e.g., `@performance:`)
2. **Update extraction script** to recognize tag
3. **Add formatting rules** for output
4. **Document tag** in this guide

### Supporting Other Languages

The pattern works for any language:
- JavaScript: `// @doc:`
- Python: `# @doc:`
- Go: `// @doc:`
- Rust: `/// @doc:`

## Troubleshooting

### Documentation Not Updating

1. Check pre-commit hook installed:
```bash
ls -la .git/hooks/pre-commit
```

2. Verify extraction script works:
```bash
python scripts/extract-schema.py
```

3. Check for syntax errors in @doc comments

### Missing Documentation

Run audit to find undocumented columns:
```bash
python scripts/audit-schema-docs.py
```

## Migration from Manual Documentation

### Phase 1: Add Inline Docs (Week 1)
- Add @doc comments to existing schema
- Keep manual docs during transition

### Phase 2: Generate and Compare (Week 2)
- Run extraction script
- Compare with manual docs
- Fix discrepancies

### Phase 3: Switch Over (Week 3)
- Replace manual with generated docs
- Enable pre-commit hook
- Archive old documentation

## Best Practices

### DO
- ✅ Document while coding
- ✅ Use clear, concise descriptions
- ✅ Include value constraints
- ✅ Document relationships
- ✅ Keep comments updated

### DON'T
- ❌ Document obvious things ("id is the ID")
- ❌ Use technical jargon
- ❌ Leave TODOs in @doc comments
- ❌ Duplicate information
- ❌ Mix implementation details

## Success Metrics

Track documentation health:
- **Coverage**: % of columns with @doc comments
- **Freshness**: Days since last update
- **Accuracy**: Validation test pass rate
- **Clarity**: Support tickets about schema

Target metrics:
- 100% column documentation coverage
- 0 days documentation lag
- 100% validation pass rate
- <5 schema questions per month

## FAQ

**Q: What if I need complex documentation?**
A: Use multiple @doc lines or link to detailed docs

**Q: Can I document future features?**
A: Use `@planned:` tag for future additions

**Q: How do I document deprecated features?**
A: Use `@deprecated:` tag with migration notes

**Q: What about non-SQL schemas?**
A: Same pattern works for any schema definition

## Conclusion

Single Source of Truth documentation eliminates documentation drift by making code the authoritative source. This approach requires minimal effort while guaranteeing accuracy, making it sustainable for long-term projects.

Remember: **The best documentation is the code itself, properly annotated.**