import 'package:drift/drift.dart';

typedef MainStoreMigration =
    Future<void> Function(Migrator migrator, MainStoreMigrationRuntime runtime);

/// Runtime dependencies passed to versioned migrations.
///
/// New migrations can be placed under `migrations/versions/` and only depend on
/// this context instead of `MainStore` internals.
class MainStoreMigrationRuntime {
  const MainStoreMigrationRuntime({
    required this.customStatement,
    required this.reinstallHistoryTriggers,
    required this.categoriesTable,
    required this.vaultItemsTable,
    required this.vaultItemHistoryTable,
  });

  final Future<void> Function(String sql) customStatement;
  final Future<void> Function() reinstallHistoryTriggers;

  final TableInfo<Table, dynamic> categoriesTable;
  final TableInfo<Table, dynamic> vaultItemsTable;
  final TableInfo<Table, dynamic> vaultItemHistoryTable;
}
