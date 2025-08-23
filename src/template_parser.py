#!/usr/bin/env python3
"""
Template Parser for Task Orchestrator
Parses and validates task templates in YAML or JSON format

@implements FR-047: Advanced Task Templates
"""

import os
import re
import json
import yaml
from typing import Dict, List, Any, Optional, Union
from pathlib import Path


class TemplateError(Exception):
    """Custom exception for template-related errors"""
    pass


class TemplateParser:
    """
    Parses and validates task templates
    
    @implements FR-047: Template parsing and validation
    """
    
    # Required fields in template
    REQUIRED_FIELDS = ['name', 'version', 'description', 'tasks']
    
    # Valid task priority values
    VALID_PRIORITIES = ['low', 'medium', 'high', 'critical']
    
    # Valid task status values
    VALID_STATUSES = ['pending', 'in_progress', 'completed', 'blocked']
    
    # Valid variable types
    VALID_TYPES = ['string', 'number', 'boolean', 'array']
    
    def __init__(self, template_dir: Optional[str] = None):
        """
        Initialize template parser
        
        Args:
            template_dir: Directory containing templates (default: .task-orchestrator/templates)
        """
        if template_dir is None:
            template_dir = os.path.join('.task-orchestrator', 'templates')
        self.template_dir = Path(template_dir)
        
    def parse_template(self, template_path: Union[str, Path]) -> Dict[str, Any]:
        """
        Parse a template file (YAML or JSON)
        
        Args:
            template_path: Path to template file
            
        Returns:
            Parsed template dictionary
            
        Raises:
            TemplateError: If template is invalid or cannot be parsed
        """
        template_path = Path(template_path)
        
        if not template_path.exists():
            raise TemplateError(f"Template file not found: {template_path}")
        
        # Read template file
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except IOError as e:
            raise TemplateError(f"Failed to read template: {e}")
        
        # Parse based on extension
        if template_path.suffix in ['.yaml', '.yml']:
            try:
                template = yaml.safe_load(content)
            except yaml.YAMLError as e:
                raise TemplateError(f"Invalid YAML in template: {e}")
        elif template_path.suffix == '.json':
            try:
                template = json.loads(content)
            except json.JSONDecodeError as e:
                raise TemplateError(f"Invalid JSON in template: {e}")
        else:
            raise TemplateError(f"Unsupported template format: {template_path.suffix}")
        
        # Validate template
        self.validate_template(template)
        
        return template
    
    def validate_template(self, template: Dict[str, Any]) -> None:
        """
        Validate template structure and content
        
        Args:
            template: Template dictionary to validate
            
        Raises:
            TemplateError: If template is invalid
        """
        # Check required fields
        for field in self.REQUIRED_FIELDS:
            if field not in template:
                raise TemplateError(f"Required field missing: {field}")
        
        # Validate metadata
        if not isinstance(template['name'], str):
            raise TemplateError("Template name must be a string")
        if not re.match(r'^[a-z0-9-]+$', template['name']):
            raise TemplateError("Template name must be kebab-case")
        if not isinstance(template['version'], str):
            raise TemplateError("Template version must be a string")
        if not isinstance(template['description'], str):
            raise TemplateError("Template description must be a string")
        
        # Validate variables if present
        if 'variables' in template:
            self._validate_variables(template['variables'])
        
        # Validate tasks
        if not isinstance(template['tasks'], list):
            raise TemplateError("Tasks must be a list")
        if len(template['tasks']) == 0:
            raise TemplateError("Template must contain at least one task")
        
        for i, task in enumerate(template['tasks']):
            self._validate_task(task, i)
        
        # Validate dependencies if present
        if 'dependencies' in template:
            self._validate_dependencies(template['dependencies'], len(template['tasks']))
    
    def _validate_variables(self, variables: Dict[str, Any]) -> None:
        """
        Validate template variables
        
        Args:
            variables: Variables dictionary to validate
            
        Raises:
            TemplateError: If variables are invalid
        """
        if not isinstance(variables, dict):
            raise TemplateError("Variables must be a dictionary")
        
        for var_name, var_def in variables.items():
            if not isinstance(var_def, dict):
                raise TemplateError(f"Variable '{var_name}' must be a dictionary")
            
            # Check required fields
            if 'type' not in var_def:
                raise TemplateError(f"Variable '{var_name}' missing required field: type")
            if 'description' not in var_def:
                raise TemplateError(f"Variable '{var_name}' missing required field: description")
            
            # Validate type
            if var_def['type'] not in self.VALID_TYPES:
                raise TemplateError(f"Variable '{var_name}' has invalid type: {var_def['type']}")
            
            # Validate validation rules if present
            if 'validation' in var_def:
                self._validate_validation_rules(var_name, var_def['type'], var_def['validation'])
    
    def _validate_validation_rules(self, var_name: str, var_type: str, rules: Dict[str, Any]) -> None:
        """
        Validate variable validation rules
        
        Args:
            var_name: Variable name
            var_type: Variable type
            rules: Validation rules dictionary
            
        Raises:
            TemplateError: If validation rules are invalid
        """
        if var_type == 'string':
            if 'pattern' in rules and not isinstance(rules['pattern'], str):
                raise TemplateError(f"Variable '{var_name}': pattern must be a string")
        elif var_type == 'number':
            if 'min' in rules and not isinstance(rules['min'], (int, float)):
                raise TemplateError(f"Variable '{var_name}': min must be a number")
            if 'max' in rules and not isinstance(rules['max'], (int, float)):
                raise TemplateError(f"Variable '{var_name}': max must be a number")
            if 'min' in rules and 'max' in rules and rules['min'] > rules['max']:
                raise TemplateError(f"Variable '{var_name}': min cannot be greater than max")
        
        if 'enum' in rules:
            if not isinstance(rules['enum'], list):
                raise TemplateError(f"Variable '{var_name}': enum must be a list")
            if len(rules['enum']) == 0:
                raise TemplateError(f"Variable '{var_name}': enum cannot be empty")
    
    def _validate_task(self, task: Dict[str, Any], index: int) -> None:
        """
        Validate a task definition
        
        Args:
            task: Task dictionary to validate
            index: Task index in template
            
        Raises:
            TemplateError: If task is invalid
        """
        if not isinstance(task, dict):
            raise TemplateError(f"Task {index} must be a dictionary")
        
        # Check required fields
        if 'title' not in task:
            raise TemplateError(f"Task {index} missing required field: title")
        if not isinstance(task['title'], str):
            raise TemplateError(f"Task {index}: title must be a string")
        
        # Validate optional fields
        if 'priority' in task:
            # Allow variable substitution in priority
            if not task['priority'].startswith('{{'):
                if task['priority'] not in self.VALID_PRIORITIES:
                    raise TemplateError(f"Task {index}: invalid priority: {task['priority']}")
        
        if 'status' in task:
            if task['status'] not in self.VALID_STATUSES:
                raise TemplateError(f"Task {index}: invalid status: {task['status']}")
        
        if 'depends_on' in task:
            if not isinstance(task['depends_on'], list):
                raise TemplateError(f"Task {index}: depends_on must be a list")
        
        if 'criteria' in task:
            if not isinstance(task['criteria'], list):
                raise TemplateError(f"Task {index}: criteria must be a list")
            for criterion in task['criteria']:
                if not isinstance(criterion, dict):
                    raise TemplateError(f"Task {index}: each criterion must be a dictionary")
                if 'criterion' not in criterion:
                    raise TemplateError(f"Task {index}: criterion missing 'criterion' field")
    
    def _validate_dependencies(self, dependencies: Dict[str, Any], task_count: int) -> None:
        """
        Validate dependency definitions
        
        Args:
            dependencies: Dependencies dictionary
            task_count: Number of tasks in template
            
        Raises:
            TemplateError: If dependencies are invalid
        """
        if not isinstance(dependencies, dict):
            raise TemplateError("Dependencies must be a dictionary")
        
        for task_ref, deps in dependencies.items():
            if not isinstance(deps, list):
                raise TemplateError(f"Dependencies for '{task_ref}' must be a list")
            
            # Validate numeric indices if used
            if task_ref.isdigit():
                if int(task_ref) >= task_count:
                    raise TemplateError(f"Task index {task_ref} out of range")
            
            for dep in deps:
                if isinstance(dep, int):
                    if dep >= task_count:
                        raise TemplateError(f"Dependency index {dep} out of range")
    
    def list_templates(self) -> List[Dict[str, str]]:
        """
        List all available templates in the template directory
        
        Returns:
            List of template metadata dictionaries
        """
        templates = []
        
        if not self.template_dir.exists():
            return templates
        
        for pattern in ['*.yaml', '*.yml', '*.json']:
            for file_path in self.template_dir.glob(pattern):
                try:
                    template = self.parse_template(file_path)
                    templates.append({
                        'name': template['name'],
                        'version': template['version'],
                        'description': template['description'],
                        'path': str(file_path),
                        'tags': template.get('tags', [])
                    })
                except TemplateError:
                    # Skip invalid templates
                    continue
        
        return sorted(templates, key=lambda t: t['name'])
    
    def get_template(self, name: str) -> Dict[str, Any]:
        """
        Get a template by name
        
        Args:
            name: Template name
            
        Returns:
            Template dictionary
            
        Raises:
            TemplateError: If template not found
        """
        # Try different extensions
        for ext in ['.yaml', '.yml', '.json']:
            template_path = self.template_dir / f"{name}{ext}"
            if template_path.exists():
                return self.parse_template(template_path)
        
        raise TemplateError(f"Template not found: {name}")