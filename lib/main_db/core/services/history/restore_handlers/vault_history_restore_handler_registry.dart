import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_restore_handler.dart';

class VaultHistoryRestoreHandlerRegistry {
  VaultHistoryRestoreHandlerRegistry(List<VaultHistoryRestoreHandler> handlers)
      : _handlers = {
          for (final h in handlers) h.type: h,
        };

  final Map<VaultItemType, VaultHistoryRestoreHandler> _handlers;

  VaultHistoryRestoreHandler? get(VaultItemType type) => _handlers[type];
}
