# Migration Guide

## Migrating to v2.7.x

### From v2.6.x to v2.7.x

#### Breaking Changes
None - v2.7.x maintains full backward compatibility.

#### New Features
- **Orchestration Enforcement**: Default enforcement for meta-agents
- **Requirements Traceability**: 91.5% implementation coverage
- **Commander's Intent Framework**: WHY/WHAT/DONE pattern for tasks
- **Enhanced Support Infrastructure**: Feedback and issue templates

#### Migration Steps
1. Update to latest version:
   ```bash
   git pull origin main
   ./tm migrate --apply
   ```

2. Enable new features (optional):
   ```bash
   # Enable orchestration enforcement
   ./tm config --enforce-orchestration true
   
   # Set enforcement level
   ./tm config --enforcement-level standard
   ```

3. Verify installation:
   ```bash
   ./tm --version  # Should show 2.7.1
   ./tm validate-orchestration
   ```

### From v2.5.x or Earlier

#### Database Schema Changes
The database schema has evolved. Run migration:
```bash
./tm migrate --apply
```

#### Configuration Updates
New configuration options available:
- `enforce_orchestration`: Enable/disable orchestration checks
- `enforcement_level`: strict/standard/advisory

#### API Changes
- `add()` method now supports Commander's Intent via --context
- New commands: `validate-orchestration`, `fix-orchestration`

### Data Migration

#### Backing Up Data
Before any migration:
```bash
cp -r .task-orchestrator .task-orchestrator.backup
```

#### Migrating Tasks
Tasks automatically migrate on first access. No manual intervention needed.

#### Preserving History
All task history is preserved during migration.

### Troubleshooting

#### Common Issues

**Database locked error**
```bash
# Solution: Stop any running tm watch processes
pkill -f "tm watch"
```

**Migration fails**
```bash
# Solution: Restore backup and retry
rm -rf .task-orchestrator
mv .task-orchestrator.backup .task-orchestrator
./tm migrate --check
```

**Version mismatch**
```bash
# Solution: Ensure using latest tm script
chmod +x tm
./tm --version
```

### Rollback Procedure

To rollback to previous version:
1. Restore database backup
2. Checkout previous version
3. No schema downgrades needed

### Support

For migration assistance:
- Check troubleshooting guide: `docs/guides/troubleshooting.md`
- Report issues: `docs/support/templates/issue.md`
- Request features: `docs/support/templates/feedback.md`

---
*Last updated: September 3, 2025 for v2.7.2*