# Commander's Intent Implementation Guide for Meta-Agents

## The Challenge
How do we ensure every meta-agent automatically uses Commander's Intent when orchestrating sub-agents?

## The Solution: Three-Layer Implementation Strategy

### Layer 1: Structural Enforcement (Built into Task Orchestrator)

#### A. Enhanced Task Creation API
Modify `tm add` to explicitly support Commander's Intent:

```bash
# Current (basic)
./tm add "Implement authentication" --assignee backend_agent

# Enhanced (with Commander's Intent structure)
./tm add "Implement authentication" \
  --assignee backend_agent \
  --purpose "Secure foundation for all user-specific features" \
  --key-tasks "OAuth2 flow|JWT tokens|Session management" \
  --end-state "Users can register, login, and maintain secure sessions"
```

#### B. Template-Based Task Creation
Provide pre-structured templates that enforce Commander's Intent:

```bash
# Use authentication template
./tm create-from-template auth \
  --assignee backend_agent \
  --vars "provider=oauth2,database=postgres"

# Template automatically includes:
# - Purpose: Why authentication matters for this project
# - Key Tasks: Standard auth requirements
# - End State: Expected security outcomes
```

#### C. Validation Hooks
Add pre-commit hooks that check for Commander's Intent:

```python
def validate_task_creation(task_data):
    """Ensure Commander's Intent is present"""
    if not has_commander_intent(task_data.context):
        return {
            "status": "warning",
            "message": "Task lacks Commander's Intent. Add PURPOSE, KEY TASKS, and END STATE.",
            "suggestion": generate_intent_template(task_data.title)
        }
```

### Layer 2: Meta-Agent System Prompts (Behavioral Guidance)

#### A. ORCHESTRATOR.md Enhancement
Add this section to ORCHESTRATOR.md that all agents discover:

