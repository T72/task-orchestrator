# Team Collaboration Workflow Patterns

## Overview

This document provides proven workflow patterns for multi-agent collaboration using Task Orchestrator Core Loop features. These patterns have been tested in real-world scenarios and optimize for transparency, coordination, and knowledge sharing.

## Table of Contents

- [Multi-Agent Feature Development](#multi-agent-feature-development)
- [Cross-Team Integration Workflows](#cross-team-integration-workflows)
- [Knowledge Transfer Patterns](#knowledge-transfer-patterns)
- [Dependency Management Workflows](#dependency-management-workflows)
- [Emergency Response Coordination](#emergency-response-coordination)
- [Quality Handoff Patterns](#quality-handoff-patterns)

## Multi-Agent Feature Development

### Pattern: Parallel Specialization with Coordination Points

**Scenario**: Building a complete user authentication system with multiple specialists.

#### Phase 1: Initial Coordination

```bash
# Orchestrating agent creates master task
MASTER_TASK=$(./tm add "User Authentication System v2.0" \
  --criteria '[
    {"criterion": "All components integrated", "measurable": "true"},
    {"criterion": "Security audit passed", "measurable": "true"},
    {"criterion": "Performance targets met", "measurable": "response_time < 200"},
    {"criterion": "Documentation complete", "measurable": "true"}
  ]' \
  --estimated-hours 40 \
  --deadline "2025-09-01T17:00:00Z")

# Create specialist tasks with dependencies
DB_TASK=$(./tm add "Database: User authentication schema" \
  --criteria '[
    {"criterion": "Schema migration tested", "measurable": "true"},
    {"criterion": "Indexes optimized", "measurable": "query_time < 50"},
    {"criterion": "Backup strategy documented", "measurable": "true"}
  ]' \
  --estimated-hours 8 \
  --assignee "database-specialist")

API_TASK=$(./tm add "Backend: Authentication API endpoints" \
  --depends-on $DB_TASK \
  --criteria '[
    {"criterion": "All endpoints tested", "measurable": "test_coverage >= 95"},
    {"criterion": "JWT implementation secure", "measurable": "security_scan_passed == true"},
    {"criterion": "Rate limiting implemented", "measurable": "true"}
  ]' \
  --estimated-hours 12 \
  --assignee "backend-specialist")

UI_TASK=$(./tm add "Frontend: Authentication UI components" \
  --depends-on $API_TASK \
  --criteria '[
    {"criterion": "Responsive design", "measurable": "mobile_tests_pass == true"},
    {"criterion": "Accessibility compliant", "measurable": "a11y_score >= 95"},
    {"criterion": "Error handling complete", "measurable": "true"}
  ]' \
  --estimated-hours 10 \
  --assignee "frontend-specialist")

# Set up shared context for coordination
./tm context $MASTER_TASK --shared "
# Authentication System Coordination

## Architecture Overview
- JWT-based authentication with refresh tokens
- Rate limiting: 5 requests/minute for login attempts
- Multi-factor authentication support
- OAuth 2.0 integration for social login

## Integration Points
1. Database schema must support OAuth providers
2. API must expose standardized error codes
3. Frontend must handle all error scenarios gracefully

## Security Requirements
- Passwords hashed with bcrypt (cost factor 12)
- JWT tokens expire in 15 minutes
- Refresh tokens expire in 7 days
- Failed login lockout after 5 attempts

## Communication Protocol
- Daily standup updates in shared context
- Immediate notification for blockers
- Integration testing after each component completion
"
```

#### Phase 2: Coordinated Execution

```bash
# Database specialist execution
./tm progress $DB_TASK "Schema design complete - supports OAuth and MFA"
./tm progress $DB_TASK "Migration scripts tested in dev environment"
./tm progress $DB_TASK "Performance optimized - user lookup in 15ms avg"

# Backend specialist waits for database completion, then proceeds
./tm complete $DB_TASK --validate --actual-hours 7 \
  --summary "Database schema implemented with full OAuth support and optimized indexes"

# Backend specialist can now start
./tm progress $API_TASK "API endpoints designed based on database schema"
./tm progress $API_TASK "JWT implementation complete with proper expiration"
./tm progress $API_TASK "Rate limiting middleware integrated"

# Frontend specialist coordinates with backend
./tm progress $UI_TASK "UI components designed, waiting for API documentation"
./tm context $UI_TASK --shared "
## Frontend Integration Notes
- Need API endpoint documentation for error codes
- Require test user accounts for development
- JWT token refresh pattern needs clarification
"

# Backend provides needed information
./tm context $API_TASK --shared "
## API Documentation for Frontend
- Error codes: 401 (invalid), 429 (rate limited), 423 (locked)
- Test accounts: user1@test.com / user2@test.com (password: Test123!)
- JWT refresh: Use /auth/refresh endpoint when token expires
"

# Frontend can now proceed
./tm progress $UI_TASK "API integration complete, all error scenarios handled"
./tm progress $UI_TASK "Accessibility testing passed - WCAG 2.1 AA compliant"
```

#### Phase 3: Integration and Completion

```bash
# Integration testing
./tm progress $MASTER_TASK "All components complete, starting integration testing"
./tm progress $MASTER_TASK "End-to-end testing passed - full workflow functional"
./tm progress $MASTER_TASK "Security audit scheduled for tomorrow"
./tm progress $MASTER_TASK "Performance testing shows 150ms avg response time"

# Complete individual tasks with feedback
./tm complete $API_TASK --validate --actual-hours 11 \
  --summary "Authentication API fully implemented with comprehensive security measures"

./tm feedback $API_TASK --quality 5 --timeliness 4 \
  --note "Excellent security implementation. Minor delay due to additional MFA features."

./tm complete $UI_TASK --validate --actual-hours 9 \
  --summary "User interface complete with excellent accessibility and error handling"

./tm feedback $UI_TASK --quality 4 --timeliness 5 \
  --note "Great accessibility work. Delivered ahead of schedule with clean code."

# Complete master task
./tm complete $MASTER_TASK --validate --actual-hours 35 \
  --summary "Authentication system fully integrated and tested. Exceeds performance targets."

./tm feedback $MASTER_TASK --quality 5 --timeliness 4 \
  --note "Outstanding cross-team collaboration. System exceeds all requirements."
```

### Pattern Benefits

- **Clear Dependencies**: Each specialist knows what they're waiting for
- **Shared Context**: All team members have access to coordination information
- **Progress Transparency**: Real-time visibility into each component's progress
- **Knowledge Capture**: Lessons learned and decisions documented
- **Quality Feedback**: Continuous improvement through structured feedback

## Cross-Team Integration Workflows

### Pattern: API Contract-First Development

**Scenario**: Frontend and backend teams working on new feature with API contract.

```bash
# Step 1: Define API contract collaboratively
CONTRACT_TASK=$(./tm add "API Contract: User Profile Management" \
  --criteria '[
    {"criterion": "OpenAPI spec complete", "measurable": "swagger_validate == 0_errors"},
    {"criterion": "Mock server running", "measurable": "mock_endpoints_responsive == true"},
    {"criterion": "Frontend tests pass against mock", "measurable": "integration_tests_pass == true"}
  ]' \
  --estimated-hours 4)

# Step 2: Parallel development with contract validation
BACKEND_IMPL=$(./tm add "Backend: Implement profile API" \
  --depends-on $CONTRACT_TASK \
  --criteria '[
    {"criterion": "Matches OpenAPI contract", "measurable": "contract_test_pass == true"},
    {"criterion": "Database integration complete", "measurable": "true"}
  ]' \
  --estimated-hours 8 \
  --assignee "backend-team")

FRONTEND_IMPL=$(./tm add "Frontend: Profile management UI" \
  --depends-on $CONTRACT_TASK \
  --criteria '[
    {"criterion": "Works with mock API", "measurable": "mock_tests_pass == true"},
    {"criterion": "Error handling complete", "measurable": "true"}
  ]' \
  --estimated-hours 6 \
  --assignee "frontend-team")

# Step 3: Contract definition with shared context
./tm context $CONTRACT_TASK --shared "
# API Contract Definition

## Endpoints
- GET /api/users/{id}/profile - Retrieve user profile
- PUT /api/users/{id}/profile - Update user profile
- POST /api/users/{id}/avatar - Upload avatar image

## Data Models
- Profile: {id, email, firstName, lastName, avatarUrl, preferences}
- Preferences: {theme, language, notifications, privacy}

## Error Handling
- 400: Validation errors with field-specific messages
- 404: User not found
- 413: Avatar file too large (max 5MB)
- 422: Invalid image format (accept: jpg, png, gif)

## Validation Rules
- firstName/lastName: 2-50 characters, letters only
- Email: RFC 5322 compliant
- Avatar: Max 5MB, square aspect ratio preferred
"

# Step 4: Coordinated execution
./tm progress $CONTRACT_TASK "OpenAPI specification drafted"
./tm progress $CONTRACT_TASK "Mock server configured with realistic data"
./tm progress $CONTRACT_TASK "Contract tests created for validation"

# Both teams can now work in parallel
./tm progress $BACKEND_IMPL "Database models created matching contract"
./tm progress $FRONTEND_IMPL "UI components built against mock API"

# Integration point
./tm complete $CONTRACT_TASK --validate --actual-hours 3
./tm complete $BACKEND_IMPL --validate --actual-hours 7
./tm complete $FRONTEND_IMPL --validate --actual-hours 6

# Final integration testing
INTEGRATION_TASK=$(./tm add "Integration: Profile management E2E testing" \
  --depends-on $BACKEND_IMPL,$FRONTEND_IMPL \
  --criteria '[
    {"criterion": "All user flows work", "measurable": "e2e_tests_pass == true"},
    {"criterion": "Performance acceptable", "measurable": "page_load < 2000"}
  ]' \
  --estimated-hours 2)
```

## Knowledge Transfer Patterns

### Pattern: Documentation-Driven Handoffs

**Scenario**: Transferring complex system knowledge between agents.

```bash
# Knowledge capture task
KNOWLEDGE_TASK=$(./tm add "Knowledge Transfer: Payment Processing System" \
  --criteria '[
    {"criterion": "Architecture documented", "measurable": "true"},
    {"criterion": "Runbook complete", "measurable": "true"},
    {"criterion": "Handoff session completed", "measurable": "true"},
    {"criterion": "New agent can deploy independently", "measurable": "deploy_test_pass == true"}
  ]' \
  --estimated-hours 6 \
  --assignee "outgoing-agent")

# Knowledge consumption task
ONBOARDING_TASK=$(./tm add "Onboarding: Payment System Ownership" \
  --depends-on $KNOWLEDGE_TASK \
  --criteria '[
    {"criterion": "System architecture understood", "measurable": "true"},
    {"criterion": "Can troubleshoot common issues", "measurable": "troubleshoot_test_pass == true"},
    {"criterion": "Deployment process mastered", "measurable": "successful_deploy == true"}
  ]' \
  --estimated-hours 8 \
  --assignee "incoming-agent")

# Structured knowledge transfer
./tm context $KNOWLEDGE_TASK --shared "
# Payment Processing System Knowledge Transfer

## System Overview
- Stripe integration for credit card processing
- PayPal integration for alternative payments
- Internal billing service for subscription management
- Webhook handling for payment status updates

## Critical Components
1. Payment Gateway Service (port 8080)
2. Webhook Processor (port 8081)
3. Billing Database (PostgreSQL)
4. Redis Cache for session data

## Common Issues and Solutions
- Webhook timeout: Check Redis connectivity
- Failed payments: Verify Stripe API keys in production
- Duplicate charges: Review idempotency key generation
- Database locks: Monitor long-running transactions

## Deployment Process
1. Run database migrations
2. Deploy payment service (blue-green)
3. Update webhook endpoints
4. Verify payment flow in staging
5. Monitor error rates for 24 hours

## Emergency Contacts
- Stripe Support: support@stripe.com
- PayPal Technical: developer.paypal.com
- Internal DBA: db-team@company.com
"

# Progress tracking with verification
./tm progress $KNOWLEDGE_TASK "System architecture diagram created"
./tm progress $KNOWLEDGE_TASK "Runbook documented with troubleshooting guide"
./tm progress $KNOWLEDGE_TASK "Handoff session scheduled for tomorrow 2pm"

./tm progress $ONBOARDING_TASK "Architecture review completed"
./tm progress $ONBOARDING_TASK "Practiced deployment in staging environment"
./tm progress $ONBOARDING_TASK "Shadowed incident response procedures"

# Validation of knowledge transfer
./tm complete $KNOWLEDGE_TASK --validate --actual-hours 5 \
  --summary "Comprehensive knowledge transfer completed with hands-on validation"

./tm complete $ONBOARDING_TASK --validate --actual-hours 7 \
  --summary "Successfully onboarded to payment system with independent deployment capability"
```

## Dependency Management Workflows

### Pattern: Critical Path Optimization

**Scenario**: Managing complex dependency chains in feature development.

```bash
# Create dependency chain with proper sequencing
DESIGN_TASK=$(./tm add "Design: New checkout flow wireframes" \
  --criteria '[
    {"criterion": "User flow validated", "measurable": "usability_test_score >= 8"},
    {"criterion": "Accessibility reviewed", "measurable": "a11y_audit_complete == true"}
  ]' \
  --estimated-hours 3)

DATA_TASK=$(./tm add "Data: Customer analytics schema" \
  --criteria '[
    {"criterion": "Schema supports new metrics", "measurable": "true"},
    {"criterion": "Migration path documented", "measurable": "true"}
  ]' \
  --estimated-hours 4)

API_TASK=$(./tm add "API: Checkout endpoints" \
  --depends-on $DESIGN_TASK,$DATA_TASK \
  --criteria '[
    {"criterion": "Endpoints match design flow", "measurable": "design_compliance == 100"},
    {"criterion": "Analytics events captured", "measurable": "event_coverage >= 95"}
  ]' \
  --estimated-hours 6)

FRONTEND_TASK=$(./tm add "Frontend: Checkout UI implementation" \
  --depends-on $API_TASK \
  --criteria '[
    {"criterion": "Matches approved design", "measurable": "design_review_approved == true"},
    {"criterion": "Analytics properly tracked", "measurable": "event_validation_pass == true"}
  ]' \
  --estimated-hours 8)

TESTING_TASK=$(./tm add "QA: End-to-end checkout testing" \
  --depends-on $FRONTEND_TASK \
  --criteria '[
    {"criterion": "All user paths tested", "measurable": "test_coverage == 100"},
    {"criterion": "Performance validated", "measurable": "checkout_time < 30000"}
  ]' \
  --estimated-hours 4)

# Parallel execution where possible
./tm progress $DESIGN_TASK "User flow wireframes created"
./tm progress $DATA_TASK "Analytics schema designed in parallel with UX"

# Critical path continues
./tm complete $DESIGN_TASK --validate --actual-hours 3
./tm complete $DATA_TASK --validate --actual-hours 4

./tm progress $API_TASK "Checkout endpoints implemented with analytics"
./tm complete $API_TASK --validate --actual-hours 6

./tm progress $FRONTEND_TASK "UI implementation matches design specifications"
./tm complete $FRONTEND_TASK --validate --actual-hours 7

./tm progress $TESTING_TASK "E2E testing completed with performance validation"
./tm complete $TESTING_TASK --validate --actual-hours 4
```

## Emergency Response Coordination

### Pattern: Incident Response with Knowledge Capture

**Scenario**: Production incident requiring immediate coordination and post-mortem.

```bash
# Immediate response task
INCIDENT_TASK=$(./tm add "URGENT: Database connection failures in production" \
  --criteria '[
    {"criterion": "Service restored", "measurable": "error_rate < 1"},
    {"criterion": "Root cause identified", "measurable": "true"},
    {"criterion": "Temporary fix deployed", "measurable": "true"},
    {"criterion": "Monitoring enhanced", "measurable": "alert_coverage_improved == true"}
  ]' \
  --estimated-hours 2 \
  --deadline "2025-08-20T16:00:00Z")

# Post-incident analysis
POSTMORTEM_TASK=$(./tm add "Post-mortem: Database connection incident" \
  --depends-on $INCIDENT_TASK \
  --criteria '[
    {"criterion": "Timeline documented", "measurable": "true"},
    {"criterion": "Action items identified", "measurable": "action_items >= 3"},
    {"criterion": "Prevention measures planned", "measurable": "true"}
  ]' \
  --estimated-hours 3)

# Rapid response with documentation
./tm context $INCIDENT_TASK --shared "
# Incident Response Coordination

## Incident Details
- Started: 2025-08-20 14:30 UTC
- Symptoms: 500 errors on API endpoints, database timeouts
- Impact: ~25% of users unable to access application
- Severity: High (customer-facing service degraded)

## Initial Investigation
- Database connections: 95/100 used (near limit)
- CPU usage: Normal on app servers
- Memory usage: Elevated on database server
- Error logs: Connection pool exhaustion

## Immediate Actions
1. Scale database connection pool temporarily
2. Restart application servers to clear stale connections
3. Monitor error rates and response times
4. Identify root cause of connection leaks

## Communication
- Status page updated
- Customer support notified
- Engineering team on standby
"

# Rapid execution with updates
./tm progress $INCIDENT_TASK "Connection pool increased from 100 to 200"
./tm progress $INCIDENT_TASK "App servers restarted, error rate dropping"
./tm progress $INCIDENT_TASK "Root cause: ORM not closing connections properly"
./tm progress $INCIDENT_TASK "Hotfix deployed - explicit connection cleanup added"

# Complete incident response
./tm complete $INCIDENT_TASK --validate --actual-hours 1.5 \
  --summary "Service restored within 90 minutes. Root cause: ORM connection leak in analytics module."

# Post-mortem with knowledge capture
./tm context $POSTMORTEM_TASK --shared "
# Post-Mortem Analysis

## Root Cause
- ORM library not automatically closing connections in analytics queries
- Connection pool exhaustion during high-traffic period
- Monitoring alerts didn't trigger until 90% pool utilization

## Action Items
1. Audit all ORM usage for proper connection management
2. Implement connection pool monitoring with alerts at 70%
3. Add automated testing for connection leaks
4. Review database scaling strategy for traffic growth

## Prevention Measures
- Code review checklist updated to include connection handling
- Database monitoring dashboard enhanced
- Load testing to include connection pool stress testing
"

./tm complete $POSTMORTEM_TASK --validate --actual-hours 2.5 \
  --summary "Post-mortem completed with 4 action items to prevent recurrence"
```

## Quality Handoff Patterns

### Pattern: Stage-Gate Quality Assurance

**Scenario**: Multi-stage quality validation with clear handoff criteria.

```bash
# Development completion
DEV_TASK=$(./tm add "Development: User notification system" \
  --criteria '[
    {"criterion": "Unit tests pass", "measurable": "unit_test_coverage >= 90"},
    {"criterion": "Code review approved", "measurable": "code_review_status == approved"},
    {"criterion": "Feature flags implemented", "measurable": "true"}
  ]' \
  --estimated-hours 12 \
  --assignee "development-team")

# QA handoff
QA_TASK=$(./tm add "QA: Notification system testing" \
  --depends-on $DEV_TASK \
  --criteria '[
    {"criterion": "All test cases pass", "measurable": "test_pass_rate == 100"},
    {"criterion": "Performance validated", "measurable": "notification_latency < 5000"},
    {"criterion": "Security testing complete", "measurable": "security_scan_pass == true"}
  ]' \
  --estimated-hours 6 \
  --assignee "qa-team")

# DevOps handoff
DEPLOY_TASK=$(./tm add "DevOps: Notification system deployment" \
  --depends-on $QA_TASK \
  --criteria '[
    {"criterion": "Staging deployment successful", "measurable": "staging_health_check == pass"},
    {"criterion": "Production rollout plan ready", "measurable": "true"},
    {"criterion": "Rollback procedure tested", "measurable": "rollback_test_pass == true"}
  ]' \
  --estimated-hours 3 \
  --assignee "devops-team")

# Quality gates with handoff documentation
./tm context $DEV_TASK --shared "
# Development Handoff Checklist

## Code Quality Standards
- All new code has unit tests (>90% coverage)
- Code passes linting and type checking
- No TODO comments in production code
- Error handling implemented for all external calls

## Feature Implementation
- Push notifications via Firebase
- Email notifications via SendGrid
- In-app notification UI components
- User preference management

## Handoff Artifacts
- Pull request with detailed description
- Unit test report with coverage metrics
- Feature flag configuration documentation
- API documentation updates
"

./tm progress $DEV_TASK "Notification backends implemented with proper error handling"
./tm progress $DEV_TASK "Unit tests written, achieving 93% coverage"
./tm progress $DEV_TASK "Code review completed with minor suggestions addressed"

./tm complete $DEV_TASK --validate --actual-hours 11 \
  --summary "Notification system development complete with comprehensive testing"

# QA takes over with clear acceptance criteria
./tm context $QA_TASK --shared "
# QA Validation Requirements

## Test Scenarios
1. Push notifications on mobile devices (iOS/Android)
2. Email notifications with proper formatting
3. In-app notifications with real-time updates
4. User preference persistence and respect
5. Notification delivery failure handling
6. High-volume notification performance

## Performance Targets
- Notification delivery: <5 seconds
- Database impact: <10ms per notification
- Mobile app responsiveness maintained
- Email delivery rate: >98%

## Security Validation
- No PII in notification logs
- Proper authentication for notification preferences
- Rate limiting for notification APIs
- Input validation for notification content
"

./tm progress $QA_TASK "Push notification testing complete - all devices working"
./tm progress $QA_TASK "Performance testing shows 3.2s avg delivery time"
./tm progress $QA_TASK "Security scan passed - no vulnerabilities found"

./tm complete $QA_TASK --validate --actual-hours 6 \
  --summary "Comprehensive testing completed - all quality gates passed"

# DevOps deployment with production readiness validation
./tm context $DEPLOY_TASK --shared "
# Deployment Readiness Checklist

## Infrastructure Requirements
- Firebase project configured for push notifications
- SendGrid API keys added to production secrets
- Database migration for notification preferences
- Redis cache for notification deduplication

## Monitoring and Alerting
- Notification delivery rate monitoring
- Error rate alerts for failed notifications
- Performance metrics for delivery latency
- User engagement metrics for notification effectiveness

## Rollout Strategy
- Feature flag enabled for 10% of users initially
- Monitor metrics for 24 hours before full rollout
- Staged deployment across geographic regions
- Immediate rollback capability via feature flags
"

./tm progress $DEPLOY_TASK "Staging deployment completed successfully"
./tm progress $DEPLOY_TASK "Rollback procedure tested and documented"
./tm progress $DEPLOY_TASK "Production rollout plan approved by engineering lead"

./tm complete $DEPLOY_TASK --validate --actual-hours 3 \
  --summary "Deployment ready with staged rollout plan and monitoring in place"
```

## Best Practices Summary

### Communication Patterns
1. **Shared Context**: Use shared context for coordination information
2. **Progress Updates**: Regular, descriptive progress updates
3. **Dependency Clarity**: Explicit dependencies and handoff criteria
4. **Knowledge Capture**: Document decisions and learnings in completion summaries

### Coordination Strategies
1. **Parallel Work**: Identify opportunities for parallel execution
2. **Critical Path**: Focus on dependency bottlenecks
3. **Quality Gates**: Clear handoff criteria between stages
4. **Feedback Loops**: Use feedback scores to improve collaboration

### Risk Mitigation
1. **Early Integration**: Test integration points frequently
2. **Clear Contracts**: Define interfaces and expectations upfront
3. **Rollback Plans**: Always have a way to undo changes
4. **Monitoring**: Implement observability before deployment

---

*Workflow patterns tested with Task Orchestrator v2.3.0*
*Best practices derived from real-world team collaboration scenarios*