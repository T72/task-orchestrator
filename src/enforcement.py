#!/usr/bin/env python3
"""
Orchestration Enforcement System
Ensures proper Task Orchestrator usage to maximize coordination benefits

@implements FR-053: Configurable Enforcement Levels
@implements FR-054: Smart Context Detection  
@implements FR-055: Enforcement Commands
@implements FR-056: User Guidance System
@implements FR-057: Interactive Fix Wizard
"""

import os
import sys
import sqlite3
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple, NamedTuple
from datetime import datetime
from enum import Enum

class EnforcementLevel(Enum):
    """Enforcement levels with different behaviors"""
    STRICT = "strict"      # Block violations
    STANDARD = "standard"  # Warn and guide
    ADVISORY = "advisory"  # Log and continue

class ViolationType(Enum):
    """Types of orchestration violations"""
    MISSING_AGENT_ID = "missing_agent_id"
    MISSING_TM_EXECUTABLE = "missing_tm_executable" 
    UNINITIALIZED_DATABASE = "uninitialized_database"
    NO_COMMANDER_INTENT = "no_commander_intent"
    BYPASS_ATTEMPT = "bypass_attempt"

class ValidationResult(NamedTuple):
    """Result of orchestration validation"""
    is_valid: bool
    violations: List[ViolationType]
    warnings: List[str]
    guidance: str

class EnforcementConfig:
    """Manages orchestration enforcement configuration"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.config_file = db_path.parent / "enforcement.json"
        self._ensure_config_exists()
    
    def _ensure_config_exists(self):
        """Create config file if it doesn't exist"""
        if not self.config_file.exists():
            default_config = {
                "enforcement_level": EnforcementLevel.STANDARD.value,
                "auto_detect": True,
                "created_date": datetime.now().isoformat(),
                "violation_counts": {}
            }
            self.config_file.write_text(json.dumps(default_config, indent=2))
    
    def get_enforcement_level(self) -> EnforcementLevel:
        """Get current enforcement level"""
        config = json.loads(self.config_file.read_text())
        level_str = config.get("enforcement_level", "standard")
        return EnforcementLevel(level_str)
    
    def set_enforcement_level(self, level: EnforcementLevel) -> bool:
        """Set enforcement level"""
        try:
            config = json.loads(self.config_file.read_text())
            config["enforcement_level"] = level.value
            config["modified_date"] = datetime.now().isoformat()
            self.config_file.write_text(json.dumps(config, indent=2))
            return True
        except Exception as e:
            print(f"Error setting enforcement level: {e}")
            return False
    
    def is_auto_detect_enabled(self) -> bool:
        """Check if auto-detection is enabled"""
        config = json.loads(self.config_file.read_text())
        return config.get("auto_detect", True)
    
    def record_violation(self, violation_type: ViolationType):
        """Record a violation for metrics"""
        try:
            config = json.loads(self.config_file.read_text())
            counts = config.get("violation_counts", {})
            counts[violation_type.value] = counts.get(violation_type.value, 0) + 1
            config["violation_counts"] = counts
            config["last_violation"] = datetime.now().isoformat()
            self.config_file.write_text(json.dumps(config, indent=2))
        except Exception:
            pass  # Don't let metrics recording break workflow

