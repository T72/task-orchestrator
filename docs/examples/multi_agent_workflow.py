#!/usr/bin/env python3
"""
Task Orchestrator - Multi-Agent Workflow Examples

This script demonstrates how multiple agents (developers, teams, or AI assistants)
can coordinate work using Task Orchestrator. It simulates realistic team scenarios
including task assignment, notification handling, and conflict resolution.

Scenarios covered:
- Team coordination workflows
- Agent specialization and assignment
- Notification and communication patterns
- Conflict detection and resolution
- Cross-team dependencies
- Workload balancing
"""

import sys
import os
import time
import random
from pathlib import Path
from typing import Dict, List
from datetime import datetime

# Add the project root to the Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from src.tm_production import TaskManager, ValidationError
    from tm_orchestrator import Orchestrator
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Make sure you're running this from the task-orchestrator directory")
    sys.exit(1)

def print_separator(title):
    """Print a formatted section separator."""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print('='*70)

def create_agent_profile(agent_id: str, name: str, specialties: List[str], workload_capacity: int = 5):
    """Create an agent profile for simulation."""
    return {
        'id': agent_id,
        'name': name,
        'specialties': specialties,
        'workload_capacity': workload_capacity,
        'current_workload': 0,
        'completed_tasks': 0,
        'task_manager': None  # Will be set when needed
    }

def print_team_status(agents: Dict, tm: TaskManager):
    """Print current status of all agents and their tasks."""
    print("\nTeam Status:")
    print("-" * 50)
    
    for agent_id, agent in agents.items():
        assigned_tasks = tm.list(assignee=agent_id)
        in_progress = [t for t in assigned_tasks if t['status'] == 'in_progress']
        pending = [t for t in assigned_tasks if t['status'] == 'pending']
        completed = [t for t in assigned_tasks if t['status'] == 'completed']
        
        workload_indicator = "●" * len(in_progress) + "○" * (agent['workload_capacity'] - len(in_progress))
        
        print(f"👤 {agent['name']} ({agent_id}):")
        print(f"   Specialties: {', '.join(agent['specialties'])}")
        print(f"   Workload: {workload_indicator} ({len(in_progress)}/{agent['workload_capacity']})")
        print(f"   Tasks: {len(pending)} pending, {len(in_progress)} active, {len(completed)} completed")
        
        if in_progress:
            print("   Active tasks:")
            for task in in_progress[:3]:  # Show first 3
                print(f"     - [{task['id']}] {task['title']}")

def simulate_agent_work(agent: Dict, tm: TaskManager, task_id: str, work_duration: int = 2):
    """Simulate an agent working on a task."""
    print(f"🔨 {agent['name']} starting work on task {task_id}")
    
    # Start the task
    tm.update(task_id, status="in_progress")
    agent['current_workload'] += 1
    
    # Simulate work (in real scenarios, this would be actual work)
    time.sleep(work_duration)
    
    # Random chance of completion vs. partial progress
    if random.random() < 0.7:  # 70% chance of completion
        tm.complete(task_id)
        agent['current_workload'] -= 1
        agent['completed_tasks'] += 1
        print(f"✅ {agent['name']} completed task {task_id}")
        return True
    else:
        tm.update(task_id, impact_notes=f"Work in progress by {agent['name']}")
        print(f"⏸️  {agent['name']} made progress on task {task_id}")
        return False

