#!/bin/bash

# Task Orchestrator Installation Script - Internal Use Only
# Version: 2.0.0
# Date: August 19, 2025

set -e

echo "🚀 Task Orchestrator v2.0.0 - Installation Script"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${1:-$(pwd)}"
BACKUP_DIR="task-orchestrator-backup-$(date +%Y%m%d_%H%M%S)"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check Python version
    if ! python3 --version >/dev/null 2>&1; then
        log_error "Python 3 is required but not installed"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    log_info "✓ Python $PYTHON_VERSION detected"
    
    # Check disk space (need ~10MB)
    AVAILABLE=$(df "$INSTALL_DIR" | tail -1 | awk '{print $4}')
    if [[ $AVAILABLE -lt 10240 ]]; then
        log_warn "Low disk space: ${AVAILABLE}KB available"
    fi
    
    log_info "✓ System requirements met"
}

backup_existing() {
    if [[ -f "$INSTALL_DIR/tm" ]] || [[ -d "$INSTALL_DIR/.task-orchestrator" ]]; then
        log_info "Backing up existing installation..."
        
        mkdir -p "$BACKUP_DIR"
        
        [[ -f "$INSTALL_DIR/tm" ]] && cp "$INSTALL_DIR/tm" "$BACKUP_DIR/"
        [[ -d "$INSTALL_DIR/src" ]] && cp -r "$INSTALL_DIR/src" "$BACKUP_DIR/"
        [[ -d "$INSTALL_DIR/.task-orchestrator" ]] && cp -r "$INSTALL_DIR/.task-orchestrator" "$BACKUP_DIR/"
        [[ -f "$INSTALL_DIR/CLAUDE.md" ]] && cp "$INSTALL_DIR/CLAUDE.md" "$BACKUP_DIR/"
        
        log_info "✓ Backup created: $BACKUP_DIR"
    fi
}

install_files() {
    log_info "Installing Task Orchestrator files..."
    
    # Copy main executable
    if [[ -f "tm" ]]; then
        cp tm "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/tm"
        log_info "✓ Executable installed: $INSTALL_DIR/tm"
    else
        log_error "Main executable 'tm' not found in package"
        exit 1
    fi
    
    # Copy source directory
    if [[ -d "src" ]]; then
        cp -r src "$INSTALL_DIR/"
        log_info "✓ Source files installed: $INSTALL_DIR/src/"
    else
        log_error "Source directory 'src' not found in package"
        exit 1
    fi
    
    # Copy CLAUDE.md example (only if doesn't exist)
    if [[ -f "CLAUDE_INTEGRATION_EXAMPLE.md" ]]; then
        if [[ ! -f "$INSTALL_DIR/CLAUDE.md" ]]; then
            cp CLAUDE_INTEGRATION_EXAMPLE.md "$INSTALL_DIR/CLAUDE.md"
            log_info "✓ CLAUDE.md template installed"
        else
            log_warn "CLAUDE.md already exists - not overwriting"
            cp CLAUDE_INTEGRATION_EXAMPLE.md "$INSTALL_DIR/CLAUDE_TEMPLATE.md"
            log_info "✓ Template saved as CLAUDE_TEMPLATE.md"
        fi
    fi
    
    # Copy documentation (optional)
    if [[ -d "docs" ]]; then
        cp -r docs "$INSTALL_DIR/"
        log_info "✓ Documentation installed: $INSTALL_DIR/docs/"
    fi
}

initialize_database() {
    log_info "Initializing Task Orchestrator database..."
    
    cd "$INSTALL_DIR"
    
    # Check if already initialized
    if [[ -f ".task-orchestrator/tasks.db" ]]; then
        log_warn "Database already exists - skipping initialization"
        return
    fi
    
    # Initialize database
    if ./tm init; then
        log_info "✓ Database initialized successfully"
    else
        log_error "Database initialization failed"
        exit 1
    fi
}

test_installation() {
    log_info "Testing installation..."
    
    cd "$INSTALL_DIR"
    
    # Test basic functionality
    TEST_ID=$(./tm add "Installation test task" | grep -o '[a-f0-9]\{8\}' || echo "")
    
    if [[ -n "$TEST_ID" ]]; then
        ./tm show "$TEST_ID" >/dev/null
        ./tm delete "$TEST_ID" >/dev/null
        log_info "✓ Installation test passed"
    else
        log_error "Installation test failed"
        exit 1
    fi
}

print_success() {
    cat << EOF

${GREEN}✅ Task Orchestrator v2.0.0 Installation Complete!${NC}

📁 Installation Directory: $INSTALL_DIR

🚀 Quick Start:
   cd $INSTALL_DIR
   ./tm add "My first task"
   ./tm list

🤖 Claude Integration:
   Ensure CLAUDE.md is in your project root for automatic agent coordination

📚 Documentation:
   - QUICKSTART_INTERNAL.md - Quick start guide
   - docs/guides/ - Complete user guides  
   - docs/reference/ - API documentation

🔧 Environment Variables (optional):
   export TM_AGENT_ID="your_name"

⚡ Multi-Agent Coordination:
   export TM_AGENT_ID="agent1"
   ./tm add "Team task"
   ./tm join [task_id]
   ./tm share [task_id] "Working on this!"

EOF

    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}📦 Backup Location: $BACKUP_DIR${NC}"
    fi
    
    echo -e "\n${GREEN}Ready for production use!${NC}"
}

# Main installation flow
main() {
    echo "Installing to: $INSTALL_DIR"
    echo ""
    
    check_requirements
    backup_existing
    install_files
    initialize_database
    test_installation
    print_success
}

# Run installation
main "$@"