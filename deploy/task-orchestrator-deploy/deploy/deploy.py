#!/usr/bin/env python3
"""
Task Orchestrator Deployment Tool
Deploy task-orchestrator to multiple projects at once
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

class TaskOrchestratorDeployer:
    """Deploy task-orchestrator to development projects"""
    
    def __init__(self, source_dir: Path = None):
        """Initialize deployer with source directory"""
        if source_dir:
            self.source_dir = Path(source_dir)
        else:
            # Default to parent directory of this script
            self.source_dir = Path(__file__).parent.parent
        
        self.tm_path = self.source_dir / "tm"
        self.src_path = self.source_dir / "src"
        self.scripts_path = self.source_dir / "scripts"
        
        # Verify source files exist
        if not self.tm_path.exists():
            raise FileNotFoundError(f"Task orchestrator not found at {self.tm_path}")
    
    def deploy_to_project(self, project_path: str, mode: str = "copy") -> bool:
        """
        Deploy task-orchestrator to a single project
        
        Args:
            project_path: Path to target project
            mode: "copy" or "link" (symlink for development)
        
        Returns:
            Success status
        """
        project = Path(project_path).resolve()
        
        if not project.exists():
            print(f"❌ Project directory does not exist: {project}")
            return False
        
        print(f"\n📦 Deploying to: {project}")
        print(f"   Mode: {mode}")
        
        try:
            # Change to project directory
            os.chdir(project)
            
            # Initialize git if needed
            if not (project / ".git").exists():
                print("   Initializing git repository...")
                subprocess.run(["git", "init"], check=True, capture_output=True)
            
            # Create .task-orchestrator directory
            task_dir = project / ".task-orchestrator"
            task_dir.mkdir(exist_ok=True)
            
            # Deploy main executable
            tm_target = project / "tm"
            if mode == "link":
                # Create symbolic link
                if tm_target.exists() or tm_target.is_symlink():
                    tm_target.unlink()
                tm_target.symlink_to(self.tm_path)
                print("   ✓ Created symbolic link to tm")
            else:
                # Copy file
                shutil.copy2(self.tm_path, tm_target)
                tm_target.chmod(0o755)
                print("   ✓ Copied tm executable")
            
            # Deploy Python modules
            if self.src_path.exists():
                src_target = task_dir / "src"
                if src_target.exists():
                    shutil.rmtree(src_target)
                
                if mode == "link":
                    src_target.symlink_to(self.src_path)
                else:
                    shutil.copytree(self.src_path, src_target)
                print("   ✓ Deployed Python modules")
            
            # Deploy helper scripts
            scripts_target = task_dir / "scripts"
            scripts_target.mkdir(exist_ok=True)
            
            helper_scripts = ["agent_helper.sh", "cleanup-hook.sh"]
            for script in helper_scripts:
                script_path = self.scripts_path / script
                if script_path.exists():
                    shutil.copy2(script_path, scripts_target / script)
                    (scripts_target / script).chmod(0o755)
            print("   ✓ Deployed helper scripts")
            
            # Create quick reference
            self._create_quick_reference(task_dir)
            print("   ✓ Created quick reference")
            
            # Update .gitignore
            self._update_gitignore(project)
            print("   ✓ Updated .gitignore")
            
            # Create configuration
            config = {
                "project_name": project.name,
                "installed_date": datetime.utcnow().isoformat() + "Z",
                "install_mode": mode,
                "version": "1.0.0",
                "source": str(self.source_dir)
            }
            
            with open(task_dir / "config.json", "w") as f:
                json.dump(config, f, indent=2)
            print("   ✓ Created configuration")
            
            # Initialize database
            result = subprocess.run(["./tm", "init"], capture_output=True, text=True)
            if result.returncode == 0:
                print("   ✓ Initialized database")
            else:
                print(f"   ⚠️  Database initialization warning: {result.stderr}")
            
            print(f"   ✅ Deployment complete!")
            return True
            
        except Exception as e:
            print(f"   ❌ Deployment failed: {e}")
            return False
    
    def deploy_to_multiple(self, projects_file: str, mode: str = "copy") -> Dict[str, bool]:
        """
        Deploy to multiple projects listed in a file
        
        Args:
            projects_file: Path to file containing project paths (one per line)
            mode: "copy" or "link"
        
        Returns:
            Dictionary of project paths and success status
        """
        results = {}
        
        with open(projects_file, "r") as f:
            projects = [line.strip() for line in f if line.strip() and not line.startswith("#")]
        
        print(f"🚀 Deploying to {len(projects)} projects...")
        
        for project_path in projects:
            success = self.deploy_to_project(project_path, mode)
            results[project_path] = success
        
        # Summary
        successful = sum(1 for s in results.values() if s)
        failed = len(results) - successful
        
        print("\n" + "=" * 50)
        print(f"📊 Deployment Summary:")
        print(f"   ✅ Successful: {successful}")
        print(f"   ❌ Failed: {failed}")
        
        if failed > 0:
            print("\n   Failed projects:")
            for project, success in results.items():
                if not success:
                    print(f"      - {project}")
        
        return results
    
    def _create_quick_reference(self, task_dir: Path):
        """Create quick reference documentation"""
        content = """# Task Orchestrator - Quick Reference

