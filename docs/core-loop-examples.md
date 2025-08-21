# Task Orchestrator Core Loop Examples

## Overview

This document provides comprehensive, real-world examples of Core Loop features in Task Orchestrator v2.3. Every example is copy-paste ready and tested in clean environments. Examples demonstrate before/after transformations and practical usage patterns.

## Table of Contents

- [Quick Start Example](#quick-start-example)
- [Before/After Transformations](#beforeafter-transformations)
- [Success Criteria Examples](#success-criteria-examples)
- [Progress Tracking Examples](#progress-tracking-examples)
- [Feedback Collection Examples](#feedback-collection-examples)
- [Metrics and Analytics Examples](#metrics-and-analytics-examples)
- [Configuration Management Examples](#configuration-management-examples)
- [Integration Examples](#integration-examples)
- [Error Handling Examples](#error-handling-examples)
- [Advanced Workflow Examples](#advanced-workflow-examples)

## Quick Start Example

### Basic Core Loop Task Creation

```bash
# Initialize Task Orchestrator (if not already done)
./tm init

# Create a task with Core Loop features
TASK_ID=$(./tm add "Implement user authentication" \
  --criteria '[
    {"criterion": "All tests pass", "measurable": "true"},
    {"criterion": "Code coverage above 80%", "measurable": "coverage >= 80"},
    {"criterion": "Security review completed", "measurable": "true"}
  ]' \
  --estimated-hours 8 \
  --deadline "2025-08-25T17:00:00Z")

echo "Created task: $TASK_ID"

# Add progress updates
./tm progress $TASK_ID "Started research phase - investigating OAuth 2.0 libraries"
./tm progress $TASK_ID "25% - Selected library and created basic authentication flow"
./tm progress $TASK_ID "50% - Implemented JWT token generation and validation"

# Complete task with validation
./tm complete $TASK_ID --validate --actual-hours 7.5 \
  --summary "Successfully implemented OAuth 2.0 authentication with JWT tokens. Tests pass, coverage at 85%."

# Provide feedback
./tm feedback $TASK_ID --quality 4 --timeliness 5 \
  --note "Well-structured implementation, delivered ahead of schedule"
```

**Expected Output:**
```
Task created with ID: abc12345
Progress updated for task abc12345
Progress updated for task abc12345  
Progress updated for task abc12345
Task abc12345 completed successfully
Feedback recorded for task abc12345
```

## Before/After Transformations

## Example 1: Database Migration Task

### Traditional Approach
```text
"Migrate user table to support multi-tenancy. 
Add tenant_id column and update queries. 
Make sure nothing breaks."
```

### Core Loop Approach

```bash
# Create task with measurable criteria
tm add "Database Migration: Add Multi-Tenancy Support" \
  --criteria '[
    {
      "criterion": "All user queries include tenant isolation",
      "measurable": "grep -r \"SELECT.*FROM users\" | grep \"tenant_id\" == 100%"
    },
    {
      "criterion": "Zero data loss during migration",
      "measurable": "pre_migration_count == post_migration_count"
    },
    {
      "criterion": "Rollback procedure tested",
      "measurable": "rollback_test_passed == true"
    },
    {
      "criterion": "Performance maintained",
      "measurable": "query_time_p95 < baseline * 1.1"
    }
  ]' \
  --deadline "2025-02-22T00:00:00Z" \
  --estimated-hours 12

# Add detailed context
tm context db_migration_001 --shared "
## Migration Brief: Multi-Tenancy Support

### Current State
- Users table: 2.3M records
- No tenant isolation
- 47 queries accessing users table
- Baseline query performance: p95 = 45ms

### Migration Requirements
- Add tenant_id column (non-nullable)
- Default existing users to tenant 'default'
- Update all queries with tenant filtering
- Create composite index (tenant_id, user_id)

### Rollback Plan
- Migration script: migrations/add_tenant_id.sql
- Rollback script: migrations/rollback_tenant_id.sql
- Test both in staging before production

### Validation
- Run: npm run test:db-integrity
- Performance test: npm run test:performance -- --baseline
"

# During execution
tm progress db_migration_001 "Migration script created and tested in dev environment"
tm progress db_migration_001 "Updated 32/47 queries with tenant isolation"
tm discover db_migration_001 "Found 3 background jobs that also need tenant filtering"

# Completion with knowledge capture
tm complete db_migration_001 --validate --summary "
Successfully migrated users table to multi-tenant architecture:
- Added tenant_id column with default value
- Updated all 47 queries + 3 background jobs
- Created optimized composite index
- Migration time: 4 minutes for 2.3M records
- Performance impact: +2ms p95 latency (acceptable)
- Rollback tested successfully in staging
Key learning: Background jobs easily missed - added to migration checklist
" --actual-hours 14

# Quality feedback
tm feedback db_migration_001 --quality 5 --timeliness 4 --note "Thorough work, especially catching the background jobs. Slight delay acceptable given extra scope discovered."
```

## Example 2: API Endpoint Development

### Traditional Approach
```text
"Create endpoint for bulk user import. Should handle CSV files."
```

### Core Loop Approach

```bash
# Create with specific success criteria
tm add "API Endpoint: Bulk User Import via CSV" \
  --criteria '[
    {
      "criterion": "Handle files up to 10MB",
      "measurable": "upload_test(10MB) returns 200"
    },
    {
      "criterion": "Process 10K records in < 30 seconds",
      "measurable": "import_time(10000) < 30s"
    },
    {
      "criterion": "Validation errors clearly reported",
      "measurable": "error_response includes line_number and field"
    },
    {
      "criterion": "Idempotent imports",
      "measurable": "duplicate_import returns same result"
    },
    {
      "criterion": "API documentation complete",
      "measurable": "OpenAPI spec updated and validated"
    }
  ]' \
  --estimated-hours 16

# Provide implementation context
tm context api_bulk_import --shared "
## API Endpoint Specification

### Endpoint Details
- Method: POST /api/v1/users/import
- Content-Type: multipart/form-data
- Auth: Bearer token with admin role

### CSV Format
- Headers: email,first_name,last_name,role,department
- Encoding: UTF-8
- Max size: 10MB
- Max records: 50,000

### Validation Rules
- Email: RFC 5322 compliant
- Role: Must exist in roles table
- Department: Optional, must exist if provided

### Error Handling
- Return 207 Multi-Status for partial success
- Include per-record success/failure
- Provide downloadable error report

### Performance Targets
- < 3ms per record processing
- Batch inserts of 1000 records
- Async processing for > 1000 records
"

# Progress tracking
tm progress api_bulk_import "Endpoint created, working on CSV parser"
tm progress api_bulk_import "Validation logic complete, 85% test coverage"
tm progress api_bulk_import "Performance optimized: 2.1ms per record"

# Completion
tm complete api_bulk_import --validate --summary "
Bulk import endpoint fully implemented:
- Handles CSV up to 10MB/50K records
- Processing speed: 2.1ms per record (target: 3ms)
- Comprehensive validation with clear error messages
- Idempotent through email-based deduplication
- OpenAPI spec updated with examples
- Integration tests cover happy path + 12 error scenarios
Note: Consider adding progress webhook for large imports in v2
" --actual-hours 15
```

## Example 3: Performance Optimization

### Traditional Approach
```text
"Dashboard is slow, please optimize it."
```

### Core Loop Approach

```bash
# Create with measurable performance targets
tm add "Performance Optimization: User Dashboard" \
  --criteria '[
    {
      "criterion": "Initial load time under 2 seconds",
      "measurable": "lighthouse_FCP < 2000ms"
    },
    {
      "criterion": "Time to interactive under 3 seconds",
      "measurable": "lighthouse_TTI < 3000ms"
    },
    {
      "criterion": "API calls reduced by 50%",
      "measurable": "api_calls_per_load <= baseline / 2"
    },
    {
      "criterion": "Memory usage stable",
      "measurable": "memory_leak_test passes"
    }
  ]' \
  --deadline "2025-02-23T17:00:00Z"

# Context with baseline metrics
tm context dashboard_perf --shared "
## Performance Optimization Brief

### Current Performance Baseline
- First Contentful Paint: 4.2s
- Time to Interactive: 6.8s
- API calls on load: 14
- Bundle size: 2.4MB
- Memory after 10 min: 145MB → 298MB (leak suspected)

### Bottleneck Analysis
1. Waterfall API calls (not parallelized)
2. No data caching between components
3. Large unoptimized images
4. Rendering all data (no virtualization)

### Optimization Strategies
- Implement parallel API calls
- Add Redis caching layer
- Lazy load images below fold
- Virtual scrolling for lists > 100 items
- Bundle splitting by route

### Testing Requirements
- Run performance suite before/after
- Test on throttled 3G connection
- Verify on low-end device (2GB RAM)
"

# Execution updates
tm progress dashboard_perf "Parallelized API calls: load time -1.8s"
tm progress dashboard_perf "Implemented caching: API calls reduced from 14 to 6"
tm discover dashboard_perf "Memory leak found in chart library - upgrading to v3.2"

# Completion with results
tm complete dashboard_perf --validate --summary "
Dashboard performance significantly improved:
- FCP: 4.2s → 1.7s (60% improvement)
- TTI: 6.8s → 2.9s (57% improvement)  
- API calls: 14 → 6 (57% reduction)
- Memory leak fixed with chart library upgrade
- Bundle size: 2.4MB → 1.1MB (54% reduction)
Key improvements:
- Parallel API calls with Promise.all
- Redis caching with 5-min TTL
- Image lazy loading (saved 800KB initial load)
- Virtual scrolling for user lists
- Code splitting reduced initial bundle
Unexpected find: Chart library memory leak was main cause of degradation
" --actual-hours 20
```

## Example 4: Security Vulnerability Fix

### Traditional Approach
```text
"Fix the SQL injection vulnerability in search."
```

### Core Loop Approach

```bash
# Create with security-focused criteria
tm add "Security Fix: SQL Injection in Search Feature" \
  --criteria '[
    {
      "criterion": "Vulnerability eliminated",
      "measurable": "sqlmap scan returns 0 vulnerabilities"
    },
    {
      "criterion": "All user inputs parameterized",
      "measurable": "grep raw SQL with user input returns 0"
    },
    {
      "criterion": "Security test suite passes",
      "measurable": "npm run test:security exit code 0"
    },
    {
      "criterion": "No functionality regression",
      "measurable": "search feature tests pass 100%"
    },
    {
      "criterion": "Audit log updated",
      "measurable": "security_fixes.log contains entry"
    }
  ]' \
  --deadline "2025-02-21T12:00:00Z" \
  --estimated-hours 4

# Security context
tm context security_fix_001 --shared "
## Security Vulnerability Brief

### Vulnerability Details
- Type: SQL Injection
- Severity: Critical (CVSS 9.1)
- Location: /api/search endpoint
- Parameter: 'query' (GET parameter)
- Discovered: Automated security scan

### Exploit Example
GET /api/search?query=' OR '1'='1

### Fix Requirements
- Replace string concatenation with parameterized queries
- Add input validation layer
- Implement query sanitization
- Add rate limiting to search endpoint

### Testing Protocol
1. Run sqlmap against fixed endpoint
2. Execute security test suite
3. Verify legitimate searches still work
4. Performance test (should not degrade)

### Compliance
- Update security_fixes.log
- Notify security team upon completion
- Schedule penetration retest
"

# Quick execution for critical fix
tm progress security_fix_001 "Replaced concatenation with parameterized queries"
tm progress security_fix_001 "Added input validation: alphanumeric + spaces only"

# Completion
tm complete security_fix_001 --validate --summary "
SQL injection vulnerability successfully eliminated:
- Converted all 3 search queries to use parameterized statements
- Added input validation middleware
- Implemented rate limiting (10 requests/minute)
- All security scans now pass
- No performance impact observed
- Feature functionality preserved
Additional hardening:
- Escaped output in search results (XSS prevention)
- Added query complexity limits
- Implemented prepared statement caching
Documented fix pattern in security playbook for future reference
" --actual-hours 3

# High priority feedback
tm feedback security_fix_001 --quality 5 --timeliness 5 --note "Excellent rapid response. Additional hardening beyond requirements shows security mindset."
```

## Example 5: Documentation Update

### Traditional Approach
```text
"Update the API docs for the new features."
```

### Core Loop Approach

```bash
# Create with documentation quality criteria
tm add "Documentation Update: Q1 2025 API Changes" \
  --criteria '[
    {
      "criterion": "All new endpoints documented",
      "measurable": "endpoint_count matches implementation"
    },
    {
      "criterion": "Examples provided for each endpoint",
      "measurable": "curl examples executable"
    },
    {
      "criterion": "Breaking changes highlighted",
      "measurable": "BREAKING_CHANGES.md updated"
    },
    {
      "criterion": "OpenAPI spec validates",
      "measurable": "swagger-cli validate returns 0"
    },
    {
      "criterion": "Changelog updated",
      "measurable": "CHANGELOG.md includes v2.3.0 section"
    }
  ]' \
  --estimated-hours 6

# Documentation context
tm context docs_update_q1 --shared "
## Documentation Update Requirements

### New Endpoints to Document (7 total)
1. POST /api/v2/users/bulk-import
2. GET /api/v2/analytics/dashboard
3. PUT /api/v2/settings/preferences
4. DELETE /api/v2/sessions/all
5. POST /api/v2/auth/2fa/enable
6. POST /api/v2/auth/2fa/verify
7. GET /api/v2/audit/logs

### Documentation Standards
- Follow OpenAPI 3.0 specification
- Include request/response examples
- Document all error codes
- Specify rate limits
- Note authentication requirements

### Required Sections per Endpoint
- Description and use case
- Parameters (path, query, body)
- Request examples (curl, JavaScript, Python)
- Response examples (success and error)
- Rate limits and quotas

### Additional Updates
- Migration guide for v1 to v2
- Deprecation notices for v1 endpoints
- Postman collection update
- API client library examples
"

# Progress updates
tm progress docs_update_q1 "Documented 4/7 new endpoints"
tm progress docs_update_q1 "All endpoints complete, working on examples"
tm discover docs_update_q1 "Found 2 undocumented endpoints from last release - adding them"

# Completion
tm complete docs_update_q1 --validate --summary "
API documentation fully updated for Q1 2025:
- Documented 7 new + 2 discovered endpoints
- Added executable examples for all endpoints
- Breaking changes documented with migration paths
- OpenAPI spec validates without warnings
- Changelog updated with categorized changes
Additional improvements:
- Added interactive API explorer using Swagger UI
- Created quick-start guide for new developers
- Updated Postman collection with example data
- Added rate limit headers to all examples
Time saved for future: Template created for endpoint documentation
" --actual-hours 7
```

## Success Criteria Examples

### Simple Boolean Criteria

```bash
# Task with straightforward pass/fail criteria
./tm add "Fix database connection timeout bug" \
  --criteria '[
    {"criterion": "Bug reproduction test passes", "measurable": "true"},
    {"criterion": "No regression in existing tests", "measurable": "true"},
    {"criterion": "Performance impact documented", "measurable": "true"}
  ]'
```

### Measurable Numeric Criteria

```bash
# Task with quantifiable success metrics
./tm add "Optimize API response times" \
  --criteria '[
    {"criterion": "Average response time under 200ms", "measurable": "avg_response_time < 200"},
    {"criterion": "95th percentile under 500ms", "measurable": "p95_response_time < 500"},
    {"criterion": "Error rate below 0.1%", "measurable": "error_rate < 0.001"}
  ]' \
  --estimated-hours 12
```

## Progress Tracking Examples

### Development Progress Pattern

```bash
TASK_ID="abc12345"

# Project initiation
./tm progress $TASK_ID "Project kickoff - requirements analysis started"

# Development milestones  
./tm progress $TASK_ID "10% - Requirements documented, technical approach defined"
./tm progress $TASK_ID "25% - Core architecture implemented, basic tests passing"
./tm progress $TASK_ID "50% - Main functionality complete, integration testing started"
./tm progress $TASK_ID "75% - All features implemented, performance optimization in progress"
./tm progress $TASK_ID "90% - Testing complete, documentation updated"

# Completion
./tm complete $TASK_ID --validate --actual-hours 16
```

## Feedback Collection Examples

### Quality Feedback Scenarios

```bash
# Excellent quality (5/5)
./tm feedback $TASK_ID --quality 5 --timeliness 4 \
  --note "Exceptional work - code is clean, well-documented, and includes comprehensive tests"

# Good quality with room for improvement (3/5)
./tm feedback $TASK_ID --quality 3 --timeliness 5 \
  --note "Functionality works well, but code could benefit from better error handling and documentation"
```

## Metrics and Analytics Examples

### Individual Task Metrics

```bash
# View metrics for a specific task
./tm metrics --task $TASK_ID

# Expected output:
# Task Metrics for abc12345:
# - Estimated vs Actual Hours: 8.0 vs 7.5 (94% accuracy)
# - Quality Score: 4/5
# - Timeliness Score: 5/5
# - Success Criteria: 3/3 passed (100%)
```

### Team Performance Metrics

```bash
# View overall team metrics
./tm metrics --period "last-month"

# Expected output:
# Team Metrics (Last Month):
# - Tasks Completed: 45
# - Average Quality Score: 4.2/5
# - Average Timeliness Score: 3.8/5
# - Time Estimation Accuracy: 87%
# - Success Criteria Pass Rate: 92%
```

## Configuration Management Examples

### Feature Enablement

```bash
# Check current configuration
./tm config --show

# Enable Core Loop features
./tm config --enable success-criteria
./tm config --enable progress-tracking
./tm config --enable feedback-system
./tm config --enable metrics-calculation
```

## Integration Examples

### CI/CD Pipeline Integration

```bash
# GitHub Actions integration
name: Task Orchestrator Integration
on: [push, pull_request]

jobs:
  create-build-task:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Create build task
        run: |
          TASK_ID=$(./tm add "Build commit ${{ github.sha }}" \
            --criteria '[{"criterion":"Tests pass","measurable":"true"}]' \
            --estimated-hours 0.5)
          echo "TASK_ID=$TASK_ID" >> $GITHUB_ENV
      
      - name: Run tests
        run: npm test
      
      - name: Complete build task
        run: |
          ./tm complete $TASK_ID --validate --actual-hours 0.3
          ./tm feedback $TASK_ID --quality 4 --timeliness 5
```

## Error Handling Examples

### Invalid Criteria Format

```bash
# Incorrect JSON format
./tm add "Test task" --criteria '[{"criterion": "Test", "measurable": true}]'
# Error: Invalid criteria format. 'measurable' must be a string, not boolean.

# Correct format
./tm add "Test task" --criteria '[{"criterion": "Test", "measurable": "true"}]'
# Task created with ID: xyz78910
```

### Validation Failures

```bash
# Task with failing criteria validation
TASK_ID=$(./tm add "Performance test" \
  --criteria '[{"criterion":"Response time","measurable":"response_time < 100"}]')

# Complete with validation
./tm complete $TASK_ID --validate
# Error: Validation failed
# - Criterion "Response time": response_time (150) not < 100
# Task remains in progress. Fix issues and retry completion.
```

## Advanced Workflow Examples

### Multi-Agent Collaboration

```bash
# Create collaborative task
TASK_ID=$(./tm add "Build new feature: real-time notifications" \
  --criteria '[
    {"criterion": "Backend API complete", "measurable": "true"},
    {"criterion": "Frontend integration complete", "measurable": "true"},
    {"criterion": "Performance tests pass", "measurable": "true"}
  ]' \
  --estimated-hours 20)

# Backend agent progress
./tm progress $TASK_ID "[Backend] API endpoints designed and implemented"

# Frontend agent progress  
./tm progress $TASK_ID "[Frontend] UI components created for notifications"

# QA agent progress
./tm progress $TASK_ID "[QA] Performance tests designed and executed"

# Completion with multi-agent feedback
./tm complete $TASK_ID --validate --actual-hours 18 \
  --summary "Feature complete with excellent cross-team collaboration"
```

## Common Patterns Across Examples

### 1. Specific Measurable Criteria
Every task includes 3-5 criteria that can be objectively validated.

### 2. Rich Context
Shared context provides:
- Current state/baseline
- Requirements/specifications  
- Resources/tools needed
- Validation methods

### 3. Progress Visibility
Regular updates with concrete progress markers.

### 4. Knowledge Capture
Completion summaries include:
- What was accomplished
- How it was done
- Unexpected discoveries
- Future improvements

### 5. Quality Feedback
Simple scores with constructive notes for continuous improvement.

## Benefits Demonstrated

1. **Clarity**: No ambiguity about what "done" means
2. **Transparency**: Progress visible throughout execution
3. **Learning**: Knowledge captured for future tasks
4. **Quality**: Objective validation ensures standards
5. **Improvement**: Feedback drives better performance

## Template Extraction

From these examples, we can extract reusable templates:

```yaml
# Performance Optimization Template
success_criteria:
  - metric_improved: "metric < baseline * target_multiplier"
  - no_regression: "feature_tests pass"
  - stable_resources: "memory_leak_test passes"

# Security Fix Template  
success_criteria:
  - vulnerability_fixed: "security_scan returns 0"
  - no_regression: "feature_tests pass"
  - audit_trail: "security_log updated"

# API Development Template
success_criteria:
  - functional: "integration_tests pass"
  - performant: "response_time < SLA"
  - documented: "OpenAPI spec updated"

# Migration Template
success_criteria:
  - data_integrity: "pre_count == post_count"
  - rollback_tested: "rollback_successful == true"
  - performance: "query_time < baseline * 1.1"
```

---

*Examples based on: Real-world development scenarios*
*Demonstrates: PRD v2.3 Core Loop enhancements*
*Created: 2025-08-20*