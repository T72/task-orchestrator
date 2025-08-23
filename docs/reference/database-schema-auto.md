# Database Schema Reference (Auto-Generated)

**Generated**: 2025-08-23 23:28:59  
**Source**: tm_production.py  
**Version**: v2.6.0

## Tables Overview

The Task Orchestrator database consists of the following tables:

### tasks

| Column | Type | Constraints |
|--------|------|-------------|
| id | TEXT | PRIMARY KEY |
| title | TEXT | NOT NULL |
| description | TEXT | - |
| status | TEXT | DEFAULT 'pending' |
| priority | TEXT | DEFAULT 'medium' |
| assignee | TEXT | - |
| created_by | TEXT | NOT NULL |
| created_at | TEXT | NOT NULL |
| updated_at | TEXT | NOT NULL |
| completed_at | TEXT | - |
| success_criteria | TEXT | - |
| feedback_quality | INTEGER | - |
| feedback_timeliness | INTEGER | - |
| feedback_notes | TEXT | - |
| completion_summary | TEXT | - |
| deadline | TEXT | - |
| estimated_hours | REAL | - |
| actual_hours | REAL | - |

### dependencies

| Column | Type | Constraints |
|--------|------|-------------|
| task_id | TEXT | NOT NULL |
| depends_on | TEXT | NOT NULL |

### notifications

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY |
| agent_id | TEXT | - |
| task_id | TEXT | - |
| type | TEXT | NOT NULL |
| message | TEXT | NOT NULL |
| created_at | TEXT | NOT NULL |
| read | BOOLEAN | DEFAULT 0 |

### participants

| Column | Type | Constraints |
|--------|------|-------------|
| task_id | TEXT | NOT NULL |
| agent_id | TEXT | NOT NULL |
| joined_at | TEXT | NOT NULL |
| created_by | TEXT | DEFAULT 'user' |

## Core Loop Extensions (v2.3+)

The following fields were added for Core Loop functionality:

### Success Criteria Fields
- **success_criteria** (TEXT): JSON array of criterion objects
- **feedback_quality** (INTEGER): Quality score 1-5
- **feedback_timeliness** (INTEGER): Timeliness score 1-5
- **feedback_notes** (TEXT): Additional feedback
- **estimated_hours** (REAL): Time estimation
- **actual_hours** (REAL): Actual time spent
- **deadline** (TEXT): ISO 8601 deadline
- **completion_summary** (TEXT): Task completion summary

### Multi-Agent Support (v2.6.0+)
- **created_by** (TEXT): Agent ID that created the task

## Indexes

The following indexes are created for performance optimization:
- idx_tasks_status (on status column)
- idx_tasks_assignee (on assignee column)
- idx_tasks_priority (on priority column)
- idx_tasks_created_at (on created_at column)

## Migration Support

The database includes migration tracking:
- **schema_version** table tracks applied migrations
- Automatic backup before migrations
- Rollback capability for safe updates

---
*This documentation is auto-generated from the source code. Do not edit directly.*

