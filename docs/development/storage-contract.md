# Storage Contract

Task Orchestrator resolves runtime storage paths through `src/storage_paths.py`.

## Precedence Rules
1. `TM_DB_PATH` environment variable (highest priority)
   - If value ends with `.db`, it is treated as an explicit DB file path.
   - Otherwise, it is treated as the storage root directory and the DB is `<TM_DB_PATH>/tasks.db`.
2. Default project-local storage root (fallback)
   - `<current-working-directory>/.task-orchestrator`

## Derived Paths
- Database: `resolve_db_path()`
- Storage root: `resolve_storage_root()`
- Config: `resolve_config_path()` (stored as `<storage-root>/config.yaml`)

## Command Handler Contract
- `tm` runtime commands and wrappers (`init`, task commands, `migrate`, `config`) must use shared resolver functions.
- Command handlers must not hardcode `~/.task-orchestrator`.

## Verification
- Run `bash tests/test_storage_contract.sh` to verify:
  - runtime writes (`tm add`) use the resolved database
  - `tm migrate` and `tm config` resolve to the same storage contract
  - no home-directory fallback path is touched when `TM_DB_PATH` is set
