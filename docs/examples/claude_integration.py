#!/usr/bin/env python3
"""
Task Orchestrator - Claude Code Integration Examples

This script demonstrates how Task Orchestrator integrates with Claude Code
for AI-assisted development workflows. It shows automated task creation,
intelligent code analysis integration, and seamless handoffs between
human developers and AI assistants.

Features demonstrated:
- Automated task creation from code comments
- File change detection and task updates
- Claude Code workflow integration
- AI-assisted task prioritization
- Code analysis to task conversion
- Handoff documentation generation
"""

import sys
import os
import json
import re
import time
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

# Add the project root to the Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from src.tm_production import TaskManager
except ImportError as e:
    print(f"Error importing TaskManager: {e}")
    print("Make sure you're running this from the task-orchestrator directory")
    sys.exit(1)

def print_separator(title):
    """Print a formatted section separator."""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print('='*70)

class ClaudeIntegrationDemo:
    """Simulates Claude Code integration with Task Orchestrator."""
    
    def __init__(self):
        self.tm = TaskManager()
        self.claude_agent_id = "claude_ai_assistant"
        
    def simulate_code_analysis(self, file_path: str) -> Dict:
        """Simulate Claude Code analyzing a file and finding tasks."""
        # This simulates what Claude Code would actually do
        analysis = {
            'file_path': file_path,
            'todos': [],
            'fixmes': [],
            'code_smells': [],
            'optimization_opportunities': [],
            'security_concerns': [],
            'test_suggestions': []
        }
        
        # Simulate finding different types of issues
        if 'auth' in file_path:
            analysis['todos'].append({
                'line': 45,
                'text': 'Add rate limiting to prevent brute force attacks',
                'priority': 'high',
                'type': 'security'
            })
            analysis['security_concerns'].append({
                'line': 78,
                'text': 'Password validation could be stronger',
                'priority': 'medium',
                'type': 'security'
            })
            
        if 'api' in file_path:
            analysis['fixmes'].append({
                'line': 123,
                'text': 'Handle edge case when database is unavailable',
                'priority': 'critical',
                'type': 'reliability'
            })
            analysis['test_suggestions'].append({
                'line': 150,
                'text': 'Add integration tests for error handling',
                'priority': 'medium',
                'type': 'testing'
            })
            
        if 'ui' in file_path or 'frontend' in file_path:
            analysis['code_smells'].append({
                'line': 67,
                'text': 'Component is too large, consider splitting',
                'priority': 'low',
                'type': 'refactoring'
            })
            analysis['optimization_opportunities'].append({
                'line': 89,
                'text': 'Use React.memo to prevent unnecessary re-renders',
                'priority': 'medium',
                'type': 'performance'
            })
        
        return analysis
    
    def create_tasks_from_analysis(self, analysis: Dict) -> List[str]:
        """Convert code analysis results into tasks."""
        created_tasks = []
        
        # Process TODOs
        for todo in analysis['todos']:
            task_id = self.tm.add_task(
                f"TODO: {todo['text']}",
                description=f"Found in code analysis of {analysis['file_path']}",
                priority=todo['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': todo['line'],
                    'context': 'TODO comment'
                }],
                tags=['todo', todo['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        # Process FIXMEs (higher priority)
        for fixme in analysis['fixmes']:
            task_id = self.tm.add_task(
                f"FIXME: {fixme['text']}",
                description=f"Critical issue found in {analysis['file_path']}",
                priority=fixme['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': fixme['line'],
                    'context': 'FIXME comment'
                }],
                tags=['fixme', fixme['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        # Process code smells
        for smell in analysis['code_smells']:
            task_id = self.tm.add_task(
                f"Refactor: {smell['text']}",
                description=f"Code quality improvement suggested for {analysis['file_path']}",
                priority=smell['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': smell['line'],
                    'context': 'Code smell detected'
                }],
                tags=['refactoring', smell['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        # Process optimization opportunities
        for opt in analysis['optimization_opportunities']:
            task_id = self.tm.add_task(
                f"Optimize: {opt['text']}",
                description=f"Performance improvement opportunity in {analysis['file_path']}",
                priority=opt['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': opt['line'],
                    'context': 'Performance optimization'
                }],
                tags=['optimization', opt['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        # Process security concerns
        for security in analysis['security_concerns']:
            task_id = self.tm.add_task(
                f"Security: {security['text']}",
                description=f"Security improvement needed in {analysis['file_path']}",
                priority=security['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': security['line'],
                    'context': 'Security concern'
                }],
                tags=['security', security['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        # Process test suggestions
        for test in analysis['test_suggestions']:
            task_id = self.tm.add_task(
                f"Test: {test['text']}",
                description=f"Testing improvement suggested for {analysis['file_path']}",
                priority=test['priority'],
                file_refs=[{
                    'file_path': analysis['file_path'],
                    'line_start': test['line'],
                    'context': 'Test suggestion'
                }],
                tags=['testing', test['type'], 'claude-generated']
            )
            if task_id:
                created_tasks.append(task_id)
        
        return created_tasks
    
    def generate_handoff_documentation(self, task_id: str) -> str:
        """Generate comprehensive handoff documentation for a task."""
        task = self.tm.show_task(task_id)
        if not task:
            return "Task not found"
        
        handoff_doc = f"""
# Task Handoff Documentation
**Generated by Claude Code Integration**

## Task Overview
- **ID**: {task['id']}
- **Title**: {task['title']}
- **Priority**: {task['priority']}
- **Status**: {task['status']}
- **Created**: {task['created_at']}

## Description
{task.get('description', 'No description provided')}

## Context and Background
This task was {'automatically generated from code analysis' if 'claude-generated' in task.get('tags', []) else 'created manually'}.

"""
        
        if task.get('file_refs'):
            handoff_doc += "## File References\n"
            for ref in task['file_refs']:
                handoff_doc += f"- **{ref['file_path']}**"
                if ref.get('line_start'):
                    handoff_doc += f" (lines {ref['line_start']}"
                    if ref.get('line_end'):
                        handoff_doc += f"-{ref['line_end']}"
                    handoff_doc += ")"
                if ref.get('context'):
                    handoff_doc += f": {ref['context']}"
                handoff_doc += "\n"
        
        if task.get('dependencies'):
            handoff_doc += f"\n## Dependencies\nThis task depends on:\n"
            for dep_id in task['dependencies']:
                dep_task = self.tm.show_task(dep_id)
                if dep_task:
                    handoff_doc += f"- [{dep_id}] {dep_task['title']}\n"
        
        if task.get('blocks'):
            handoff_doc += f"\n## Blocked Tasks\nCompleting this task will unblock:\n"
            for blocked_id in task['blocks']:
                blocked_task = self.tm.show_task(blocked_id)
                if blocked_task:
                    handoff_doc += f"- [{blocked_id}] {blocked_task['title']}\n"
        
        handoff_doc += f"""
## Implementation Suggestions
Based on code analysis and task context:

1. **Review existing code** in the referenced files
2. **Check for related tests** that might need updates
3. **Consider impact** on other components
4. **Update documentation** as needed

## Acceptance Criteria
- [ ] Implementation addresses the core issue
- [ ] Code follows project style guidelines
- [ ] Tests are updated/added as appropriate
- [ ] Documentation is updated if needed
- [ ] No new security vulnerabilities introduced

## Next Steps
1. Assign the task to appropriate developer
2. Review file references and understand context
3. Implement changes following project standards
4. Test thoroughly
5. Update task status and add completion notes

---
*Generated by Claude Code Integration at {datetime.now().isoformat()}*
"""
        
        return handoff_doc

def demonstrate_automated_task_creation():
    """Show how Claude Code can automatically create tasks from code analysis."""
    print_separator("Automated Task Creation from Code Analysis")
    
    claude_demo = ClaudeIntegrationDemo()
    
    print("🤖 Claude Code analyzing project files...")
    
    # Simulate analyzing different types of files
    files_to_analyze = [
        'src/auth/authentication.py',
        'src/api/user_endpoints.py', 
        'frontend/components/UserProfile.jsx',
        'src/utils/validation.py',
        'tests/integration/api_tests.py'
    ]
    
    all_created_tasks = []
    
    for file_path in files_to_analyze:
        print(f"\n📁 Analyzing {file_path}...")
        
        # Simulate code analysis
        analysis = claude_demo.simulate_code_analysis(file_path)
        
        # Count issues found
        total_issues = (len(analysis['todos']) + len(analysis['fixmes']) + 
                       len(analysis['code_smells']) + len(analysis['optimization_opportunities']) +
                       len(analysis['security_concerns']) + len(analysis['test_suggestions']))
        
        print(f"   Found {total_issues} potential improvements:")
        print(f"   - TODOs: {len(analysis['todos'])}")
        print(f"   - FIXMEs: {len(analysis['fixmes'])}")
        print(f"   - Code smells: {len(analysis['code_smells'])}")
        print(f"   - Optimizations: {len(analysis['optimization_opportunities'])}")
        print(f"   - Security concerns: {len(analysis['security_concerns'])}")
        print(f"   - Test suggestions: {len(analysis['test_suggestions'])}")
        
        # Create tasks from analysis
        if total_issues > 0:
            created_tasks = claude_demo.create_tasks_from_analysis(analysis)
            all_created_tasks.extend(created_tasks)
            print(f"   ✅ Created {len(created_tasks)} tasks")
    
    print(f"\n🎉 Total tasks created: {len(all_created_tasks)}")
    
    # Show sample of created tasks
    print("\nSample created tasks:")
    for task_id in all_created_tasks[:5]:  # Show first 5
        task = claude_demo.tm.show_task(task_id)
        if task:
            tags_str = ', '.join(task.get('tags', []))
            print(f"  [{task_id}] {task['title']} ({task['priority']}) - {tags_str}")
    
    return all_created_tasks

def demonstrate_intelligent_prioritization():
    """Show how Claude Code can intelligently prioritize tasks."""
    print_separator("AI-Assisted Task Prioritization")
    
    claude_demo = ClaudeIntegrationDemo()
    
    print("🧠 Claude Code analyzing task priorities based on:")
    print("   - Security impact")
    print("   - Performance implications") 
    print("   - Code complexity")
    print("   - Dependencies")
    print("   - Business value")
    
    # Get all tasks
    tasks = claude_demo.tm.list_tasks()
    claude_tasks = [t for t in tasks if 'claude-generated' in t.get('tags', [])]
    
    if not claude_tasks:
        print("   No Claude-generated tasks found. Run automated task creation first.")
        return
    
    print(f"\n📊 Analyzing {len(claude_tasks)} Claude-generated tasks...")
    
    # Simulate intelligent prioritization
    prioritized_tasks = []
    
    for task in claude_tasks:
        # Calculate priority score based on various factors
        score = 0
        factors = []
        
        # Security tasks get highest priority
        if 'security' in task.get('tags', []):
            score += 50
            factors.append("Security impact")
        
        # Performance optimizations
        if 'performance' in task.get('tags', []) or 'optimization' in task.get('tags', []):
            score += 30
            factors.append("Performance impact")
        
        # Critical bugs (FIXMEs)
        if 'fixme' in task.get('tags', []):
            score += 40
            factors.append("Critical bug fix")
        
        # Testing improvements
        if 'testing' in task.get('tags', []):
            score += 25
            factors.append("Test coverage")
        
        # Refactoring (lower priority unless blocking)
        if 'refactoring' in task.get('tags', []):
            score += 15
            factors.append("Code quality")
        
        # File-based priority (some files are more critical)
        if task.get('file_refs'):
            for ref in task['file_refs']:
                if 'auth' in ref['file_path'] or 'security' in ref['file_path']:
                    score += 20
                    factors.append("Critical file")
                elif 'api' in ref['file_path']:
                    score += 15
                    factors.append("API impact")
        
        prioritized_tasks.append((task, score, factors))
    
    # Sort by score (highest first)
    prioritized_tasks.sort(key=lambda x: x[1], reverse=True)
    
    print("\n🎯 Prioritized task recommendations:")
    for i, (task, score, factors) in enumerate(prioritized_tasks[:8]):  # Top 8
        priority_emoji = "🔴" if score >= 70 else "🟡" if score >= 40 else "🟢"
        factors_str = ", ".join(factors[:3])  # Show top 3 factors
        
        print(f"  {i+1}. {priority_emoji} [{task['id']}] {task['title']}")
        print(f"     Score: {score}, Factors: {factors_str}")
        
        # Suggest priority adjustment
        suggested_priority = "critical" if score >= 70 else "high" if score >= 40 else "medium"
        if task['priority'] != suggested_priority:
            print(f"     💡 Suggest changing priority from '{task['priority']}' to '{suggested_priority}'")
            # Actually update priority in demo
            claude_demo.tm.update_task(task['id'], impact_notes=f"Priority updated by Claude analysis (score: {score})")

def demonstrate_workflow_integration():
    """Show Claude Code integrating with development workflows."""
    print_separator("Development Workflow Integration")
    
    claude_demo = ClaudeIntegrationDemo()
    
    print("🔄 Simulating Claude Code development workflow...")
    
    # Scenario: Claude Code working on a feature
    print("\n1. Claude Code starts working on authentication improvements:")
    
    # Create a feature task
    feature_task_id = claude_demo.tm.add_task(
        "Improve authentication security",
        description="Enhance login security with rate limiting and better validation",
        priority="high",
        tags=["security", "authentication", "feature"]
    )
    
    # Assign to Claude
    claude_demo.tm.update_task(feature_task_id, assignee=claude_demo.claude_agent_id)
    claude_demo.tm.update_task(feature_task_id, status="in_progress")
    
    print(f"   ✅ Started work on task: {feature_task_id}")
    
    # Simulate Claude making progress and discovering sub-tasks
    print("\n2. During implementation, Claude discovers additional work needed:")
    
    subtasks = [
        {
            'title': 'Add rate limiting middleware',
            'priority': 'high',
            'file_path': 'src/middleware/rate_limiter.py'
        },
        {
            'title': 'Update password validation rules',
            'priority': 'medium', 
            'file_path': 'src/auth/validation.py'
        },
        {
            'title': 'Add authentication unit tests',
            'priority': 'medium',
            'file_path': 'tests/auth/test_authentication.py'
        }
    ]
    
    subtask_ids = []
    for subtask in subtasks:
        task_id = claude_demo.tm.add_task(
            subtask['title'],
            depends_on=[feature_task_id],
            priority=subtask['priority'],
            file_refs=[{
                'file_path': subtask['file_path'],
                'context': 'Implementation file'
            }],
            tags=["subtask", "claude-generated"]
        )
        subtask_ids.append(task_id)
        print(f"   📝 Created subtask: [{task_id}] {subtask['title']}")
    
    # Simulate completing main task and creating handoff
    print("\n3. Claude completes main implementation and creates handoff:")
    
    claude_demo.tm.complete_task(feature_task_id)
    
    # Generate handoff documentation
    handoff_doc = claude_demo.generate_handoff_documentation(subtask_ids[0])  # For first subtask
    
    print(f"   ✅ Completed main task: {feature_task_id}")
    print(f"   📋 Generated handoff documentation for remaining work")
    print(f"   🔄 {len(subtask_ids)} subtasks ready for human review")
    
    # Show handoff documentation sample
    print("\n4. Sample handoff documentation:")
    print("-" * 50)
    print(handoff_doc[:500] + "..." if len(handoff_doc) > 500 else handoff_doc)

def demonstrate_human_ai_collaboration():
    """Show collaboration between human developers and Claude Code."""
    print_separator("Human-AI Collaboration Patterns")
    
    claude_demo = ClaudeIntegrationDemo()
    
    print("👥 Simulating human-AI collaborative development...")
    
    # Scenario: Complex feature requiring both human and AI work
    print("\n1. Creating collaborative workflow for 'User Dashboard Redesign':")
    
    # Epic created by human
    epic_id = claude_demo.tm.add_task(
        "User Dashboard Redesign",
        description="Complete redesign of user dashboard with modern UI and improved UX",
        priority="high",
        tags=["epic", "ui", "redesign"]
    )
    
    # Human creates high-level tasks
    human_tasks = [
        ("Research user requirements", "alice_designer", ["research", "ux"]),
        ("Create UI mockups", "alice_designer", ["design", "mockups"]),
        ("Review design with stakeholders", "bob_pm", ["review", "stakeholders"])
    ]
    
    human_task_ids = []
    for title, assignee, tags in human_tasks:
        task_id = claude_demo.tm.add_task(
            title,
            depends_on=[epic_id],
            priority="medium",
            tags=tags + ["human-created"]
        )
        claude_demo.tm.update_task(task_id, assignee=assignee)
        human_task_ids.append(task_id)
        print(f"   👤 Human task: [{task_id}] {title} → {assignee}")
    
    # Claude analyzes and creates technical tasks
    print("\n2. Claude Code analyzes requirements and creates technical tasks:")
    
    claude_tasks = [
        ("Implement responsive grid layout", "high", "frontend/components/DashboardGrid.jsx"),
        ("Create data fetching hooks", "medium", "frontend/hooks/useDashboardData.js"),
        ("Add dashboard API endpoints", "high", "backend/api/dashboard.py"),
        ("Implement real-time data updates", "medium", "backend/websocket/dashboard.py"),
        ("Add dashboard unit tests", "medium", "tests/frontend/dashboard.test.js")
    ]
    
    claude_task_ids = []
    for title, priority, file_path in claude_tasks:
        task_id = claude_demo.tm.add_task(
            title,
            depends_on=human_task_ids[:2],  # Depends on research and mockups
            priority=priority,
            file_refs=[{
                'file_path': file_path,
                'context': 'Implementation target'
            }],
            tags=["claude-generated", "technical"]
        )
        claude_task_ids.append(task_id)
        print(f"   🤖 Claude task: [{task_id}] {title}")
    
    # Show collaboration flow
    print("\n3. Collaboration flow:")
    print("   Human: Research & Design → Claude: Technical Implementation")
    print("   Human: Review & Testing → Claude: Bug fixes & Optimization")
    print("   Human: User Acceptance → Claude: Performance Monitoring")
    
    # Simulate completing some tasks and showing notifications
    print("\n4. Simulating task completion and notifications:")
    
    # Human completes design
    claude_demo.tm.complete_task(human_task_ids[1])  # UI mockups
    print("   ✅ Human completed: UI mockups")
    
    # This should unblock Claude tasks
    unblocked_tasks = claude_demo.tm.list_tasks(status="pending")
    claude_ready_tasks = [t for t in unblocked_tasks if t['id'] in claude_task_ids]
    
    if claude_ready_tasks:
        print(f"   🔓 {len(claude_ready_tasks)} Claude tasks now ready to start")
        
        # Claude starts working on ready tasks
        for task in claude_ready_tasks[:2]:  # Start first 2
            claude_demo.tm.update_task(task['id'], 
                                     assignee=claude_demo.claude_agent_id,
                                     status="in_progress")
            print(f"   🤖 Claude started: [{task['id']}] {task['title']}")
    
    # Show notifications
    notifications = claude_demo.tm.check_notifications()
    if notifications:
        print(f"\n📬 Notifications generated ({len(notifications)}):")
        for notif in notifications[:3]:
            print(f"   [{notif['type']}] {notif['message']}")

def demonstrate_claude_code_commands():
    """Show Claude Code CLI integration examples."""
    print_separator("Claude Code CLI Integration")
    
    print("💻 Claude Code CLI integration examples:")
    print("These commands could be used within Claude Code sessions:")
    
    print("\n1. Task creation from Claude Code:")
    print("   @tm add 'Fix authentication bug' --file src/auth.py:42 --priority high")
    print("   @tm add 'Optimize database query' --file src/models.py:156 --tag performance")
    
    print("\n2. Status updates during development:")
    print("   @tm update abc12345 --status in_progress")
    print("   @tm update abc12345 --impact 'Fixed validation, working on error handling'")
    print("   @tm complete abc12345 --impact-review")
    
    print("\n3. Information queries:")
    print("   @tm list --status pending --assignee claude_ai")
    print("   @tm show abc12345")
    print("   @tm watch")
    
    print("\n4. Project coordination:")
    print("   @tm export --format markdown > status_report.md")
    print("   @tm list --has-deps | grep -E 'blocked|pending'")
    
    # Demonstrate actual CLI integration
    claude_demo = ClaudeIntegrationDemo()
    
    print("\n🚀 Demonstrating actual CLI integration:")
    
    # Create a task that Claude Code might create
    task_id = claude_demo.tm.add_task(
        "Implement error boundary for React components",
        description="Add error boundaries to prevent component crashes from breaking the entire app",
        priority="medium",
        file_refs=[{
            'file_path': 'frontend/components/ErrorBoundary.jsx',
            'context': 'New component to implement'
        }],
        tags=["react", "error-handling", "claude-suggested"]
    )
    
    if task_id:
        print(f"   ✅ Claude Code created task: [{task_id}]")
        
        # Show how Claude would update the task
        claude_demo.tm.update_task(
            task_id, 
            assignee=claude_demo.claude_agent_id,
            status="in_progress"
        )
        print(f"   🤖 Claude Code started working on task")
        
        # Generate progress update
        claude_demo.tm.update_task(
            task_id,
            impact_notes="Implemented basic error boundary, adding tests and documentation"
        )
        print(f"   📝 Claude Code added progress notes")
        
        # Complete the task
        claude_demo.tm.complete_task(task_id)
        print(f"   ✅ Claude Code completed task")

def main():
    """Run all Claude Code integration demonstrations."""
    print("Task Orchestrator - Claude Code Integration Examples")
    print("====================================================")
    print("This script demonstrates how Task Orchestrator seamlessly integrates")
    print("with Claude Code for AI-assisted development workflows.")
    
    try:
        # Initialize clean environment
        tm = TaskManager()
        tm.init_db()
        
        # Run demonstrations
        created_tasks = demonstrate_automated_task_creation()
        time.sleep(1)
        
        if created_tasks:
            demonstrate_intelligent_prioritization()
            time.sleep(1)
        
        demonstrate_workflow_integration()
        time.sleep(1)
        
        demonstrate_human_ai_collaboration()
        time.sleep(1)
        
        demonstrate_claude_code_commands()
        
        print_separator("Claude Code Integration Examples Complete")
        print("All Claude Code integration scenarios have been demonstrated!")
        print("\nKey Integration Benefits:")
        print("1. ✨ Automated task creation from code analysis")
        print("2. 🧠 Intelligent prioritization based on impact")
        print("3. 📋 Comprehensive handoff documentation")
        print("4. 👥 Seamless human-AI collaboration")
        print("5. 💻 Native CLI integration within Claude Code")
        print("6. 🔄 Real-time workflow coordination")
        
        print(f"\nDatabase: {tm.db_path}")
        print("To enable Claude Code integration:")
        print("  export TM_CLAUDE_INTEGRATION=true")
        print("  Run './tm list' to see all created tasks")
        
    except Exception as e:
        print(f"\nError during demonstration: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()