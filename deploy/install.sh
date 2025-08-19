#!/bin/bash
# Task Orchestrator - Deployment Script for Internal Projects
# This script deploys the task-orchestrator to any development project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SOURCE="${SCRIPT_DIR}/.."
TARGET_PROJECT="${1:-$(pwd)}"
INSTALL_MODE="${2:-link}"  # link or copy

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Header
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   Task Orchestrator Deployment     ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Validate target project
if [ ! -d "$TARGET_PROJECT" ]; then
    print_error "Target directory does not exist: $TARGET_PROJECT"
    exit 1
fi

# Check if git repository
cd "$TARGET_PROJECT"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_warning "Target is not a git repository. Initializing git..."
    git init
fi

print_info "Deploying to: $TARGET_PROJECT"
print_info "Install mode: $INSTALL_MODE"

# Create .task-orchestrator directory
print_info "Creating task orchestrator directory..."
mkdir -p .task-orchestrator

# Deploy main executable
print_info "Deploying task orchestrator executable..."

# Check if enhanced version exists and use it
if [ -f "${DEPLOY_SOURCE}/tm_enhanced.py" ]; then
    print_info "Using enhanced version with collaboration features"
    if [ "$INSTALL_MODE" = "link" ]; then
        ln -sf "${DEPLOY_SOURCE}/tm_enhanced.py" tm
    else
        cp "${DEPLOY_SOURCE}/tm_enhanced.py" tm
    fi
else
    # Fall back to base version
    print_info "Using base version"
    if [ "$INSTALL_MODE" = "link" ]; then
        ln -sf "${DEPLOY_SOURCE}/tm" tm
    else
        cp "${DEPLOY_SOURCE}/tm" tm
    fi
fi
chmod +x tm
print_success "Deployed tm executable"

# Deploy Python modules if they exist
if [ -d "${DEPLOY_SOURCE}/src" ]; then
    print_info "Deploying Python modules..."
    if [ "$INSTALL_MODE" = "link" ]; then
        ln -sf "${DEPLOY_SOURCE}/src" .task-orchestrator/src
    else
        cp -r "${DEPLOY_SOURCE}/src" .task-orchestrator/
    fi
    print_success "Deployed Python modules"
fi

# Deploy helper scripts
print_info "Deploying helper scripts..."
mkdir -p .task-orchestrator/scripts

# Copy essential scripts
for script in agent_helper.sh cleanup-hook.sh; do
    if [ -f "${DEPLOY_SOURCE}/scripts/$script" ]; then
        cp "${DEPLOY_SOURCE}/scripts/$script" .task-orchestrator/scripts/
        chmod +x ".task-orchestrator/scripts/$script"
        print_success "Deployed $script"
    fi
done

# Deploy minimal documentation
print_info "Deploying quick reference..."
cat > .task-orchestrator/QUICK_REFERENCE.md << 'EOF'
# Task Orchestrator - Quick Reference

## Essential Commands
- `./tm init` - Initialize task database
- `./tm add "task"` - Create a task
- `./tm list` - List all tasks
- `./tm update ID --status STATUS` - Update task
- `./tm complete ID` - Complete task
- `./tm help` - Full help

## Status Values
- pending, in_progress, completed, blocked, cancelled

## Examples
```bash
# Create dependent tasks
TASK1=$(./tm add "Setup database")
./tm add "Run migrations" --depends-on $TASK1

# Add file reference
./tm add "Fix bug" --file src/auth.py:42

# Filter tasks
./tm list --status pending --assignee me
```

## Environment Variables
- `TM_AGENT_ID` - Set agent identifier
- `TM_DB_PATH` - Custom database location

For full documentation, see: https://github.com/your-org/task-orchestrator
EOF
print_success "Created quick reference"

# Deploy orchestrator guide if available
if [ -f "${DEPLOY_SOURCE}/docs/ORCHESTRATOR-GUIDE.md" ]; then
    print_info "Deploying orchestrator guide..."
    cp "${DEPLOY_SOURCE}/docs/ORCHESTRATOR-GUIDE.md" .task-orchestrator/
    print_success "Deployed orchestrator guide"
elif [ -f "${DEPLOY_SOURCE}/docs/guides/ORCHESTRATOR-GUIDE.md" ]; then
    print_info "Deploying orchestrator guide..."
    cp "${DEPLOY_SOURCE}/docs/guides/ORCHESTRATOR-GUIDE.md" .task-orchestrator/
    print_success "Deployed orchestrator guide"
fi

# Update or create .gitignore
print_info "Updating .gitignore..."
GITIGNORE_ENTRIES=(
    "# Task Orchestrator"
    ".task-orchestrator/tasks.db"
    ".task-orchestrator/tasks.db-journal"
    ".task-orchestrator/tasks.db-wal"
    ".task-orchestrator/archives/"
    ".task-orchestrator/contexts/"
    ".task-orchestrator/notes/"
    ".task-orchestrator/*.log"
    ".task-orchestrator/.lock"
    ""
)

if [ -f .gitignore ]; then
    # Check if already configured
    if ! grep -q "# Task Orchestrator" .gitignore; then
        echo "" >> .gitignore
        for entry in "${GITIGNORE_ENTRIES[@]}"; do
            echo "$entry" >> .gitignore
        done
        print_success "Updated .gitignore"
    else
        print_info ".gitignore already configured"
    fi
else
    # Create new .gitignore
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        echo "$entry" >> .gitignore
    done
    print_success "Created .gitignore"
fi

# Initialize database
print_info "Initializing task database..."
./tm init
print_success "Database initialized"

# Create initial task (optional)
print_info "Creating welcome task..."
WELCOME_ID=$(./tm add "Welcome to Task Orchestrator! Run './tm help' to get started" -p low | grep -o '[a-f0-9]\{8\}' || echo "")
if [ -n "$WELCOME_ID" ]; then
    ./tm update "$WELCOME_ID" --tag welcome --tag setup
    print_success "Created welcome task: $WELCOME_ID"
fi

# Create project-specific configuration
print_info "Creating project configuration..."
cat > .task-orchestrator/config.json << EOF
{
  "project_name": "$(basename "$TARGET_PROJECT")",
  "installed_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "install_mode": "$INSTALL_MODE",
  "version": "1.0.0",
  "source": "$DEPLOY_SOURCE"
}
EOF
print_success "Created configuration"

# Summary
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   Deployment Complete!              ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
print_success "Task Orchestrator is ready to use!"
echo ""
echo "Next steps:"
echo "  1. Run: ${BLUE}./tm list${NC} to see all tasks"
echo "  2. Run: ${BLUE}./tm add \"Your first task\"${NC} to create a task"
echo "  3. Run: ${BLUE}./tm help${NC} for full documentation"
echo ""
echo "Quick reference available at: ${BLUE}.task-orchestrator/QUICK_REFERENCE.md${NC}"
echo ""

# Optional: Run initial test
read -p "Would you like to test the installation? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running installation test..."
    ./tm list
    print_success "Installation test passed!"
fi