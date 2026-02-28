# Task Orchestrator Core Loop Architecture

## Overview

Task Orchestrator v2.3 introduces the Core Loop architecture, a sophisticated system for continuous improvement in task management. This document explains the architectural decisions, component relationships, and design patterns that enable robust, scalable task orchestration with quality tracking.

## Table of Contents

- [Architectural Principles](#architectural-principles)
- [System Overview](#system-overview)
- [Component Architecture](#component-architecture)
- [Data Flow Patterns](#data-flow-patterns)
- [Module Interactions](#module-interactions)
- [Design Decisions](#design-decisions)
- [Extension Points](#extension-points)
- [Performance Considerations](#performance-considerations)

## Architectural Principles

### 1. Modularity & Separation of Concerns
Each Core Loop feature is implemented as a separate module with well-defined interfaces.

### 2. Backward Compatibility
All Core Loop features are optional and non-breaking to existing workflows.

### 3. Data Integrity
ACID transactions ensure consistency across all operations.

### 4. Progressive Enhancement
Features can be enabled incrementally as teams mature.

### 5. Fail-Safe Design
System degrades gracefully when optional components fail.

### 6. Performance First
Minimal overhead for basic operations, with complex features opt-in.

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Task Orchestrator                      │
│                     Application Layer                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                    CLI Interface                            │
│                      (tm)                                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  TaskManager                                │
│              (Core Orchestration)                           │
├─────────────────────┬───────────────────────────────────────┤
│ - Basic CRUD        │ - Core Loop Features                  │
│ - Dependencies      │ - Progress Tracking                   │
│ - Notifications     │ - Feedback System                     │
│ - Collaboration     │ - Metrics & Analytics                │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┬─────────────────────┐
    │                 │                 │                     │
┌───▼──┐         ┌───▼──┐         ┌────▼────┐         ┌─────▼─────┐
│Config│         │Migrate│         │Criteria │         │ Metrics   │
│ Mgr  │         │System │         │Validator│         │Calculator │
└──────┘         └──────┘         └─────────┘         └───────────┘
    │                 │                 │                     │
    │            ┌────▼────┐       ┌────▼────┐         ┌─────▼─────┐
    │            │  Error  │       │Telemetry│         │   Event   │
    │            │ Handler │       │ Capture │         │  System   │
    │            └─────────┘       └─────────┘         └───────────┘
    │                 │                 │                     │
    └─────────────────┼─────────────────┼─────────────────────┘
                      │                 │
                 ┌────▼─────────────────▼────┐
                 │       SQLite Database      │
                 │   (ACID + WAL Mode)        │
                 └────────────────────────────┘
```

## Component Architecture

### Core Components

#### 1. TaskManager (Core Orchestration)
**Location**: `src/tm_production.py`  
**Responsibility**: Central orchestration of all task operations

**Key Methods**:
- `add()` - Task creation with Core Loop features
- `complete()` - Task completion with validation
- `progress()` - Progress tracking
- `feedback()` - Quality feedback collection
- `metrics()` - Performance analytics

**Design Pattern**: Facade + Coordinator
- Provides simple interface to complex subsystems
- Coordinates between multiple specialized components
- Maintains backward compatibility with v2.2 API

#### 2. Configuration Manager
**Location**: `src/config_manager.py`  
**Responsibility**: Feature toggle management and configuration persistence

```python
class ConfigManager:
    def __init__(self, config_path: Path):
        self.config_path = config_path
        self.config = self._load_config()
    
    def enable_feature(self, feature: str) -> bool
    def disable_feature(self, feature: str) -> bool
    def set_minimal_mode(self, enabled: bool) -> bool
    def get_config(self) -> Dict[str, bool]
```

**Design Pattern**: Configuration Object
- Centralized feature management
- YAML-based persistence
- Runtime feature toggling
- Default value management

#### 3. Migration System
**Location**: `src/migrations/`  
**Responsibility**: Schema evolution and backward compatibility

```python
class MigrationManager:
    def apply_migrations(self) -> bool
    def rollback(self) -> bool
    def get_status(self) -> Dict[str, Any]
    def create_backup(self) -> Path
```

**Design Pattern**: Migration Pattern + Command Pattern
- Version-controlled schema changes
- Automatic backup creation
- Rollback capability
- Idempotent operations

#### 4. Criteria Validator
**Location**: `src/criteria_validator.py`  
**Responsibility**: Success criteria evaluation and validation

```python
class CriteriaValidator:
    def validate(self, criteria: List[Dict], context: Dict = None) -> Dict
    def parse_expression(self, expression: str) -> Any
    def evaluate_criterion(self, criterion: Dict, context: Dict) -> bool
```

**Design Pattern**: Strategy Pattern + Interpreter Pattern
- Pluggable validation strategies
- Expression language for measurable criteria
- Context-aware evaluation
- Safe expression execution

#### 5. Metrics Calculator
**Location**: `src/metrics_calculator.py`  
**Responsibility**: Performance metrics and analytics computation

```python
class MetricsCalculator:
    def calculate_feedback_metrics(self) -> Dict
    def calculate_time_metrics(self) -> Dict
    def calculate_success_rates(self) -> Dict
    def generate_insights(self) -> Dict
```

**Design Pattern**: Strategy Pattern + Template Method
- Modular metric calculation
- Aggregation strategies
- Caching for performance
- Extensible metric types

#### 6. Telemetry Capture
**Location**: `src/telemetry.py`  
**Responsibility**: Optional usage analytics and pattern detection

```python
class TelemetryCapture:
    def capture_event(self, event_type: str, data: Dict) -> None
    def get_insights(self) -> Dict
    def export_data(self) -> Dict
```

**Design Pattern**: Observer Pattern + Event Sourcing
- Non-intrusive event capture
- Privacy-first design
- Opt-in analytics
- Event aggregation

#### 7. Error Handler
**Location**: `src/error_handler.py`  
**Responsibility**: Robust error handling and recovery

```python
class ErrorHandler:
    def handle_error(self, error: Exception, context: str, critical: bool = False) -> Dict
    def create_recovery_plan(self, error: Exception) -> List[str]
    def log_error(self, error: Exception, context: str) -> None
```

**Design Pattern**: Chain of Responsibility + Strategy Pattern
- Graduated error responses
- Context-aware recovery
- Centralized error logging
- Graceful degradation

## Data Flow Patterns

### 1. Task Creation Flow

```
User Input
    │
    ▼
┌───────────────┐    ┌─────────────┐    ┌──────────────┐
│  CLI Parser   │───▶│TaskManager  │───▶│Configuration │
└───────────────┘    │   .add()    │    │   Manager    │
                     └─────┬───────┘    └──────────────┘
                           │
                     ┌─────▼───────┐    ┌──────────────┐
                     │  Criteria   │───▶│   Database   │
                     │ Validator   │    │  Transaction │
                     └─────────────┘    └──────────────┘
                           │
                     ┌─────▼───────┐
                     │ Telemetry   │
                     │  Capture    │
                     └─────────────┘
```

### 2. Completion Validation Flow

```
Complete Request
    │
    ▼
┌───────────────┐    ┌─────────────┐    ┌──────────────┐
│   Validate    │───▶│  Criteria   │───▶│   Context    │
│    Flag       │    │ Validator   │    │  Variables   │
└───────────────┘    └─────┬───────┘    └──────────────┘
                           │
                     ┌─────▼───────┐    ┌──────────────┐
                     │ Evaluation  │───▶│   Results    │
                     │   Engine    │    │  Aggregator  │
                     └─────────────┘    └──────┬───────┘
                           │                   │
                     ┌─────▼───────┐          │
                     │   Status    │◀─────────┘
                     │   Update    │
                     └─────────────┘
```

### 3. Metrics Aggregation Flow

```
Metrics Request
    │
    ▼
┌───────────────┐    ┌─────────────┐    ┌──────────────┐
│ Configuration │───▶│   Metrics   │───▶│   Database   │
│    Check      │    │ Calculator  │    │    Query     │
└───────────────┘    └─────┬───────┘    └──────┬───────┘
                           │                   │
                     ┌─────▼───────┐          │
                     │    Cache    │◀─────────┘
                     │    Check    │
                     └─────┬───────┘
                           │
                     ┌─────▼───────┐
                     │   Results   │
                     │ Formatting  │
                     └─────────────┘
```

## Module Interactions

### Dependency Graph

```
TaskManager (Core)
├── ConfigManager ──── YAML Config File
├── MigrationManager ── Database Schema
├── CriteriaValidator ── Expression Engine
├── MetricsCalculator ── Database Queries
├── TelemetryCapture ── Event Storage
└── ErrorHandler ──── Recovery Strategies
```

### Interface Contracts

#### TaskManager ↔ ConfigManager
```python
# TaskManager queries configuration before Core Loop operations
config = self.config_manager.get_config()
if config.get('success-criteria', False):
    # Proceed with criteria validation
```

#### TaskManager ↔ CriteriaValidator
```python
# Validation only when requested and enabled
if validate and self.config.get('success-criteria'):
    result = self.validator.validate(criteria, context)
    if not result['overall_pass']:
        raise ValidationError(result['failures'])
```

#### MetricsCalculator ↔ Database
```python
# Metrics calculator uses direct SQL for performance
with self.get_connection() as conn:
    cursor = conn.execute("""
        SELECT AVG(feedback_quality) FROM tasks 
        WHERE feedback_quality IS NOT NULL
    """)
    return cursor.fetchone()[0]
```

## Design Decisions

### 1. SQLite over NoSQL
**Decision**: Use SQLite for data persistence  
**Rationale**: 
- ACID compliance for data integrity
- No external dependencies
- Excellent performance for workload size
- SQL enables complex analytics queries
- File-based for simplicity

**Trade-offs**:
- ✅ Zero configuration
- ✅ Strong consistency
- ❌ No built-in horizontal scaling
- ❌ No document-style flexibility

### 2. JSON for Flexible Fields
**Decision**: Store success criteria as JSON TEXT  
**Rationale**:
- Flexible schema for criteria evolution
- SQLite has good JSON support
- Maintains backward compatibility
- Enables complex nested structures

**Trade-offs**:
- ✅ Schema flexibility
- ✅ Backward compatible
- ❌ Less query performance
- ❌ No referential integrity

### 3. Feature Toggles over Versioning
**Decision**: Use runtime configuration over multiple versions  
**Rationale**:
- Single codebase maintenance
- Gradual feature adoption
- Easy rollback of problematic features
- Reduced testing matrix

**Trade-offs**:
- ✅ Operational flexibility
- ✅ Reduced complexity
- ❌ Increased code paths
- ❌ Configuration complexity

### 4. Modular Architecture
**Decision**: Separate modules for each Core Loop feature  
**Rationale**:
- Independent failure modes
- Testability
- Clear responsibilities
- Extension points

**Trade-offs**:
- ✅ Maintainability
- ✅ Extensibility
- ❌ More interfaces
- ❌ Integration complexity

### 5. Idempotent Migrations
**Decision**: Make all migrations idempotent  
**Rationale**:
- Safe to re-run
- Handles partial failures
- Simplifies deployment
- Reduces migration errors

**Trade-offs**:
- ✅ Operational safety
- ✅ Deployment simplicity
- ❌ More complex migration code
- ❌ Performance overhead

## Extension Points

### 1. Custom Validators
```python
class CustomValidator:
    def validate(self, criterion: Dict, context: Dict) -> bool:
        # Custom validation logic
        return True
    
    def get_name(self) -> str:
        return "custom_validator"

# Registration
validator_registry.register(CustomValidator())
```

### 2. Metric Calculators
```python
class CustomMetricCalculator:
    def calculate(self, tasks: List[Dict]) -> Dict:
        # Custom metric calculation
        return {"custom_metric": value}

# Registration
metrics_registry.register("custom", CustomMetricCalculator())
```

### 3. Event Handlers
```python
class TaskCompletionHandler:
    def handle(self, event: Dict) -> None:
        # Custom completion logic
        pass

# Registration
event_bus.subscribe("task.completed", TaskCompletionHandler())
```

### 4. Configuration Providers
```python
class DatabaseConfigProvider:
    def get_config(self) -> Dict:
        # Load config from database
        return config
    
    def set_config(self, config: Dict) -> None:
        # Save config to database
        pass

# Registration
config_manager.add_provider(DatabaseConfigProvider())
```

## Performance Considerations

### 1. Database Optimization
- WAL mode for concurrent access
- Strategic indexes on query patterns
- Connection pooling for high load
- VACUUM for maintenance

### 2. Memory Management
- Lazy loading of optional modules
- Result caching for expensive queries
- Stream processing for large datasets
- Garbage collection optimization

### 3. CPU Optimization
- Compiled regexes for validation
- Batch operations where possible
- Async operations for I/O
- Profile-guided optimization

### 4. I/O Optimization
- Minimize database roundtrips
- Bulk inserts for batch operations
- Streaming for large exports
- Compression for backups

## Security Considerations

### 1. Input Validation
- SQL injection prevention
- Expression language sandboxing
- File path validation
- Data type enforcement

### 2. Data Protection
- No sensitive data in telemetry
- Secure temporary files
- Permission checks
- Audit logging

### 3. Error Handling
- No sensitive data in error messages
- Controlled information disclosure
- Safe error recovery
- Attack detection

## Monitoring and Observability

### 1. Logging Levels
```python
# Strategic logging throughout the system
logger.debug("Validation context prepared")
logger.info("Task completed with validation")
logger.warning("Feature disabled, skipping")
logger.error("Critical operation failed")
```

### 2. Metrics Collection
- Operation timing
- Error rates
- Feature usage
- Performance trends

### 3. Health Checks
- Database connectivity
- Module availability
- Configuration validity
- Resource utilization

## Future Architecture Evolution

### Planned Enhancements
1. **Plugin System**: Dynamic module loading
2. **Event Sourcing**: Complete audit trail
3. **API Layer**: REST/GraphQL interface
4. **Distributed Mode**: Multi-node coordination
5. **Machine Learning**: Predictive analytics

### Migration Path
- Maintain interface compatibility
- Gradual feature introduction
- Configuration-driven evolution
- Backward compatibility guarantees

---

## See Also

- [API Reference](../api/core-loop-api-reference.md)
- [Database Schema](../database/core-loop-schema.md)
- [Extension Guide](../extending/extending-core-loop.md)
- [Performance Guide](../performance/performance-guide.md)