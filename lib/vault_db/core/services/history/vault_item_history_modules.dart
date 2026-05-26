import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';

import 'normalizers/vault_history_type_normalizer.dart';
import 'readers/vault_history_type_reader.dart';
import 'restore_handlers/vault_history_restore_handler.dart';
import 'snapshot_handlers/vault_snapshot_type_handler.dart';

class VaultItemHistoryModule {
  final VaultItemType type;
  final VaultHistoryTypeNormalizer? normalizer;
  final VaultHistoryRestoreHandler? restoreHandler;
  final VaultSnapshotTypeHandler? snapshotHandler;
  final VaultHistoryTypeReader? cardReader;

  const VaultItemHistoryModule({
    required this.type,
    this.normalizer,
    this.restoreHandler,
    this.snapshotHandler,
    this.cardReader,
  });
}

class VaultItemHistoryModules {
  VaultItemHistoryModules(List<VaultItemHistoryModule> modules)
    : _modules = {for (final module in modules) module.type: module};

  final Map<VaultItemType, VaultItemHistoryModule> _modules;

  VaultItemHistoryModule? get(VaultItemType type) => _modules[type];

  VaultHistoryTypeNormalizer? normalizer(VaultItemType type) =>
      _modules[type]?.normalizer;

  VaultHistoryRestoreHandler? restoreHandler(VaultItemType type) =>
      _modules[type]?.restoreHandler;

  VaultSnapshotTypeHandler? snapshotHandler(VaultItemType type) =>
      _modules[type]?.snapshotHandler;

  VaultHistoryTypeReader? cardReader(VaultItemType type) =>
      _modules[type]?.cardReader;

  bool supportsSnapshot(VaultItemType type) =>
      _modules.containsKey(type) && _modules[type]?.snapshotHandler != null;

  bool supportsReader(VaultItemType type) =>
      _modules.containsKey(type) && _modules[type]?.cardReader != null;
}