class OrchestrationValidator:
    """Validates orchestration context and provides guidance"""
    
    def __init__(self, config: EnforcementConfig):
        self.config = config
    
    def validate_context(self) -> ValidationResult:
        """Run comprehensive orchestration validation"""
        violations = []
        warnings = []
        
        # Check TM_AGENT_ID
        if not self._check_agent_id():
            violations.append(ViolationType.MISSING_AGENT_ID)
        
        # Check tm executable
        if not self._check_tm_executable():
            violations.append(ViolationType.MISSING_TM_EXECUTABLE)
        
        # Check database initialization
        if not self._check_database_initialized():
            violations.append(ViolationType.UNINITIALIZED_DATABASE)
        
        # Generate guidance based on violations
        guidance = self._generate_guidance(violations)
        
        return ValidationResult(
            is_valid=len(violations) == 0,
            violations=violations,
            warnings=warnings,
            guidance=guidance
        )
    
    def _check_agent_id(self) -> bool:
        """Check if TM_AGENT_ID is set"""
        agent_id = os.environ.get('TM_AGENT_ID')
        return agent_id is not None and len(agent_id.strip()) > 0
    
    def _check_tm_executable(self) -> bool:
        """Check if tm executable is available"""
        # Check in current directory first
        if Path('./tm').exists() and os.access('./tm', os.X_OK):
            return True
        
        # Check in parent directory
        if Path('../tm').exists() and os.access('../tm', os.X_OK):
            return True
        
        # Check in PATH
        import shutil
        return shutil.which('tm') is not None
    
    def _check_database_initialized(self) -> bool:
        """Check if Task Orchestrator database is initialized"""
        db_path = Path.cwd() / ".task-orchestrator" / "tasks.db"
        if not db_path.exists():
            return False
        
        # Check if database has required tables
        try:
            conn = sqlite3.connect(str(db_path))
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'")
            result = cursor.fetchone()
            conn.close()
            return result is not None
        except Exception:
            return False
    
    def _generate_guidance(self, violations: List[ViolationType]) -> str:
        """Generate user-friendly guidance for violations"""
        if not violations:
            return "✅ Orchestration context is properly configured!"
        
        guidance_parts = ["🚨 ORCHESTRATION ENFORCEMENT VIOLATIONS DETECTED\n"]
        
        for violation in violations:
            if violation == ViolationType.MISSING_AGENT_ID:
                guidance_parts.append(
                    "❌ Problem: TM_AGENT_ID not set\n"
                    "   Impact: Agent coordination and context sharing disabled\n"
                    "   Fix: export TM_AGENT_ID=\"your_agent_name\"\n"
                    "   Example: export TM_AGENT_ID=\"backend_specialist\"\n"
                )
            
            elif violation == ViolationType.MISSING_TM_EXECUTABLE:
                guidance_parts.append(
                    "❌ Problem: tm executable not found\n"
                    "   Impact: Task Orchestrator commands unavailable\n"
                    "   Fix: Ensure ./tm is in current directory or PATH\n"
                    "   Check: ls -la ./tm or which tm\n"
                )
            
            elif violation == ViolationType.UNINITIALIZED_DATABASE:
                guidance_parts.append(
                    "❌ Problem: Task Orchestrator database not initialized\n"
                    "   Impact: No task coordination or context sharing\n"
                    "   Fix: ./tm init\n"
                    "   Verify: ./tm list should work without errors\n"
                )
        
        guidance_parts.extend([
            "\n💡 Why This Matters:",
            "   Proper orchestration delivers 4x-5x velocity improvements",
            "   Shared context prevents information loss between agents", 
            "   Commander's Intent framework ensures clear communication\n",
            "🔧 Quick Fix: ./tm fix-orchestration --interactive",
            "📚 Learn More: ./tm help enforcement\n"
        ])
        
        return "\n".join(guidance_parts)

