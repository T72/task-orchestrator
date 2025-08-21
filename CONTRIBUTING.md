# Contributing to Task Orchestrator

Thank you for your interest in contributing to Task Orchestrator! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to maintain a respectful, inclusive, and collaborative environment. We welcome contributions from everyone regardless of background, experience level, or identity.

## How to Contribute

### Reporting Issues

Before creating a new issue, please:
1. Search existing issues to avoid duplicates
2. Use a clear, descriptive title
3. Provide detailed reproduction steps
4. Include system information (OS, Python version)
5. Add relevant logs or error messages

### Suggesting Features

We welcome feature suggestions! Please:
1. Check if the feature already exists or is planned
2. Describe the use case and benefit
3. Provide implementation ideas if you have them
4. Consider backward compatibility

### Contributing Code

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/task-orchestrator.git
   cd task-orchestrator
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set Up Development Environment**
   ```bash
   # Make sure you have Python 3.8+
   python3 --version
   
   # Run tests to ensure everything works
   ./test_tm.sh
   ./test_edge_cases.sh
   ```

## Development Guidelines

### Code Style

- **Python Version**: Python 3.8+ compatibility required
- **Standard Library Only**: No external dependencies for core functionality
- **PEP 8**: Follow Python style guidelines
- **Type Hints**: Use type hints for function signatures
- **Docstrings**: Document all public functions and classes

Example:
```python
def add_task(title: str, priority: Priority = Priority.MEDIUM) -> str:
    """Add a new task to the database.
    
    Args:
        title: The task title (required, non-empty)
        priority: Task priority level (default: MEDIUM)
        
    Returns:
        The unique task ID
        
    Raises:
        ValidationError: If title is empty or invalid
    """
```

### Testing Requirements

All contributions must include appropriate tests, especially for Core Loop features:

#### Core Loop Test Requirements

**1. Success Criteria Testing**
- Test valid and invalid criteria JSON formats
- Test criteria validation logic
- Test completion with and without validation
- Test edge cases for measurable expressions

**2. Feedback System Testing**
- Test quality and timeliness score validation (1-5 range)
- Test feedback note length limits
- Test one feedback per task enforcement
- Test metrics aggregation accuracy

**3. Configuration Testing**
- Test feature enable/disable functionality
- Test minimal mode behavior
- Test configuration persistence
- Test invalid configuration handling

**4. Migration Testing**
- Test schema upgrades and rollbacks
- Test data preservation during migration
- Test idempotent migration behavior
- Test backup creation and restoration

#### Test Execution

```bash
# Core Loop test suite (required for Core Loop features)
./tests/run_core_loop_tests.sh

# Individual Core Loop test categories
./tests/test_core_loop_success_criteria.sh
./tests/test_core_loop_feedback.sh
./tests/test_core_loop_schema.sh
./tests/test_core_loop_configuration.sh
./tests/test_core_loop_migration.sh
./tests/test_core_loop_integration.sh

# Legacy test suite (still required)
./test_tm.sh          # Basic functionality (must pass 100%)
./test_edge_cases.sh  # Edge cases (aim for >85%)
./stress_test.sh      # Performance tests
```

#### Test Coverage Requirements

- **Core Loop Features**: 100% test coverage required
- **New API Methods**: 95% line coverage minimum
- **Integration Points**: All major workflows tested
- **Error Conditions**: All error paths validated
- **WSL Compatibility**: Tests must pass in WSL environment

### Database Schema Changes

Core Loop features extend the database schema. If your contribution modifies the schema:

#### Migration Requirements
1. **Create Migration Script**: Use `src/migrations/` directory
2. **Idempotent Operations**: Migrations must be safely re-runnable
3. **Backward Compatibility**: New fields must be nullable or have defaults
4. **Rollback Capability**: Provide rollback procedures for all changes
5. **Test Data Preservation**: Verify no data loss during migration

#### Core Loop Schema Considerations
- **JSON Fields**: Use TEXT type for flexible schema evolution
- **Index Strategy**: Add indexes for performance-critical queries
- **Constraint Validation**: Use CHECK constraints for data integrity
- **Field Naming**: Follow existing naming conventions

#### Migration Testing Process
```bash
# Test migration on sample database
./tm migrate --dry-run                    # Preview changes
./tm migrate --backup                     # Create backup
./tm migrate --apply                      # Apply migration
./tm migrate --validate                   # Verify integrity

# Test rollback capability
./tm migrate --rollback                   # Rollback if needed
```

#### Schema Documentation
- Update `reference/database-schema.md`
- Include ER diagrams for complex relationships
- Document all new fields and their purposes
- Provide query examples for new capabilities

### Performance Considerations

- **Database Locking**: Minimize lock duration
- **Query Optimization**: Use efficient SQL queries
- **Memory Usage**: Avoid loading large datasets into memory
- **Concurrent Access**: Test with multiple simultaneous operations

## Pull Request Process

### Core Loop Feature Contributions

**Special Requirements for Core Loop Features:**

1. **Pre-submission Checklist (Extended for Core Loop)**
   - [ ] All Core Loop tests pass (`./tests/run_core_loop_tests.sh`)
   - [ ] Legacy tests still pass (`./test_tm.sh`)
   - [ ] Code follows Core Loop coding standards
   - [ ] Success criteria properly validated
   - [ ] Migration scripts tested and documented
   - [ ] Feature toggles implemented correctly
   - [ ] WSL compatibility verified
   - [ ] Documentation updated (API reference, examples, schemas)
   - [ ] Backward compatibility maintained
   - [ ] Performance regression tests pass