def create_development_team():
    """Create a realistic development team with different specialties."""
    print_separator("Creating Development Team")
    
    agents = {
        'alice_backend': create_agent_profile(
            'alice_backend', 
            'Alice (Backend Developer)',
            ['api', 'database', 'security', 'performance'],
            workload_capacity=4
        ),
        'bob_frontend': create_agent_profile(
            'bob_frontend',
            'Bob (Frontend Developer)', 
            ['ui', 'components', 'styling', 'accessibility'],
            workload_capacity=3
        ),
        'charlie_fullstack': create_agent_profile(
            'charlie_fullstack',
            'Charlie (Full-Stack Developer)',
            ['api', 'ui', 'integration', 'testing'],
            workload_capacity=5
        ),
        'diana_devops': create_agent_profile(
            'diana_devops',
            'Diana (DevOps Engineer)',
            ['deployment', 'monitoring', 'infrastructure', 'ci-cd'],
            workload_capacity=3
        ),
        'eve_qa': create_agent_profile(
            'eve_qa',
            'Eve (QA Engineer)',
            ['testing', 'automation', 'quality-assurance', 'bugs'],
            workload_capacity=4
        )
    }
    
    print("Team created:")
    for agent_id, agent in agents.items():
        print(f"  👤 {agent['name']}")
        print(f"     Specialties: {', '.join(agent['specialties'])}")
        print(f"     Capacity: {agent['workload_capacity']} concurrent tasks")
    
    return agents

def create_project_tasks(tm: TaskManager):
    """Create a realistic project with tasks suitable for different specialists."""
    print_separator("Creating Project Tasks")
    
    print("Creating 'E-commerce Platform' project tasks...")
    
    # Backend tasks
    backend_tasks = []
    backend_tasks.append(tm.add(
        "Implement user authentication API",
        description="JWT-based authentication with refresh tokens",
        priority="critical",
        tags=["backend", "api", "security"]
    ))
    
    backend_tasks.append(tm.add(
        "Design product catalog database schema",
        description="Optimize for product search and filtering",
        priority="high",
        tags=["backend", "database"]
    ))
    
    backend_tasks.append(tm.add(
        "Implement payment processing API",
        description="Integrate with Stripe and PayPal",
        priority="critical",
        tags=["backend", "api", "payment"]
    ))
    
    backend_tasks.append(tm.add(
        "Add product search API with filtering",
        depends_on=[backend_tasks[1]],  # Depends on database schema
        priority="high",
        tags=["backend", "api", "search"]
    ))
    
    # Frontend tasks
    frontend_tasks = []
    frontend_tasks.append(tm.add(
        "Create responsive product listing page",
        description="Grid layout with filters and sorting",
        priority="high",
        tags=["frontend", "ui", "responsive"]
    ))
    
    frontend_tasks.append(tm.add(
        "Build shopping cart component",
        description="Persistent cart with local storage backup",
        priority="high",
        tags=["frontend", "ui", "components"]
    ))
    
    frontend_tasks.append(tm.add(
        "Implement checkout flow UI",
        depends_on=[frontend_tasks[1], backend_tasks[2]],  # Needs cart and payment API
        priority="critical",
        tags=["frontend", "ui", "checkout"]
    ))
    
    frontend_tasks.append(tm.add(
        "Add user authentication forms",
        depends_on=[backend_tasks[0]],  # Needs auth API
        priority="medium",
        tags=["frontend", "ui", "auth"]
    ))
    
    # Full-stack integration tasks
    integration_tasks = []
    integration_tasks.append(tm.add(
        "Integrate product listing with search API",
        depends_on=[frontend_tasks[0], backend_tasks[3]],
        priority="high",
        tags=["integration", "frontend", "backend"]
    ))
    
    integration_tasks.append(tm.add(
        "End-to-end checkout flow integration",
        depends_on=[frontend_tasks[2]],
        priority="critical",
        tags=["integration", "testing"]
    ))
    
    # DevOps tasks
    devops_tasks = []
    devops_tasks.append(tm.add(
        "Set up production database cluster",
        priority="critical",
        tags=["devops", "infrastructure", "database"]
    ))
    
    devops_tasks.append(tm.add(
        "Configure CI/CD pipeline",
        priority="high",
        tags=["devops", "ci-cd", "automation"]
    ))
    
    devops_tasks.append(tm.add(
        "Set up monitoring and alerting",
        depends_on=[devops_tasks[0]],  # Needs production environment
        priority="medium",
        tags=["devops", "monitoring"]
    ))
    
    # QA tasks
    qa_tasks = []
    qa_tasks.append(tm.add(
        "Write automated tests for auth API",
        depends_on=[backend_tasks[0]],
        priority="high",
        tags=["qa", "testing", "api"]
    ))
    
    qa_tasks.append(tm.add(
        "Create UI automation tests for checkout",
        depends_on=[integration_tasks[1]],
        priority="high",
        tags=["qa", "testing", "ui"]
    ))
    
    qa_tasks.append(tm.add(
        "Perform security testing on payment flow",
        depends_on=[backend_tasks[2], frontend_tasks[2]],
        priority="critical",
        tags=["qa", "security", "testing"]
    ))
    
    all_task_ids = backend_tasks + frontend_tasks + integration_tasks + devops_tasks + qa_tasks
    
    print(f"✓ Created {len(all_task_ids)} project tasks")
    print(f"  Backend: {len(backend_tasks)} tasks")
    print(f"  Frontend: {len(frontend_tasks)} tasks") 
    print(f"  Integration: {len(integration_tasks)} tasks")
    print(f"  DevOps: {len(devops_tasks)} tasks")
    print(f"  QA: {len(qa_tasks)} tasks")
    
    return {
        'backend': backend_tasks,
        'frontend': frontend_tasks,
        'integration': integration_tasks,
        'devops': devops_tasks,
        'qa': qa_tasks,
        'all': all_task_ids
    }

