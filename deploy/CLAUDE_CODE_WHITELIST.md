# Task Orchestrator - Claude Code Whitelist

This document defines recommended Claude Code command whitelist settings for Task Orchestrator.

## Required Baseline

For most development environments, allow all `tm` commands:

```json
{
  "whitelisted_commands": [
    "./tm *"
  ]
}
```

This is the minimum setup to avoid repeated confirmation prompts during normal Task Orchestrator usage.

## Security-Focused Option

If you need tighter control, whitelist only core commands:

```json
{
  "whitelisted_commands": [
    "./tm init",
    "./tm add *",
    "./tm list*",
    "./tm show *",
    "./tm update *",
    "./tm complete *",
    "./tm assign *",
    "./tm export*",
    "./tm join *",
    "./tm share *",
    "./tm note *",
    "./tm discover *",
    "./tm sync *",
    "./tm context *",
    "./tm progress *",
    "./tm feedback *",
    "./tm watch",
    "./tm validate-orchestration*",
    "./tm fix-orchestration*"
  ]
}
```

## Where to Configure

- Project configuration file used by your Claude Code setup.
- Claude Code security/settings UI where `whitelisted_commands` can be managed.

## Verification

After configuring, run:

```bash
./tm --help
./tm init
./tm list
```

If you still see repeated confirmation prompts for `tm` commands, your whitelist pattern is too restrictive for your workflow.
