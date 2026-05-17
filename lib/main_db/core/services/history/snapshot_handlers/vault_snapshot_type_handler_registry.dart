import '../../../tables/vault_items/vault_items.dart';
import 'vault_snapshot_type_handler.dart';

class VaultSnapshotTypeHandlerRegistry {
  VaultSnapshotTypeHandlerRegistry(List<VaultSnapshotTypeHandler> handlers)
    : _handlers = {for (final handler in handlers) handler.type: handler};

  final Map<VaultItemType, VaultSnapshotTypeHandler> _handlers;

  VaultSnapshotTypeHandler? get(VaultItemType type) {
    return _handlers[type];
  }

  bool supports(VaultItemType type) {
    return _handlers.containsKey(type);
  }
}
