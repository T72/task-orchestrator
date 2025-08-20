#!/usr/bin/env python3
"""
Task Orchestrator - Advanced Dependency Management Examples

This script demonstrates sophisticated dependency management patterns,
including complex workflows, parallel execution paths, and dependency
optimization strategies.

Use cases covered:
- Feature development workflows
- Release preparation processes
- Parallel development coordination
- Dependency optimization
- Complex project structures
"""

import sys
import os
import time
from pathlib import Path
from datetime import datetime, timedelta

# Add the project root to the Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from src.tm_production import TaskManagerexcept ImportError as e:
    print(f"Error importing TaskManager: {e}")
    print("Make sure you're running this from the task-orchestrator directory")
    sys.exit(1)

def print_separator(title):
    """Print a formatted section separator."""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print('='*70)

def print_dependency_graph(tm, title="Dependency Graph"):
    """Print tasks showing dependency relationships."""
    print(f"\n{title}:")
    print("-" * 50)
    
    tasks = tm.list()
    if not tasks:
        print("No tasks found.")
        return
    
    # Group by status for better visualization
    status_groups = {
        'pending': [],
        'in_progress': [],
        'completed': [],
        'blocked': []
    }
    
    for task in tasks:
        status_groups.setdefault(task['status'], []).append(task)
    
    status_symbols = {
        'pending': '○',
        'in_progress': '◐',
        'completed': '●',
        'blocked': '⊘',
        'cancelled': '✗'
    }
    
    for status, task_list in status_groups.items():
        if task_list:
            print(f"\n{status.upper()}:")
            for task in task_list:
                symbol = status_symbols.get(status, '?')
                deps = f" ← depends on: {','.join(task['dependencies'])}" if task['dependencies'] else ""
                blocks = f" → blocks: {','.join(task['blocks'])}" if task['blocks'] else ""
                priority_marker = "!" if task['priority'] in ['high', 'critical'] else ""
                
                print(f"  {symbol} [{task['id']}] {priority_marker}{task['title']}")
                if deps:
                    print(f"      {deps}")
                if blocks:
                    print(f"      {blocks}")

def create_feature_development_workflow():
    """Create a realistic feature development workflow with dependencies."""
    print_separator("Feature Development Workflow")
    
    tm = TaskManager()
    
    print("Creating a complete feature development workflow...")
    print("This simulates developing a 'User Profile Management' feature.")
    
    # 1. Planning and Design Phase
    epic_id = tm.add(
        "User Profile Management Feature Epic",
        description="Complete user profile management system with editing, privacy controls, and image upload",
        priority="high",
        tags=["epic", "user-profile"]
    )
    print(f"✓ Epic created: {epic_id}")
    
    # Design tasks
    requirements_id = tm.add(
        "Gather user profile requirements",
        depends_on=[epic_id],
        priority="critical",
        tags=["planning", "requirements"]
    )
    
    ui_design_id = tm.add(
        "Design user profile UI mockups",
        depends_on=[requirements_id],
        priority="high",
        tags=["design", "ui"]
    )
    
    api_design_id = tm.add(
        "Design profile API specification",
        depends_on=[requirements_id],
        priority="high",
        tags=["design", "api"]
    )
    
    # 2. Backend Development
    db_schema_id = tm.add(
        "Create user profile database schema",
        depends_on=[api_design_id],
        priority="high",
        tags=["backend", "database"]
    )
    
    api_impl_id = tm.add(
        "Implement profile API endpoints",
        depends_on=[api_design_id, db_schema_id],
        priority="high",
        tags=["backend", "api"]
    )
    
    image_upload_id = tm.add(
        "Implement image upload service",
        depends_on=[api_design_id],
        priority="medium",
        tags=["backend", "images"]
    )
    
    # 3. Frontend Development (can start after UI design)
    components_id = tm.add(
        "Build profile UI components",
        depends_on=[ui_design_id],
        priority="medium",
        tags=["frontend", "components"]
    )
    
    forms_id = tm.add(
        "Create profile edit forms",
        depends_on=[components_id],
        priority="medium",
        tags=["frontend", "forms"]
    )
    
    integration_id = tm.add(
        "Integrate frontend with API",
        depends_on=[forms_id, api_impl_id],
        priority="high",
        tags=["frontend", "integration"]
    )
    
    # 4. Testing Phase
    backend_tests_id = tm.add(
        "Write backend unit tests",
        depends_on=[api_impl_id, image_upload_id],
        priority="high",
        tags=["testing", "backend"]
    )
    
    frontend_tests_id = tm.add(
        "Write frontend component tests",
        depends_on=[integration_id],
        priority="high",
        tags=["testing", "frontend"]
    )
    
    e2e_tests_id = tm.add(
        "Create end-to-end tests",
        depends_on=[integration_id, backend_tests_id],
        priority="medium",
        tags=["testing", "e2e"]
    )
    
    # 5. Deployment and Documentation
    docs_id = tm.add(
        "Update user documentation",
        depends_on=[integration_id],
        priority="medium",
        tags=["documentation"]
    )
    
    deployment_id = tm.add(
        "Deploy to staging environment",
        depends_on=[e2e_tests_id, frontend_tests_id, docs_id],
        priority="critical",
        tags=["deployment", "staging"]
    )
    
    print_dependency_graph(tm, "Initial Feature Workflow")
    
    return {
        'epic_id': epic_id,
        'requirements_id': requirements_id,
        'ui_design_id': ui_design_id,
        'api_design_id': api_design_id,
        'deployment_id': deployment_id
    }

