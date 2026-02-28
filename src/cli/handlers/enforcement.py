from __future__ import annotations

from typing import Optional


ENFORCEMENT_COMMANDS = {"validate-orchestration", "fix-orchestration", "config"}


def handle_enforcement(command: str, argv: list[str], enforcement_engine: object) -> Optional[int]:
    if command == "validate-orchestration":
        if enforcement_engine:
            result = enforcement_engine.validator.validate_context()
            if result.is_valid:
                print("✅ Orchestration context is valid")
                return 0
            print(result.guidance)
            return 1
        print("❌ Enforcement system not available")
        return 1

    if command == "fix-orchestration":
        if enforcement_engine:
            interactive = "--interactive" in argv
            if interactive:
                success = enforcement_engine.fix_orchestration_interactive()
                return 0 if success else 1
            print("Use --interactive flag: tm fix-orchestration --interactive")
            return 1
        print("❌ Enforcement system not available")
        return 1

    if command == "config" and ("--enforce-orchestration" in argv or "--enforce-usage" in argv):
        if not enforcement_engine:
            print("❌ Enforcement system not available")
            return 1

        flag = "--enforce-orchestration" if "--enforce-orchestration" in argv else "--enforce-usage"
        idx = argv.index(flag)
        if idx + 1 >= len(argv):
            print(f"Usage: tm config {flag} true|false")
            return 1

        value = argv[idx + 1].lower()
        if value not in ["true", "false"]:
            print(f"Use {flag} true|false")
            return 1

        from enforcement import EnforcementLevel

        level = EnforcementLevel.STANDARD if value == "true" else EnforcementLevel.ADVISORY
        if enforcement_engine.config.set_enforcement_level(level):
            print(f"✅ Enforcement {'enabled' if value == 'true' else 'disabled'}")
            return 0
        print("❌ Failed to update enforcement setting")
        return 1

    if command == "config" and "--show-enforcement" in argv:
        if enforcement_engine:
            print(enforcement_engine.show_enforcement_status())
            return 0
        print("❌ Enforcement system not available")
        return 1

    if command == "config" and "--enforcement-level" in argv:
        if not enforcement_engine:
            print("❌ Enforcement system not available")
            return 1

        idx = argv.index("--enforcement-level")
        if idx + 1 >= len(argv):
            print("Usage: tm config --enforcement-level [strict|standard|advisory]")
            return 1

        level_str = argv[idx + 1]
        if level_str not in ["strict", "standard", "advisory"]:
            print("Invalid level - use: strict, standard, or advisory")
            return 1

        from enforcement import EnforcementLevel

        level = EnforcementLevel(level_str)
        if enforcement_engine.config.set_enforcement_level(level):
            print(f"✅ Enforcement level set to: {level_str}")
            return 0
        print("❌ Failed to set enforcement level")
        return 1

    return None
