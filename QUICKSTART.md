# Task Orchestrator: 2-Minute Quick Start

**Goal**: From zero to productive task orchestration in 2 minutes.

## ⚡ Setup (30 seconds)

```bash
git clone https://github.com/T72/task-orchestrator.git && cd task-orchestrator && chmod +x tm && ./tm init
```

## 🚀 First Tasks (60 seconds)

```bash
# Add your first task
./tm add "Set up development environment" --priority high

# Create a dependency chain
SETUP_ID=$(./tm add "Install dependencies" | grep -o '[a-f0-9]\{8\}')
TEST_ID=$(./tm add "Run tests" --depends-on $SETUP_ID | grep -o '[a-f0-9]\{8\}')

# View your workflow
./tm list
```

## 🔄 Work & Track (30 seconds)

```bash
# Start working
./tm update $SETUP_ID --status in_progress

# Complete task (automatically unblocks dependent tasks)
./tm complete $SETUP_ID

# See the magic - tests are now unblocked
./tm list
```

## 🎯 You're Done!

**You now have:**
- ✅ Task orchestration with dependencies
- ✅ Automatic workflow management  
- ✅ Status tracking and progress visibility

## 💡 Common Patterns (Choose what you need)

### Code Work
```bash
./tm add "Fix auth bug" --file src/auth.py:42 --priority critical
```

### Team Coordination
```bash
./tm add "Review PR #123" --assignee alice
./tm watch  # Check notifications
```

### Project Planning
```bash
EPIC=$(./tm add "User Dashboard Feature")
./tm add "Design API" --depends-on $EPIC
./tm add "Build UI" --depends-on $EPIC
```

## 📚 Next Steps

- **More examples**: [docs/examples/](docs/examples/)
- **Full guide**: [docs/user-guide.md](docs/user-guide.md)  
- **Claude Code**: [docs/quickstart-claude-code.md](docs/quickstart-claude-code.md)
- **All commands**: [docs/reference/api-reference.md](docs/reference/api-reference.md)

---

**🎉 Success!** Start using `./tm` to orchestrate your workflows efficiently.