def simulate_parallel_development():
    """Demonstrate parallel development streams with smart dependencies."""
    print_separator("Parallel Development Coordination")
    
    tm = TaskManager()
    
    print("Creating parallel development streams that can work independently...")
    
    # Core infrastructure (blocking for others)
    auth_service_id = tm.add(
        "Implement authentication service",
        priority="critical",
        tags=["infrastructure", "auth"]
    )
    
    database_id = tm.add(
        "Set up production database",
        priority="critical",
        tags=["infrastructure", "database"]
    )
    
    # Team A: User Management
    team_a_lead_id = tm.add(
        "User management API design",
        depends_on=[auth_service_id],
        priority="high",
        tags=["team-a", "api"]
    )
    
    user_crud_id = tm.add(
        "Implement user CRUD operations",
        depends_on=[team_a_lead_id, database_id],
        priority="high",
        tags=["team-a", "backend"]
    )
    
    user_ui_id = tm.add(
        "Build user management UI",
        depends_on=[team_a_lead_id],  # Can start with just API design
        priority="medium",
        tags=["team-a", "frontend"]
    )
    
    # Team B: Content Management (independent)
    content_api_id = tm.add(
        "Content management API design",
        depends_on=[database_id],  # Only needs database
        priority="high",
        tags=["team-b", "api"]
    )
    
    content_crud_id = tm.add(
        "Implement content CRUD operations",
        depends_on=[content_api_id],
        priority="high",
        tags=["team-b", "backend"]
    )
    
    content_ui_id = tm.add(
        "Build content management UI",
        depends_on=[content_api_id],
        priority="medium",
        tags=["team-b", "frontend"]
    )
    
    # Team C: Analytics (depends on both teams)
    analytics_design_id = tm.add(
        "Design analytics data collection",
        depends_on=[user_crud_id, content_crud_id],
        priority="medium",
        tags=["team-c", "analytics"]
    )
    
    analytics_impl_id = tm.add(
        "Implement analytics tracking",
        depends_on=[analytics_design_id],
        priority="low",
        tags=["team-c", "analytics"]
    )
    
    # Integration tasks (require multiple teams)
    integration_tests_id = tm.add(
        "Cross-team integration tests",
        depends_on=[user_ui_id, content_ui_id, analytics_impl_id],
        priority="high",
        tags=["integration", "testing"]
    )
    
    print_dependency_graph(tm, "Parallel Development Streams")
    
    # Simulate completing infrastructure first
    print("\n1. Completing infrastructure tasks...")
    tm.complete(auth_service_id)
    tm.complete(database_id)
    
    print_dependency_graph(tm, "After Infrastructure Completion")
    
    # Show how teams can now work in parallel
    ready_tasks = tm.list(status="pending")
    print(f"\nTasks ready for parallel development: {len(ready_tasks)}")
    for task in ready_tasks:
        team = [tag for tag in task.get('tags', []) if tag.startswith('team-')]
        team_name = team[0] if team else "shared"
        print(f"  - {team_name}: [{task['id']}] {task['title']}")

