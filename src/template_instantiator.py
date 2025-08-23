#!/usr/bin/env python3
"""
Template Instantiator for Task Orchestrator
Creates tasks from templates with variable substitution

@implements FR-047: Template instantiation with variable substitution
"""

import re
import copy
import uuid
from typing import Dict, List, Any, Optional, Union
from datetime import datetime, timedelta


class InstantiationError(Exception):
    """Custom exception for instantiation errors"""
    pass


class TemplateInstantiator:
    """
    Instantiates task templates with variable substitution
    
    @implements FR-047: Template instantiation engine
    """
    
    def __init__(self):
        """Initialize template instantiator"""
        self.generated_tasks = []
        self.task_id_map = {}  # Maps template indices to generated task IDs
    
    def instantiate(self, template: Dict[str, Any], variables: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Instantiate a template with provided variables
        
        Args:
            template: Parsed template dictionary
            variables: Variable values for substitution
            
        Returns:
            List of generated task dictionaries
            
        Raises:
            InstantiationError: If instantiation fails
        """
        # Validate and process variables
        processed_vars = self._process_variables(template, variables)
        
        # Clear previous state
        self.generated_tasks = []
        self.task_id_map = {}
        
        # Process each task
        for index, task_template in enumerate(template['tasks']):
            # Check if task should be included (conditional logic)
            if self._should_include_task(task_template, processed_vars):
                task = self._instantiate_task(task_template, processed_vars, index)
                self.generated_tasks.append(task)
                self.task_id_map[index] = task['id']
        
        # Process dependencies
        self._process_dependencies(template)
        
        # Run post-processing hooks if defined
        if 'hooks' in template and 'post_instantiate' in template['hooks']:
            self._run_hook(template['hooks']['post_instantiate'], self.generated_tasks)
        
        return self.generated_tasks
    
    def _process_variables(self, template: Dict[str, Any], variables: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process and validate variables against template definition
        
        Args:
            template: Template dictionary
            variables: User-provided variables
            
        Returns:
            Processed variables with defaults applied
            
        Raises:
            InstantiationError: If required variables missing or invalid
        """
        processed = {}
        template_vars = template.get('variables', {})
        
        for var_name, var_def in template_vars.items():
            # Check if required variable is provided
            if var_def.get('required', False) and var_name not in variables:
                raise InstantiationError(f"Required variable missing: {var_name}")
            
            # Use provided value or default
            if var_name in variables:
                value = variables[var_name]
                # Validate value
                self._validate_variable_value(var_name, value, var_def)
                processed[var_name] = value
            elif 'default' in var_def:
                processed[var_name] = var_def['default']
            else:
                # Optional variable without default - skip
                continue
        
        # Add any extra variables provided (for flexibility)
        for var_name, value in variables.items():
            if var_name not in processed:
                processed[var_name] = value
        
        return processed
    
    def _validate_variable_value(self, name: str, value: Any, definition: Dict[str, Any]) -> None:
        """
        Validate a variable value against its definition
        
        Args:
            name: Variable name
            value: Variable value
            definition: Variable definition from template
            
        Raises:
            InstantiationError: If value is invalid
        """
        var_type = definition['type']
        
        # Type validation
        if var_type == 'string' and not isinstance(value, str):
            raise InstantiationError(f"Variable '{name}' must be a string")
        elif var_type == 'number' and not isinstance(value, (int, float)):
            raise InstantiationError(f"Variable '{name}' must be a number")
        elif var_type == 'boolean' and not isinstance(value, bool):
            raise InstantiationError(f"Variable '{name}' must be a boolean")
        elif var_type == 'array' and not isinstance(value, list):
            raise InstantiationError(f"Variable '{name}' must be an array")
        
        # Validation rules
        if 'validation' in definition:
            rules = definition['validation']
            
            if var_type == 'string' and 'pattern' in rules:
                if not re.match(rules['pattern'], value):
                    raise InstantiationError(f"Variable '{name}' does not match pattern: {rules['pattern']}")
            
            if var_type == 'number':
                if 'min' in rules and value < rules['min']:
                    raise InstantiationError(f"Variable '{name}' is below minimum: {rules['min']}")
                if 'max' in rules and value > rules['max']:
                    raise InstantiationError(f"Variable '{name}' is above maximum: {rules['max']}")
            
            if 'enum' in rules and value not in rules['enum']:
                raise InstantiationError(f"Variable '{name}' must be one of: {rules['enum']}")
    
    def _should_include_task(self, task_template: Dict[str, Any], variables: Dict[str, Any]) -> bool:
        """
        Check if a task should be included based on conditional logic
        
        Args:
            task_template: Task template dictionary
            variables: Processed variables
            
        Returns:
            True if task should be included
        """
        # Check for conditional inclusion
        # For now, check if task title contains reference to a false boolean variable
        # This is a simple implementation - could be enhanced with more complex conditions
        
        # Example: If task title references {{include_docs}} and it's false, skip
        title = task_template.get('title', '')
        for var_name, var_value in variables.items():
            if isinstance(var_value, bool) and not var_value:
                if f'{{{{{var_name}}}}}' in str(task_template):
                    return False
        
        return True
    
    def _instantiate_task(self, task_template: Dict[str, Any], variables: Dict[str, Any], index: int) -> Dict[str, Any]:
        """
        Instantiate a single task with variable substitution
        
        Args:
            task_template: Task template dictionary
            variables: Variables for substitution
            index: Task index in template
            
        Returns:
            Instantiated task dictionary
        """
        # Deep copy to avoid modifying template
        task = copy.deepcopy(task_template)
        
        # Generate unique task ID
        task['id'] = self._generate_task_id()
        
        # Perform variable substitution on all string fields
        task = self._substitute_variables(task, variables)
        
        # Evaluate expressions (e.g., mathematical operations)
        task = self._evaluate_expressions(task, variables)
        
        # Add template metadata
        task['template_index'] = index
        task['created_at'] = datetime.now().isoformat()
        
        # Set default status if not provided
        if 'status' not in task:
            task['status'] = 'pending'
        
        return task
    
    def _generate_task_id(self) -> str:
        """
        Generate a unique task ID
        
        Returns:
            8-character hexadecimal ID
        """
        return uuid.uuid4().hex[:8]
    
    def _substitute_variables(self, obj: Any, variables: Dict[str, Any]) -> Any:
        """
        Recursively substitute variables in an object
        
        Args:
            obj: Object to process (dict, list, string, etc.)
            variables: Variables for substitution
            
        Returns:
            Object with variables substituted
        """
        if isinstance(obj, str):
            # Replace {{variable}} patterns
            pattern = r'\{\{([^}]+)\}\}'
            
            def replacer(match):
                var_expr = match.group(1).strip()
                
                # Check if it's a simple variable reference
                if var_expr in variables:
                    return str(variables[var_expr])
                
                # Check if it's an expression (contains operators)
                if any(op in var_expr for op in ['+', '-', '*', '/', '%']):
                    # Will be handled by _evaluate_expressions
                    return match.group(0)
                
                # Variable not found - keep placeholder
                return match.group(0)
            
            return re.sub(pattern, replacer, obj)
        
        elif isinstance(obj, dict):
            return {key: self._substitute_variables(value, variables) for key, value in obj.items()}
        
        elif isinstance(obj, list):
            return [self._substitute_variables(item, variables) for item in obj]
        
        else:
            return obj
    
    def _evaluate_expressions(self, obj: Any, variables: Dict[str, Any]) -> Any:
        """
        Evaluate mathematical expressions in strings
        
        Args:
            obj: Object to process
            variables: Variables for expression evaluation
            
        Returns:
            Object with expressions evaluated
        """
        if isinstance(obj, str):
            # Look for expressions like {{estimated_days * 2}}
            pattern = r'\{\{([^}]+[+\-*/][^}]+)\}\}'
            
            def evaluator(match):
                expr = match.group(1).strip()
                
                # Create safe evaluation context
                context = {}
                for var_name, var_value in variables.items():
                    if isinstance(var_value, (int, float)):
                        context[var_name] = var_value
                
                try:
                    # Safe evaluation - only allows basic math operations
                    # Replace variable names with values
                    for var_name, var_value in context.items():
                        expr = re.sub(r'\b' + var_name + r'\b', str(var_value), expr)
                    
                    # Evaluate the expression
                    result = eval(expr, {"__builtins__": {}}, {})
                    return str(result)
                except:
                    # If evaluation fails, keep the original
                    return match.group(0)
            
            return re.sub(pattern, evaluator, obj)
        
        elif isinstance(obj, dict):
            return {key: self._evaluate_expressions(value, variables) for key, value in obj.items()}
        
        elif isinstance(obj, list):
            return [self._evaluate_expressions(item, variables) for item in obj]
        
        else:
            return obj
    
    def _process_dependencies(self, template: Dict[str, Any]) -> None:
        """
        Process and resolve task dependencies
        
        Args:
            template: Template dictionary
        """
        # Process inline dependencies in tasks
        for task in self.generated_tasks:
            if 'depends_on' in task:
                resolved_deps = []
                for dep in task['depends_on']:
                    if isinstance(dep, int):
                        # Convert template index to generated task ID
                        if dep in self.task_id_map:
                            resolved_deps.append(self.task_id_map[dep])
                    else:
                        # Keep string dependencies as-is
                        resolved_deps.append(dep)
                task['depends_on'] = resolved_deps
        
        # Process global dependencies if defined
        if 'dependencies' in template:
            for task_ref, deps in template['dependencies'].items():
                # Find the corresponding generated task
                if task_ref.isdigit():
                    task_index = int(task_ref)
                    if task_index in self.task_id_map:
                        task_id = self.task_id_map[task_index]
                        # Find the task in generated_tasks
                        for task in self.generated_tasks:
                            if task['id'] == task_id:
                                if 'depends_on' not in task:
                                    task['depends_on'] = []
                                # Add dependencies
                                for dep in deps:
                                    if isinstance(dep, int) and dep in self.task_id_map:
                                        task['depends_on'].append(self.task_id_map[dep])
                                    else:
                                        task['depends_on'].append(dep)
                                break
    
    def _run_hook(self, hook_script: str, tasks: List[Dict[str, Any]]) -> None:
        """
        Run a post-instantiation hook
        
        Args:
            hook_script: Hook script to execute
            tasks: Generated tasks
        """
        # This is a placeholder for hook execution
        # In a real implementation, this would safely execute the hook script
        # with the generated tasks as input
        pass
    
    def validate_instantiation(self, tasks: List[Dict[str, Any]], template: Dict[str, Any]) -> bool:
        """
        Validate that instantiation produced expected results
        
        Args:
            tasks: Generated tasks
            template: Original template
            
        Returns:
            True if validation passes
        """
        # Check if we have tasks
        if len(tasks) == 0:
            return False
        
        # Check if all tasks have required fields
        for task in tasks:
            if 'id' not in task:
                return False
            if 'title' not in task:
                return False
            if 'status' not in task:
                return False
        
        # Check if dependencies are valid
        task_ids = {task['id'] for task in tasks}
        for task in tasks:
            if 'depends_on' in task:
                for dep_id in task['depends_on']:
                    if dep_id not in task_ids:
                        # External dependency - that's okay
                        pass
        
        return True