2. **Core Loop Pull Request Template**
   ```markdown
   ## Core Loop Feature: [Feature Name]
   
   ### Description
   Brief description of the Core Loop enhancement
   
   ### Changes Made
   - [ ] Success criteria validation
   - [ ] Feedback collection
   - [ ] Progress tracking
   - [ ] Metrics calculation
   - [ ] Configuration management
   - [ ] Database schema updates
   - [ ] Migration scripts
   
   ### Testing Completed
   - [ ] Core Loop test suite passes
   - [ ] Edge cases tested
   - [ ] WSL environment tested
   - [ ] Performance impact assessed
   - [ ] Migration tested (upgrade + rollback)
   
   ### Documentation Updated
   - [ ] API documentation
   - [ ] Schema documentation
   - [ ] User guide examples
   - [ ] Migration guide
   
   ### Backward Compatibility
   - [ ] Existing tasks unaffected
   - [ ] Legacy API maintains functionality
   - [ ] Optional feature (can be disabled)
   - [ ] Migration preserves data integrity
   
   ### Performance Impact
   - [ ] No significant performance regression
   - [ ] Database query optimization considered
   - [ ] Memory usage impact assessed
   
   ### Configuration
   - [ ] Feature toggle implemented
   - [ ] Default configuration specified
   - [ ] Minimal mode compatibility
   ```

3. **Review Process (Enhanced)**
   - **Initial Review**: Within 24 hours for Core Loop features
   - **Core Loop Specialist Review**: Required for all Core Loop changes
   - **Integration Testing**: Automated testing in multiple environments
   - **Documentation Review**: Ensure examples and documentation accuracy
   - **Performance Review**: Assess impact on system performance
   - **Security Review**: Validate input sanitization and data protection

## Release Process

Releases follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Development Setup

### Required Tools
- Python 3.8+
- Git
- Text editor or IDE
- Shell/terminal access

### Testing Locally
```bash
# Quick smoke test
./tm init
./tm add "Test task"
./tm list

# Full test suite
./test_tm.sh && echo "Basic tests passed"
./test_edge_cases.sh && echo "Edge cases passed"
```

### Debugging
- Use Python's built-in `pdb` for debugging
- Add verbose logging for complex operations
- Test with sample databases

## Areas for Contribution

### Core Loop Enhancement Opportunities

**High Priority - Core Loop Features:**
- Advanced success criteria expressions and operators
- Custom metrics calculators and aggregation functions
- Enhanced feedback analytics and trend analysis
- Integration with external quality measurement tools
- Performance optimization for large task volumes
- Advanced configuration management and presets

**Medium Priority - Core Loop Extensions:**
- Real-time collaboration features for shared contexts
- Automated task creation from external systems
- Advanced reporting and dashboard capabilities
- Machine learning for estimation improvement
- Integration with CI/CD systems and workflows
- Mobile-friendly progress tracking interfaces

**Core Loop Documentation:**
- Additional workflow pattern examples
- Integration guides for popular development tools
- Video tutorials for complex Core Loop workflows
- Best practices guides for different team sizes
- Troubleshooting guides for common issues

### Legacy System Improvements

**High Priority:**
- Performance optimization for concurrent access
- Enhanced error messages and validation
- Additional export formats
- Documentation improvements

**Medium Priority:**
- REST API interface
- Web dashboard
- Integration with external tools
- Advanced reporting features

**Low Priority:**
- GUI application
- Plugin system
- Cloud synchronization
- Mobile companion app

### Contributing to Core Loop vs Legacy Features

**Core Loop Contributions** require:
- Understanding of quality measurement principles
- Knowledge of feedback systems and metrics
- Familiarity with configuration management patterns
- Experience with database schema evolution

**Legacy Contributions** require:
- Understanding of existing task management workflows
- Familiarity with SQLite and Python development
- Knowledge of command-line interface design
- Experience with testing and documentation

## Getting Help

### Core Loop Development Resources

- **Core Loop Documentation**: 
  - API Reference: `docs/developer/api/core-loop-api-reference.md`
  - Database Schema: `reference/database-schema.md`
  - Architecture Guide: `docs/developer/architecture/core-loop-architecture.md`
  - Examples: `docs/examples/core-loop-examples.md`
  - Test Documentation: `tests/README-CORE-LOOP-TESTS.md`

- **Workflow Examples**:
  - Team Collaboration: `docs/examples/workflows/team-collaboration-patterns.md`
  - Quality Assurance: `docs/examples/workflows/quality-assurance-workflows.md`
  - Automation Integration: `docs/examples/workflows/automation-integration-examples.md`

### General Resources

- **Documentation**: Check the `docs/` directory
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: Request feedback on draft PRs

### Core Loop Specific Help

- **Test Failures**: Check `tests/README-CORE-LOOP-TESTS.md` for debugging guidance
- **Migration Issues**: Refer to migration documentation and use `--dry-run` first
- **Configuration Problems**: Review `docs/configuration/config-guide.md`
- **Performance Concerns**: Review architecture documentation and optimization guides

## Recognition

Contributors will be recognized in:
- Release notes
- README acknowledgments
- Git commit history
- Optional contributors file

Thank you for contributing to Task Orchestrator! Your efforts help make this tool better for everyone.