def demonstrate_release_workflow():
    """Create a complex release preparation workflow."""
    print_separator("Release Workflow Management")
    
    tm = TaskManager()
    
    print("Creating release preparation workflow for v2.0.0...")
    
    # Release planning
    release_planning_id = tm.add(
        "Plan v2.0.0 release scope",
        priority="critical",
        tags=["release", "planning"]
    )
    
    # Feature completion (parallel)
    feature1_id = tm.add(
        "Complete authentication redesign",
        depends_on=[release_planning_id],
        priority="critical",
        tags=["release", "feature"]
    )
    
    feature2_id = tm.add(
        "Complete dashboard improvements",
        depends_on=[release_planning_id],
        priority="high",
        tags=["release", "feature"]
    )
    
    feature3_id = tm.add(
        "Complete mobile responsiveness",
        depends_on=[release_planning_id],
        priority="medium",
        tags=["release", "feature"]
    )
    
    # Code quality tasks
    security_audit_id = tm.add(
        "Perform security audit",
        depends_on=[feature1_id],  # Auth changes need security review
        priority="critical",
        tags=["release", "security"]
    )
    
    performance_testing_id = tm.add(
        "Run performance tests",
        depends_on=[feature1_id, feature2_id, feature3_id],
        priority="high",
        tags=["release", "performance"]
    )
    
    # Documentation tasks
    changelog_id = tm.add(
        "Update changelog",
        depends_on=[feature1_id, feature2_id, feature3_id],
        priority="medium",
        tags=["release", "documentation"]
    )
    
    api_docs_id = tm.add(
        "Update API documentation",
        depends_on=[feature1_id, feature2_id],  # Only features affecting API
        priority="medium",
        tags=["release", "documentation"]
    )
    
    user_guide_id = tm.add(
        "Update user guide",
        depends_on=[feature2_id, feature3_id],  # UI-affecting features
        priority="low",
        tags=["release", "documentation"]
    )
    
    # Pre-release validation
    staging_deployment_id = tm.add(
        "Deploy to staging",
        depends_on=[security_audit_id, performance_testing_id],
        priority="critical",
        tags=["release", "deployment"]
    )
    
    qa_testing_id = tm.add(
        "QA acceptance testing",
        depends_on=[staging_deployment_id],
        priority="critical",
        tags=["release", "qa"]
    )
    
    # Release tasks
    version_bump_id = tm.add(
        "Version bump and tagging",
        depends_on=[qa_testing_id, changelog_id],
        priority="critical",
        tags=["release", "versioning"]
    )
    
    production_deployment_id = tm.add(
        "Deploy to production",
        depends_on=[version_bump_id],
        priority="critical",
        tags=["release", "deployment"]
    )
    
    # Post-release
    monitoring_id = tm.add(
        "Monitor production deployment",
        depends_on=[production_deployment_id],
        priority="high",
        tags=["release", "monitoring"]
    )
    
    announcement_id = tm.add(
        "Release announcement",
        depends_on=[production_deployment_id, api_docs_id, user_guide_id],
        priority="medium",
        tags=["release", "communication"]
    )
    
    print_dependency_graph(tm, "Release Workflow")
    
    # Show critical path
    critical_tasks = tm.list()
    critical_path = [t for t in critical_tasks if t['priority'] == 'critical']
    print(f"\nCritical path tasks ({len(critical_path)} tasks):")
    for task in critical_path:
        deps = f" (depends on {len(task['dependencies'])} tasks)" if task['dependencies'] else ""
        print(f"  - [{task['id']}] {task['title']}{deps}")

def analyze_workflow_efficiency():
    """Analyze and optimize workflow dependencies."""
    print_separator("Workflow Optimization Analysis")
    
    tm = TaskManager()
    
    # Create a suboptimal workflow first
    print("Creating a workflow with optimization opportunities...")
    
    # Sequential workflow (suboptimal)
    task1 = tm.add("Research requirements", priority="high")
    task2 = tm.add("Write specification", depends_on=[task1], priority="high")
    task3 = tm.add("Design database schema", depends_on=[task2], priority="medium")
    task4 = tm.add("Design API", depends_on=[task2], priority="medium")
    task5 = tm.add("Design UI mockups", depends_on=[task2], priority="low")
    task6 = tm.add("Implement database", depends_on=[task3], priority="medium")
    task7 = tm.add("Implement API", depends_on=[task4, task6], priority="high")
    task8 = tm.add("Implement UI", depends_on=[task5, task7], priority="medium")
    task9 = tm.add("Integration testing", depends_on=[task8], priority="high")
    task10 = tm.add("Deploy", depends_on=[task9], priority="critical")
    
    print_dependency_graph(tm, "Original Workflow")
    
    # Analyze bottlenecks
    print("\nWorkflow Analysis:")
    all_tasks = tm.list()
    
    # Find tasks with no dependencies (can start immediately)
    ready_tasks = [t for t in all_tasks if not t['dependencies']]
    print(f"✓ Tasks that can start immediately: {len(ready_tasks)}")
    
    # Find tasks that block many others
    blocking_tasks = [(t, len(t['blocks'])) for t in all_tasks if t['blocks']]
    blocking_tasks.sort(key=lambda x: x[1], reverse=True)
    print("✓ Tasks blocking the most others:")
    for task, block_count in blocking_tasks[:3]:
        print(f"    [{task['id']}] {task['title']} (blocks {block_count} tasks)")
    
    # Find longest dependency chains
    def get_dependency_depth(task_id, tasks_dict, visited=None):
        if visited is None:
            visited = set()
        if task_id in visited:
            return 0
        visited.add(task_id)
        
        task = tasks_dict.get(task_id)
        if not task or not task['dependencies']:
            return 1
        
        max_depth = 0
        for dep_id in task['dependencies']:
            depth = get_dependency_depth(dep_id, tasks_dict, visited.copy())
            max_depth = max(max_depth, depth)
        
        return max_depth + 1
    
    tasks_dict = {t['id']: t for t in all_tasks}
    depths = [(t, get_dependency_depth(t['id'], tasks_dict)) for t in all_tasks]
    depths.sort(key=lambda x: x[1], reverse=True)
    
    print("✓ Longest dependency chains:")
    for task, depth in depths[:3]:
        print(f"    [{task['id']}] {task['title']} (depth: {depth})")
    
    print("\nOptimization Recommendations:")
    print("1. Tasks 3, 4, 5 could be parallelized after task 2")
    print("2. Consider if UI design really needs to wait for full specification")
    print("3. Some testing could happen in parallel with development")
    print("4. Documentation tasks could start earlier in the process")

