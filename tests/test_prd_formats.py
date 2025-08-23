#!/usr/bin/env python3
"""Test enhanced PRD parser with multiple formats"""
import sys
import json
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent / ".claude/hooks"))
from prd_to_tasks import parse_prd_to_tasks, detect_prd_format

# Test different PRD formats
test_prds = {
    "phases": """
    Phase 1: Database Design
    - Design user authentication schema
    - Create session management tables (depends on: Design user authentication schema)
    - Add audit logging tables
    
    Phase 2: Backend Implementation  
    - Implement JWT token generation (requires: session management)
    - Create REST API endpoints
    - Add middleware for authentication (after: JWT token generation)
    """,
    
    "markdown": """
    # Authentication System
    
    ## Database Layer
    - Design user authentication schema
    - Create session management tables
    - Add audit logging tables
    
    ## Backend Services
    - Implement JWT token generation
    - Create REST API endpoints
    - Add middleware for authentication
    """,
    
    "user_stories": """
    As a user, I want to be able to log in securely so that I can access my account
    As an admin, I want to see audit logs so that I can track user activity
    As a developer, I want JWT authentication so that the API is stateless
    """,
    
    "requirements": """
    FR-001: The system shall provide user authentication
    FR-002: The system shall support JWT tokens
    FR-003: The system shall log all authentication attempts
    NFR-001: Authentication shall complete within 200ms
    """,
    
    "sprint": """
    Sprint 1: Core Authentication
    - Set up database schema
    - Create user model
    - Add password hashing
    
    Sprint 2: API Development
    - Build login endpoint
    - Add token generation
    - Implement middleware
    """
}

# Test each format
for format_name, prd_text in test_prds.items():
    print(f"\n{'='*60}")
    print(f"Testing format: {format_name}")
    print(f"{'='*60}")
    
    # Detect format
    detected = detect_prd_format(prd_text)
    print(f"Detected format: {detected}")
    
    # Parse tasks
    tasks = parse_prd_to_tasks(prd_text)
    print(f"Generated {len(tasks)} tasks")
    
    # Show first 2 tasks
    for task in tasks[:2]:
        print(f"\nTask: {task['id']}")
        print(f"  Content: {task['content']}")
        print(f"  Specialist: {task['metadata'].get('specialist')}")
        print(f"  Dependencies: {task['metadata'].get('depends_on', [])}")
        print(f"  Phase: {task['metadata'].get('phase', 'N/A')}")