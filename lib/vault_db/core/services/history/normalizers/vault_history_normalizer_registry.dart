import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_type_normalizer.dart';

class VaultHistoryNormalizerRegistry {
  VaultHistoryNormalizerRegistry(List<VaultHistoryTypeNormalizer> normalizers)
    : _normalizers = {for (final n in normalizers) n.type: n};

  final Map<VaultItemType, VaultHistoryTypeNormalizer> _normalizers;

  VaultHistoryTypeNormalizer? get(VaultItemType type) => _normalizers[type];
}
