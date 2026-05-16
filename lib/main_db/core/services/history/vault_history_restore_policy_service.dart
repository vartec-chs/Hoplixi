import 'vault_history_normalized_loader.dart';
import '../../tables/vault_items/vault_items.dart';

class VaultHistoryRestorePolicyService {
  bool isRestorable(NormalizedHistorySnapshot snapshot) {
    switch (snapshot.snapshot.type) {
      case VaultItemType.document:
      case VaultItemType.file:
      case VaultItemType.recoveryCodes:
        return false;
      default:
        // Regular items are restorable if we have the snapshot
        return true;
    }
  }

  List<String> restoreWarnings(NormalizedHistorySnapshot snapshot) {
    final warnings = <String>[];

    final type = snapshot.snapshot.type;

    if (type == VaultItemType.file) {
      warnings.add('Восстановление файлов пока не поддерживается.');
    } else if (type == VaultItemType.document) {
      warnings.add('Восстановление документов пока не поддерживается.');
    } else if (type == VaultItemType.recoveryCodes) {
      warnings.add('Восстановление кодов восстановления пока не поддерживается.');
    }

    // Check for missing secrets
    for (final key in snapshot.sensitiveKeys) {
      if (snapshot.fields[key] == null) {
        warnings.add('В снимке отсутствует секретное поле "$key". Оно не будет восстановлено.');
      }
    }

    if (snapshot.snapshot.isDeleted) {
      warnings.add('Запись сейчас находится в корзине. Восстановление переместит её в активные.');
    }

    // Custom fields warning (not implemented yet)
    // warnings.add('Восстановление дополнительных полей пока не реализовано.');

    return warnings;
  }
}