def intelligent_task_assignment(agents: Dict, tm: TaskManager):
    """Assign tasks to agents based on their specialties and workload."""
    print_separator("Intelligent Task Assignment")
    
    print("Assigning tasks based on agent specialties and current workload...")
    
    # Get all unassigned pending tasks
    unassigned_tasks = [t for t in tm.list(status="pending") if not t['assignee']]
    
    assignments = []
    
    for task in unassigned_tasks:
        task_tags = set(task.get('tags', []))
        
        # Find agents whose specialties match task tags
        candidate_agents = []
        for agent_id, agent in agents.items():
            specialty_match = len(set(agent['specialties']) & task_tags)
            if specialty_match > 0:
                # Consider both specialty match and current workload
                score = specialty_match * 10 - agent['current_workload']
                candidate_agents.append((agent_id, agent, score))
        
        if candidate_agents:
            # Sort by score (higher is better)
            candidate_agents.sort(key=lambda x: x[2], reverse=True)
            best_agent_id, best_agent, score = candidate_agents[0]
            
            # Check if agent has capacity
            if best_agent['current_workload'] < best_agent['workload_capacity']:
                tm.update(task['id'], assignee=best_agent_id)
                best_agent['current_workload'] += 1
                assignments.append((task['id'], task['title'], best_agent['name'], score))
    
    print(f"✓ Assigned {len(assignments)} tasks")
    for task_id, title, agent_name, score in assignments:
        print(f"  [{task_id}] {title} → {agent_name} (score: {score})")
    
    return assignments

def simulate_team_collaboration(agents: Dict, tm: TaskManager):
    """Simulate agents working collaboratively on tasks."""
    print_separator("Team Collaboration Simulation")
    
    print("Simulating collaborative development work...")
    
    # Simulate multiple work cycles
    for cycle in range(1, 4):
        print(f"\n🔄 Work Cycle {cycle}")
        print("-" * 30)
        
        # Each agent works on their assigned tasks
        for agent_id, agent in agents.items():
            assigned_tasks = tm.list(assignee=agent_id, status="pending")
            
            if assigned_tasks:
                # Pick a random task to work on
                task = random.choice(assigned_tasks)
                simulate_agent_work(agent, tm, task['id'], work_duration=1)
            
            # Check for notifications
            notifications = tm.watch()
            if notifications:
                print(f"📬 {agent['name']} has {len(notifications)} notifications")
                for notif in notifications[:2]:  # Show first 2
                    print(f"    [{notif['type']}] {notif['message']}")
        
        print_team_status(agents, tm)
        time.sleep(1)

