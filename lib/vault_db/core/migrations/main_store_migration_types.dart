import 'package:drift/drift.dart';

typedef VaultDBMigration =
    Future<void> Function(Migrator migrator, VaultDBMigrationRuntime runtime);

/// Runtime dependencies passed to versioned migrations.
///
/// New migrations can be placed under `migrations/versions/` and only depend on
/// this context instead of `VaultDB` internals.
class VaultDBMigrationRuntime {
  const VaultDBMigrationRuntime({
    required this.customStatement,
    required this.reinstallHistoryTriggers,
    required this.categoriesTable,
    required this.vaultItemsTable,
  });

  final Future<void> Function(String sql) customStatement;
  final Future<void> Function() reinstallHistoryTriggers;

  final TableInfo<Table, dynamic> categoriesTable;
  final TableInfo<Table, dynamic> vaultItemsTable;
}
