#!/bin/bash
# Multi-Agent Workflow Example
# Shows how multiple AI agents and developers coordinate seamlessly

echo "=== Multi-Agent Payment System Development ==="
echo "Simulating 3 specialists working in parallel..."
echo

# Orchestrator creates the project structure
export TM_AGENT_ID="orchestrator"
EPIC=$(./tm add "Payment System Implementation" -p high | grep -o '[a-f0-9]\{8\}')
echo "🎯 Orchestrator: Created epic $EPIC"

# Database specialist's tasks
DB=$(./tm add "Design payment schema" --depends-on $EPIC | grep -o '[a-f0-9]\{8\}')
./tm share $DB "Need tables for: transactions, payment_methods, refunds"
echo "🗄️  DB Specialist: Will design schema"

# Backend specialist's tasks (depends on DB)
API=$(./tm add "Payment API endpoints" --depends-on $DB | grep -o '[a-f0-9]\{8\}')
./tm note $API "Considering Stripe vs PayPal integration"
echo "⚙️  Backend Dev: Waiting for database schema..."

# Frontend specialist's tasks (depends on API)
UI=$(./tm add "Payment UI components" --depends-on $API | grep -o '[a-f0-9]\{8\}')
echo "🎨 Frontend Dev: Waiting for API..."

echo
echo "=== Initial Status - Notice the Dependencies ==="
./tm list

echo
echo "=== Database specialist completes work ==="
export TM_AGENT_ID="db_specialist"
./tm complete $DB
./tm share $DB "Schema complete: 3 tables, indexes optimized for high volume"

echo
echo "=== Backend can now start (automatically unblocked!) ==="
export TM_AGENT_ID="backend_dev"
./tm update $API --status in_progress
./tm progress $API "30% - Stripe integration working"
./tm progress $API "60% - Refund endpoints complete"
./tm progress $API "90% - Final testing"
./tm complete $API
./tm share $API "API complete: RESTful, 12 endpoints, full test coverage"

echo
echo "=== Frontend can now start (cascade unblocking!) ==="
export TM_AGENT_ID="frontend_dev"
./tm update $UI --status in_progress
./tm share $UI "Building React components with the new API"

echo
echo "=== Final Status - See the Progress ==="
./tm list

echo
echo "=== Shared Context (visible to all agents) ==="
./tm context $EPIC

echo
echo "💡 Key Benefits Demonstrated:"
echo "   • Automatic dependency resolution"
echo "   • Shared context between agents"
echo "   • Private notes for reasoning"
echo "   • Progress tracking"
echo "   • No coordination overhead!"