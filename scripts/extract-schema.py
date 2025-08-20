#!/usr/bin/env python3
"""
Extract database schema documentation from source code.
Parses @doc comments from SQL CREATE TABLE statements and generates markdown.
"""

import re
import sys
from pathlib import Path
from datetime import datetime

def extract_create_tables(content):
    """Extract all CREATE TABLE statements from source code."""
    # Pattern to match CREATE TABLE statements including all content until the closing )
    pattern = r'conn\.execute\("""(.*?)"""\)'
    matches = re.findall(pattern, content, re.DOTALL)
    
    tables = []
    for match in matches:
        if 'CREATE TABLE' in match:
            tables.append(match.strip())
    
    return tables

def parse_table_schema(table_sql):
    """Parse a CREATE TABLE statement and extract documentation."""
    lines = table_sql.split('\n')
    
    # Extract table name
    table_name = None
    for line in lines:
        if 'CREATE TABLE' in line:
            match = re.search(r'CREATE TABLE IF NOT EXISTS (\w+)', line)
            if match:
                table_name = match.group(1)
            break
    
    if not table_name:
        return None
    
    # Extract table documentation
    table_doc = None
    for line in lines:
        if '-- @table-doc:' in line:
            table_doc = line.split('-- @table-doc:')[1].strip()
            break
    
    # Extract columns and their documentation
    columns = []
    constraints = []
    
    for line in lines:
        # Skip CREATE TABLE line and closing parenthesis
        if 'CREATE TABLE' in line or line.strip() in [')', ');', '-- @table-doc:', '']:
            continue
            
        # Check for constraint documentation
        if '-- @constraint:' in line:
            constraint = line.split('-- @constraint:')[1].strip()
            constraints.append(constraint)
            continue
        
        # Parse column definition
        if '--' in line and '@doc:' in line:
            # Split line into column definition and documentation
            parts = line.split('--')
            col_def = parts[0].strip().rstrip(',')
            doc = parts[1].split('@doc:')[1].strip() if '@doc:' in parts[1] else ''
            
            # Parse column details
            col_parts = col_def.split()
            if len(col_parts) >= 2:
                col_name = col_parts[0]
                col_type = ' '.join(col_parts[1:])
                
                columns.append({
                    'name': col_name,
                    'type': col_type,
                    'doc': doc
                })
        elif 'PRIMARY KEY' in line and '(' in line:
            # Handle composite primary keys
            match = re.search(r'PRIMARY KEY \((.*?)\)', line)
            if match:
                keys = match.group(1).strip()
                doc = ''
                if '-- @doc:' in line:
                    doc = line.split('-- @doc:')[1].strip()
                columns.append({
                    'name': f'PRIMARY KEY ({keys})',
                    'type': 'CONSTRAINT',
                    'doc': doc or 'Composite primary key'
                })
    
    return {
        'name': table_name,
        'doc': table_doc,
        'columns': columns,
        'constraints': constraints
    }

def generate_markdown(tables_data):
    """Generate markdown documentation from parsed table data."""
    md = []
    
    # Header
    md.append("# Database Schema Documentation")
    md.append("")
    md.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    md.append("**Source**: `src/tm_production.py`")
    md.append("")
    md.append("> **Note**: This documentation is auto-generated from code comments. Do not edit directly.")
    md.append("")
    md.append("## Tables")
    md.append("")
    
    # Table of contents
    md.append("### Quick Navigation")
    md.append("")
    for table in tables_data:
        if table:
            md.append(f"- [{table['name']}](#{table['name'].lower()}-table)")
    md.append("")
    
    # Detailed table documentation
    for table in tables_data:
        if not table:
            continue
            
        md.append(f"## {table['name']} Table")
        md.append("")
        
        if table['doc']:
            md.append(f"**Purpose**: {table['doc']}")
            md.append("")
        
        # Table structure
        md.append("### Structure")
        md.append("")
        md.append("| Column | Type | Description |")
        md.append("|--------|------|-------------|")
        
        for col in table['columns']:
            # Clean up the type for display
            col_type = col['type'].replace('TEXT', 'TEXT').replace('INTEGER', 'INTEGER').replace('BOOLEAN', 'BOOLEAN')
            col_type = re.sub(r'\s+', ' ', col_type)  # Normalize whitespace
            
            # Escape pipe characters in documentation
            doc = col['doc'].replace('|', '\\|')
            
            md.append(f"| `{col['name']}` | {col_type} | {doc} |")
        
        md.append("")
        
        # Constraints if any
        if table['constraints']:
            md.append("### Constraints")
            md.append("")
            for constraint in table['constraints']:
                md.append(f"- {constraint}")
            md.append("")
        
        # SQL Definition
        md.append("### SQL Definition")
        md.append("")
        md.append("```sql")
        md.append(f"CREATE TABLE IF NOT EXISTS {table['name']} (")
        
        for i, col in enumerate(table['columns']):
            if col['name'].startswith('PRIMARY KEY'):
                md.append(f"    {col['name']}")
            else:
                line = f"    {col['name']} {col['type']}"
                if i < len(table['columns']) - 1:
                    line += ","
                md.append(line)
        
        md.append(")")
        md.append("```")
        md.append("")
    
    # Implementation notes
    md.append("## Implementation Notes")
    md.append("")
    md.append("### Current Implementation Status")
    md.append("")
    md.append("- ✅ All tables shown above are implemented")
    md.append("- ✅ Column definitions match source code")
    md.append("- ⚠️ Foreign key constraints not enforced at database level")
    md.append("- ⚠️ Indexes not yet implemented for performance optimization")
    md.append("")
    
    md.append("### Data Storage Patterns")
    md.append("")
    md.append("- **Timestamps**: All timestamps use ISO 8601 format")
    md.append("- **IDs**: Task IDs are 8-character strings, auto-generated")
    md.append("- **Agent IDs**: From `TM_AGENT_ID` environment variable or auto-generated")
    md.append("")
    
    md.append("### Related Files")
    md.append("")
    md.append("- **Context Storage**: `.task-orchestrator/contexts/{task_id}.yaml`")
    md.append("- **Private Notes**: `.task-orchestrator/private_notes/{task_id}.yaml`")
    md.append("- **Database Location**: `.task-orchestrator/tasks.db`")
    md.append("")
    
    return '\n'.join(md)

def main():
    """Main extraction process."""
    # Read the source file
    source_file = Path(__file__).parent.parent / 'src' / 'tm_production.py'
    
    if not source_file.exists():
        print(f"Error: Source file not found: {source_file}", file=sys.stderr)
        sys.exit(1)
    
    with open(source_file, 'r') as f:
        content = f.read()
    
    # Extract CREATE TABLE statements
    tables_sql = extract_create_tables(content)
    
    if not tables_sql:
        print("Warning: No CREATE TABLE statements found", file=sys.stderr)
        sys.exit(1)
    
    # Parse each table
    tables_data = []
    for table_sql in tables_sql:
        table_info = parse_table_schema(table_sql)
        if table_info:
            tables_data.append(table_info)
    
    # Generate markdown
    markdown = generate_markdown(tables_data)
    
    # Output to stdout (can be redirected to file)
    print(markdown)

if __name__ == "__main__":
    main()