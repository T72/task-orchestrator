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

All contributions must include appropriate tests:

1. **Unit Tests**: Test individual functions and methods
2. **Integration Tests**: Test component interactions
3. **Edge Cases**: Test boundary conditions and error cases

```bash
# Run the full test suite
./test_tm.sh          # Basic functionality (must pass 100%)
./test_edge_cases.sh  # Edge cases (aim for >85%)
./stress_test.sh      # Performance tests
python3 test_validation.py  # Validation tests
```

### Database Schema Changes

If your contribution modifies the database schema:
1. Review the current schema in `src/tm_production.py`
2. Add clear comments to your schema changes
3. Create a migration function for backward compatibility
4. Test migration with both new and existing databases
5. Update relevant documentation

### Performance Considerations

- **Database Locking**: Minimize lock duration
- **Query Optimization**: Use efficient SQL queries
- **Memory Usage**: Avoid loading large datasets into memory
- **Concurrent Access**: Test with multiple simultaneous operations

## Pull Request Process

1. **Pre-submission Checklist**
   - [ ] All tests pass
   - [ ] Code follows style guidelines
   - [ ] Documentation updated
   - [ ] Backward compatibility maintained
   - [ ] Changelog updated

2. **Pull Request Description**
   - Clear title describing the change
   - Detailed description of what changed and why
   - Reference related issues
   - Include test results
   - Note any breaking changes

3. **Review Process**
   - Maintainers will review within 48 hours
   - Address feedback promptly
   - Keep discussions constructive
   - Update branch with latest main if needed

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

### High Priority
- Performance optimization for concurrent access
- Enhanced error messages and validation
- Additional export formats
- Documentation improvements

### Medium Priority
- REST API interface
- Web dashboard
- Integration with external tools
- Advanced reporting features

### Low Priority
- GUI application
- Plugin system
- Cloud synchronization
- Mobile companion app

## Getting Help

- **Documentation**: Check the `docs/` directory
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: Request feedback on draft PRs

## Recognition

Contributors will be recognized in:
- Release notes
- README acknowledgments
- Git commit history
- Optional contributors file

Thank you for contributing to Task Orchestrator! Your efforts help make this tool better for everyone.
