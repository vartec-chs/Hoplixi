import 'vault_history_normalized_loader.dart';
import '../../tables/vault_items/vault_items.dart';

class VaultHistoryRestorePolicyService {
  bool isRestorable(NormalizedHistorySnapshot snapshot) {
    switch (snapshot.snapshot.type) {
      case VaultItemType.document:
        return false;
      case VaultItemType.recoveryCodes:
        // Recovery codes are restorable only if values are present and not null
        final missingCount = snapshot.fields['missingValuesCount'] as int? ?? 0;
        final valuesCount = snapshot.fields['valuesCount'] as int? ?? 0;
        final codesCount = snapshot.fields['codesCount'] as int? ?? 0;
        
        if (codesCount > 0 && valuesCount == 0) return false;
        if (missingCount > 0) return false;
        
        return true;
      default:
        return true;
    }
  }

  List<String> restoreWarnings(NormalizedHistorySnapshot snapshot) {
    final warnings = <String>[];

    final type = snapshot.snapshot.type;

    if (type == VaultItemType.file) {
      final availabilityStatus = snapshot.fields['availabilityStatus'] as String?;
      if (availabilityStatus == 'missing') {
        warnings.add('Файл помечен как отсутствующий. Будет восстановлена только метаинформация.');
      } else if (availabilityStatus == 'deleted') {
        warnings.add('Файл помечен как удалённый. Будет восстановлена только метаинформация.');
      } else {
        warnings.add('Восстановление файла восстановит только запись в БД. Убедитесь, что физический файл всё ещё на месте.');
      }
      
      if (snapshot.fields['filePath'] == null) {
        warnings.add('Путь к файлу в снимке отсутствует.');
      }
    } else if (type == VaultItemType.document) {
      warnings.add('Восстановление документов пока не поддерживается.');
    } else if (type == VaultItemType.recoveryCodes) {
      final usedValuesCount = snapshot.fields['usedValuesCount'] as int? ?? 0;
      if (usedValuesCount > 0) {
        warnings.add('Будет восстановлен статус использованных кодов ($usedValuesCount шт.).');
      }
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

    warnings.add('Пользовательские поля (если есть) будут восстановлены.');
    warnings.add('Связи с тегами будут восстановлены (несуществующие теги будут проигнорированы).');

    return warnings;
  }
}
