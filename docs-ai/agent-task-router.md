# Agent Task Router

Use this file to quickly choose which docs to read for a specific task. Read
only the rows relevant to your current change.

## Priority

1. Task-specific docs from this file
2. Existing code patterns in the same module
3. MCP tools for execution workflow:
   - Dart/Flutter MCP for formatting and Flutter/Dart operations
   - Serena MCP for semantic symbol/code search and safe refactors
   - `rust-mcp-server` for Rust semantic workflows and Rust-aware operations
4. `context7` only if project docs are not enough or API behavior is
   version-sensitive

## Routing Matrix

| Task type                                         | Read first                               | Then read if needed                                                 |
| ------------------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------- |
| UI layout, responsive screens, widget composition | `flutter-rules.md`, `widget-patterns.md` | `shared-ui-components.md`                                           |
| Shared UI components usage                        | `shared-ui-components.md`                | `wolt-modal-sheet.md`                                               |
| Modal flows, multi-step sheets                    | `wolt-modal-sheet.md`                    | `widget-patterns.md`                                                |
| Navigation and route behavior                     | `gorouter-navigation.md`                 | `SidebarRouting.md`                                                 |
| Riverpod state modeling and providers             | `state-management.md`                    | `error-handling.md`                                                 |
| Error mapping and user-facing failures            | `error-handling.md`                      | `state-management.md`                                               |
| Localization and new translation keys             | `localization.md`                        | `flutter-rules.md`                                                  |
| Add new vault entity/table/DAO/form/card          | `add-new-vault-entity-guide.md`          | `db-migrations.md`                                                  |
| Schema/migration changes                          | `db-migrations.md`                       | `add-new-vault-entity-guide.md`                                     |
| Cryptography and secure file API                  | `crypt-api-usage.md`                     | `error-handling.md`                                                 |
| Multi-window behaviors, app/window lifecycle      | `multi-window-architecture.md`           | `gorouter-navigation.md`                                            |
| Rust bridge integration                           | `rust-integration.md`                    | `rust-mcp-server`, `crypt-api-usage.md`                             |
| Cloud sync implementation                         | `cloud-sync-module.md`                   | `cloud-sync-auth.md`, `cloud-sync-http.md`, `cloud-sync-storage.md` |
| Dart/Flutter formatting                           | Dart/Flutter MCP tools                   | avoid shell formatting commands when MCP tool exists                |
| Semantic search / symbol navigation               | Serena MCP tools                         | fallback to text search only when semantic tool is unavailable      |
| Rust semantic search / navigation                 | rust-mcp-server                          | fallback to text search only when semantic tool is unavailable      |

## Hard Stops

- Do not invent missing APIs.
- Do not bypass secure storage, encryption, or auth checks.
- Do not add ad-hoc UI patterns when a shared component exists.
- Do not skip `CHANGELOG.md` updates after edits.
- Do not default to shell formatting/search commands when dedicated MCP tools
  are available.
- Do not default to generic shell Rust workflows when `rust-mcp-server` provides
  equivalent semantic tooling.
