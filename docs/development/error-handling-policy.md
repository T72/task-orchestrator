# Error Handling Policy

## Runtime Policy by Layer
- Domain/validation errors:
  - Return user-actionable messages.
  - Exit with non-zero status for invalid command usage or invalid inputs.
- Infrastructure/runtime errors:
  - Surface explicit warning/error output (no silent swallow).
  - Preserve deterministic exit semantics in command handlers.
- Optional/non-critical integrations:
  - Allowed to continue execution when unavailable.
  - Must emit explicit warning/debug signal instead of `except: pass`.

## Command Semantics
- Wrapper command groups (`add`, `share`, `discover`, `config`, etc.) should:
  - Print explicit failure reason.
  - Exit `1` on failure.
- Success paths should exit `0`.

## Verification
- `bash tests/test_error_exit_codes.sh`
- `bash tests/test_storage_contract.sh`
- `bash tests/test_collaboration_event_store.sh`
