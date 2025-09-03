# Task Orchestrator - Deployment Package
Version: 1.0.0
Packaged: 2025-08-19 19:32:18 UTC

## Quick Start

1. Extract this package to your tools directory
2. Deploy to a project:
   ```bash
   ./deploy/install.sh /path/to/your/project
   ```

## Contents

- `tm` - Main task orchestrator executable
- `src/` - Python modules (if applicable)
- `scripts/` - Helper scripts
- `deploy/` - Deployment tools and documentation

## Deployment Options

### Single Project
```bash
./deploy/install.sh /path/to/project
```

### Multiple Projects
```bash
python3 deploy/deploy.py --batch projects.txt
```

See `deploy/README.md` for full deployment documentation.

## Requirements

- Python 3.8+
- Git (optional, but recommended)
- Unix-like environment (Linux, macOS) or Windows with WSL

## Support

For documentation and support, visit:
https://github.com/T72/task-orchestrator
