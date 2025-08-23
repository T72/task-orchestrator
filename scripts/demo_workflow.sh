#!/bin/bash

# Demo: Role-Based Task Orchestrator Workflow
# Shows how orchestrator and workers interact

set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Task Orchestrator Role-Based Workflow Demo"
echo "========================================"
echo ""

# Setup
DEMO_DIR="/tmp/tm_demo_$$"
mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"
git init --quiet

# Copy the scripts
cp /mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/tm_orchestrator.py .
cp /mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/tm_worker.py .
chmod +x *.py

echo -e "${BLUE}=== Scenario: User requests 'Build a login system' ===${NC}"
echo ""

# Orchestrator receives request
echo -e "${BLUE}[ORCHESTRATOR] Creating project...${NC}"
PROJECT_ID=$(python3 tm_orchestrator.py --id main_orchestrator project "Build login system" | grep "Project ID:" | cut -d' ' -f3)
echo "Created project: $PROJECT_ID"
echo ""

echo -e "${BLUE}[ORCHESTRATOR] Breaking down into work items...${NC}"
DB_ITEM=$(python3 tm_orchestrator.py create $PROJECT_ID "Design user database" \
  -d "Create schema for users and sessions" \
  -r "Users table with email, password" "Sessions table with tokens" | grep "Work item ID:" | cut -d' ' -f3)
echo "Created work item: $DB_ITEM - Design user database"

AUTH_ITEM=$(python3 tm_orchestrator.py create $PROJECT_ID "Implement authentication" \
  -d "JWT-based authentication logic" \
  -r "Login endpoint" "Logout endpoint" "Token refresh" | grep "Work item ID:" | cut -d' ' -f3)
echo "Created work item: $AUTH_ITEM - Implement authentication"

UI_ITEM=$(python3 tm_orchestrator.py create $PROJECT_ID "Create login UI" \
  -d "Frontend login form" \
  -r "Login form" "Password reset link" "Remember me option" | grep "Work item ID:" | cut -d' ' -f3)
echo "Created work item: $UI_ITEM - Create login UI"
echo ""

echo -e "${BLUE}[ORCHESTRATOR] Assigning work to specialists...${NC}"
python3 tm_orchestrator.py assign $DB_ITEM database_expert
echo "Assigned $DB_ITEM to database_expert"

python3 tm_orchestrator.py assign $AUTH_ITEM backend_dev
echo "Assigned $AUTH_ITEM to backend_dev"

python3 tm_orchestrator.py assign $UI_ITEM frontend_dev
echo "Assigned $UI_ITEM to frontend_dev"
echo ""

echo "========================================"
echo -e "${GREEN}[DATABASE EXPERT] Starting work...${NC}"
export AGENT_ID="database_expert"

# Check assignments
echo "Checking assignments..."
python3 tm_worker.py check

# Get work details
echo "Getting work details..."
python3 tm_worker.py get $DB_ITEM

# Work on task
echo "Working on database design..."
python3 tm_worker.py progress $DB_ITEM "Analyzing requirements"
sleep 1
python3 tm_worker.py progress $DB_ITEM "Creating ER diagram" --percent 30
sleep 1
python3 tm_worker.py discover $DB_ITEM "Need additional table for password reset tokens" \
  --impact "Improves security by separating concerns"
sleep 1
python3 tm_worker.py progress $DB_ITEM "Finalizing schema with 3 tables" --percent 90
python3 tm_worker.py complete $DB_ITEM "Database schema complete: users, sessions, password_resets tables"
echo -e "${GREEN}Database work completed!${NC}"
echo ""

echo "========================================"
echo -e "${YELLOW}[BACKEND DEV] Starting work...${NC}"
export AGENT_ID="backend_dev"

# Check assignments
echo "Checking assignments..."
python3 tm_worker.py check

# Work on task
echo "Working on authentication..."
python3 tm_worker.py progress $AUTH_ITEM "Setting up JWT library"
sleep 1
python3 tm_worker.py progress $AUTH_ITEM "Implementing login endpoint" --percent 40
python3 tm_worker.py discover $AUTH_ITEM "Rate limiting needed to prevent brute force" \
  --impact "Security requirement"
sleep 1
python3 tm_worker.py progress $AUTH_ITEM "Adding refresh token logic" --percent 70
python3 tm_worker.py complete $AUTH_ITEM "Authentication complete with JWT and refresh tokens"
echo -e "${YELLOW}Backend work completed!${NC}"
echo ""

echo "========================================"
echo -e "${BLUE}[ORCHESTRATOR] Checking progress...${NC}"
python3 tm_orchestrator.py --id main_orchestrator progress $PROJECT_ID

echo ""
echo -e "${BLUE}[ORCHESTRATOR] Reviewing discoveries...${NC}"
python3 tm_orchestrator.py --id main_orchestrator discoveries $PROJECT_ID

echo ""
echo -e "${BLUE}[ORCHESTRATOR] Completing project...${NC}"
python3 tm_orchestrator.py --id main_orchestrator complete $PROJECT_ID

echo ""
echo "========================================"
echo -e "${GREEN}✅ Demo Complete!${NC}"
echo ""
echo "Key observations:"
echo "1. Orchestrator creates and assigns work"
echo "2. Workers only see their assignments"
echo "3. Clear handoff via structured packages"
echo "4. Progress flows back to orchestrator"
echo "5. No confusion about roles or responsibilities"
echo ""

# Cleanup
cd /
rm -rf "$DEMO_DIR"

echo "Demo files cleaned up."