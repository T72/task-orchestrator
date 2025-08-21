#!/usr/bin/env python3
"""
Dependency graph builder for circular dependency detection.
Implements FR-042: Circular Dependency Detection.

@implements FR-042: Detect and prevent circular dependencies
@implements FR-043: Critical path visualization support
"""
from typing import Dict, List, Set, Optional, Tuple
from collections import defaultdict, deque

class DependencyGraph:
    """
    A directed graph for managing task dependencies with cycle detection
    and critical path analysis capabilities.
    """
    
    def __init__(self):
        """Initialize an empty dependency graph."""
        self.nodes: Set[str] = set()
        self.edges: Dict[str, Set[str]] = defaultdict(set)  # node -> set of dependencies
        self.reverse_edges: Dict[str, Set[str]] = defaultdict(set)  # node -> set of dependents
        self.weights: Dict[str, float] = {}  # node -> estimated hours
    
    def add_node(self, node_id: str, weight: float = 1.0) -> None:
        """
        Add a node to the graph.
        
        Args:
            node_id: Unique identifier for the node
            weight: Estimated hours/cost for this node (default 1.0)
        """
        self.nodes.add(node_id)
        self.weights[node_id] = weight
    
    def add_edge(self, from_node: str, to_node: str) -> None:
        """
        Add a directed edge from from_node to to_node.
        This means from_node depends on to_node.
        
        Args:
            from_node: Node that has the dependency
            to_node: Node that from_node depends on
        """
        # Ensure both nodes exist
        if from_node not in self.nodes:
            self.add_node(from_node)
        if to_node not in self.nodes:
            self.add_node(to_node)
        
        # Add the edge
        self.edges[from_node].add(to_node)
        self.reverse_edges[to_node].add(from_node)
    
    def remove_edge(self, from_node: str, to_node: str) -> None:
        """Remove an edge from the graph."""
        if from_node in self.edges:
            self.edges[from_node].discard(to_node)
        if to_node in self.reverse_edges:
            self.reverse_edges[to_node].discard(from_node)
    
    def get_dependencies(self, node_id: str) -> Set[str]:
        """Get all direct dependencies of a node."""
        return self.edges.get(node_id, set())
    
    def get_dependents(self, node_id: str) -> Set[str]:
        """Get all nodes that depend on this node."""
        return self.reverse_edges.get(node_id, set())
    
    def has_node(self, node_id: str) -> bool:
        """Check if a node exists in the graph."""
        return node_id in self.nodes
    
    def topological_sort(self) -> Optional[List[str]]:
        """
        Perform topological sort on the graph.
        
        Returns:
            List of nodes in topological order, or None if cycle exists
        """
        # Create a copy of in-degrees
        in_degree = {node: len(self.edges[node]) for node in self.nodes}
        
        # Find all nodes with no dependencies
        queue = deque([node for node in self.nodes if in_degree[node] == 0])
        result = []
        
        while queue:
            node = queue.popleft()
            result.append(node)
            
            # For each dependent of this node
            for dependent in self.reverse_edges[node]:
                in_degree[dependent] -= 1
                if in_degree[dependent] == 0:
                    queue.append(dependent)
        
        # If we processed all nodes, no cycle exists
        if len(result) == len(self.nodes):
            return result
        else:
            return None  # Cycle detected
    
    def detect_cycle(self) -> Optional[List[str]]:
        """
        Detect if there's a cycle in the graph using DFS.
        
        Returns:
            List representing the cycle path if found, None otherwise
        """
        # Track visit states: 0=unvisited, 1=visiting, 2=visited
        state = {node: 0 for node in self.nodes}
        parent = {}
        cycle_path = []
        
        def dfs(node: str) -> bool:
            """DFS helper to detect cycle."""
            state[node] = 1  # Mark as visiting
            
            for neighbor in self.edges[node]:
                if state[neighbor] == 1:
                    # Found a cycle - build the path
                    cycle_path.clear()
                    current = node
                    cycle_path.append(neighbor)
                    cycle_path.append(current)
                    
                    # Trace back through parents to complete the cycle
                    while current in parent and parent[current] != neighbor:
                        current = parent[current]
                        cycle_path.append(current)
                    
                    cycle_path.reverse()
                    return True
                elif state[neighbor] == 0:
                    parent[neighbor] = node
                    if dfs(neighbor):
                        return True
            
            state[node] = 2  # Mark as visited
            return False
        
        # Check each unvisited node
        for node in self.nodes:
            if state[node] == 0:
                if dfs(node):
                    return cycle_path
        
        return None
    
    def find_self_loops(self) -> List[str]:
        """Find all nodes that depend on themselves."""
        self_loops = []
        for node in self.nodes:
            if node in self.edges[node]:
                self_loops.append(node)
        return self_loops
    
    def validate_new_edge(self, from_node: str, to_node: str) -> Tuple[bool, Optional[str]]:
        """
        Check if adding an edge would create a cycle.
        
        Args:
            from_node: Source node
            to_node: Target node
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check for self-loop
        if from_node == to_node:
            return False, f"Self-dependency detected: {from_node} cannot depend on itself"
        
        # Temporarily add the edge
        self.add_edge(from_node, to_node)
        
        # Check for cycle
        cycle = self.detect_cycle()
        
        # Remove the temporary edge
        self.remove_edge(from_node, to_node)
        
        if cycle:
            cycle_str = " → ".join(cycle)
            return False, f"Circular dependency detected: {cycle_str}"
        
        return True, None
    
    def find_roots(self) -> Set[str]:
        """Find all nodes with no dependencies (root nodes)."""
        return {node for node in self.nodes if len(self.edges[node]) == 0}
    
    def find_leaves(self) -> Set[str]:
        """Find all nodes with no dependents (leaf nodes)."""
        return {node for node in self.nodes if len(self.reverse_edges[node]) == 0}
    
    def get_all_dependencies(self, node_id: str) -> Set[str]:
        """
        Get all dependencies of a node (transitive closure).
        
        Args:
            node_id: Node to get dependencies for
            
        Returns:
            Set of all nodes this node depends on (directly or indirectly)
        """
        result = set()
        stack = list(self.edges.get(node_id, set()))
        
        while stack:
            current = stack.pop()
            if current not in result:
                result.add(current)
                stack.extend(self.edges.get(current, set()))
        
        return result
    
    def get_all_dependents(self, node_id: str) -> Set[str]:
        """
        Get all dependents of a node (reverse transitive closure).
        
        Args:
            node_id: Node to get dependents for
            
        Returns:
            Set of all nodes that depend on this node (directly or indirectly)
        """
        result = set()
        stack = list(self.reverse_edges.get(node_id, set()))
        
        while stack:
            current = stack.pop()
            if current not in result:
                result.add(current)
                stack.extend(self.reverse_edges.get(current, set()))
        
        return result
    
    def find_critical_path(self) -> Tuple[List[str], float]:
        """
        Find the critical path through the dependency graph.
        Uses DAG longest path algorithm with node weights.
        
        @implements FR-043: Critical Path Visualization Support
        
        Returns:
            Tuple of (path nodes, total weight/time)
        """
        # First check if graph has cycles
        if self.detect_cycle():
            return [], 0.0
        
        # Get topological sort
        topo_order = self.topological_sort()
        if not topo_order:
            return [], 0.0
        
        # Initialize distances and predecessors
        distance = {node: 0.0 for node in self.nodes}
        predecessor = {node: None for node in self.nodes}
        
        # Process nodes in topological order
        for node in topo_order:
            node_weight = self.weights.get(node, 1.0)
            
            # For each dependent of this node
            for dependent in self.reverse_edges[node]:
                # Calculate distance through this path
                new_distance = distance[node] + node_weight
                
                # Update if this path is longer
                if new_distance > distance[dependent]:
                    distance[dependent] = new_distance
                    predecessor[dependent] = node
        
        # Find the node with maximum distance (end of critical path)
        max_distance = 0.0
        end_node = None
        for node in self.nodes:
            node_distance = distance[node] + self.weights.get(node, 1.0)
            if node_distance > max_distance:
                max_distance = node_distance
                end_node = node
        
        # Reconstruct the critical path
        if not end_node:
            return [], 0.0
        
        path = []
        current = end_node
        while current is not None:
            path.append(current)
            current = predecessor[current]
        
        path.reverse()
        return path, max_distance
    
    def identify_blocking_tasks(self) -> Dict[str, float]:
        """
        Identify blocking tasks based on their impact on the critical path.
        Tasks with high blocking scores are bottlenecks.
        
        Returns:
            Dictionary of node_id -> blocking_score
        """
        blocking_scores = {}
        
        for node in self.nodes:
            # Calculate blocking score based on:
            # 1. Number of direct dependents
            num_dependents = len(self.reverse_edges[node])
            
            # 2. Total downstream tasks affected
            all_dependents = self.get_all_dependents(node)
            downstream_impact = len(all_dependents)
            
            # 3. Weight/duration of the task
            task_weight = self.weights.get(node, 1.0)
            
            # 4. Whether task is on critical path
            critical_path, _ = self.find_critical_path()
            on_critical_path = 2.0 if node in critical_path else 1.0
            
            # Calculate composite blocking score
            blocking_score = (
                (num_dependents * 2.0) +  # Direct impact
                (downstream_impact * 1.5) +  # Cascading impact
                (task_weight * 1.0) +  # Duration impact
                (on_critical_path * 3.0)  # Critical path multiplier
            )
            
            blocking_scores[node] = blocking_score
        
        return blocking_scores
    
    def to_dot(self) -> str:
        """
        Export graph to DOT format for visualization.
        
        Returns:
            DOT format string
        """
        lines = ["digraph dependencies {"]
        lines.append('  rankdir=TB;')
        lines.append('  node [shape=box];')
        
        # Add nodes with labels
        for node in self.nodes:
            weight = self.weights.get(node, 1.0)
            lines.append(f'  "{node}" [label="{node}\\n({weight}h)"];')
        
        # Add edges
        for from_node, to_nodes in self.edges.items():
            for to_node in to_nodes:
                lines.append(f'  "{from_node}" -> "{to_node}";')
        
        lines.append("}")
        return "\n".join(lines)
    
    def __str__(self) -> str:
        """String representation of the graph."""
        lines = [f"DependencyGraph with {len(self.nodes)} nodes:"]
        for node in sorted(self.nodes):
            deps = self.edges[node]
            if deps:
                deps_str = ", ".join(sorted(deps))
                lines.append(f"  {node} → {deps_str}")
            else:
                lines.append(f"  {node} (no dependencies)")
        return "\n".join(lines)