def demonstrate_conflict_detection(agents: Dict, tm: TaskManager):
    """Demonstrate conflict detection when multiple agents work on related tasks."""
    print_separator("Conflict Detection and Resolution")
    
    print("Creating scenario with potential conflicts...")
    
    # Create tasks that might conflict
    shared_file_task1 = tm.add(
        "Refactor authentication middleware",
        priority="high",
        file_refs=[{
            'file_path': 'src/middleware/auth.js',
            'line_start': 1,
            'line_end': 100
        }],
        tags=["backend", "refactoring"]
    )
    
    shared_file_task2 = tm.add(
        "Add rate limiting to authentication",
        priority="medium", 
        file_refs=[{
            'file_path': 'src/middleware/auth.js',
            'line_start': 50,
            'line_end': 80
        }],
        tags=["backend", "security"]
    )
    
    # Assign to different agents
    tm.update(shared_file_task1, assignee="alice_backend")
    tm.update(shared_file_task2, assignee="charlie_fullstack")
    
    print("✓ Created conflicting tasks:")
    print(f"  Task 1 (Alice): {shared_file_task1} - Refactor auth middleware")
    print(f"  Task 2 (Charlie): {shared_file_task2} - Add rate limiting")
    print("  Both tasks modify the same file: src/middleware/auth.js")
    
    # Simulate both agents starting work
    print("\n🔄 Simulating concurrent work:")
    tm.update(shared_file_task1, status="in_progress")
    print("  Alice started refactoring...")
    
    tm.update(shared_file_task2, status="in_progress") 
    print("  Charlie started adding rate limiting...")
    
    # In a real system, this would trigger conflict detection
    print("\n⚠️  Potential conflict detected!")
    print("  Resolution strategies:")
    print("    1. Coordinate work timing")
    print("    2. Split file into smaller modules")
    print("    3. Create dependency between tasks")
    print("    4. Merge tasks into single larger task")
    
    # Demonstrate resolution by creating dependency
    print("\n✅ Resolution: Converting to dependency")
    tm.update(shared_file_task2, status="blocked")
    
    # Update task dependencies manually (in practice, this would be more sophisticated)
    print("  Charlie's task now waits for Alice's refactoring to complete")

def demonstrate_cross_team_coordination(agents: Dict, tm: TaskManager):
    """Show how different teams coordinate on cross-cutting concerns."""
    print_separator("Cross-Team Coordination")
    
    print("Creating cross-team feature requiring coordination...")
    
    # Epic that requires multiple teams
    epic_id = tm.add(
        "Implement real-time notifications",
        description="Users get real-time updates for orders, messages, etc.",
        priority="high",
        tags=["epic", "real-time", "notifications"]
    )
    
    # Backend work
    websocket_api = tm.add(
        "Implement WebSocket notification API",
        depends_on=[epic_id],
        priority="high",
        tags=["backend", "api", "websocket"]
    )
    tm.update(websocket_api, assignee="alice_backend")
    
    # Frontend work
    notification_ui = tm.add(
        "Build notification UI components",
        depends_on=[epic_id],
        priority="medium",
        tags=["frontend", "ui", "components"]
    )
    tm.update(notification_ui, assignee="bob_frontend")
    
    # Integration work
    integration_task = tm.add(
        "Integrate WebSocket with notification UI",
        depends_on=[websocket_api, notification_ui],
        priority="high",
        tags=["integration", "real-time"]
    )
    tm.update(integration_task, assignee="charlie_fullstack")
    
    # Infrastructure work
    infra_task = tm.add(
        "Set up WebSocket load balancing",
        depends_on=[websocket_api],
        priority="medium",
        tags=["devops", "infrastructure", "scalability"]
    )
    tm.update(infra_task, assignee="diana_devops")
    
    # QA work
    testing_task = tm.add(
        "Test real-time notification reliability",
        depends_on=[integration_task, infra_task],
        priority="high",
        tags=["qa", "testing", "real-time"]
    )
    tm.update(testing_task, assignee="eve_qa")
    
    print("✓ Cross-team feature created:")
    print("  👤 Alice (Backend): WebSocket API")
    print("  👤 Bob (Frontend): Notification UI")  
    print("  👤 Charlie (Full-stack): Integration")
    print("  👤 Diana (DevOps): Infrastructure")
    print("  👤 Eve (QA): Testing")
    
    # Show dependency chain
    tasks = tm.list()
    feature_tasks = [t for t in tasks if 'notification' in t['title'].lower() or 'websocket' in t['title'].lower()]
    
    print("\nDependency flow:")
    for task in feature_tasks:
        deps = f" (depends on {len(task['dependencies'])} tasks)" if task['dependencies'] else ""
        assignee = f" - {agents[task['assignee']]['name']}" if task['assignee'] else ""
        print(f"  [{task['id']}] {task['title']}{assignee}{deps}")

