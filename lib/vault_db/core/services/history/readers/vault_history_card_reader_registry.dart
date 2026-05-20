import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_type_reader.dart';

class VaultHistoryCardReaderRegistry {
  VaultHistoryCardReaderRegistry(List<VaultHistoryTypeReader> readers)
    : _readers = {for (final reader in readers) reader.type: reader};

  final Map<VaultItemType, VaultHistoryTypeReader> _readers;

  VaultHistoryTypeReader? getReader(VaultItemType type) {
    return _readers[type];
  }

  bool supports(VaultItemType type) {
    return _readers.containsKey(type);
  }
}
