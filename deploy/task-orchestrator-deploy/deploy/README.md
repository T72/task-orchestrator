# Task Orchestrator - Deployment Package

This deployment package allows you to quickly deploy the Task Orchestrator to any internal development project.

## 🚀 Quick Deployment

### Single Project Deployment

```bash
# Navigate to this deploy directory
cd /path/to/task-orchestrator/deploy

# Deploy to a project (copy mode)
./install.sh /path/to/your/project

# Or deploy with symlinks (for development)
./install.sh /path/to/your/project link
```

### Batch Deployment (Multiple Projects)

```bash
# Using Python deployer for multiple projects
python3 deploy.py --batch projects.txt

# Or with symlinks for all
python3 deploy.py --batch projects.txt --mode link
```

## 📦 What Gets Deployed

When you deploy Task Orchestrator to a project, the following is installed:

```
your-project/
├── tm                           # Main executable
├── .task-orchestrator/
│   ├── config.json             # Project configuration
│   ├── tasks.db                # Task database (created on init)
│   ├── scripts/                # Helper scripts
│   │   ├── agent_helper.sh
│   │   └── cleanup-hook.sh
│   ├── src/                    # Python modules (if needed)
│   └── QUICK_REFERENCE.md      # Quick command reference
└── .gitignore                  # Updated with task-orchestrator entries
```

## 🔧 Deployment Options

### Install Script (`install.sh`)

Basic shell script for single project deployment:

```bash
# Default: Copy files to project
./install.sh /path/to/project

# Development: Create symlinks instead
./install.sh /path/to/project link
```

**Features:**
- Automatic git initialization if needed
- Creates all necessary directories
- Updates .gitignore automatically
- Initializes task database
- Creates welcome task
- Interactive testing option

### Python Deployer (`deploy.py`)

Advanced deployment tool with batch capabilities:

```bash
# Single project
python3 deploy.py /path/to/project

# Multiple projects from file
python3 deploy.py --batch projects.txt

# Custom source directory
python3 deploy.py /path/to/project --source /custom/task-orchestrator

# Development mode with symlinks
python3 deploy.py /path/to/project --mode link
```

**Features:**
- Batch deployment to multiple projects
- Progress tracking and summary
- Error handling and reporting
- Configuration management
- Cross-platform compatibility

## 📝 Project List Format

For batch deployment, create a `projects.txt` file:

```
# Frontend projects
/home/dev/projects/web-app
/home/dev/projects/mobile-app

# Backend projects
/home/dev/projects/api-server
/home/dev/projects/microservice-auth
/home/dev/projects/microservice-data

# Comments and blank lines are ignored
```

## 🔄 Deployment Modes

### Copy Mode (Default)
- Files are copied to target project
- Independent installation
- Best for production use
- No dependency on source

### Link Mode (Development)
- Symbolic links to source files
- Changes in source reflect immediately
- Best for development/testing
- Requires source to remain available

## 🎯 Usage in Projects

After deployment, each project can use Task Orchestrator:

```bash
# In deployed project
cd /your/project

# Create tasks
./tm add "Implement new feature"

# Track progress
./tm list
./tm update task_id --status in_progress
./tm complete task_id
```

## 🔐 Security Notes

The deployment:
- Never copies `.claude/` directory (private configuration)
- Never copies archive/ or sensitive documentation
- Updates .gitignore to exclude task databases
- Keeps all task data local to each project

## 📊 Deployment Verification

After deployment, verify installation:

```bash
# Check installation
cd /deployed/project
./tm --version
./tm list

# Check configuration
cat .task-orchestrator/config.json

# View quick reference
cat .task-orchestrator/QUICK_REFERENCE.md
```

## 🛠️ Customization

### Custom Deployment Script

Create your own deployment wrapper:

```bash
#!/bin/bash
# my-deploy.sh

# Set your defaults
ORCHESTRATOR_SOURCE="/company/tools/task-orchestrator"
DEFAULT_MODE="copy"

# Deploy with your settings
for project in "$@"; do
    "${ORCHESTRATOR_SOURCE}/deploy/install.sh" "$project" "$DEFAULT_MODE"
done
```

### Environment Setup

Add to your team's shell configuration:

```bash
# ~/.bashrc or ~/.zshrc
export TASK_ORCHESTRATOR_HOME="/path/to/task-orchestrator"
alias deploy-tm="${TASK_ORCHESTRATOR_HOME}/deploy/install.sh"
```

## 📚 Documentation

After deployment, users can access:
- Quick reference: `.task-orchestrator/QUICK_REFERENCE.md`
- Full documentation: Point to this repository
- Help command: `./tm help`

## 🔍 Troubleshooting

### Permission Denied
```bash
chmod +x deploy/install.sh
chmod +x deploy/deploy.py
```

### Symlink Issues (Windows)
On Windows, you may need administrator privileges for symlinks. Use copy mode instead:
```bash
./install.sh /path/to/project copy
```

### Database Lock Issues
If you get database lock errors, ensure only one process accesses the database:
```bash
export TM_LOCK_TIMEOUT=30
```

## 📈 Best Practices

1. **Use copy mode for production** - More stable and independent
2. **Use link mode for development** - Easier to update and test
3. **Keep a projects.txt file** - Track all deployed projects
4. **Regular updates** - Redeploy when new versions are available
5. **Document project-specific usage** - Add to each project's README

## 🚦 Quick Start Example

```bash
# 1. Clone or download task-orchestrator
git clone https://github.com/T72/task-orchestrator.git

# 2. Navigate to deploy directory
cd task-orchestrator/deploy

# 3. Deploy to your project
./install.sh ~/my-awesome-project

# 4. Start using in your project
cd ~/my-awesome-project
./tm add "Start using Task Orchestrator!"
./tm list
```

That's it! Task Orchestrator is now managing tasks in your project.

---

For more information, see the main [Task Orchestrator documentation](../README.md).