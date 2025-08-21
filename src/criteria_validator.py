"""
Success Criteria Validator for Task Orchestrator Core Loop.
Validates task completion against defined success criteria.
"""

import json
import re
from typing import Dict, List, Tuple, Any, Optional
from datetime import datetime


class CriteriaValidator:
    """
    Validate task completion against success criteria.
    
    @implements FR-004: Success Criteria Definition
    @implements FR-013: Completion Validation
    @implements CORE-VALIDATION: Success criteria enforcement
    """
    
    def __init__(self):
        """Initialize criteria validator."""
        self.validators = {
            'contains': self._validate_contains,
            'equals': self._validate_equals,
            'greater_than': self._validate_greater_than,
            'less_than': self._validate_less_than,
            'regex': self._validate_regex,
            'true': self._validate_true,
            'exists': self._validate_exists
        }
    
    def validate_criteria(self, criteria_json: str, context: Dict[str, Any] = None) -> Tuple[bool, List[Dict]]:
        """
        Validate success criteria against context.
        
        Returns:
            Tuple of (all_passed: bool, results: List[Dict])
        """
        if not criteria_json:
            return True, []
        
        try:
            criteria = json.loads(criteria_json)
        except json.JSONDecodeError:
            return False, [{'error': 'Invalid criteria JSON format'}]
        
        if not isinstance(criteria, list):
            return False, [{'error': 'Criteria must be a JSON array'}]
        
        results = []
        all_passed = True
        
        for criterion in criteria:
            result = self._validate_single_criterion(criterion, context or {})
            results.append(result)
            if not result['passed']:
                all_passed = False
        
        return all_passed, results
    
    def _validate_single_criterion(self, criterion: Dict, context: Dict) -> Dict:
        """Validate a single criterion."""
        result = {
            'criterion': criterion.get('criterion', 'Unknown'),
            'measurable': criterion.get('measurable', ''),
            'passed': False,
            'reason': ''
        }
        
        if not criterion.get('measurable'):
            result['passed'] = True  # No measurable defined, auto-pass
            result['reason'] = 'No measurable criteria defined'
            return result
        
        # Parse the measurable expression
        measurable = criterion['measurable']
        
        # Try to evaluate the measurable as a simple expression
        try:
            # Check for simple comparison operators
            if '==' in measurable:
                parts = measurable.split('==')
                if len(parts) == 2:
                    left = self._evaluate_expression(parts[0].strip(), context)
                    right = self._evaluate_expression(parts[1].strip(), context)
                    result['passed'] = left == right
                    result['reason'] = f"{left} == {right}" if result['passed'] else f"{left} != {right}"
            
            elif '<' in measurable and '=' not in measurable:
                parts = measurable.split('<')
                if len(parts) == 2:
                    left = self._evaluate_expression(parts[0].strip(), context)
                    right = self._evaluate_expression(parts[1].strip(), context)
                    result['passed'] = float(left) < float(right)
                    result['reason'] = f"{left} < {right}" if result['passed'] else f"{left} >= {right}"
            
            elif '>' in measurable and '=' not in measurable:
                parts = measurable.split('>')
                if len(parts) == 2:
                    left = self._evaluate_expression(parts[0].strip(), context)
                    right = self._evaluate_expression(parts[1].strip(), context)
                    result['passed'] = float(left) > float(right)
                    result['reason'] = f"{left} > {right}" if result['passed'] else f"{left} <= {right}"
            
            elif measurable.lower() == 'true':
                result['passed'] = True
                result['reason'] = 'Automatically validated as true'
            
            elif measurable.lower() == 'false':
                result['passed'] = False
                result['reason'] = 'Automatically validated as false'
            
            else:
                # If we can't parse it, ask for manual validation
                result['passed'] = None  # Indicates manual validation needed
                result['reason'] = 'Requires manual validation'
        
        except Exception as e:
            result['passed'] = None
            result['reason'] = f'Validation error: {str(e)}'
        
        return result
    
    def _evaluate_expression(self, expr: str, context: Dict) -> Any:
        """Evaluate a simple expression."""
        expr = expr.strip()
        
        # Check if it's a number
        try:
            return float(expr)
        except ValueError:
            pass
        
        # Check if it's a string literal
        if expr.startswith('"') and expr.endswith('"'):
            return expr[1:-1]
        if expr.startswith("'") and expr.endswith("'"):
            return expr[1:-1]
        
        # Check if it's a context variable
        if expr in context:
            return context[expr]
        
        # Check for nested path (e.g., performance.query_time)
        if '.' in expr:
            parts = expr.split('.')
            current = context
            for part in parts:
                if isinstance(current, dict) and part in current:
                    current = current[part]
                else:
                    return expr  # Return as string if not found
            return current
        
        # Return as is if we can't evaluate
        return expr
    
    def _validate_contains(self, value: Any, target: str) -> bool:
        """Validate that value contains target."""
        return target in str(value)
    
    def _validate_equals(self, value: Any, target: Any) -> bool:
        """Validate that value equals target."""
        return value == target
    
    def _validate_greater_than(self, value: Any, target: Any) -> bool:
        """Validate that value is greater than target."""
        try:
            return float(value) > float(target)
        except:
            return False
    
    def _validate_less_than(self, value: Any, target: Any) -> bool:
        """Validate that value is less than target."""
        try:
            return float(value) < float(target)
        except:
            return False
    
    def _validate_regex(self, value: str, pattern: str) -> bool:
        """Validate that value matches regex pattern."""
        try:
            return bool(re.match(pattern, str(value)))
        except:
            return False
    
    def _validate_true(self, value: Any, _: Any = None) -> bool:
        """Validate that value is truthy."""
        return bool(value)
    
    def _validate_exists(self, value: Any, _: Any = None) -> bool:
        """Validate that value exists (is not None)."""
        return value is not None
    
    def format_validation_report(self, results: List[Dict]) -> str:
        """Format validation results into a readable report."""
        if not results:
            return "No criteria to validate"
        
        lines = ["=== Success Criteria Validation Report ==="]
        
        passed = sum(1 for r in results if r['passed'])
        total = len(results)
        lines.append(f"Overall: {passed}/{total} criteria passed")
        lines.append("")
        
        for i, result in enumerate(results, 1):
            status = "✓" if result['passed'] else "✗" if result['passed'] is False else "?"
            lines.append(f"{status} Criterion {i}: {result['criterion']}")
            lines.append(f"  Measurable: {result['measurable']}")
            lines.append(f"  Result: {result['reason']}")
            lines.append("")
        
        return "\n".join(lines)