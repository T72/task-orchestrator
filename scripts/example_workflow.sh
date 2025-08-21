#!/bin/bash

# Example workflow demonstrating multi-agent task coordination

echo "=== Task Orchestrator Multi-Agent Workflow Example ==="
echo ""

# Clean slate
rm -rf .task-orchestrator

# Initialize
./tm init
echo "✓ Task manager initialized"
echo ""

# Simulate Agent 1: Project Lead
echo "=== Agent 1 (Project Lead) ==="
echo "Creating project tasks..."

# Create main project structure
FEAT=$(./tm add "Implement payment processing feature" -p high | grep -o '[a-f0-9]\{8\}')
echo "Created feature task: $FEAT"

API=$(./tm add "Design payment API" --depends-on $FEAT -p high | grep -o '[a-f0-9]\{8\}')
echo "Created API design task: $API (depends on $FEAT)"

IMPL=$(./tm add "Implement payment gateway integration" --depends-on $API --file src/payments/gateway.py -p high | grep -o '[a-f0-9]\{8\}')
echo "Created implementation task: $IMPL (depends on $API)"

DB=$(./tm add "Add payment tables to database" --depends-on $API --file migrations/add_payments.sql -p medium | grep -o '[a-f0-9]\{8\}')
echo "Created database task: $DB (depends on $API)"

TESTS=$(./tm add "Write payment integration tests" --depends-on $IMPL --file tests/test_payments.py | grep -o '[a-f0-9]\{8\}')
echo "Created test task: $TESTS (depends on $IMPL)"

echo ""
echo "Current task list:"
./tm list
echo ""

# Simulate Agent 2: Backend Developer
echo "=== Agent 2 (Backend Dev) ==="
echo "Picking up feature task..."
./tm update $FEAT --status in_progress
./tm assign $FEAT backend_agent
echo "Working on feature planning..."
sleep 1
./tm complete $FEAT
echo "✓ Feature planning complete!"
echo ""

echo "Checking notifications:"
./tm watch
echo ""

# Now API task should be unblocked
echo "API task status:"
./tm show $API | grep Status
echo ""

# Simulate Agent 3: API Designer
echo "=== Agent 3 (API Designer) ==="
echo "Starting API design..."
./tm update $API --status in_progress
./tm assign $API api_agent
echo "Designing endpoints..."
sleep 1
./tm complete $API --impact-review
echo "✓ API design complete!"
echo ""

# Both IMPL and DB tasks should now be unblocked
echo "Task statuses after API completion:"
./tm show $IMPL | grep Status
./tm show $DB | grep Status
echo ""

# Simulate parallel work
echo "=== Parallel Work ==="
echo "Agent 2 working on implementation..."
./tm update $IMPL --status in_progress
./tm assign $IMPL backend_agent

echo "Agent 4 working on database..."
./tm update $DB --status in_progress
./tm assign $DB db_agent
echo ""

# Complete database first
echo "Database work completed:"
./tm complete $DB
echo ""

# Complete implementation
echo "Implementation completed:"
./tm complete $IMPL --impact-review
echo ""

# Tests should now be unblocked
echo "Test task status:"
./tm show $TESTS | grep Status
echo ""

# Agent 5: QA Engineer
echo "=== Agent 5 (QA Engineer) ==="
./tm update $TESTS --status in_progress
./tm assign $TESTS qa_agent
echo "Running tests..."
sleep 1
./tm complete $TESTS
echo "✓ All tests passing!"
echo ""

# Final status
echo "=== Final Project Status ==="
./tm list --status completed
echo ""

# Export report
echo "=== Generating Report ==="
./tm export --format markdown > project_report.md
echo "✓ Report saved to project_report.md"
echo ""

# Add improvement notes
echo "=== Adding Future Improvements ==="
./tm add "Optimize payment processing performance" --file src/payments/gateway.py:150 -p low --tag enhancement
./tm add "Add support for cryptocurrency payments" -p low --tag enhancement
./tm add "Implement payment webhooks" --file src/payments/webhooks.py -p medium --tag enhancement
echo ""

echo "Enhancement tasks for future sprints:"
./tm list --status pending
echo ""

echo "=== Workflow Complete ==="
echo "This example demonstrated:"
echo "  ✓ Task creation with dependencies"
echo "  ✓ Automatic blocking/unblocking"
echo "  ✓ Parallel agent coordination"
echo "  ✓ File reference tracking"
echo "  ✓ Impact notifications"
echo "  ✓ Task assignment and status updates"
echo "  ✓ Export capabilities"