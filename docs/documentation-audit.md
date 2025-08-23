# Documentation Audit: tm add Examples

## Summary
- Total tm add examples found: ~100+
- Files needing updates: 3 main user-facing docs
- Pattern needed: When capturing output to variable, add `| grep -o '[a-f0-9]\{8\}'`

## Files Requiring Updates

### 1. docs/guides/USER_GUIDE.md
Examples missing grep pattern when capturing to variables:
- Line 579: `EPIC=$(./tm add "User Authentication Epic" --priority critical)`
- Line 582-584, 587-588, 591: Multiple dependency examples
- Line 753: `SETUP=$(./tm add "Setup test database")`
- Line 764-767: Profile feature chain
- Line 836-843: User profile management
- Line 860, 870-871: Bug fix workflow
- Line 881, 884-886: Sprint planning
- Line 902, 905-909: Release preparation

### 2. docs/guides/QUICKSTART-CLAUDE-CODE.md
Examples that should show proper ID capture:
- Line 53: `MAIN=$(./tm add "Build authentication system" -p high)`
- Line 56-59: Dependency chain examples

### 3. README.md
✅ Already correct - all variable captures use grep pattern

## Pattern Rules

### When to Add grep Pattern
- ✅ When capturing to variable: `VAR=$(./tm add "task" | grep -o '[a-f0-9]\{8\}')`
- ❌ When just showing command: `./tm add "task"`
- ❌ When showing output inline

### Correct Examples
```bash
# Capturing ID
TASK_ID=$(./tm add "My task" | grep -o '[a-f0-9]\{8\}')

# Just running command
./tm add "Simple task"

# With dependencies
PARENT=$(./tm add "Parent" | grep -o '[a-f0-9]\{8\}')
./tm add "Child" --depends-on $PARENT
```

## Action Items
1. Update USER_GUIDE.md - ~20 instances
2. Update QUICKSTART-CLAUDE-CODE.md - 5 instances  
3. Verify all examples are executable
4. Test each modified example