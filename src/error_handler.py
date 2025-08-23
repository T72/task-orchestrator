"""
Error handling utilities for Task Orchestrator Core Loop.
Provides consistent error handling and recovery strategies.

@implements SYS-001: System Error Handling
@implements SYS-002: Error Recovery Mechanisms
@implements SYS-003: Error Logging and Reporting
@implements NFR-004: Maintainability through consistent error handling
"""

import sys
import traceback
from typing import Any, Callable, Optional, Dict
from datetime import datetime
from pathlib import Path
import json


class TaskOrchestratorError(Exception):
    """Base exception for Task Orchestrator errors."""
    pass


class ValidationError(TaskOrchestratorError):
    """Raised when validation fails."""
    pass


class MigrationError(TaskOrchestratorError):
    """Raised when database migration fails."""
    pass


class ConfigurationError(TaskOrchestratorError):
    """Raised when configuration is invalid."""
    pass


class TelemetryError(TaskOrchestratorError):
    """Non-critical error in telemetry system."""
    pass


class ErrorHandler:
    """
    Centralized error handling and recovery.
    
    @implements SYS-001: System Error Handling
    @implements SYS-002: Error Recovery Mechanisms  
    @implements SYS-003: Error Logging and Reporting
    """
    
    def __init__(self, log_dir: Path = None):
        """Initialize error handler."""
        if log_dir:
            self.log_dir = Path(log_dir)
        else:
            self.log_dir = Path.home() / ".task-orchestrator" / "logs"
        
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.error_log = self.log_dir / "errors.log"
    
    def handle_error(self, error: Exception, context: str = "", 
                    critical: bool = False) -> bool:
        """
        Handle an error with appropriate logging and recovery.
        
        Returns:
            bool: True if error was handled and execution can continue
        """
        error_data = {
            'timestamp': datetime.now().isoformat(),
            'type': type(error).__name__,
            'message': str(error),
            'context': context,
            'critical': critical,
            'traceback': traceback.format_exc()
        }
        
        # Log error
        self._log_error(error_data)
        
        # Handle based on error type
        if isinstance(error, TelemetryError):
            # Non-critical, continue execution
            return True
        
        elif isinstance(error, ValidationError):
            # Show user-friendly message
            print(f"Validation Error: {error}")
            return not critical
        
        elif isinstance(error, MigrationError):
            # Critical for data integrity
            print(f"Migration Error: {error}")
            print("Please restore from backup and check migration scripts")
            return False
        
        elif isinstance(error, ConfigurationError):
            # Try to reset to defaults
            print(f"Configuration Error: {error}")
            print("Resetting to default configuration...")
            return self._recover_config()
        
        else:
            # Unknown error
            if critical:
                print(f"Critical Error: {error}")
                print(f"Details logged to: {self.error_log}")
                return False
            else:
                print(f"Warning: {error}")
                return True
    
    def _log_error(self, error_data: Dict):
        """Log error to file."""
        try:
            with open(self.error_log, 'a') as f:
                f.write(json.dumps(error_data) + '\n')
        except:
            # If we can't log, at least print to stderr
            print(f"Error logging failed: {error_data}", file=sys.stderr)
    
    def _recover_config(self) -> bool:
        """Attempt to recover from configuration error."""
        try:
            from config_manager import ConfigManager
            config = ConfigManager()
            config.reset_to_defaults()
            return True
        except:
            return False
    
    def safe_execute(self, func: Callable, *args, **kwargs) -> Optional[Any]:
        """
        Safely execute a function with error handling.
        
        Returns:
            Result of function or None if error occurred
        """
        try:
            return func(*args, **kwargs)
        except Exception as e:
            self.handle_error(e, context=f"Executing {func.__name__}")
            return None
    
    def with_retry(self, func: Callable, max_retries: int = 3, 
                  delay: float = 1.0, *args, **kwargs) -> Optional[Any]:
        """
        Execute function with retry logic.
        
        Returns:
            Result of function or None if all retries failed
        """
        import time
        
        for attempt in range(max_retries):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if attempt == max_retries - 1:
                    # Last attempt failed
                    self.handle_error(e, context=f"Final retry of {func.__name__}")
                    return None
                else:
                    # Wait before retry
                    time.sleep(delay * (attempt + 1))
                    continue
    
    def validate_input(self, value: Any, validator: Callable, 
                      error_msg: str = "Validation failed") -> Any:
        """
        Validate input with custom validator.
        
        Raises:
            ValidationError if validation fails
        """
        try:
            if not validator(value):
                raise ValidationError(error_msg)
            return value
        except Exception as e:
            if isinstance(e, ValidationError):
                raise
            else:
                raise ValidationError(f"{error_msg}: {e}")
    
    def ensure_path_exists(self, path: Path, create: bool = True) -> bool:
        """
        Ensure a path exists with proper error handling.
        
        Returns:
            bool: True if path exists or was created
        """
        try:
            if path.exists():
                return True
            
            if create:
                if path.suffix:  # It's a file
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.touch()
                else:  # It's a directory
                    path.mkdir(parents=True, exist_ok=True)
                return True
            
            return False
        except Exception as e:
            self.handle_error(e, context=f"Ensuring path exists: {path}")
            return False
    
    def safe_json_load(self, file_path: Path, default: Any = None) -> Any:
        """
        Safely load JSON file with error handling.
        
        Returns:
            Parsed JSON or default value if error
        """
        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return default
        except json.JSONDecodeError as e:
            self.handle_error(e, context=f"Loading JSON from {file_path}")
            return default
        except Exception as e:
            self.handle_error(e, context=f"Reading file {file_path}")
            return default
    
    def safe_json_save(self, data: Any, file_path: Path) -> bool:
        """
        Safely save data to JSON file.
        
        Returns:
            bool: True if successful
        """
        try:
            self.ensure_path_exists(file_path.parent)
            
            # Write to temp file first
            temp_file = file_path.with_suffix('.tmp')
            with open(temp_file, 'w') as f:
                json.dump(data, f, indent=2)
            
            # Atomic rename
            temp_file.replace(file_path)
            return True
            
        except Exception as e:
            self.handle_error(e, context=f"Saving JSON to {file_path}")
            return False


# Global error handler instance
error_handler = ErrorHandler()