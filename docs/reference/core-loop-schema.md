# Core Loop Database Schema Extensions

## Status: Implemented
## Last Verified: August 23, 2025
Against version: v2.7.2

## Overview
The Core Loop enhancements add new fields to support success criteria, feedback mechanisms, and completion summaries while maintaining 100% backward compatibility.

## New Database Fields

### Success Criteria Field
- **Column**: `success_criteria`
- **Type**: TEXT (storing JSON array)
- **Nullable**: Yes (for backward compatibility)
- **Format**: 
  ```json
  [
    {
      "criterion": "Query time reduced by 30%",
      "measurable": "avg_query_time < baseline * 0.7"
    }
  ]
  ```

### Feedback Fields
- **Column**: `feedback_quality`
- **Type**: INTEGER (1-5 scale)
- **Nullable**: Yes
- **Constraint**: Value between 1 and 5

- **Column**: `feedback_timeliness`
- **Type**: INTEGER (1-5 scale)
- **Nullable**: Yes
- **Constraint**: Value between 1 and 5

- **Column**: `feedback_notes`
- **Type**: TEXT
- **Nullable**: Yes
- **Purpose**: Free-form feedback comments

### Completion Summary
- **Column**: `completion_summary`
- **Type**: TEXT
- **Nullable**: Yes
- **Purpose**: Capture lessons learned and implementation details at task completion

### Time Management Fields
- **Column**: `deadline`
- **Type**: TEXT (ISO8601 format)
- **Nullable**: Yes
- **Format**: "2025-03-01T00:00:00Z"

- **Column**: `estimated_hours`
- **Type**: REAL
- **Nullable**: Yes
- **Purpose**: Initial time estimate

- **Column**: `actual_hours`
- **Type**: REAL
- **Nullable**: Yes
- **Purpose**: Actual time spent

## Migration SQL

```sql
-- Migration 001: Add Core Loop fields
ALTER TABLE tasks ADD COLUMN success_criteria TEXT;
ALTER TABLE tasks ADD COLUMN feedback_quality INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_timeliness INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_notes TEXT;
ALTER TABLE tasks ADD COLUMN completion_summary TEXT;
ALTER TABLE tasks ADD COLUMN deadline TEXT;
ALTER TABLE tasks ADD COLUMN estimated_hours REAL;
ALTER TABLE tasks ADD COLUMN actual_hours REAL;
```

## Backward Compatibility

All new fields are:
1. **Nullable** - Existing tasks continue to work without these fields
2. **Optional** - Task creation/completion works without providing these values
3. **Progressive** - Features can be enabled/disabled via configuration

## Usage Examples

### Creating task with success criteria
```bash
tm add "Optimize database" --criteria '[
  {"criterion": "Query time < 100ms", "measurable": "performance_test() < 100"},
  {"criterion": "All tests pass", "measurable": "test_suite.run() == true"}
]' --deadline "2025-03-01T00:00:00Z" --estimated-hours 12
```

### Providing feedback
```bash
tm feedback task_123 --quality 5 --timeliness 4 --note "Excellent optimization, exceeded targets"
```

### Completing with summary
```bash
tm complete task_123 --summary "Reduced query time by 45% through index optimization and query restructuring" --actual-hours 10
```

## Data Validation

- Success criteria must be valid JSON array
- Feedback scores must be integers 1-5
- Deadlines must be valid ISO8601 timestamps
- Hours must be positive numbers
- All text fields support Unicode

## Indexes

For performance optimization:
```sql
CREATE INDEX idx_tasks_deadline ON tasks(deadline);
CREATE INDEX idx_tasks_feedback_quality ON tasks(feedback_quality);
```

## Schema Version

This schema is part of migration version 001, tracked in the `schema_migrations` table.