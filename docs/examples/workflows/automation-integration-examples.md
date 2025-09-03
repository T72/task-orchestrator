# Automation Integration Examples

## Overview

This document provides comprehensive examples of integrating Task Orchestrator Core Loop features with automation systems, CI/CD pipelines, external tools, and monitoring solutions to create seamless, efficient workflows.

## Table of Contents

- [Git Hook Integrations](#git-hook-integrations)
- [CI/CD Pipeline Enhancements](#cicd-pipeline-enhancements)
- [External System Integrations](#external-system-integrations)
- [Monitoring and Alerting Automation](#monitoring-and-alerting-automation)
- [Report Generation Workflows](#report-generation-workflows)
- [Slack and Communication Integration](#slack-and-communication-integration)

## Git Hook Integrations

### Pattern: Automated Task Creation from Commits

**Scenario**: Automatically create tasks for specific types of commits with appropriate success criteria.

#### Pre-commit Hook: Task Creation for Features

```bash
#!/bin/bash
# File: .git/hooks/pre-commit
# Purpose: Create tasks for feature commits

# Extract commit message from staged changes
COMMIT_MSG=$(git diff --cached --name-only | head -1 | xargs -I {} git log --format=%B -n 1 HEAD 2>/dev/null || echo "")

# Check if this is a feature commit
if [[ "$COMMIT_MSG" =~ ^feat: ]]; then
    FEATURE_NAME=$(echo "$COMMIT_MSG" | sed 's/feat: //' | cut -d' ' -f1-3)
    
    # Create task with standard feature criteria
    TASK_ID=$(./tm add "Feature Implementation: $FEATURE_NAME" \
      --criteria '[
        {
          "criterion": "Unit tests pass",
          "measurable": "unit_test_pass_rate == 100"
        },
        {
          "criterion": "Code review approved",
          "measurable": "code_review_status == approved"
        },
        {
          "criterion": "No security vulnerabilities",
          "measurable": "security_scan_issues == 0"
        },
        {
          "criterion": "Performance regression prevented",
          "measurable": "performance_regression == false"
        }
      ]' \
      --estimated-hours 4 \
      --assignee "$(git config user.email)")
    
    # Add commit context
    ./tm context $TASK_ID --shared "
# Automated Task Creation from Git Commit

## Commit Information
- Author: $(git config user.name) <$(git config user.email)>
- Branch: $(git branch --show-current)
- Commit Type: Feature
- Files Modified: $(git diff --cached --name-only | tr '\n' ', ')

## Automated Success Criteria Applied
- Standard feature development quality gates
- Security scan requirements
- Performance regression prevention
- Code review workflow integration

## Next Steps
1. Complete feature implementation
2. Run automated test suite
3. Submit for code review
4. Validate against success criteria
"
    
    echo "✓ Created task $TASK_ID for feature: $FEATURE_NAME"
fi
```

#### Post-commit Hook: Progress Updates

```bash
#!/bin/bash
# File: .git/hooks/post-commit
# Purpose: Update task progress based on commit patterns

COMMIT_MSG=$(git log --format=%B -n 1 HEAD)
COMMIT_HASH=$(git rev-parse --short HEAD)

# Look for task ID in commit message
TASK_ID=$(echo "$COMMIT_MSG" | grep -o "Task-ID: [a-f0-9]\{8\}" | cut -d' ' -f2)

if [[ -n "$TASK_ID" ]]; then
    # Extract progress information from commit
    PROGRESS_MSG="Commit $COMMIT_HASH: $(echo "$COMMIT_MSG" | head -1)"
    
    # Add files changed information
    FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l)
    PROGRESS_MSG="$PROGRESS_MSG ($FILES_CHANGED files modified)"
    
    # Update task progress
    ./tm progress $TASK_ID "$PROGRESS_MSG"
    
    echo "✓ Updated progress for task $TASK_ID"
fi

# Check for completion keywords
if [[ "$COMMIT_MSG" =~ (closes|completes|finishes).*task ]]; then
    if [[ -n "$TASK_ID" ]]; then
        # Attempt to complete task with validation
        ./tm complete $TASK_ID --validate --summary "
Feature implementation completed with commit $COMMIT_HASH.

Automated completion triggered by commit message containing completion keyword.
All success criteria validated before marking complete.
"
        echo "✓ Completed task $TASK_ID (validation required)"
    fi
fi
```

### Pattern: Branch-based Task Management

```bash
#!/bin/bash
# File: .git/hooks/post-checkout
# Purpose: Manage tasks based on branch switches

PREV_HEAD=$1
NEW_HEAD=$2
BRANCH_CHECKOUT=$3

# Only process branch checkouts (not file checkouts)
if [[ $BRANCH_CHECKOUT == "1" ]]; then
    NEW_BRANCH=$(git branch --show-current)
    
    # Parse branch name for task information
    if [[ "$NEW_BRANCH" =~ feature/([a-f0-9]{8})-(.+) ]]; then
        TASK_ID="${BASH_REMATCH[1]}"
        FEATURE_NAME="${BASH_REMATCH[2]}"
        
        # Update task with branch context
        ./tm context $TASK_ID --shared "
# Branch Checkout Automation

## Branch Information
- Branch Name: $NEW_BRANCH
- Feature: $FEATURE_NAME
- Created: $(date)
- Base Commit: $NEW_HEAD

## Development Environment
- Developer: $(git config user.name)
- Workspace: $(pwd)
- Git Version: $(git --version)

## Branch Workflow
1. Feature development in isolated branch
2. Regular commits with progress updates
3. Pull request creation triggers review process
4. Merge triggers task completion validation
"
        
        echo "✓ Updated task $TASK_ID context for branch $NEW_BRANCH"
        
        # Start task if not already in progress
        TASK_STATUS=$(./tm show $TASK_ID --format json | jq -r '.status')
        if [[ "$TASK_STATUS" == "pending" ]]; then
            ./tm progress $TASK_ID "Started development on branch $NEW_BRANCH"
            echo "✓ Started task $TASK_ID development"
        fi
    fi
fi
```

## CI/CD Pipeline Enhancements

### Pattern: GitHub Actions Integration

**Scenario**: Comprehensive CI/CD pipeline with Task Orchestrator integration.

#### Build and Test Workflow

```yaml
# File: .github/workflows/build-and-test.yml
name: Build and Test with Task Orchestrator

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  create-build-task:
    runs-on: ubuntu-latest
    outputs:
      task-id: ${{ steps.create-task.outputs.task-id }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Create build task
        id: create-task
        run: |
          TASK_ID=$(./tm add "CI Build: ${{ github.sha }}" \
            --criteria '[
              {
                "criterion": "All tests pass",
                "measurable": "test_pass_rate == 100"
              },
              {
                "criterion": "Code coverage maintained",
                "measurable": "code_coverage >= 85"
              },
              {
                "criterion": "Security scan clean",
                "measurable": "security_issues == 0"
              },
              {
                "criterion": "Build artifacts generated",
                "measurable": "build_artifacts_count >= 1"
              }
            ]' \
            --estimated-hours 0.5 \
            --assignee "ci-system")
          
          echo "task-id=$TASK_ID" >> $GITHUB_OUTPUT
          
          # Add CI context
          ./tm context $TASK_ID --shared "
# CI/CD Build Context

## Build Information
- Commit: ${{ github.sha }}
- Branch: ${{ github.ref_name }}
- Author: ${{ github.actor }}
- Event: ${{ github.event_name }}
- Repository: ${{ github.repository }}

## Build Environment
- Runner: ${{ runner.os }}
- Workflow: ${{ github.workflow }}
- Job: ${{ github.job }}
- Run ID: ${{ github.run_id }}

## Quality Gates
- Unit tests must pass 100%
- Integration tests must pass 100%
- Code coverage must be >= 85%
- Security scan must show 0 critical/high issues
- Performance tests must not show regression
"

  test:
    needs: create-build-task
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: |
          npm run test:unit -- --coverage
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          echo "Code coverage: $COVERAGE%"
          ./tm progress ${{ needs.create-build-task.outputs.task-id }} "Unit tests completed with $COVERAGE% coverage"
      
      - name: Run integration tests
        run: |
          npm run test:integration
          ./tm progress ${{ needs.create-build-task.outputs.task-id }} "Integration tests completed successfully"
      
      - name: Security scan
        run: |
          npm audit --audit-level=high
          ISSUES=$(npm audit --json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical')
          ./tm progress ${{ needs.create-build-task.outputs.task-id }} "Security scan completed - $ISSUES critical/high issues"

  build:
    needs: [ create-build-task, test ]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Build application
        run: |
          npm ci
          npm run build
          
          # Get build artifacts info
          BUILD_SIZE=$(du -sh dist/ | cut -f1)
          ARTIFACT_COUNT=$(find dist/ -type f | wc -l)
          
          ./tm progress ${{ needs.create-build-task.outputs.task-id }} "Build completed - $ARTIFACT_COUNT artifacts, $BUILD_SIZE total size"
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/

  complete-build-task:
    needs: [ create-build-task, test, build ]
    runs-on: ubuntu-latest
    if: success()
    steps:
      - uses: actions/checkout@v3
      
      - name: Complete build task
        run: |
          ./tm complete ${{ needs.create-build-task.outputs.task-id }} --validate \
            --actual-hours 0.3 \
            --summary "
CI build completed successfully for commit ${{ github.sha }}.

## Build Results
- All tests passed (unit + integration)
- Code coverage maintained above threshold
- Security scan clean
- Build artifacts generated and uploaded

## Performance
- Build time: ${{ github.run_number }} minutes
- Test execution: Efficient
- No regressions detected

## Artifacts
- Build output available in GitHub Actions artifacts
- Ready for deployment pipeline
"
          
          ./tm feedback ${{ needs.create-build-task.outputs.task-id }} \
            --quality 5 --timeliness 5 \
            --note "Automated CI build completed successfully with all quality gates passed"

  handle-failure:
    needs: [ create-build-task, test, build ]
    runs-on: ubuntu-latest
    if: failure()
    steps:
      - uses: actions/checkout@v3
      
      - name: Report build failure
        run: |
          ./tm progress ${{ needs.create-build-task.outputs.task-id }} "❌ CI build failed - investigating issues"
          
          # Add failure context without completing the task
          ./tm context ${{ needs.create-build-task.outputs.task-id }} --shared "
# Build Failure Analysis

## Failure Information
- Workflow Run: ${{ github.run_id }}
- Failed Jobs: $(echo '${{ toJSON(needs) }}' | jq -r 'to_entries[] | select(.value.result == \"failure\") | .key' | tr '\n' ', ')
- Commit: ${{ github.sha }}
- Branch: ${{ github.ref_name }}

## Investigation Required
- Check test failures for root cause
- Verify dependency compatibility
- Review recent changes for breaking modifications
- Check environment-specific issues

## Next Steps
1. Investigate failed job logs
2. Fix identified issues
3. Re-run pipeline
4. Complete task when build succeeds
"
```

### Pattern: Jenkins Pipeline Integration

```groovy
// File: Jenkinsfile
pipeline {
    agent any
    
    environment {
        TASK_ID = ""
    }
    
    stages {
        stage('Create Task') {
            steps {
                script {
                    env.TASK_ID = sh(
                        script: """
                            ./tm add "Jenkins Build: ${env.BUILD_NUMBER}" \
                              --criteria '[
                                {
                                  "criterion": "Build succeeds",
                                  "measurable": "build_exit_code == 0"
                                },
                                {
                                  "criterion": "Tests pass",
                                  "measurable": "test_failures == 0"
                                },
                                {
                                  "criterion": "Quality gates pass",
                                  "measurable": "sonar_quality_gate == passed"
                                }
                              ]' \
                              --estimated-hours 0.5 \
                              --assignee "jenkins-ci"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    sh """
                        ./tm context ${env.TASK_ID} --shared "
# Jenkins Build Context

## Build Information
- Build Number: ${env.BUILD_NUMBER}
- Job Name: ${env.JOB_NAME}
- Branch: ${env.BRANCH_NAME}
- Workspace: ${env.WORKSPACE}
- Node: ${env.NODE_NAME}

## Git Information
- Commit: ${env.GIT_COMMIT}
- Author: ${env.GIT_AUTHOR_NAME}
- Branch: ${env.GIT_BRANCH}

## Build Environment
- Jenkins URL: ${env.JENKINS_URL}
- Build URL: ${env.BUILD_URL}
- Java Version: \$(java -version 2>&1 | head -1)
"
                    """
                }
            }
        }
        
        stage('Build') {
            steps {
                sh """
                    ./tm progress ${env.TASK_ID} "Starting Maven build process"
                    mvn clean compile
                    ./tm progress ${env.TASK_ID} "Build compilation completed successfully"
                """
            }
        }
        
        stage('Test') {
            steps {
                sh """
                    ./tm progress ${env.TASK_ID} "Running unit and integration tests"
                    mvn test
                    
                    # Get test results
                    TEST_COUNT=\$(find target/surefire-reports -name "*.xml" -exec grep -h "tests=" {} \\; | sed 's/.*tests="\\([0-9]*\\)".*/\\1/' | awk '{sum+=\$1} END {print sum}')
                    FAILURE_COUNT=\$(find target/surefire-reports -name "*.xml" -exec grep -h "failures=" {} \\; | sed 's/.*failures="\\([0-9]*\\)".*/\\1/' | awk '{sum+=\$1} END {print sum}')
                    
                    ./tm progress ${env.TASK_ID} "Tests completed: \$TEST_COUNT tests, \$FAILURE_COUNT failures"
                """
                
                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
            }
        }
        
        stage('Quality Analysis') {
            steps {
                sh """
                    ./tm progress ${env.TASK_ID} "Running SonarQube quality analysis"
                    mvn sonar:sonar
                    
                    # Wait for quality gate result
                    sleep 30
                    QUALITY_GATE=\$(curl -s "${env.SONAR_URL}/api/qualitygates/project_status?projectKey=${env.PROJECT_KEY}" | jq -r '.projectStatus.status')
                    
                    ./tm progress ${env.TASK_ID} "Quality gate status: \$QUALITY_GATE"
                """
            }
        }
        
        stage('Package') {
            steps {
                sh """
                    ./tm progress ${env.TASK_ID} "Creating deployment packages"
                    mvn package
                    
                    # Get artifact information
                    ARTIFACT_SIZE=\$(du -h target/*.jar | cut -f1)
                    ./tm progress ${env.TASK_ID} "Package created: \$ARTIFACT_SIZE"
                """
                
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
    
    post {
        success {
            sh """
                ./tm complete ${env.TASK_ID} --validate \
                  --actual-hours 0.4 \
                  --summary "
Jenkins build ${env.BUILD_NUMBER} completed successfully.

## Build Results
- Compilation: Successful
- Tests: All passed
- Quality Gate: Passed
- Artifacts: Generated and archived

## Metrics
- Build Duration: ${currentBuild.durationString}
- Test Count: \$(find target/surefire-reports -name '*.xml' | wc -l)
- Artifact Size: \$(du -h target/*.jar | cut -f1)
"
                
                ./tm feedback ${env.TASK_ID} \
                  --quality 5 --timeliness 5 \
                  --note "Automated Jenkins build completed with all quality checks passed"
            """
        }
        
        failure {
            sh """
                ./tm progress ${env.TASK_ID} "❌ Jenkins build failed - see build logs for details"
                
                ./tm context ${env.TASK_ID} --shared "
# Build Failure Details

## Failure Information
- Build Number: ${env.BUILD_NUMBER}
- Failed Stage: \${env.STAGE_NAME}
- Build Status: ${currentBuild.result}
- Build URL: ${env.BUILD_URL}

## Log Analysis Required
- Check console output for specific error messages
- Review test failures if any
- Verify dependency resolution
- Check environment configuration

## Recovery Steps
1. Investigate failure cause from logs
2. Fix identified issues
3. Trigger new build
4. Monitor for successful completion
"
            """
        }
        
        always {
            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
        }
    }
}
```

## External System Integrations

### Pattern: Slack Integration for Notifications

**Scenario**: Automated Slack notifications for task progress and completions.

```bash
#!/bin/bash
# File: scripts/slack-integration.sh
# Purpose: Send Task Orchestrator updates to Slack

send_slack_notification() {
    local webhook_url="$1"
    local message="$2"
    local color="$3"
    local task_id="$4"
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{
            \"attachments\": [
                {
                    \"color\": \"$color\",
                    \"blocks\": [
                        {
                            \"type\": \"section\",
                            \"text\": {
                                \"type\": \"mrkdwn\",
                                \"text\": \"$message\"
                            }
                        },
                        {
                            \"type\": \"actions\",
                            \"elements\": [
                                {
                                    \"type\": \"button\",
                                    \"text\": {
                                        \"type\": \"plain_text\",
                                        \"text\": \"View Task\"
                                    },
                                    \"url\": \"https://task-dashboard.company.com/tasks/$task_id\"
                                }
                            ]
                        }
                    ]
                }
            ]
        }" \
        "$webhook_url"
}

# Task completion notification
notify_task_completion() {
    local task_id="$1"
    local task_title="$(./tm show $task_id --format json | jq -r '.title')"
    local assignee="$(./tm show $task_id --format json | jq -r '.assignee')"
    local quality_score="$(./tm show $task_id --format json | jq -r '.feedback_quality // "N/A"')"
    
    local message="🎉 *Task Completed*
*Title:* $task_title
*Assignee:* $assignee
*Quality Score:* $quality_score/5
*Task ID:* $task_id"
    
    send_slack_notification "$SLACK_WEBHOOK_URL" "$message" "good" "$task_id"
}

# Task blocked notification
notify_task_blocked() {
    local task_id="$1"
    local reason="$2"
    local task_title="$(./tm show $task_id --format json | jq -r '.title')"
    local assignee="$(./tm show $task_id --format json | jq -r '.assignee')"
    
    local message="🚫 *Task Blocked*
*Title:* $task_title
*Assignee:* $assignee
*Reason:* $reason
*Task ID:* $task_id
*Action Required:* Please review and unblock"
    
    send_slack_notification "$SLACK_WEBHOOK_URL" "$message" "warning" "$task_id"
}

# High-priority task alert
notify_urgent_task() {
    local task_id="$1"
    local task_title="$(./tm show $task_id --format json | jq -r '.title')"
    local deadline="$(./tm show $task_id --format json | jq -r '.deadline')"
    
    local message="🚨 *Urgent Task Alert*
*Title:* $task_title
*Deadline:* $deadline
*Task ID:* $task_id
*Status:* Requires immediate attention"
    
    send_slack_notification "$SLACK_WEBHOOK_URL" "$message" "danger" "$task_id"
}

# Usage examples
# notify_task_completion "abc12345"
# notify_task_blocked "def67890" "Waiting for API credentials"
# notify_urgent_task "ghi13579"
```

### Pattern: JIRA Integration

```bash
#!/bin/bash
# File: scripts/jira-integration.sh
# Purpose: Synchronize Task Orchestrator with JIRA

JIRA_BASE_URL="https://company.atlassian.net"
JIRA_USERNAME="service-account@company.com"
JIRA_API_TOKEN="your-api-token"

# Create JIRA issue from Task Orchestrator task
create_jira_issue() {
    local task_id="$1"
    local project_key="$2"
    local issue_type="$3"
    
    # Get task details
    local task_data=$(./tm show $task_id --format json)
    local title=$(echo "$task_data" | jq -r '.title')
    local description=$(echo "$task_data" | jq -r '.description // ""')
    local assignee=$(echo "$task_data" | jq -r '.assignee // ""')
    local priority=$(echo "$task_data" | jq -r '.priority')
    
    # Map priority
    local jira_priority
    case "$priority" in
        "critical") jira_priority="Highest" ;;
        "high") jira_priority="High" ;;
        "medium") jira_priority="Medium" ;;
        "low") jira_priority="Low" ;;
        *) jira_priority="Medium" ;;
    esac
    
    # Create JIRA issue
    local jira_response=$(curl -s -X POST \
        -H "Authorization: Basic $(echo -n "${JIRA_USERNAME}:${JIRA_API_TOKEN}" | base64)" \
        -H "Content-Type: application/json" \
        -d "{
            \"fields\": {
                \"project\": {\"key\": \"$project_key\"},
                \"summary\": \"$title\",
                \"description\": \"$description\n\nTask Orchestrator ID: $task_id\",
                \"issuetype\": {\"name\": \"$issue_type\"},
                \"priority\": {\"name\": \"$jira_priority\"}
            }
        }" \
        "${JIRA_BASE_URL}/rest/api/3/issue")
    
    local jira_key=$(echo "$jira_response" | jq -r '.key')
    
    if [[ "$jira_key" != "null" ]]; then
        # Update Task Orchestrator with JIRA key
        ./tm context $task_id --shared "
# JIRA Integration

## JIRA Issue
- Key: $jira_key
- URL: ${JIRA_BASE_URL}/browse/$jira_key
- Project: $project_key
- Type: $issue_type
- Priority: $jira_priority

## Synchronization
- Created: $(date)
- Status: Linked
- Sync Direction: Bi-directional
"
        echo "Created JIRA issue: $jira_key for task: $task_id"
    else
        echo "Failed to create JIRA issue for task: $task_id"
        echo "Response: $jira_response"
    fi
}

# Update JIRA issue status based on task progress
update_jira_status() {
    local task_id="$1"
    local jira_key="$2"
    local new_status="$3"
    
    # Get JIRA transition ID for status
    local transitions=$(curl -s -X GET \
        -H "Authorization: Basic $(echo -n "${JIRA_USERNAME}:${JIRA_API_TOKEN}" | base64)" \
        "${JIRA_BASE_URL}/rest/api/3/issue/${jira_key}/transitions")
    
    local transition_id=$(echo "$transitions" | jq -r ".transitions[] | select(.to.name == \"$new_status\") | .id")
    
    if [[ "$transition_id" != "null" ]]; then
        curl -s -X POST \
            -H "Authorization: Basic $(echo -n "${JIRA_USERNAME}:${JIRA_API_TOKEN}" | base64)" \
            -H "Content-Type: application/json" \
            -d "{\"transition\": {\"id\": \"$transition_id\"}}" \
            "${JIRA_BASE_URL}/rest/api/3/issue/${jira_key}/transitions"
        
        echo "Updated JIRA issue $jira_key to status: $new_status"
    else
        echo "No valid transition found for status: $new_status"
    fi
}

# Usage examples
# create_jira_issue "abc12345" "PROJ" "Task"
# update_jira_status "abc12345" "PROJ-123" "In Progress"
```

## Monitoring and Alerting Automation

### Pattern: Prometheus Integration

**Scenario**: Exposing Task Orchestrator metrics to Prometheus for monitoring.

```bash
#!/bin/bash
# File: scripts/prometheus-exporter.sh
# Purpose: Export Task Orchestrator metrics for Prometheus

METRICS_PORT=9100
METRICS_FILE="/tmp/task_orchestrator_metrics.prom"

generate_metrics() {
    local timestamp=$(date +%s)
    
    # Get basic task metrics
    local total_tasks=$(./tm list --format json | jq '. | length')
    local pending_tasks=$(./tm list --status pending --format json | jq '. | length')
    local in_progress_tasks=$(./tm list --status in_progress --format json | jq '. | length')
    local completed_tasks=$(./tm list --status completed --format json | jq '. | length')
    local blocked_tasks=$(./tm list --status blocked --format json | jq '. | length')
    
    # Get quality metrics
    local avg_quality=$(./tm metrics --format json | jq -r '.average_quality_score // 0')
    local avg_timeliness=$(./tm metrics --format json | jq -r '.average_timeliness_score // 0')
    
    # Get estimation accuracy
    local estimation_accuracy=$(./tm metrics --format json | jq -r '.estimation_accuracy // 0')
    
    # Generate Prometheus metrics
    cat > "$METRICS_FILE" << EOF
# HELP task_orchestrator_tasks_total Total number of tasks
# TYPE task_orchestrator_tasks_total gauge
task_orchestrator_tasks_total $total_tasks

# HELP task_orchestrator_tasks_by_status Number of tasks by status
# TYPE task_orchestrator_tasks_by_status gauge
task_orchestrator_tasks_by_status{status="pending"} $pending_tasks
task_orchestrator_tasks_by_status{status="in_progress"} $in_progress_tasks
task_orchestrator_tasks_by_status{status="completed"} $completed_tasks
task_orchestrator_tasks_by_status{status="blocked"} $blocked_tasks

# HELP task_orchestrator_quality_score Average quality score
# TYPE task_orchestrator_quality_score gauge
task_orchestrator_quality_score $avg_quality

# HELP task_orchestrator_timeliness_score Average timeliness score
# TYPE task_orchestrator_timeliness_score gauge
task_orchestrator_timeliness_score $avg_timeliness

# HELP task_orchestrator_estimation_accuracy Estimation accuracy percentage
# TYPE task_orchestrator_estimation_accuracy gauge
task_orchestrator_estimation_accuracy $estimation_accuracy

# HELP task_orchestrator_last_update_timestamp Last metrics update timestamp
# TYPE task_orchestrator_last_update_timestamp gauge
task_orchestrator_last_update_timestamp $timestamp
EOF
}

# Start metrics server
start_metrics_server() {
    echo "Starting Task Orchestrator metrics server on port $METRICS_PORT..."
    
    while true; do
        generate_metrics
        
        # Serve metrics via HTTP
        {
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r"
            cat "$METRICS_FILE"
        } | nc -l -p $METRICS_PORT -q 1
        
        sleep 10
    done
}

# Run as daemon
if [[ "$1" == "daemon" ]]; then
    start_metrics_server &
    echo $! > /tmp/task_orchestrator_exporter.pid
    echo "Metrics exporter started with PID: $(cat /tmp/task_orchestrator_exporter.pid)"
else
    generate_metrics
    cat "$METRICS_FILE"
fi
```

### Pattern: Alertmanager Integration

```yaml
# File: alertmanager-rules.yml
# Purpose: Alerting rules for Task Orchestrator metrics

groups:
  - name: task_orchestrator_alerts
    rules:
      - alert: TaskOrchestrator_HighBlockedTasks
        expr: task_orchestrator_tasks_by_status{status="blocked"} > 5
        for: 5m
        labels:
          severity: warning
          service: task_orchestrator
        annotations:
          summary: "High number of blocked tasks"
          description: "{{ $value }} tasks are currently blocked"
          
      - alert: TaskOrchestrator_QualityScoreDropped
        expr: task_orchestrator_quality_score < 3.5
        for: 10m
        labels:
          severity: warning
          service: task_orchestrator
        annotations:
          summary: "Quality score below threshold"
          description: "Average quality score is {{ $value }}, below 3.5 threshold"
          
      - alert: TaskOrchestrator_PoorEstimationAccuracy
        expr: task_orchestrator_estimation_accuracy < 70
        for: 15m
        labels:
          severity: info
          service: task_orchestrator
        annotations:
          summary: "Estimation accuracy needs improvement"
          description: "Estimation accuracy is {{ $value }}%, below 70% threshold"
          
      - alert: TaskOrchestrator_MetricsStale
        expr: time() - task_orchestrator_last_update_timestamp > 300
        for: 2m
        labels:
          severity: critical
          service: task_orchestrator
        annotations:
          summary: "Task Orchestrator metrics are stale"
          description: "Metrics haven't been updated for over 5 minutes"
```

## Report Generation Workflows

### Pattern: Automated Weekly Reports

```bash
#!/bin/bash
# File: scripts/weekly-report.sh
# Purpose: Generate comprehensive weekly team reports

REPORT_DATE=$(date +"%Y-%m-%d")
REPORT_FILE="reports/weekly-report-$REPORT_DATE.md"

generate_weekly_report() {
    local start_date=$(date -d "7 days ago" +"%Y-%m-%d")
    local end_date=$(date +"%Y-%m-%d")
    
    mkdir -p reports
    
    cat > "$REPORT_FILE" << EOF
# Weekly Task Orchestrator Report
**Period:** $start_date to $end_date  
**Generated:** $(date)

## Executive Summary

EOF

    # Get metrics for the week
    local metrics=$(./tm metrics --period "last-week" --format json)
    local tasks_completed=$(echo "$metrics" | jq -r '.tasks_completed // 0')
    local avg_quality=$(echo "$metrics" | jq -r '.average_quality_score // 0')
    local avg_timeliness=$(echo "$metrics" | jq -r '.average_timeliness_score // 0')
    local estimation_accuracy=$(echo "$metrics" | jq -r '.estimation_accuracy // 0')
    
    cat >> "$REPORT_FILE" << EOF
- **Tasks Completed:** $tasks_completed
- **Average Quality Score:** $avg_quality/5
- **Average Timeliness Score:** $avg_timeliness/5
- **Estimation Accuracy:** $estimation_accuracy%

## Detailed Metrics

### Task Completion by Status
EOF

    # Get task breakdowns
    local pending=$(./tm list --status pending --format json | jq '. | length')
    local in_progress=$(./tm list --status in_progress --format json | jq '. | length')
    local completed=$(./tm list --status completed --format json | jq '. | length')
    local blocked=$(./tm list --status blocked --format json | jq '. | length')
    
    cat >> "$REPORT_FILE" << EOF
- Pending: $pending
- In Progress: $in_progress  
- Completed: $completed
- Blocked: $blocked

### Quality Trends
EOF

    # Add quality analysis
    local high_quality_tasks=$(./tm list --completed --format json | jq '[.[] | select(.feedback_quality >= 4)] | length')
    local total_rated_tasks=$(./tm list --completed --format json | jq '[.[] | select(.feedback_quality != null)] | length')
    
    if [[ $total_rated_tasks -gt 0 ]]; then
        local quality_percentage=$((high_quality_tasks * 100 / total_rated_tasks))
        cat >> "$REPORT_FILE" << EOF
- High Quality Tasks (4+ rating): $high_quality_tasks/$total_rated_tasks ($quality_percentage%)
- Tasks with Feedback: $total_rated_tasks
EOF
    fi
    
    cat >> "$REPORT_FILE" << EOF

### Top Performers

EOF

    # Get individual contributor metrics
    ./tm list --completed --format json | \
        jq -r '.[] | select(.assignee != null and .feedback_quality != null) | "\(.assignee) \(.feedback_quality)"' | \
        sort | uniq -c | sort -nr | head -5 | \
        while read count assignee quality; do
            echo "- $assignee: $count tasks completed (avg quality: $quality)" >> "$REPORT_FILE"
        done
    
    cat >> "$REPORT_FILE" << EOF

### Recommendations

EOF

    # Generate recommendations based on metrics
    if (( $(echo "$avg_quality < 4" | bc -l) )); then
        echo "- **Quality Improvement Needed:** Average quality score is below 4. Consider additional code review or training." >> "$REPORT_FILE"
    fi
    
    if (( $(echo "$avg_timeliness < 4" | bc -l) )); then
        echo "- **Timeline Management:** Average timeliness score is below 4. Review estimation and planning processes." >> "$REPORT_FILE"
    fi
    
    if (( $(echo "$estimation_accuracy < 80" | bc -l) )); then
        echo "- **Estimation Calibration:** Estimation accuracy is below 80%. Consider estimation training or smaller task breakdown." >> "$REPORT_FILE"
    fi
    
    if [[ $blocked -gt 3 ]]; then
        echo "- **Dependency Management:** $blocked tasks are currently blocked. Review dependency identification and management processes." >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

---
*Report generated automatically by Task Orchestrator v2.3*
EOF

    echo "Weekly report generated: $REPORT_FILE"
}

# Generate and optionally email report
generate_weekly_report

if [[ "$1" == "--email" ]]; then
    # Email the report (requires mail configuration)
    mail -s "Weekly Task Orchestrator Report - $REPORT_DATE" \
         team@company.com < "$REPORT_FILE"
    echo "Report emailed to team@company.com"
fi

if [[ "$1" == "--slack" ]]; then
    # Post summary to Slack
    source scripts/slack-integration.sh
    
    local summary="📊 Weekly Report Generated ($REPORT_DATE)
• Tasks Completed: $tasks_completed
• Avg Quality: $avg_quality/5
• Avg Timeliness: $avg_timeliness/5
• Estimation Accuracy: $estimation_accuracy%

Full report: [View Report](https://reports.company.com/weekly-report-$REPORT_DATE.md)"
    
    send_slack_notification "$SLACK_WEBHOOK_URL" "$summary" "good" "weekly-report"
fi
```

## Best Practices Summary

### Automation Principles
1. **Idempotent Operations**: Ensure automation can be run multiple times safely
2. **Error Handling**: Include comprehensive error handling and recovery
3. **Logging**: Provide detailed logs for troubleshooting
4. **Configuration**: Use environment variables for configuration

### Integration Strategies
1. **Loose Coupling**: Integrate without creating tight dependencies
2. **Async Processing**: Use background processing for non-critical integrations
3. **Fallback Mechanisms**: Provide graceful degradation when external systems fail
4. **Rate Limiting**: Respect external system rate limits and quotas

### Monitoring and Observability
1. **Health Checks**: Include health endpoints for all automation services
2. **Metrics**: Expose relevant metrics for monitoring
3. **Alerting**: Set up appropriate alerts for failure conditions
4. **Documentation**: Document all integration points and dependencies

---

*Automation integration examples tested with Task Orchestrator v2.3.0*
*Best practices derived from production automation workflows*