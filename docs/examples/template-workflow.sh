#!/bin/bash
# Template Workflow Example (v2.6.0 feature)
# Shows how templates save time on repetitive workflows

echo "=== Task Templates Demo ==="
echo "Stop recreating the same tasks every sprint!"
echo

# Create a reusable sprint template
cat > /tmp/sprint-template.yaml << 'EOF'
name: sprint-template
description: Standard 2-week sprint workflow
tasks:
  - title: "Sprint {{sprint_num}} Planning"
    priority: high
    description: "Plan work for {{feature_name}}"
    
  - title: "Database: {{feature_name}}"
    depends_on: [0]
    assignee: "db_team"
    
  - title: "Backend: {{feature_name}}"
    depends_on: [1]
    assignee: "backend_team"
    
  - title: "Frontend: {{feature_name}}"
    depends_on: [2]
    assignee: "frontend_team"
    
  - title: "Testing: {{feature_name}}"
    depends_on: [3]
    assignee: "qa_team"
    
  - title: "Sprint {{sprint_num}} Review"
    depends_on: [4]
    priority: high
EOF

echo "=== Sprint 1: Authentication Feature ==="
./tm template apply /tmp/sprint-template.yaml \
  --var sprint_num=1 \
  --var feature_name="Authentication"

echo
./tm list
echo

echo "=== Sprint 2: Payment Integration (same template!) ==="
./tm template apply /tmp/sprint-template.yaml \
  --var sprint_num=2 \
  --var feature_name="Payment Integration"

echo
./tm list
echo

echo "=== Sprint 3: Reporting Dashboard (30 seconds vs 30 minutes!) ==="
./tm template apply /tmp/sprint-template.yaml \
  --var sprint_num=3 \
  --var feature_name="Reporting Dashboard"

echo
echo "=== All Tasks Created from Template ==="
./tm list

echo
echo "💡 Time Saved:"
echo "   • Manual creation: 10-15 minutes per sprint"
echo "   • With templates: 30 seconds"
echo "   • 3 sprints saved: 30+ minutes!"
echo
echo "📝 Create templates for:"
echo "   • Bug fix workflows"
echo "   • Feature development"
echo "   • Code reviews"
echo "   • Deployments"
echo "   • Any repetitive process!"

# Cleanup
rm -f /tmp/sprint-template.yaml