def demonstrate_workload_balancing(agents: Dict, tm: TaskManager):
    """Show how workload can be balanced across team members."""
    print_separator("Dynamic Workload Balancing")
    
    print("Current team workload distribution:")
    print_team_status(agents, tm)
    
    # Find overloaded agents
    overloaded_agents = [(agent_id, agent) for agent_id, agent in agents.items() 
                        if agent['current_workload'] > agent['workload_capacity'] * 0.8]
    
    underutilized_agents = [(agent_id, agent) for agent_id, agent in agents.items()
                           if agent['current_workload'] < agent['workload_capacity'] * 0.5]
    
    if overloaded_agents and underutilized_agents:
        print("\n⚖️  Workload rebalancing opportunities found:")
        
        for overloaded_id, overloaded_agent in overloaded_agents:
            print(f"  Overloaded: {overloaded_agent['name']} ({overloaded_agent['current_workload']}/{overloaded_agent['workload_capacity']})")
            
            # Find tasks that could be reassigned
            overloaded_tasks = tm.list(assignee=overloaded_id, status="pending")
            
            for task in overloaded_tasks[:2]:  # Consider first 2 tasks
                task_tags = set(task.get('tags', []))
                
                # Find underutilized agents who could take this task
                for underutil_id, underutil_agent in underutilized_agents:
                    agent_specialties = set(underutil_agent['specialties'])
                    if task_tags & agent_specialties:  # Has relevant expertise
                        print(f"    Could reassign [{task['id']}] {task['title']}")
                        print(f"      From: {overloaded_agent['name']} → To: {underutil_agent['name']}")
                        
                        # Actually reassign (in demo)
                        tm.update(task['id'], assignee=underutil_id)
                        overloaded_agent['current_workload'] -= 1
                        underutil_agent['current_workload'] += 1
                        print(f"      ✅ Reassigned!")
                        break
    
    print("\nWorkload after rebalancing:")
    print_team_status(agents, tm)

