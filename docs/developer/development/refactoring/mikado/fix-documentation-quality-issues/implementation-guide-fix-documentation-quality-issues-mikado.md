# Mikado Method Implementation Guide: Fix Documentation Quality Issues

## Pre-Execution Validation
- [ ] Quality gate report reviewed (current score: 72/100)
- [ ] Target score understood (85+/100)
- [ ] All affected files identified
- [ ] Backup created (git status clean)

## Phase 1: Critical Fixes (30 minutes)

### Task 1.1: Fix Version Inconsistencies
- [ ] Search for all version references: `grep -r "2\.5\.[0-1]" docs/ README.md`
- [ ] Replace with v2.6.0 in README.md
- [ ] Replace with v2.6.0 in api-reference.md
- [ ] Replace with v2.6.0 in all reference/*.md files
- [ ] Update version badges if present
- [ ] **VALIDATION**: `grep -r "2\.5\.[0-1]" docs/ README.md` returns nothing
- [ ] Commit: "docs: Fix version inconsistencies to v2.6.0"

### Task 1.2: Add Status Headers to Reference Docs
- [ ] Create status header template:
  ```markdown
  ## Status: Implemented
  ## Last Verified: August 23, 2025
  ```
- [ ] Add to api-reference.md (after title)
- [ ] Add to cli-commands.md
- [ ] Add to database-schema.md
- [ ] Add to all other reference/*.md files (18 total)
- [ ] **VALIDATION**: `grep -L "## Status:" docs/reference/*.md` returns nothing
- [ ] Commit: "docs: Add implementation status headers to reference docs"

### Task 1.3: Create Version Consistency Validation Script
- [ ] Create scripts/validate-version-consistency.sh
- [ ] Add version extraction logic
- [ ] Add comparison logic
- [ ] Add fix option (--fix)
- [ ] Make executable: `chmod +x scripts/validate-version-consistency.sh`
- [ ] **VALIDATION**: Run script - all versions match v2.6.0
- [ ] Commit: "chore: Add version consistency validation script"

## Phase 2: Documentation Updates (1 hour)

### Task 2.1: Document Wizard Command
- [ ] Open docs/reference/cli-commands.md
- [ ] Add section for `tm wizard`
- [ ] Document `tm wizard` (interactive mode)
- [ ] Document `tm wizard --quick` (quick mode)
- [ ] Add examples of template selection
- [ ] Add examples of batch creation
- [ ] Test each example works
- [ ] **VALIDATION**: Run `tm wizard --help` and verify matches docs
- [ ] Update status header with verification date

### Task 2.2: Document Template Commands
- [ ] Add section for `tm template`
- [ ] Document `tm template list`
- [ ] Document `tm template show <name>`
- [ ] Document `tm template apply <name> [vars]`
- [ ] List all 5 available templates
- [ ] Add example of applying bug-fix template
- [ ] Test template commands work
- [ ] **VALIDATION**: Run each template command successfully
- [ ] Update status header

### Task 2.3: Document Hooks Performance Commands
- [ ] Add section for `tm hooks`
- [ ] Document `tm hooks report [hook_name] [days]`
- [ ] Document `tm hooks alerts [severity] [hours]`
- [ ] Document `tm hooks thresholds [warning] [critical] [timeout]`
- [ ] Document `tm hooks cleanup [days]`
- [ ] Add example output for report
- [ ] Test hooks commands work
- [ ] **VALIDATION**: Run `tm hooks report` successfully
- [ ] Update status header

### Task 2.4: Update API Reference with v2.6.0 Methods
- [ ] Open docs/reference/api-reference.md
- [ ] Add TemplateParser class documentation
- [ ] Add TemplateInstantiator class documentation
- [ ] Add InteractiveWizard class documentation
- [ ] Add HookPerformanceMonitor class documentation
- [ ] Document key methods for each class
- [ ] Update version to v2.6.0
- [ ] **VALIDATION**: All new classes have documentation
- [ ] Commit: "docs: Add v2.6.0 features to documentation"

## Phase 3: Validation & Testing (30 minutes)

### Task 3.1: Test All Code Examples
- [ ] Extract all code examples from user-guide.md
- [ ] Run each example in test environment
- [ ] Fix any that don't work
- [ ] Update examples to use v2.6.0 features where relevant
- [ ] Document test results
- [ ] **VALIDATION**: 100% of examples execute successfully
- [ ] Update "Last Verified" date in guide

### Task 3.2: Verify All Documentation Links
- [ ] Run `./scripts/validate-all-doc-links.sh`
- [ ] Fix any broken internal links
- [ ] Fix any broken external links
- [ ] Update moved references
- [ ] **VALIDATION**: Script reports 0 broken links
- [ ] Document in status headers

### Task 3.3: Update Screenshots (if needed)
- [ ] Review current screenshots in user guide
- [ ] Identify outdated ones
- [ ] Capture new screenshots with v2.6.0
- [ ] Replace outdated images
- [ ] Ensure consistent styling
- [ ] **VALIDATION**: Screenshots match current UI
- [ ] Note: Consider text examples instead for maintainability

### Task 3.4: Run Final Quality Gate Check
- [ ] Run documentation quality gate analysis
- [ ] Verify score >= 85/100
- [ ] Review any remaining warnings
- [ ] Document final score
- [ ] **VALIDATION**: Quality score meets target
- [ ] Commit: "docs: Complete documentation quality improvements"

## Final Validation Checklist
- [ ] All version references show v2.6.0
- [ ] All 18 reference docs have status headers
- [ ] Wizard commands fully documented
- [ ] Template commands fully documented
- [ ] Hooks commands fully documented
- [ ] API reference includes new classes
- [ ] All code examples tested and working
- [ ] Zero broken links
- [ ] Quality score >= 85/100
- [ ] All changes committed with clear messages

## Post-Execution
- [ ] Update todo list task to completed
- [ ] Run `git log --oneline -5` to review commits
- [ ] Create summary of improvements made
- [ ] Document actual time vs estimates
- [ ] Note any deviations from plan
- [ ] Archive Mikado artifacts if 100% complete

## Quick Commands Reference
```bash
# Version check
grep -r "2\.5\.[0-1]" docs/ README.md

# Status header check  
grep -L "## Status:" docs/reference/*.md

# Link validation
./scripts/validate-all-doc-links.sh

# Test template command
tm template list

# Test wizard
tm wizard --quick

# Test hooks
tm hooks report
```