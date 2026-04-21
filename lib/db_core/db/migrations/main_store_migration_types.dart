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
    required this.categoriesIconSource,
    required this.categoriesIconValue,
    required this.vaultItemsTable,
    required this.vaultItemsIconSource,
    required this.vaultItemsIconValue,
    required this.vaultItemHistoryTable,
    required this.vaultItemHistoryIconSource,
    required this.vaultItemHistoryIconValue,
  });

  final Future<void> Function(String sql) customStatement;
  final Future<void> Function() reinstallHistoryTriggers;

  final TableInfo<Table, dynamic> categoriesTable;
  final GeneratedColumn<Object> categoriesIconSource;
  final GeneratedColumn<Object> categoriesIconValue;

  final TableInfo<Table, dynamic> vaultItemsTable;
  final GeneratedColumn<Object> vaultItemsIconSource;
  final GeneratedColumn<Object> vaultItemsIconValue;

  final TableInfo<Table, dynamic> vaultItemHistoryTable;
  final GeneratedColumn<Object> vaultItemHistoryIconSource;
  final GeneratedColumn<Object> vaultItemHistoryIconValue;
}
