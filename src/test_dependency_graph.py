#!/usr/bin/env python3
"""
Unit tests for dependency graph module.
Tests graph construction, cycle detection, and topological sorting.

@implements FR-042: Circular dependency detection testing
@implements FR-043: Critical path visualization testing  
@implements FR-003: Dependency graph validation testing
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dependency_graph import DependencyGraph

class TestDependencyGraph:
    """Test suite for DependencyGraph class."""
    
    def test_add_node(self):
        """Test adding nodes to the graph."""
        graph = DependencyGraph()
        graph.add_node("task1", weight=2.0)
        graph.add_node("task2", weight=3.0)
        
        assert graph.has_node("task1")
        assert graph.has_node("task2")
        assert not graph.has_node("task3")
        assert graph.weights["task1"] == 2.0
        assert graph.weights["task2"] == 3.0
    
    def test_add_edge(self):
        """Test adding edges between nodes."""
        graph = DependencyGraph()
        graph.add_edge("task1", "task2")  # task1 depends on task2
        
        assert "task2" in graph.get_dependencies("task1")
        assert "task1" in graph.get_dependents("task2")
        assert len(graph.get_dependencies("task2")) == 0
    
    def test_auto_node_creation(self):
        """Test that adding edges automatically creates nodes."""
        graph = DependencyGraph()
        graph.add_edge("task1", "task2")
        
        assert graph.has_node("task1")
        assert graph.has_node("task2")
    
    def test_remove_edge(self):
        """Test removing edges."""
        graph = DependencyGraph()
        graph.add_edge("task1", "task2")
        graph.remove_edge("task1", "task2")
        
        assert "task2" not in graph.get_dependencies("task1")
        assert "task1" not in graph.get_dependents("task2")
    
    def test_topological_sort_no_cycle(self):
        """Test topological sort on a DAG."""
        graph = DependencyGraph()
        # Create a simple DAG: task3 -> task2 -> task1
        graph.add_edge("task3", "task2")
        graph.add_edge("task2", "task1")
        
        sorted_nodes = graph.topological_sort()
        assert sorted_nodes is not None
        assert sorted_nodes.index("task1") < sorted_nodes.index("task2")
        assert sorted_nodes.index("task2") < sorted_nodes.index("task3")
    
    def test_topological_sort_with_cycle(self):
        """Test topological sort returns None when cycle exists."""
        graph = DependencyGraph()
        # Create a cycle: A -> B -> C -> A
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        graph.add_edge("C", "A")
        
        sorted_nodes = graph.topological_sort()
        assert sorted_nodes is None
    
    def test_detect_cycle_simple(self):
        """Test cycle detection with a simple cycle."""
        graph = DependencyGraph()
        # Create a cycle: A -> B -> C -> A
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        graph.add_edge("C", "A")
        
        cycle = graph.detect_cycle()
        assert cycle is not None
        assert len(cycle) >= 3
        # Verify it's actually a cycle
        assert "A" in cycle
        assert "B" in cycle
        assert "C" in cycle
    
    def test_detect_cycle_none(self):
        """Test cycle detection returns None for DAG."""
        graph = DependencyGraph()
        # Create a DAG
        graph.add_edge("A", "B")
        graph.add_edge("A", "C")
        graph.add_edge("B", "D")
        graph.add_edge("C", "D")
        
        cycle = graph.detect_cycle()
        assert cycle is None
    
    def test_self_loop_detection(self):
        """Test detection of self-loops."""
        graph = DependencyGraph()
        graph.add_edge("task1", "task1")  # Self-loop
        graph.add_edge("task2", "task3")
        
        self_loops = graph.find_self_loops()
        assert "task1" in self_loops
        assert "task2" not in self_loops
    
    def test_validate_new_edge_no_cycle(self):
        """Test edge validation when no cycle would be created."""
        graph = DependencyGraph()
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        
        valid, error = graph.validate_new_edge("C", "D")
        assert valid
        assert error is None
    
    def test_validate_new_edge_creates_cycle(self):
        """Test edge validation when cycle would be created."""
        graph = DependencyGraph()
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        
        valid, error = graph.validate_new_edge("C", "A")
        assert not valid
        assert "Circular dependency detected" in error
        assert "A" in error
        assert "B" in error
        assert "C" in error
    
    def test_validate_self_dependency(self):
        """Test validation of self-dependencies."""
        graph = DependencyGraph()
        
        valid, error = graph.validate_new_edge("task1", "task1")
        assert not valid
        assert "Self-dependency detected" in error
    
    def test_find_roots(self):
        """Test finding root nodes (no dependencies)."""
        graph = DependencyGraph()
        graph.add_edge("A", "B")
        graph.add_edge("A", "C")
        graph.add_edge("D", "C")
        graph.add_node("E")
        
        roots = graph.find_roots()
        assert "B" in roots
        assert "C" in roots
        assert "E" in roots
        assert "A" not in roots
        assert "D" not in roots
    
    def test_find_leaves(self):
        """Test finding leaf nodes (no dependents)."""
        graph = DependencyGraph()
        graph.add_edge("A", "B")
        graph.add_edge("A", "C")
        graph.add_edge("D", "C")
        graph.add_node("E")
        
        leaves = graph.find_leaves()
        assert "A" in leaves
        assert "D" in leaves
        assert "E" in leaves
        assert "B" not in leaves
        assert "C" not in leaves
    
    def test_transitive_dependencies(self):
        """Test getting all transitive dependencies."""
        graph = DependencyGraph()
        # A -> B -> C -> D
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        graph.add_edge("C", "D")
        
        all_deps = graph.get_all_dependencies("A")
        assert "B" in all_deps
        assert "C" in all_deps
        assert "D" in all_deps
        assert "A" not in all_deps
    
    def test_transitive_dependents(self):
        """Test getting all transitive dependents."""
        graph = DependencyGraph()
        # A -> B -> C -> D
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        graph.add_edge("C", "D")
        
        all_deps = graph.get_all_dependents("D")
        assert "C" in all_deps
        assert "B" in all_deps
        assert "A" in all_deps
        assert "D" not in all_deps
    
    def test_complex_graph(self):
        """Test with a more complex graph structure."""
        graph = DependencyGraph()
        
        # Create a complex DAG
        graph.add_edge("frontend", "api")
        graph.add_edge("frontend", "auth")
        graph.add_edge("api", "database")
        graph.add_edge("api", "auth")
        graph.add_edge("auth", "database")
        graph.add_edge("tests", "frontend")
        graph.add_edge("tests", "api")
        
        # Should be able to sort topologically
        sorted_nodes = graph.topological_sort()
        assert sorted_nodes is not None
        
        # Database should come before everything that depends on it
        db_index = sorted_nodes.index("database")
        auth_index = sorted_nodes.index("auth")
        api_index = sorted_nodes.index("api")
        frontend_index = sorted_nodes.index("frontend")
        
        assert db_index < auth_index
        assert db_index < api_index
        assert auth_index < api_index
        assert auth_index < frontend_index
        assert api_index < frontend_index
    
    def test_critical_path_simple(self):
        """Test critical path identification in a simple graph."""
        graph = DependencyGraph()
        # A -> B -> C (linear path)
        graph.add_node("A", weight=2.0)
        graph.add_node("B", weight=3.0)
        graph.add_node("C", weight=1.0)
        graph.add_edge("C", "B")
        graph.add_edge("B", "A")
        
        path, total_weight = graph.find_critical_path()
        assert path == ["A", "B", "C"]
        assert total_weight == 6.0  # 2 + 3 + 1
    
    def test_critical_path_complex(self):
        """Test critical path in a complex graph with multiple paths."""
        graph = DependencyGraph()
        # Two paths: A->B->D (2+3+4=9) and A->C->D (2+5+4=11)
        graph.add_node("A", weight=2.0)
        graph.add_node("B", weight=3.0)
        graph.add_node("C", weight=5.0)
        graph.add_node("D", weight=4.0)
        
        graph.add_edge("B", "A")
        graph.add_edge("C", "A")
        graph.add_edge("D", "B")
        graph.add_edge("D", "C")
        
        path, total_weight = graph.find_critical_path()
        assert "A" in path
        assert "C" in path  # C path is longer
        assert "D" in path
        assert total_weight == 11.0
    
    def test_blocking_tasks(self):
        """Test identification of blocking tasks."""
        graph = DependencyGraph()
        # A is a bottleneck - blocks both B and C
        graph.add_node("A", weight=5.0)
        graph.add_node("B", weight=2.0)
        graph.add_node("C", weight=2.0)
        graph.add_node("D", weight=1.0)
        
        graph.add_edge("B", "A")
        graph.add_edge("C", "A")
        graph.add_edge("D", "B")
        graph.add_edge("D", "C")
        
        blocking_scores = graph.identify_blocking_tasks()
        
        # A should have highest blocking score (blocks B, C, and indirectly D)
        assert blocking_scores["A"] > blocking_scores["B"]
        assert blocking_scores["A"] > blocking_scores["C"]
        assert blocking_scores["A"] > blocking_scores["D"]
    
    def test_to_dot(self):
        """Test DOT format export."""
        graph = DependencyGraph()
        graph.add_node("A", weight=2.0)
        graph.add_node("B", weight=1.5)
        graph.add_edge("A", "B")
        
        dot = graph.to_dot()
        assert "digraph dependencies" in dot
        assert '"A" [label="A\\n(2.0h)"]' in dot
        assert '"B" [label="B\\n(1.5h)"]' in dot
        assert '"A" -> "B"' in dot

if __name__ == "__main__":
    import unittest
    
    # Convert to unittest format
    suite = unittest.TestSuite()
    test_instance = TestDependencyGraph()
    
    for method_name in dir(test_instance):
        if method_name.startswith('test_'):
            suite.addTest(unittest.FunctionTestCase(
                getattr(test_instance, method_name),
                description=method_name
            ))
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)