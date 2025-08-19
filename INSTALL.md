# Task Orchestrator Installation Guide

## System Requirements

- **Python**: 3.8 or higher
- **OS**: Linux, macOS, or Windows (with WSL)
- **Disk Space**: 10MB minimum
- **Memory**: 50MB runtime memory

## Quick Install (2 Minutes)

```bash
# 1. Clone and setup
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator

# 2. Make executable (Linux/macOS)
chmod +x tm

# 3. Initialize database
./tm init

# 4. Verify installation
./tm add "Test task"
./tm list
```

## Alternative Installation Methods

### Method 1: Direct Download

```bash
# Download latest release
curl -L https://github.com/T72/task-orchestrator/releases/latest/download/tm -o tm
chmod +x tm
./tm init
```

### Method 2: Windows Installation

```bash
# Use Python directly on Windows
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
python tm init
python tm add "Test task"
```

### Method 3: Project-Specific Installation

```bash
# Copy to existing project
cp /path/to/task-orchestrator/tm ./tm
chmod +x tm
./tm init
```

## Verification

```bash
# Test core functionality
./tm add "Setup complete" --priority high
./tm list
./tm complete $(./tm list | grep -o '[a-f0-9]\{8\}' | head -1)
```

## Troubleshooting

- **Permission denied**: Run `chmod +x tm`
- **Not in git repo**: Run `git init` first
- **Database locked**: Wait and retry, or set `export TM_LOCK_TIMEOUT=30`

## Next Steps

- **Quick start**: Read [QUICKSTART.md](QUICKSTART.md) for 2-minute productivity guide
- **Full guide**: See [docs/user-guide.md](docs/user-guide.md) for complete documentation
- **Claude Code**: Check [docs/quickstart-claude-code.md](docs/quickstart-claude-code.md) for AI integration

---

**Installation complete!** Task Orchestrator is ready for use.
