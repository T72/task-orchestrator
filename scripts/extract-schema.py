#!/usr/bin/env python3
"""
Extract and document database schema from tm_production.py
Generates markdown documentation for database schema reference
"""

import re
import sys
import os
from datetime import datetime

def extract_schema():
    """Extract database schema from tm_production.py"""
    
    # Try to find tm_production.py
    possible_paths = [
        'src/tm_production.py',
        '../src/tm_production.py',
        'tm_production.py'
    ]
    
    tm_production_path = None
    for path in possible_paths:
        if os.path.exists(path):
            tm_production_path = path
            break
    
    if not tm_production_path:
        print("Error: Could not find tm_production.py", file=sys.stderr)
        sys.exit(1)
    
    with open(tm_production_path, 'r') as f:
        content = f.read()
    
    # Extract CREATE TABLE statements
    create_table_pattern = r'CREATE TABLE.*?(?=CREATE TABLE|\Z)'
    tables = re.findall(create_table_pattern, content, re.DOTALL)
    
    # Generate markdown documentation
    doc = f"""# Database Schema Reference (Auto-Generated)

**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Source**: tm_production.py  
**Version**: v2.6.0

## Tables Overview

The Task Orchestrator database consists of the following tables:

"""
    
    # Parse each table
    for table_sql in tables:
        if 'CREATE TABLE' in table_sql:
            # Extract table name
            table_name_match = re.search(r'CREATE TABLE (?:IF NOT EXISTS )?(\w+)', table_sql)
            if table_name_match:
                table_name = table_name_match.group(1)
                doc += f"### {table_name}\n\n"
                
                # Extract columns
                columns_pattern = r'(\w+)\s+(TEXT|INTEGER|REAL|BLOB|BOOLEAN)(?:\s+(PRIMARY KEY|NOT NULL|DEFAULT[^,\n)]*))?'
                columns = re.findall(columns_pattern, table_sql)
                
                if columns:
                    doc += "| Column | Type | Constraints |\n"
                    doc += "|--------|------|-------------|\n"
                    for col_name, col_type, constraints in columns:
                        if col_name.upper() not in ['CREATE', 'TABLE', 'IF', 'NOT', 'EXISTS', 'FOREIGN', 'KEY', 'REFERENCES', 'UNIQUE']:
                            doc += f"| {col_name} | {col_type} | {constraints.strip() if constraints else '-'} |\n"
                    doc += "\n"
    
    # Add Core Loop fields if they exist
    if 'success_criteria' in content:
        doc += """## Core Loop Extensions (v2.3+)

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

"""

    # Add v2.6.0 additions
    if 'created_by' in content:
        doc += """### Multi-Agent Support (v2.6.0+)
- **created_by** (TEXT): Agent ID that created the task

"""

    doc += """## Indexes

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
"""
    
    return doc

if __name__ == '__main__':
    try:
        schema_doc = extract_schema()
        print(schema_doc)
    except Exception as e:
        print(f"Error extracting schema: {e}", file=sys.stderr)
        sys.exit(1)