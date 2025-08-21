# Quality Assurance Workflow Patterns

## Overview

This document provides comprehensive QA workflow patterns using Task Orchestrator Core Loop features to ensure consistent quality, enable continuous improvement, and create systematic approaches to quality validation.

## Table of Contents

- [Success Criteria Definition Patterns](#success-criteria-definition-patterns)
- [Feedback Collection Best Practices](#feedback-collection-best-practices)
- [Metrics-Driven Improvement Cycles](#metrics-driven-improvement-cycles)
- [Performance Monitoring Workflows](#performance-monitoring-workflows)
- [Quality Gate Implementation](#quality-gate-implementation)
- [Continuous Improvement Patterns](#continuous-improvement-patterns)

## Success Criteria Definition Patterns

### Pattern: SMART Criteria for Quality Validation

**Scenario**: Defining measurable quality criteria for different types of work.

#### Code Quality Criteria

```bash
# Development task with comprehensive quality criteria
DEV_TASK=$(./tm add "Implement user search functionality" \
  --criteria '[
    {
      "criterion": "Unit test coverage above 90%",
      "measurable": "test_coverage >= 90"
    },
    {
      "criterion": "No critical security vulnerabilities",
      "measurable": "security_scan_critical == 0"
    },
    {
      "criterion": "Code complexity within limits",
      "measurable": "cyclomatic_complexity <= 10"
    },
    {
      "criterion": "Performance meets SLA",
      "measurable": "search_response_time <= 200"
    },
    {
      "criterion": "Code review approved",
      "measurable": "code_review_status == approved"
    }
  ]' \
  --estimated-hours 8)

# Context for quality validation
./tm context $DEV_TASK --shared "
# Quality Standards for Search Functionality

## Code Quality Requirements
- Unit tests: >90% line coverage, >85% branch coverage
- Integration tests: Happy path + 3 error scenarios
- Code review: 2 approvals required
- Static analysis: 0 critical issues, <5 minor issues

## Performance Requirements
- Search response time: <200ms (95th percentile)
- Database query time: <50ms per search
- Memory usage: <100MB increase during search
- Concurrent users: Handle 1000 simultaneous searches

## Security Requirements
- Input validation: SQL injection prevention
- Authorization: User can only search own data
- Audit logging: All search queries logged
- Rate limiting: 100 searches per minute per user

## Definition of Done
- All criteria met and verified
- Documentation updated
- Monitoring dashboards show green metrics
- Stakeholder acceptance obtained
"

# Quality validation workflow
./tm progress $DEV_TASK "Search algorithm implemented with fuzzy matching"
./tm progress $DEV_TASK "Unit tests written - currently at 92% coverage"
./tm progress $DEV_TASK "Security scan completed - 0 critical vulnerabilities"
./tm progress $DEV_TASK "Performance testing shows 180ms avg response time"

# Validation and completion
./tm complete $DEV_TASK --validate --actual-hours 7.5 \
  --summary "Search functionality implemented meeting all quality criteria. Performance exceeds targets."

./tm feedback $DEV_TASK --quality 5 --timeliness 4 \
  --note "Excellent quality implementation. Minor delay due to additional fuzzy matching feature."
```

#### Documentation Quality Criteria

```bash
# Documentation task with measurable quality standards
DOC_TASK=$(./tm add "API Documentation for v2.3 release" \
  --criteria '[
    {
      "criterion": "All endpoints documented",
      "measurable": "endpoint_coverage == 100"
    },
    {
      "criterion": "Examples are executable",
      "measurable": "example_test_pass_rate == 100"
    },
    {
      "criterion": "Readability score acceptable",
      "measurable": "flesch_kincaid_score >= 60"
    },
    {
      "criterion": "Internal links validated",
      "measurable": "broken_links == 0"
    },
    {
      "criterion": "User testing feedback positive",
      "measurable": "user_satisfaction_score >= 4"
    }
  ]' \
  --estimated-hours 6)

# Quality context for documentation
./tm context $DOC_TASK --shared "
# Documentation Quality Standards

## Content Requirements
- Every endpoint has description, parameters, examples
- Error codes documented with resolution steps
- Authentication requirements clearly stated
- Rate limits and quotas specified

## Usability Requirements
- New developer can make first API call in <10 minutes
- Examples are copy-paste ready
- Common use cases covered with workflows
- Troubleshooting section addresses frequent issues

## Technical Requirements
- OpenAPI 3.0 specification validates
- Code examples syntax highlighted
- Interactive API explorer functional
- Links checked and working

## Validation Process
1. Technical review by development team
2. Usability testing with 3 external developers
3. Accessibility audit (WCAG 2.1 AA)
4. Link validation automated testing
"

./tm progress $DOC_TASK "OpenAPI specification complete and validates"
./tm progress $DOC_TASK "All examples tested and working in clean environment"
./tm progress $DOC_TASK "Usability testing shows 4.2/5 satisfaction score"

./tm complete $DOC_TASK --validate --actual-hours 6 \
  --summary "API documentation complete with excellent usability scores"
```

### Pattern: Graduated Quality Criteria

**Scenario**: Different quality levels for different project phases.

```bash
# MVP quality criteria (minimal viable)
MVP_TASK=$(./tm add "MVP: Basic notification system" \
  --criteria '[
    {
      "criterion": "Core functionality works",
      "measurable": "happy_path_test_pass == true"
    },
    {
      "criterion": "No data corruption possible",
      "measurable": "data_integrity_test_pass == true"
    },
    {
      "criterion": "Basic error handling",
      "measurable": "error_scenarios_covered >= 3"
    }
  ]' \
  --estimated-hours 4)

# Production quality criteria (comprehensive)
PROD_TASK=$(./tm add "Production: Enterprise notification system" \
  --criteria '[
    {
      "criterion": "Comprehensive test coverage",
      "measurable": "test_coverage >= 95"
    },
    {
      "criterion": "Performance under load",
      "measurable": "notifications_per_second >= 1000"
    },
    {
      "criterion": "Monitoring and alerting",
      "measurable": "observability_score >= 90"
    },
    {
      "criterion": "Security audit passed",
      "measurable": "security_audit_score >= 95"
    },
    {
      "criterion": "Disaster recovery tested",
      "measurable": "recovery_time_objective <= 4_hours"
    }
  ]' \
  --estimated-hours 20)
```

## Feedback Collection Best Practices

### Pattern: Structured Feedback with Context

**Scenario**: Collecting actionable feedback that drives improvement.

```bash
# Task with detailed feedback collection
FEATURE_TASK=$(./tm add "User profile management interface" \
  --criteria '[
    {
      "criterion": "UI matches design specifications",
      "measurable": "design_compliance >= 95"
    },
    {
      "criterion": "Accessibility standards met",
      "measurable": "wcag_score >= 95"
    },
    {
      "criterion": "Performance acceptable",
      "measurable": "page_load_time <= 2000"
    }
  ]' \
  --estimated-hours 10)

# Complete with comprehensive feedback
./tm complete $FEATURE_TASK --validate --actual-hours 9 \
  --summary "Profile interface implemented with excellent accessibility and performance"

# Detailed feedback with specific observations
./tm feedback $FEATURE_TASK --quality 4 --timeliness 5 \
  --note "
## Quality Assessment (4/5)
### Strengths
- Excellent accessibility implementation (WCAG 2.1 AAA level)
- Clean, intuitive user interface design
- Robust form validation with helpful error messages
- Performance optimization with lazy loading

### Areas for Improvement
- Consider adding keyboard shortcuts for power users
- Form autosave could be more frequent (currently 30s intervals)
- Avatar upload could support drag-and-drop

## Timeliness Assessment (5/5)
- Delivered 1 hour ahead of estimate
- No scope creep or unexpected complications
- Proactive communication about progress
- Well-planned approach minimized iterations

## Impact on Team
- Clean code structure will help future maintenance
- Accessibility patterns can be reused in other components
- Performance optimizations demonstrate best practices
- Thorough testing approach should be adopted team-wide

## Recommendations
- Share accessibility implementation in team knowledge base
- Create reusable form validation components
- Consider this developer for future UI-critical tasks
"
```

### Pattern: Feedback Aggregation and Analysis

```bash
# Create feedback analysis task
FEEDBACK_ANALYSIS=$(./tm add "Team Performance Analysis - Q1 2025" \
  --criteria '[
    {
      "criterion": "All team member feedback analyzed",
      "measurable": "feedback_coverage == 100"
    },
    {
      "criterion": "Improvement patterns identified",
      "measurable": "improvement_areas >= 3"
    },
    {
      "criterion": "Action plan created",
      "measurable": "action_items >= 5"
    }
  ]' \
  --estimated-hours 4)

# Gather feedback metrics
./tm metrics --period "last-quarter" --format "detailed" > /tmp/team_metrics.json

# Analyze and provide insights
./tm context $FEEDBACK_ANALYSIS --shared "
# Team Performance Analysis - Q1 2025

## Overall Metrics
- Tasks Completed: 156
- Average Quality Score: 4.1/5 (up from 3.8 previous quarter)
- Average Timeliness Score: 3.9/5 (down from 4.2 previous quarter)
- Estimation Accuracy: 84% (up from 79%)

## Quality Trends
### Strengths
- Code quality consistently high (4.5/5 average)
- Documentation quality improved significantly (3.5 to 4.2)
- Security practices excellent (4.8/5 average)

### Areas for Improvement
- UI/UX tasks show more variability (3.2-4.8 range)
- Performance optimization tasks often exceed estimates
- Integration tasks require more coordination

## Timeliness Trends
### Challenges
- Dependencies cause 23% of delays
- Scope creep in 18% of tasks
- External blockers affect 12% of timelines

### Successes
- Planning accuracy improved for familiar task types
- Emergency response time excellent (avg 2.3/5 urgency)
- Regular estimation calibration showing results

## Individual Contributor Insights
- Frontend specialists: High quality, need better time estimation
- Backend specialists: Excellent timeliness, maintain quality consistency
- DevOps specialists: Outstanding in both quality and timeliness
- Full-stack generalists: Variable performance, need specialization

## Recommendations
1. Implement dependency mapping in project planning
2. Scope control training for product managers
3. Cross-training to reduce single points of failure
4. Regular estimation calibration sessions
5. Pair programming for knowledge transfer
"

./tm complete $FEEDBACK_ANALYSIS --validate --actual-hours 3.5 \
  --summary "Comprehensive Q1 analysis completed with 5 actionable improvement recommendations"
```

## Metrics-Driven Improvement Cycles

### Pattern: Continuous Improvement with Data

**Scenario**: Using metrics to identify and address performance issues.

```bash
# Baseline measurement
BASELINE_TASK=$(./tm add "Establish deployment time baseline" \
  --criteria '[
    {
      "criterion": "10 deployments measured",
      "measurable": "deployment_samples >= 10"
    },
    {
      "criterion": "Bottlenecks identified",
      "measurable": "bottleneck_analysis_complete == true"
    },
    {
      "criterion": "Improvement targets set",
      "measurable": "target_deployment_time <= 15_minutes"
    }
  ]' \
  --estimated-hours 3)

# Improvement implementation
IMPROVE_TASK=$(./tm add "Optimize deployment pipeline" \
  --depends-on $BASELINE_TASK \
  --criteria '[
    {
      "criterion": "Deployment time improved by 30%",
      "measurable": "deployment_time <= baseline * 0.7"
    },
    {
      "criterion": "Reliability maintained",
      "measurable": "deployment_success_rate >= 95"
    },
    {
      "criterion": "No manual steps added",
      "measurable": "manual_steps == 0"
    }
  ]' \
  --estimated-hours 8)

# Validation and measurement
VALIDATE_TASK=$(./tm add "Validate deployment improvements" \
  --depends-on $IMPROVE_TASK \
  --criteria '[
    {
      "criterion": "Sustained improvement over 2 weeks",
      "measurable": "sustained_improvement == true"
    },
    {
      "criterion": "Team satisfaction improved",
      "measurable": "team_satisfaction_score >= 4"
    },
    {
      "criterion": "Best practices documented",
      "measurable": "documentation_complete == true"
    }
  ]' \
  --estimated-hours 2)

# Execute improvement cycle
./tm progress $BASELINE_TASK "Measured 12 deployments - avg time 22 minutes"
./tm progress $BASELINE_TASK "Identified bottlenecks: test execution (40%), artifact building (35%)"
./tm complete $BASELINE_TASK --validate --actual-hours 2.5

./tm progress $IMPROVE_TASK "Parallelized test execution - 40% reduction in test time"
./tm progress $IMPROVE_TASK "Implemented build caching - 60% reduction in build time"
./tm progress $IMPROVE_TASK "Overall deployment time now 14 minutes (36% improvement)"
./tm complete $IMPROVE_TASK --validate --actual-hours 7

./tm progress $VALIDATE_TASK "2-week monitoring shows consistent 14-minute deployments"
./tm progress $VALIDATE_TASK "Team satisfaction survey: 4.3/5 (up from 3.1/5)"
./tm complete $VALIDATE_TASK --validate --actual-hours 1.5
```

### Pattern: A/B Testing Quality Processes

```bash
# A/B test different code review processes
REVIEW_TEST_A=$(./tm add "Code Review Process A: Async Reviews" \
  --criteria '[
    {
      "criterion": "Review turnaround time measured",
      "measurable": "review_time_samples >= 20"
    },
    {
      "criterion": "Code quality maintained",
      "measurable": "defect_rate <= baseline"
    },
    {
      "criterion": "Developer satisfaction measured",
      "measurable": "dev_satisfaction_score >= 3"
    }
  ]' \
  --estimated-hours 2)

REVIEW_TEST_B=$(./tm add "Code Review Process B: Pair Reviews" \
  --criteria '[
    {
      "criterion": "Review efficiency measured",
      "measurable": "reviews_per_hour >= baseline"
    },
    {
      "criterion": "Knowledge sharing improved",
      "measurable": "knowledge_transfer_score >= 4"
    },
    {
      "criterion": "Code quality maintained",
      "measurable": "defect_rate <= baseline"
    }
  ]' \
  --estimated-hours 2)

# Compare results and implement best approach
REVIEW_ANALYSIS=$(./tm add "Analyze code review process results" \
  --depends-on $REVIEW_TEST_A,$REVIEW_TEST_B \
  --criteria '[
    {
      "criterion": "Statistical significance achieved",
      "measurable": "p_value <= 0.05"
    },
    {
      "criterion": "Recommendation provided",
      "measurable": "process_recommendation_complete == true"
    },
    {
      "criterion": "Implementation plan created",
      "measurable": "rollout_plan_approved == true"
    }
  ]' \
  --estimated-hours 3)
```

## Performance Monitoring Workflows

### Pattern: Proactive Performance Management

**Scenario**: Systematic performance monitoring and optimization.

```bash
# Establish performance monitoring
PERF_MONITORING=$(./tm add "Implement performance monitoring dashboard" \
  --criteria '[
    {
      "criterion": "Key metrics tracked",
      "measurable": "monitored_metrics >= 10"
    },
    {
      "criterion": "Alerting configured",
      "measurable": "alert_rules >= 5"
    },
    {
      "criterion": "Historical trending available",
      "measurable": "trend_analysis_available == true"
    },
    {
      "criterion": "Team trained on dashboard",
      "measurable": "training_completion >= 90"
    }
  ]' \
  --estimated-hours 6)

# Context for performance standards
./tm context $PERF_MONITORING --shared "
# Performance Monitoring Requirements

## Key Performance Indicators
1. Response Time Metrics
   - API endpoints: p50, p95, p99 latencies
   - Database queries: average and peak execution times
   - Page load times: First Contentful Paint, Time to Interactive

2. Throughput Metrics
   - Requests per second
   - Transactions per minute
   - Concurrent user capacity

3. Resource Utilization
   - CPU usage across services
   - Memory consumption patterns
   - Disk I/O and network bandwidth

4. Error Metrics
   - Error rates by service and endpoint
   - Failed transaction percentages
   - Timeout and connection failure rates

5. Business Metrics
   - Task completion rates
   - User satisfaction scores
   - Feature adoption metrics

## Alert Thresholds
- Response time > 2x baseline for 5 minutes
- Error rate > 5% for 2 minutes
- CPU usage > 80% for 10 minutes
- Memory usage > 90% for 5 minutes
- Disk space < 20% remaining

## Dashboard Requirements
- Real-time updates (30-second refresh)
- Historical data (90 days retention)
- Custom time range selection
- Drill-down capability to individual services
- Mobile-responsive design for on-call access
"

./tm progress $PERF_MONITORING "Metrics collection implemented for all services"
./tm progress $PERF_MONITORING "Dashboard created with real-time visualization"
./tm progress $PERF_MONITORING "Alert rules configured with PagerDuty integration"
./tm progress $PERF_MONITORING "Team training completed - 95% attendance"

./tm complete $PERF_MONITORING --validate --actual-hours 5.5 \
  --summary "Performance monitoring system operational with comprehensive coverage"
```

### Pattern: Performance Regression Prevention

```bash
# Automated performance testing
PERF_GATES=$(./tm add "Implement automated performance gates" \
  --criteria '[
    {
      "criterion": "CI pipeline includes performance tests",
      "measurable": "perf_tests_in_ci == true"
    },
    {
      "criterion": "Regression detection automated",
      "measurable": "regression_detection_accuracy >= 95"
    },
    {
      "criterion": "Performance budgets enforced",
      "measurable": "budget_violations_blocked == true"
    },
    {
      "criterion": "Results tracked over time",
      "measurable": "performance_history_available == true"
    }
  ]' \
  --estimated-hours 8)

# Performance budget definition
./tm context $PERF_GATES --shared "
# Performance Budget Definitions

## API Performance Budgets
- Authentication endpoints: <100ms (p95)
- Data retrieval endpoints: <200ms (p95)
- Data modification endpoints: <500ms (p95)
- Report generation endpoints: <2000ms (p95)

## Frontend Performance Budgets
- First Contentful Paint: <1.5s
- Time to Interactive: <3s
- Largest Contentful Paint: <2.5s
- Cumulative Layout Shift: <0.1

## Resource Budgets
- JavaScript bundle size: <500KB (gzipped)
- CSS bundle size: <100KB (gzipped)
- Image assets: <2MB total per page
- Font assets: <200KB total

## Database Performance Budgets
- Query execution time: <50ms (average)
- Connection pool usage: <70% utilization
- Lock wait time: <10ms (average)
- Index efficiency: >95% index usage

## Testing Strategy
- Automated tests run on every pull request
- Performance comparison against main branch
- Fail build if budget exceeded by >10%
- Weekly performance trend analysis
- Monthly performance review with team
"

./tm progress $PERF_GATES "Performance tests integrated into CI pipeline"
./tm progress $PERF_GATES "Budget enforcement prevents regression deployments"
./tm progress $PERF_GATES "Historical trending dashboard shows improvement"

./tm complete $PERF_GATES --validate --actual-hours 7 \
  --summary "Automated performance gates prevent regressions and maintain quality"
```

## Quality Gate Implementation

### Pattern: Multi-Stage Quality Validation

**Scenario**: Progressive quality validation through development lifecycle.

```bash
# Stage 1: Development Quality Gate
DEV_GATE=$(./tm add "Development Quality Gate: Feature X" \
  --criteria '[
    {
      "criterion": "Unit tests pass",
      "measurable": "unit_test_pass_rate == 100"
    },
    {
      "criterion": "Code coverage adequate",
      "measurable": "code_coverage >= 85"
    },
    {
      "criterion": "Static analysis clean",
      "measurable": "static_analysis_issues == 0"
    },
    {
      "criterion": "Code review approved",
      "measurable": "code_review_approvals >= 2"
    }
  ]' \
  --estimated-hours 1)

# Stage 2: Integration Quality Gate
INTEGRATION_GATE=$(./tm add "Integration Quality Gate: Feature X" \
  --depends-on $DEV_GATE \
  --criteria '[
    {
      "criterion": "Integration tests pass",
      "measurable": "integration_test_pass_rate == 100"
    },
    {
      "criterion": "API contracts validated",
      "measurable": "contract_test_pass_rate == 100"
    },
    {
      "criterion": "Database migrations successful",
      "measurable": "migration_test_pass == true"
    },
    {
      "criterion": "Performance within limits",
      "measurable": "performance_regression == false"
    }
  ]' \
  --estimated-hours 2)

# Stage 3: User Acceptance Quality Gate
UAT_GATE=$(./tm add "User Acceptance Quality Gate: Feature X" \
  --depends-on $INTEGRATION_GATE \
  --criteria '[
    {
      "criterion": "User scenarios validated",
      "measurable": "user_scenario_pass_rate == 100"
    },
    {
      "criterion": "Accessibility compliance",
      "measurable": "accessibility_score >= 95"
    },
    {
      "criterion": "Cross-browser compatibility",
      "measurable": "browser_compatibility >= 95"
    },
    {
      "criterion": "Mobile responsiveness verified",
      "measurable": "mobile_test_pass_rate == 100"
    }
  ]' \
  --estimated-hours 3)

# Stage 4: Production Readiness Gate
PROD_GATE=$(./tm add "Production Readiness Gate: Feature X" \
  --depends-on $UAT_GATE \
  --criteria '[
    {
      "criterion": "Load testing passed",
      "measurable": "load_test_pass == true"
    },
    {
      "criterion": "Security scan clean",
      "measurable": "security_vulnerabilities == 0"
    },
    {
      "criterion": "Monitoring configured",
      "measurable": "monitoring_coverage >= 90"
    },
    {
      "criterion": "Rollback plan tested",
      "measurable": "rollback_test_pass == true"
    },
    {
      "criterion": "Documentation complete",
      "measurable": "documentation_score >= 90"
    }
  ]' \
  --estimated-hours 2)

# Execute quality gates progressively
./tm complete $DEV_GATE --validate --actual-hours 1
./tm complete $INTEGRATION_GATE --validate --actual-hours 2
./tm complete $UAT_GATE --validate --actual-hours 3
./tm complete $PROD_GATE --validate --actual-hours 2
```

## Continuous Improvement Patterns

### Pattern: Retrospective-Driven Improvements

**Scenario**: Regular retrospectives with actionable improvements.

```bash
# Monthly retrospective
RETRO_TASK=$(./tm add "Team Retrospective - March 2025" \
  --criteria '[
    {
      "criterion": "All team members participated",
      "measurable": "participation_rate >= 90"
    },
    {
      "criterion": "Action items identified",
      "measurable": "action_items >= 3"
    },
    {
      "criterion": "Previous action items reviewed",
      "measurable": "previous_items_reviewed == true"
    },
    {
      "criterion": "Improvement experiments planned",
      "measurable": "experiments_planned >= 2"
    }
  ]' \
  --estimated-hours 2)

# Context for retrospective structure
./tm context $RETRO_TASK --shared "
# Retrospective Agenda - March 2025

## Data Review (15 minutes)
- Team velocity and throughput metrics
- Quality scores and trend analysis
- Estimation accuracy review
- Incident frequency and resolution times

## What Went Well (15 minutes)
- Celebrate successes and positive patterns
- Identify practices to continue and amplify
- Recognize individual and team achievements

## What Could Be Improved (20 minutes)
- Discuss challenges and pain points
- Identify root causes of recurring issues
- Brainstorm potential solutions

## Action Items (10 minutes)
- Prioritize improvements based on impact/effort
- Assign owners and deadlines for action items
- Define success metrics for each improvement

## Previous Action Items Review (5 minutes)
- February action items: Status and lessons learned
- Update on ongoing improvement experiments
- Celebrate completed improvements

## Improvement Experiments (10 minutes)
- Design experiments to test improvement hypotheses
- Define measurement criteria and timelines
- Plan implementation and evaluation approach
"

./tm progress $RETRO_TASK "Retrospective held with 100% team participation"
./tm progress $RETRO_TASK "Identified 4 action items with clear owners and deadlines"
./tm progress $RETRO_TASK "Planned 2 improvement experiments for April"

./tm complete $RETRO_TASK --validate --actual-hours 1.5 \
  --summary "Productive retrospective with concrete action items and improvement experiments"

# Follow-up improvement implementation
IMPROVEMENT_1=$(./tm add "Implement automated code formatting" \
  --criteria '[
    {
      "criterion": "Formatting rules configured",
      "measurable": "formatting_rules_complete == true"
    },
    {
      "criterion": "CI integration complete",
      "measurable": "ci_formatting_check == true"
    },
    {
      "criterion": "Team trained on new process",
      "measurable": "team_training_complete == true"
    },
    {
      "criterion": "Code review time reduced",
      "measurable": "review_time_improvement >= 20"
    }
  ]' \
  --estimated-hours 4)
```

### Pattern: Quality Metrics Dashboard and Reviews

```bash
# Create quality dashboard
QUALITY_DASHBOARD=$(./tm add "Team Quality Metrics Dashboard" \
  --criteria '[
    {
      "criterion": "All quality metrics visualized",
      "measurable": "metric_coverage == 100"
    },
    {
      "criterion": "Historical trends available",
      "measurable": "trend_data_months >= 6"
    },
    {
      "criterion": "Drill-down capability",
      "measurable": "detailed_views_available == true"
    },
    {
      "criterion": "Automated reporting configured",
      "measurable": "weekly_reports_automated == true"
    }
  ]' \
  --estimated-hours 6)

# Regular quality review process
QUALITY_REVIEW=$(./tm add "Monthly Quality Review - March 2025" \
  --criteria '[
    {
      "criterion": "Trends analyzed",
      "measurable": "trend_analysis_complete == true"
    },
    {
      "criterion": "Improvement opportunities identified",
      "measurable": "opportunities_identified >= 3"
    },
    {
      "criterion": "Action plan created",
      "measurable": "action_plan_approved == true"
    },
    {
      "criterion": "Success metrics defined",
      "measurable": "success_metrics_defined == true"
    }
  ]' \
  --estimated-hours 2)
```

## Best Practices Summary

### Success Criteria Design
1. **SMART Criteria**: Specific, Measurable, Achievable, Relevant, Time-bound
2. **Context-Aware**: Consider project phase and business requirements
3. **Balanced**: Cover quality, performance, and usability aspects
4. **Testable**: Ensure criteria can be objectively validated

### Feedback Collection
1. **Structured**: Use consistent formats for comparable feedback
2. **Timely**: Provide feedback soon after task completion
3. **Actionable**: Include specific suggestions for improvement
4. **Balanced**: Address both strengths and improvement areas

### Metrics and Monitoring
1. **Leading Indicators**: Track metrics that predict future quality
2. **Trending**: Monitor changes over time to identify patterns
3. **Actionable**: Focus on metrics that can drive decisions
4. **Automated**: Reduce manual effort in data collection

### Continuous Improvement
1. **Data-Driven**: Base improvements on objective metrics
2. **Experimental**: Test changes with A/B testing when possible
3. **Incremental**: Make small, measurable improvements
4. **Systematic**: Use regular reviews and retrospectives

---

*Quality assurance patterns validated with Task Orchestrator v2.3.0*
*Best practices derived from continuous improvement cycles*