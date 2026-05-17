import 'package:hoplixi/main_db/core/services/history/history.dart';
import 'package:hoplixi/main_db/core/tables/file/file_metadata.dart';

import '../../../tables/vault_items/vault_items.dart';
import '../../../models/dto_history/cards/cards_exports.dart';

class VaultHistoryRestorePolicyService {
  bool isRestorable(AnyNormalizedHistorySnapshot snapshot) {
    switch (snapshot.base.type) {
      case VaultItemType.document:
        return false;
      case VaultItemType.recoveryCodes:
        if (snapshot.payload is! RecoveryCodesHistoryPayload) return true;
        final p = snapshot.payload as RecoveryCodesHistoryPayload;

        final codesCount = p.codesCount ?? 0;
        final valuesCount = p.valuesCount ?? 0;
        final missingCount = p.missingValuesCount ?? 0;

        if (codesCount > 0 && valuesCount == 0) return false;
        if (missingCount > 0) return false;

        return true;
      default:
        return true;
    }
  }

  bool isCardRestorable(VaultHistoryCardDto card) {
    switch (card.snapshot.type) {
      case VaultItemType.document:
        return false;
      default:
        return true;
    }
  }

  List<String> restoreWarningsForCard(VaultHistoryCardDto card) {
    final type = card.snapshot.type;
    if (type == VaultItemType.document) {
      return ['Восстановление документов из истории пока не поддерживается'];
    } else if (type == VaultItemType.file) {
      return [
        'Восстанавливаются только данные и метаинформация файла',
        'Физический файл не копируется и не проверяется автоматически',
      ];
    } else if (type == VaultItemType.recoveryCodes) {
      return [
        'Recovery codes будут восстановлены только если значения кодов сохранены в снимке',
      ];
    }
    return const [];
  }

  List<String> restoreWarnings(AnyNormalizedHistorySnapshot snapshot) {
    final warnings = <String>[];

    final type = snapshot.base.type;

    if (type == VaultItemType.file) {
      if (snapshot.payload is FileHistoryPayload) {
        final p = snapshot.payload as FileHistoryPayload;
        if (p.availabilityStatus == FileAvailabilityStatus.missing) {
          warnings.add(
            'Файл помечен как отсутствующий. Будет восстановлена только метаинформация.',
          );
        } else if (p.availabilityStatus == FileAvailabilityStatus.deleted) {
          warnings.add(
            'Файл помечен как удалённый. Будет восстановлена только метаинформация.',
          );
        } else {
          warnings.add(
            'Восстановление файла восстановит только запись в БД. Убедитесь, что физический файл всё ещё на месте.',
          );
        }

        if (p.filePath == null) {
          warnings.add('Путь к файлу в снимке отсутствует.');
        }
      }
    } else if (type == VaultItemType.document) {
      warnings.add('Восстановление документов пока не поддерживается.');
    } else if (type == VaultItemType.recoveryCodes) {
      if (snapshot.payload is RecoveryCodesHistoryPayload) {
        final p = snapshot.payload as RecoveryCodesHistoryPayload;
        final usedValuesCount = p.usedValuesCount ?? 0;
        if (usedValuesCount > 0) {
          warnings.add(
            'Будет восстановлен статус использованных кодов ($usedValuesCount шт.).',
          );
        }
      }
    }

    // Check for missing secrets in type-specific payload
    for (final field in snapshot.payload.diffFields()) {
      if (field.isSensitive && field.value == null) {
        warnings.add(
          'В снимке отсутствует секретное поле "${field.label}". Оно не будет восстановлено.',
        );
      }
    }

    if (snapshot.base.isDeleted) {
      warnings.add(
        'Запись сейчас находится в корзине. Восстановление переместит её в активные.',
      );
    }

    warnings.add('Пользовательские поля (если есть) будут восстановлены.');
    warnings.add(
      'Связи с тегами будут восстановлены (несуществующие теги будут проигнорированы).',
    );

    return warnings;
  }
}