def demonstrate_advanced_patterns():
    """Show advanced dependency patterns and edge cases."""
    print_separator("Advanced Dependency Patterns")
    
    tm = TaskManager()
    
    print("1. Diamond Dependency Pattern:")
    print("   A common pattern where multiple tasks depend on a common ancestor")
    
    #     A
    #    / \
    #   B   C
    #    \ /
    #     D
    
    a_id = tm.add("Define project requirements", priority="critical")
    b_id = tm.add("Backend development", depends_on=[a_id], priority="high")
    c_id = tm.add("Frontend development", depends_on=[a_id], priority="high")
    d_id = tm.add("Integration testing", depends_on=[b_id, c_id], priority="high")
    
    print(f"   A (requirements): {a_id}")
    print(f"   B (backend): {b_id}")
    print(f"   C (frontend): {c_id}")
    print(f"   D (integration): {d_id}")
    
    print("\n2. Fan-out Pattern:")
    print("   One task enables many parallel tasks")
    
    foundation_id = tm.add("Set up development environment", priority="critical")
    
    parallel_tasks = []
    for i, task_name in enumerate([
        "Set up linting rules",
        "Configure testing framework", 
        "Set up CI/CD pipeline",
        "Create project documentation template",
        "Set up monitoring"
    ]):
        task_id = tm.add(task_name, depends_on=[foundation_id], priority="medium")
        parallel_tasks.append(task_id)
    
    print(f"   Foundation: {foundation_id}")
    print(f"   Parallel tasks: {len(parallel_tasks)} tasks can run after foundation")
    
    print("\n3. Convergent Pattern:")
    print("   Many tasks converge to a single milestone")
    
    milestone_deps = []
    for task_name in [
        "Complete user authentication",
        "Complete data validation", 
        "Complete error handling",
        "Complete logging",
        "Complete security review"
    ]:
        task_id = tm.add(task_name, priority="high")
        milestone_deps.append(task_id)
    
    milestone_id = tm.add(
        "Release candidate ready",
        depends_on=milestone_deps,
        priority="critical"
    )
    
    print(f"   Milestone: {milestone_id} (depends on {len(milestone_deps)} tasks)")
    
    print_dependency_graph(tm, "Advanced Dependency Patterns")

def main():
    """Run all dependency management demonstrations."""
    print("Task Orchestrator - Advanced Dependency Management")
    print("==================================================")
    print("This script demonstrates sophisticated dependency management patterns")
    print("used in real-world development workflows.")
    
    try:
        # Initialize clean database for examples
        tm = TaskManager()
        
        # Run demonstrations
        feature_workflow = create_feature_development_workflow()
        time.sleep(1)
        
        simulate_parallel_development()
        time.sleep(1)
        
        demonstrate_release_workflow()
        time.sleep(1)
        
        analyze_workflow_efficiency()
        time.sleep(1)
        
        demonstrate_advanced_patterns()
        
        print_separator("Dependency Management Examples Complete")
        print("All advanced dependency patterns have been demonstrated!")
        print("\nKey Takeaways:")
        print("1. Smart dependencies enable parallel work")
        print("2. Critical path identification helps prioritize work")
        print("3. Dependency analysis can reveal optimization opportunities")
        print("4. Different patterns suit different project structures")
        print(f"\nDatabase: {tm.db_path}")
        print("Run './tm list --has-deps' to see all tasks with dependencies")
        
    except Exception as e:
        print(f"\nError during demonstration: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()