## Essential Commands
```bash
./tm init                     # Initialize database
./tm add "task"              # Create a task  
./tm list                    # List all tasks
./tm update ID --status STATUS  # Update task
./tm complete ID             # Complete task
./tm help                    # Full help
```

## Working with Dependencies
```bash
TASK1=$(./tm add "Setup")
./tm add "Test" --depends-on $TASK1
```

## File References
```bash
./tm add "Fix bug" --file src/main.py:42
```

## Filtering
```bash
./tm list --status pending
./tm list --assignee john
./tm list --tag backend
```

## Collaboration
```bash
./tm share ID "Progress update"
./tm discover ID "Found issue"
./tm context ID  # View history
```

For full documentation: https://github.com/your-org/task-orchestrator
"""
        
        with open(task_dir / "QUICK_REFERENCE.md", "w") as f:
            f.write(content)
    
    def _update_gitignore(self, project: Path):
        """Update or create .gitignore with task-orchestrator entries"""
        gitignore_path = project / ".gitignore"
        
        entries = [
            "",
            "# Task Orchestrator",
            ".task-orchestrator/tasks.db",
            ".task-orchestrator/tasks.db-journal", 
            ".task-orchestrator/tasks.db-wal",
            ".task-orchestrator/archives/",
            ".task-orchestrator/contexts/",
            ".task-orchestrator/notes/",
            ".task-orchestrator/*.log",
            ".task-orchestrator/.lock",
            ""
        ]
        
        if gitignore_path.exists():
            with open(gitignore_path, "r") as f:
                content = f.read()
            
            if "# Task Orchestrator" not in content:
                with open(gitignore_path, "a") as f:
                    f.write("\n".join(entries))
        else:
            with open(gitignore_path, "w") as f:
                f.write("\n".join(entries))


def main():
    """Main entry point for deployment tool"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Deploy Task Orchestrator to development projects"
    )
    parser.add_argument(
        "target",
        help="Target project directory or file containing list of projects"
    )
    parser.add_argument(
        "--mode",
        choices=["copy", "link"],
        default="copy",
        help="Deployment mode: copy files or create symlinks (default: copy)"
    )
    parser.add_argument(
        "--source",
        help="Source directory containing task-orchestrator (default: parent of this script)"
    )
    parser.add_argument(
        "--batch",
        action="store_true",
        help="Treat target as a file containing list of projects"
    )
    
    args = parser.parse_args()
    
    # Initialize deployer
    deployer = TaskOrchestratorDeployer(args.source)
    
    # Deploy
    if args.batch:
        results = deployer.deploy_to_multiple(args.target, args.mode)
        sys.exit(0 if all(results.values()) else 1)
    else:
        success = deployer.deploy_to_project(args.target, args.mode)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()