```markdown
## 📋 MANDATORY: Commander's Intent Protocol

**EVERY task delegation MUST include:**

1. **PURPOSE**: Why does this task matter to the project?
2. **KEY TASKS**: What are the 3-5 non-negotiable deliverables?
3. **END STATE**: What does success look like?

**Format for ALL task creation:**
```bash
TASK=$(./tm add "[Task Title]" \
  --assignee [agent] \
  --context "PURPOSE: [Why this matters]
             KEY TASKS: [3-5 essential deliverables]
             END STATE: [Definition of success]")
```

**Tasks without Commander's Intent will be flagged for review.**
```

#### B. Meta-Agent Instruction Set
Create a standard instruction that's prepended to all meta-agent prompts:

```markdown
# Meta-Agent Orchestration Protocol

You are a meta-agent using Task Orchestrator. ALWAYS follow these rules:

## Task Creation Requirements
Every task you create MUST include Commander's Intent in this format:

```
PURPOSE: [One sentence explaining why this task matters to the overall goal]
KEY TASKS: [3-5 bullet points of non-negotiable deliverables]
END STATE: [Clear description of what success looks like]
```

## Example:
```bash
./tm add "Implement payment processing" \
  --assignee backend_agent \
  --context "PURPOSE: Enable revenue generation through user purchases.
             KEY TASKS: 
             • Stripe integration for card payments
             • Invoice generation system
             • Payment webhook handlers
             • Refund processing logic
             END STATE: Users can purchase products with credit cards, receive invoices, and request refunds through a PCI-compliant system."
```

## Validation:
- Tasks without PURPOSE will be rejected
- Tasks without KEY TASKS lack clarity
- Tasks without END STATE cause misalignment
```

### Layer 3: Intelligent Assistance (Proactive Support)

#### A. Intent Generation Assistant
Create a helper that generates Commander's Intent from task titles:

```python
# commander_intent_generator.py
class CommanderIntentGenerator:
    def generate_intent(self, task_title: str, project_context: dict) -> dict:
        """
        Analyzes task title and project context to suggest Commander's Intent
        """
        return {
            "purpose": self._infer_purpose(task_title, project_context),
            "key_tasks": self._identify_key_tasks(task_title),
            "end_state": self._define_success_criteria(task_title)
        }
    
    def enhance_task_command(self, basic_command: str) -> str:
        """
        Takes a basic tm add command and enhances it with Commander's Intent
        """
        # Parse the basic command
        task_title = extract_title(basic_command)
        
        # Generate intent
        intent = self.generate_intent(task_title, get_project_context())
        
        # Return enhanced command
        return f'{basic_command} --context "{format_intent(intent)}"'
```

#### B. Interactive Mode for Meta-Agents
Add an interactive mode that guides intent creation:

```bash
$ ./tm add-interactive

Task Orchestrator - Commander's Intent Builder
=============================================

Task Title: Implement user authentication

PURPOSE (Why does this matter?):
> Secure foundation for all user-specific features and data protection

KEY TASKS (3-5 essential deliverables):
1> Secure registration with email verification
2> Login with password and 2FA support
3> Session management with JWT tokens
4> Password reset flow
5> Account lockout after failed attempts

END STATE (What does success look like?):
> Users can securely create accounts, login with 2FA, maintain sessions across devices, and recover access through password reset

Assignee: backend_agent

✓ Task created with Commander's Intent:
  ID: abc12345
  Title: Implement user authentication
  Assignee: backend_agent
  Intent: Fully specified
```

#### C. Feedback Loop Integration
Track and learn from successful patterns:

```python
class IntentPatternLearning:
    def analyze_successful_tasks(self):
        """
        Identifies patterns in high-performing tasks
        """
        successful_tasks = self.get_tasks_with_high_completion_rate()
        
        patterns = {
            "purpose_patterns": extract_purpose_patterns(successful_tasks),
            "key_task_patterns": extract_key_task_patterns(successful_tasks),
            "end_state_patterns": extract_end_state_patterns(successful_tasks)
        }
        
        return self.generate_recommendations(patterns)
    
    def suggest_improvements(self, current_intent):
        """
        Suggests improvements based on successful patterns
        """
        patterns = self.analyze_successful_tasks()
        return enhance_intent_with_patterns(current_intent, patterns)
```

## Implementation Roadmap

### Phase 1: Soft Enforcement (Week 1)
1. Update ORCHESTRATOR.md template with Commander's Intent examples
2. Add Commander's Intent section to documentation
3. Create example templates for common task types

### Phase 2: Structural Support (Week 2)
1. Add `--purpose`, `--key-tasks`, `--end-state` flags to `tm add`
2. Create intent validation function (warning only)
3. Build interactive mode for task creation

### Phase 3: Intelligent Assistance (Week 3)
1. Implement intent generator from task titles
2. Create pattern learning system
3. Add intent quality scoring

### Phase 4: Full Integration (Week 4)
1. Make Commander's Intent required (with override flag)
2. Add intent tracking to metrics
3. Generate intent quality reports

## Metrics for Success

### Adoption Metrics
- **Intent Presence Rate**: % of tasks with Commander's Intent
- **Intent Quality Score**: Average completeness of PURPOSE, KEY TASKS, END STATE
- **Template Usage**: % of tasks created from templates

### Outcome Metrics
- **Task Completion Rate**: Should increase to 95%+
- **First-Time Success Rate**: Should increase to 90%+
- **Rework Rate**: Should decrease to <5%
- **Time to Completion**: Should decrease by 30%+

## Example Implementation

### 1. Enhanced Task Creation
```python
# In tm_production.py
def add(self, title: str, ..., purpose: str = None, 
        key_tasks: List[str] = None, end_state: str = None):
    """Enhanced add method with Commander's Intent"""
    
    # Build context from Commander's Intent
    if purpose or key_tasks or end_state:
        context_parts = []
        if purpose:
            context_parts.append(f"PURPOSE: {purpose}")
        if key_tasks:
            context_parts.append(f"KEY TASKS: {' | '.join(key_tasks)}")
        if end_state:
            context_parts.append(f"END STATE: {end_state}")
        
        # Combine with existing context
        context = "\n".join(context_parts)
        if existing_context:
            context = f"{context}\n\nADDITIONAL CONTEXT: {existing_context}"
    
    # Validate Commander's Intent
    if self.config.require_commander_intent:
        validation = self.validate_commander_intent(context)
        if not validation.is_valid:
            print(f"⚠️ Task lacks Commander's Intent: {validation.missing}")
            if not force:
                return None
```

### 2. Template System
```yaml
# templates/auth.yaml
name: authentication
purpose: "Secure foundation for user identity and access control"
key_tasks:
  - "User registration with validation"
  - "Secure login with optional 2FA"
  - "Session management"
  - "Password reset capability"
  - "Account security features"
end_state: "Users can securely create accounts, authenticate, maintain sessions, and recover access"
variables:
  - name: auth_type
    options: ["oauth2", "jwt", "session"]
  - name: database
    options: ["postgres", "mysql", "mongodb"]
```

### 3. Meta-Agent System Prompt Addition
```python
# In meta_agent_prompt.py
COMMANDER_INTENT_REQUIREMENT = """
CRITICAL REQUIREMENT: Every task you create MUST include Commander's Intent.

Structure EVERY task delegation as:
```
./tm add "[TASK]" --assignee [AGENT] --context "PURPOSE: [why] KEY TASKS: [what] END STATE: [success]"
```

Tasks without complete Commander's Intent will impair sub-agent performance.
"""

def enhance_meta_agent_prompt(base_prompt: str) -> str:
    return f"{COMMANDER_INTENT_REQUIREMENT}\n\n{base_prompt}"
```

## Quick Start for Meta-Agents

To immediately start using Commander's Intent:

```bash
# 1. Set enforcement mode
export TM_REQUIRE_INTENT=true

# 2. Use the enhanced command format
./tm add "Build user dashboard" \
  --assignee frontend_agent \
  --purpose "Central hub for user interactions and data visualization" \
  --key-tasks "Profile view|Activity feed|Settings panel|Data charts" \
  --end-state "Users can view and manage all their data from a single, responsive dashboard"

# 3. Or use interactive mode
./tm add-interactive

# 4. Or use templates
./tm create-from-template dashboard --assignee frontend_agent
```

## Conclusion

By implementing this three-layer approach:
1. **Structural** (built into the tool)
2. **Behavioral** (guided through prompts)
3. **Intelligent** (assisted with AI)

We ensure that Commander's Intent becomes the natural, default way that meta-agents delegate tasks, leading to the superior KPIs that Task Orchestrator promises.

The key is making it EASIER to use Commander's Intent than not to use it.