class EnforcementEngine:
    """Core enforcement engine that integrates with Task Orchestrator"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.config = EnforcementConfig(db_path)
        self.validator = OrchestrationValidator(self.config)
    
    def is_enforcement_active(self) -> bool:
        """Check if enforcement should be active"""
        # Always check explicit configuration first
        level = self.config.get_enforcement_level()
        if level != EnforcementLevel.ADVISORY:
            return True
        
        # If advisory only, check auto-detection
        if self.config.is_auto_detect_enabled():
            return self._detect_orchestration_context()
        
        return False
    
    def _detect_orchestration_context(self) -> bool:
        """Auto-detect if orchestration context is expected"""
        indicators = [
            # TM_AGENT_ID suggests orchestrated environment
            os.environ.get('TM_AGENT_ID') is not None,
            
            # Claude Code integration detected
            Path('.claude').exists(),
            
            # Task Orchestrator database exists
            (Path.cwd() / ".task-orchestrator").exists(),
            
            # Multiple agent pattern in environment
            self._detect_multi_agent_patterns(),
            
            # Commander's Intent patterns in tasks
            self._detect_commander_intent_usage()
        ]
        
        return any(indicators)
    
    def _detect_multi_agent_patterns(self) -> bool:
        """Detect patterns suggesting multi-agent usage"""
        # Check for agent-specific environment variables
        agent_vars = [var for var in os.environ.keys() if 'AGENT' in var.upper()]
        return len(agent_vars) > 1
    
    def _detect_commander_intent_usage(self) -> bool:
        """Detect Commander's Intent pattern usage in tasks"""
        try:
            if not self.validator._check_database_initialized():
                return False
            
            db_path = Path.cwd() / ".task-orchestrator" / "tasks.db"
            conn = sqlite3.connect(str(db_path))
            cursor = conn.cursor()
            
            # Look for WHY/WHAT/DONE patterns in task contexts
            cursor.execute("""
                SELECT context FROM tasks 
                WHERE context LIKE '%WHY:%' 
                   OR context LIKE '%WHAT:%' 
                   OR context LIKE '%DONE:%'
                LIMIT 1
            """)
            result = cursor.fetchone()
            conn.close()
            
            return result is not None
        except Exception:
            return False
    
    def enforce_orchestration(self, command: str) -> bool:
        """Enforce orchestration for a specific command"""
        if not self.is_enforcement_active():
            return True  # No enforcement needed
        
        # Commands that require orchestration
        orchestrated_commands = [
            'add', 'join', 'share', 'note', 'discover', 'sync', 'context',
            'assign', 'watch', 'template'
        ]
        
        if command not in orchestrated_commands:
            return True  # Command doesn't require orchestration
        
        # Run validation
        result = self.validator.validate_context()
        
        if result.is_valid:
            return True
        
        # Handle violations based on enforcement level
        level = self.config.get_enforcement_level()
        
        # Record violations for metrics
        for violation in result.violations:
            self.config.record_violation(violation)
        
        if level == EnforcementLevel.STRICT:
            print(result.guidance)
            print("🚫 Command blocked due to orchestration violations")
            return False
        
        elif level == EnforcementLevel.STANDARD:
            print(result.guidance)
            response = input("Continue anyway? (y/N): ").lower().strip()
            return response in ['y', 'yes']
        
        else:  # ADVISORY
            print("⚠️  Orchestration Advisory:")
            print(result.guidance)
            return True
    
    def show_enforcement_status(self) -> str:
        """Show current enforcement status"""
        level = self.config.get_enforcement_level()
        active = self.is_enforcement_active()
        auto_detect = self.config.is_auto_detect_enabled()
        
        status_parts = [
            f"Enforcement Level: {level.value}",
            f"Currently Active: {'Yes' if active else 'No'}",
            f"Auto-Detection: {'Enabled' if auto_detect else 'Disabled'}"
        ]
        
        if active:
            result = self.validator.validate_context()
            if result.is_valid:
                status_parts.append("✅ Orchestration Context: Valid")
            else:
                status_parts.append(f"❌ Violations Found: {len(result.violations)}")
        
        return "\n".join(status_parts)
    
    def fix_orchestration_interactive(self) -> bool:
        """Interactive orchestration fix wizard"""
        print("🔧 Task Orchestrator Fix Wizard")
        print("=" * 40)
        
        result = self.validator.validate_context()
        
        if result.is_valid:
            print("✅ No violations found - orchestration is properly configured!")
            return True
        
        print(f"Found {len(result.violations)} violations to fix:\n")
        
        fixed_count = 0
        
        for violation in result.violations:
            if violation == ViolationType.MISSING_AGENT_ID:
                fixed_count += self._fix_agent_id()
            elif violation == ViolationType.MISSING_TM_EXECUTABLE:
                fixed_count += self._fix_tm_executable()  
            elif violation == ViolationType.UNINITIALIZED_DATABASE:
                fixed_count += self._fix_database_init()
        
        print(f"\n✅ Fixed {fixed_count}/{len(result.violations)} violations")
        
        # Re-validate after fixes
        final_result = self.validator.validate_context()
        
        if final_result.is_valid:
            print("🎉 Orchestration is now properly configured!")
            return True
        else:
            print(f"⚠️  {len(final_result.violations)} violations remain - manual intervention may be needed")
            print(final_result.guidance)
            return False
    
    def _fix_agent_id(self) -> int:
        """Fix missing TM_AGENT_ID"""
        print("🔧 Fixing TM_AGENT_ID...")
        
        suggestions = [
            "backend_specialist",
            "frontend_specialist", 
            "database_specialist",
            "orchestrator",
            "research_agent"
        ]
        
        print("Suggested agent IDs:")
        for i, suggestion in enumerate(suggestions, 1):
            print(f"  {i}. {suggestion}")
        print("  6. Custom name")
        
        while True:
            choice = input("Select option (1-6): ").strip()
            
            if choice in ['1', '2', '3', '4', '5']:
                agent_id = suggestions[int(choice) - 1]
                break
            elif choice == '6':
                agent_id = input("Enter custom agent ID: ").strip()
                if agent_id:
                    break
                print("Agent ID cannot be empty")
            else:
                print("Invalid choice - please select 1-6")
        
        # Set environment variable for current session
        os.environ['TM_AGENT_ID'] = agent_id
        
        # Provide instructions for permanent fix
        print(f"\n✅ Set TM_AGENT_ID={agent_id} for current session")
        print("To make permanent, add to your shell profile:")
        print(f"  echo 'export TM_AGENT_ID=\"{agent_id}\"' >> ~/.bashrc")
        
        return 1
    
    def _fix_tm_executable(self) -> int:
        """Fix missing tm executable"""
        print("🔧 Checking tm executable location...")
        
        # Try to find tm in common locations
        locations = ['./tm', '../tm']
        
        for location in locations:
            if Path(location).exists():
                if os.access(location, os.X_OK):
                    print(f"✅ Found executable tm at {location}")
                    return 1
                else:
                    print(f"⚠️  Found tm at {location} but it's not executable")
                    try:
                        os.chmod(location, 0o755)
                        print(f"✅ Made {location} executable")
                        return 1
                    except Exception as e:
                        print(f"❌ Could not make executable: {e}")
        
        print("❌ Could not find tm executable")
        print("Manual steps needed:")
        print("1. Ensure you're in the Task Orchestrator project directory")
        print("2. Verify tm file exists: ls -la tm")
        print("3. Make executable if needed: chmod +x tm")
        
        return 0
    
    def _fix_database_init(self) -> int:
        """Fix uninitialized database"""
        print("🔧 Initializing Task Orchestrator database...")
        
        try:
            # Try to run ./tm init
            import subprocess
            result = subprocess.run(['./tm', 'init'], 
                                  capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print("✅ Database initialized successfully")
                return 1
            else:
                print(f"❌ Database initialization failed: {result.stderr}")
                return 0
                
        except Exception as e:
            print(f"❌ Could not initialize database: {e}")
            print("Manual step: ./tm init")
            return 0

# Decorator for enforcement integration
def enforce_orchestration(func):
    """Decorator to enforce orchestration before command execution"""
    def wrapper(*args, **kwargs):
        # Find database path
        db_dir = Path.cwd() / ".task-orchestrator"
        if not db_dir.exists():
            db_dir.mkdir(exist_ok=True)
        
        db_path = db_dir / "tasks.db"
        
        # Create enforcement engine
        engine = EnforcementEngine(db_path)
        
        # Extract command from args or function name
        command = kwargs.get('command') or (args[0] if args else func.__name__)
        
        # Enforce orchestration
        if not engine.enforce_orchestration(command):
            sys.exit(1)
        
        return func(*args, **kwargs)
    
    return wrapper

if __name__ == "__main__":
    # Command-line interface for enforcement commands
    if len(sys.argv) < 2:
        print("Usage: python enforcement.py <command>")
        sys.exit(1)
    
    db_dir = Path.cwd() / ".task-orchestrator"
    if not db_dir.exists():
        db_dir.mkdir(exist_ok=True)
    
    db_path = db_dir / "tasks.db"
    engine = EnforcementEngine(db_path)
    
    command = sys.argv[1]
    
    if command == "status":
        print(engine.show_enforcement_status())
    
    elif command == "validate":
        result = engine.validator.validate_context()
        if result.is_valid:
            print("✅ Orchestration context is valid")
            sys.exit(0)
        else:
            print(result.guidance)
            sys.exit(1)
    
    elif command == "fix":
        interactive = "--interactive" in sys.argv
        if interactive:
            success = engine.fix_orchestration_interactive()
            sys.exit(0 if success else 1)
        else:
            print("Use --interactive flag for guided fixes")
            sys.exit(1)
    
    elif command == "config":
        if len(sys.argv) < 3:
            print(engine.show_enforcement_status())
        else:
            level_arg = sys.argv[2]
            if level_arg in ["strict", "standard", "advisory"]:
                level = EnforcementLevel(level_arg)
                if engine.config.set_enforcement_level(level):
                    print(f"✅ Enforcement level set to: {level.value}")
                else:
                    print("❌ Failed to set enforcement level")
                    sys.exit(1)
            else:
                print("Invalid level - use: strict, standard, or advisory")
                sys.exit(1)
    
    else:
        print(f"Unknown command: {command}")
        print("Available commands: status, validate, fix, config")
        sys.exit(1)