def generate_team_report(agents: Dict, tm: TaskManager):
    """Generate a comprehensive team productivity report."""
    print_separator("Team Productivity Report")
    
    print(f"📊 Team Report - Generated {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Overall statistics
    all_tasks = tm.list()
    total_tasks = len(all_tasks)
    completed_tasks = len([t for t in all_tasks if t['status'] == 'completed'])
    in_progress_tasks = len([t for t in all_tasks if t['status'] == 'in_progress'])
    pending_tasks = len([t for t in all_tasks if t['status'] == 'pending'])
    blocked_tasks = len([t for t in all_tasks if t['status'] == 'blocked'])
    
    print(f"\n📈 Overall Progress:")
    print(f"  Total Tasks: {total_tasks}")
    print(f"  Completed: {completed_tasks} ({completed_tasks/total_tasks*100:.1f}%)")
    print(f"  In Progress: {in_progress_tasks} ({in_progress_tasks/total_tasks*100:.1f}%)")
    print(f"  Pending: {pending_tasks} ({pending_tasks/total_tasks*100:.1f}%)")
    print(f"  Blocked: {blocked_tasks} ({blocked_tasks/total_tasks*100:.1f}%)")
    
    # Agent performance
    print(f"\n👥 Individual Performance:")
    for agent_id, agent in agents.items():
        agent_tasks = tm.list(assignee=agent_id)
        completed_count = len([t for t in agent_tasks if t['status'] == 'completed'])
        active_count = len([t for t in agent_tasks if t['status'] == 'in_progress'])
        
        efficiency = completed_count / max(len(agent_tasks), 1) * 100
        
        print(f"  {agent['name']}:")
        print(f"    Tasks: {len(agent_tasks)} total, {completed_count} completed ({efficiency:.1f}% efficiency)")
        print(f"    Current Load: {active_count}/{agent['workload_capacity']} capacity")
        print(f"    Specialties: {', '.join(agent['specialties'])}")
    
    # Bottleneck analysis
    print(f"\n🚧 Bottleneck Analysis:")
    blocked_tasks_detail = [t for t in all_tasks if t['status'] == 'blocked']
    if blocked_tasks_detail:
        print(f"  {len(blocked_tasks_detail)} tasks are currently blocked:")
        for task in blocked_tasks_detail[:5]:  # Show top 5
            deps = ', '.join(task['dependencies']) if task['dependencies'] else 'None'
            print(f"    [{task['id']}] {task['title']} (waiting for: {deps})")
    else:
        print("  ✅ No tasks are currently blocked!")
    
    # Recommendations
    print(f"\n💡 Recommendations:")
    if pending_tasks > in_progress_tasks * 2:
        print("  - Consider increasing parallel work capacity")
    if blocked_tasks > total_tasks * 0.2:
        print("  - Review dependencies to reduce blocking")
    if any(agent['current_workload'] == 0 for agent in agents.values()):
        print("  - Redistribute work to underutilized team members")
    print("  - Schedule regular standup meetings for coordination")
    print("  - Consider pair programming for complex integration tasks")

def main():
    """Run all multi-agent workflow demonstrations."""
    print("Task Orchestrator - Multi-Agent Workflow Examples")
    print("==================================================")
    print("This script simulates realistic team collaboration scenarios")
    print("using Task Orchestrator for coordination.")
    
    try:
        # Initialize clean environment
        tm = TaskManager()
        
        # Create development team
        agents = create_development_team()
        
        # Create project with realistic tasks
        task_groups = create_project_tasks(tm)
        
        # Demonstrate intelligent assignment
        intelligent_task_assignment(agents, tm)
        
        # Simulate team collaboration
        simulate_team_collaboration(agents, tm)
        
        # Show conflict detection
        demonstrate_conflict_detection(agents, tm)
        
        # Cross-team coordination
        demonstrate_cross_team_coordination(agents, tm)
        
        # Workload balancing
        demonstrate_workload_balancing(agents, tm)
        
        # Generate final report
        generate_team_report(agents, tm)
        
        print_separator("Multi-Agent Workflow Examples Complete")
        print("All team collaboration scenarios have been demonstrated!")
        print("\nKey Insights:")
        print("1. Task assignment based on expertise improves efficiency")
        print("2. Dependency management prevents conflicts and bottlenecks")
        print("3. Notifications keep team members informed of changes")
        print("4. Workload balancing prevents burnout and improves delivery")
        print("5. Cross-team coordination ensures feature completeness")
        print(f"\nDatabase: {tm.db_path}")
        print("Run './tm export --format markdown' to see a detailed project report")
        
    except Exception as e:
        print(f"\nError during demonstration: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()