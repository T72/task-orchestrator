# Task Orchestrator Architecture

## Status: Implemented
- **Implemented**: Actual architecture as built in v2.3.0
- **Verified**: All components exist and function as described

## Last Verified: 2025-08-21
Against version: 2.3.0

## Overview

Task Orchestrator is a standalone Python-based task management system designed for multi-agent coordination, particularly optimized for AI agents like Claude Code.

## System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     USER/AGENT                            │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   CLI INTERFACE (tm)                      │
│                    540 lines bash                         │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│              PYTHON CORE (src/*.py)                       │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │     tm_production.py (998 lines)               │     │
│  │     Core task management and database          │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │     tm_collaboration.py (348 lines)            │     │
│  │     Multi-agent coordination features          │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │     tm_orchestrator.py (287 lines)             │     │
│  │     Task orchestration and scheduling          │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │     tm_worker.py (434 lines)                   │     │
│  │     Background worker processes                │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │     Supporting Modules                         │     │
│  │     - config_manager.py                        │     │
│  │     - criteria_validator.py                    │     │
│  │     - error_handler.py                         │     │
│  │     - metrics_calculator.py                    │     │
│  │     - telemetry.py                             │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                  DATA STORAGE LAYER                       │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │            SQLite Database                       │    │
│  │     ~/.task-orchestrator/tasks.db               │    │
│  │     Core task data and relationships            │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │            File-Based Storage                    │    │
│  │     ~/.task-orchestrator/shared_context/        │    │
│  │     YAML files for collaboration                │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

## Component Descriptions

### CLI Interface (`tm`)
- **Purpose**: Command-line interface wrapper
- **Language**: Bash
- **Lines**: ~540
- **Responsibilities**:
  - Parse command-line arguments
  - Route commands to Python implementation
  - Format output for terminal display

### Core Module (`tm_production.py`)
- **Purpose**: Core task management functionality
- **Lines**: ~998
- **Key Features**:
  - Task CRUD operations
  - Database management
  - Dependency tracking
  - Core Loop v2.3 features (success criteria, feedback, metrics)

### Collaboration Module (`tm_collaboration.py`)
- **Purpose**: Multi-agent coordination
- **Lines**: ~348
- **Key Features**:
  - Shared context management
  - Private notes
  - Agent communication
  - Synchronization points

### Orchestrator Module (`tm_orchestrator.py`)
- **Purpose**: Task scheduling and automation
- **Lines**: ~287
- **Key Features**:
  - Dependency resolution
  - Task routing
  - Event handling
  - Notification system

### Worker Module (`tm_worker.py`)
- **Purpose**: Background processing
- **Lines**: ~434
- **Key Features**:
  - Asynchronous task execution
  - Progress monitoring
  - Error recovery
  - Resource management

## Data Flow

```
1. User/Agent Input
   │
   ├─→ CLI Parser (tm script)
   │   └─→ Command validation
   │
   ▼
2. Python Core Processing
   │
   ├─→ tm_production.py
   │   └─→ Core operations
   │
   ├─→ tm_collaboration.py
   │   └─→ Multi-agent features
   │
   ▼
3. Data Persistence
   │
   ├─→ SQLite Database
   │   └─→ Structured task data
   │
   ├─→ File System
   │   └─→ Shared context YAML
   │
   ▼
4. Response/Output
   │
   └─→ Formatted CLI output
```

## Storage Architecture

### SQLite Database Schema
Primary storage for task data with tables:
- `tasks` - Core task information
- `task_participants` - Agent collaboration
- `task_dependencies` - Dependency graph
- `notifications` - Event notifications
- `migrations` - Schema version tracking

### File-Based Storage
Complementary storage for:
- Shared context (YAML format)
- Private notes (Markdown format)
- Configuration (JSON format)
- Telemetry logs (JSONL format)

## Key Design Decisions

### 1. Hybrid Storage Model
- **SQLite**: Structured data requiring ACID properties
- **Files**: Flexible content and human-readable formats
- **Rationale**: Best tool for each data type

### 2. Modular Architecture
- **Separation**: Clear module boundaries
- **Independence**: Each module has specific responsibility
- **Testing**: Modules can be tested independently

### 3. Zero External Dependencies
- **Python Standard Library Only**: No pip packages required
- **Rationale**: Maximum portability and reliability

### 4. CLI Wrapper Pattern
- **Bash Script**: Handles argument parsing
- **Python Core**: Business logic implementation
- **Rationale**: Leverages strengths of each language

## Performance Characteristics

```
┌─────────────────────────────────────────────────────┐
│             Performance Metrics                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Startup Time:        ~200ms (Python import)       │
│  Memory Usage:        ~20MB baseline               │
│  Database Size:       Grows ~1KB per task          │
│  Max Tasks:           Limited by disk space        │
│  Concurrent Agents:   Limited by file locks        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Deployment Structure

```
~/.task-orchestrator/
├── tasks.db                  # SQLite database
├── shared_context/           # Collaboration data
│   └── task_*.yaml          # Per-task context
├── private_notes/           # Agent private notes
│   └── agent_*/            # Per-agent directory
├── config/                  # Configuration
│   └── features.json       # Feature flags
├── telemetry/              # Usage metrics
│   └── events.jsonl        # Event log
└── backups/                # Database backups
    └── tasks_backup_*.db   # Timestamped backups
```

## Integration Points

### For AI Agents (Claude Code, etc.)
- **CLI Commands**: Standard Unix interface
- **Exit Codes**: Standard success/error signaling
- **JSON Output**: Machine-readable format option
- **Environment Variables**: Configuration options

### For Automation
- **Watch Mode**: Monitor for task changes
- **Export Formats**: JSON, CSV, Markdown
- **Notification System**: Event-driven updates

## Security Considerations

- **Local Only**: No network services
- **File Permissions**: User-level access control
- **No Authentication**: Relies on OS user permissions
- **Backup Strategy**: Automatic before migrations

## Limitations

- **Single Node**: No distributed operation
- **File Locking**: Can cause contention with many agents
- **No REST API**: CLI interface only
- **No Web UI**: Terminal-based interaction

## Future Architecture Considerations

Potential enhancements maintaining current simplicity:
- REST API layer (optional service)
- Web dashboard (separate project)
- Distributed coordination (via shared filesystem)
- Plugin system (Python module loading)

---

*This document describes the actual implemented architecture of Task Orchestrator v2.3.0*