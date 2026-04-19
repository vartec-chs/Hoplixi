# Hoplixi Agent Handbook (Lean)

This document is the minimal entry point for coding agents. Goal: quickly apply
core project rules and route to the exact docs without loading redundant
context.

## 1) Read Order (Mandatory)

1. This file (`AGENTS.md`)
2. `docs-ai/agent-task-router.md`
3. Task-specific docs from the router
4. If docs are insufficient: MCP (`context7` for Dart/Flutter version-specific
   details)

## 2) Non-Negotiable Rules

- Follow project docs first. Do not invent architecture, APIs, or behavior.
- Security first:
  - never log or store sensitive data in plain text
  - never bypass encryption/auth/secure storage flows
- Keep code explicit and maintainable; avoid clever implicit behavior.
- Use existing shared UI components and established UX patterns.
- Respect performance:
  - avoid heavy synchronous work on UI thread
  - minimize unnecessary rebuilds
  - prefer lazy loading/pagination where applicable
- Use project logging (`logInfo/logWarning/logError/...`), not `print()`.
- Use Riverpod 3+ patterns; do not use deprecated providers.
- Do not use `@riverpod` code generation in this project.
- For DB domain flows, keep `AsyncResult<T, DatabaseError>` patterns.
- Prefer Dart/Flutter MCP tools over shell commands for Flutter/Dart workflows
  (for example: use MCP formatter tools instead of `flutter format`).
- Prefer Serena MCP tools for semantic symbol/code navigation and refactoring
  instead of plain text search when semantic accuracy matters.
- Prefer `rust-mcp-server` tools for Rust workflows (semantic navigation,
  refactoring, and Rust-aware operations) instead of generic shell-based
  commands when MCP support is available.
- Changelog is mandatory after any agent edits:
  - update root `CHANGELOG.md`
  - group entries by module/feature (`password_manager`, `cloud_sync`, `docs`,
    ...)

## 3) Quick Routing

Use `docs-ai/agent-task-router.md` as the primary map from task type to docs.

Fast examples:

- UI/layout/components -> `flutter-rules.md`, `widget-patterns.md`,
  `shared-ui-components.md`
- Wolt modal flows -> `wolt-modal-sheet.md`
- Routing/go_router -> `gorouter-navigation.md`, `SidebarRouting.md`
- State management -> `state-management.md`
- Error handling -> `error-handling.md`
- Localization -> `localization.md`
- DB entities and schema -> `add-new-vault-entity-guide.md`, `db-migrations.md`
- Crypto API usage -> `crypt-api-usage.md`
- Multi-window/logging -> `multi-window-architecture.md`
- Rust bridge -> `rust-integration.md`, `rust-mcp-server`

## 4) Architecture Snapshot

See `docs-ai/agent-architecture-map.md` for compact module and folder map.

## 5) Source Priority

1. This handbook and `docs-ai/*`
2. Existing project code patterns
3. MCP tools for implementation workflows:
   - Dart/Flutter MCP for formatting, project/app tooling, and framework-aware
     operations
   - Serena MCP for semantic search/navigation/refactoring
   - `rust-mcp-server` for Rust semantic workflows and Rust-aware operations
   - `context7` for version-sensitive framework behavior
4. General Flutter/Dart knowledge

Never override project rules with generic recommendations.

## 6) Platforms and Stack

- Platforms: Android, iOS, macOS, Linux, Windows
- Core stack: Flutter, Dart, Rust, Riverpod, Freezed, Drift (SQLite3 Multiple
  Ciphers), GoRouter

## 7) Done Criteria for Agent Tasks

- Implementation follows task-specific docs and project rules.
- No sensitive data exposure introduced.
- Errors are handled explicitly (UI and domain layers).
- Changes are reflected in `CHANGELOG.md`.
