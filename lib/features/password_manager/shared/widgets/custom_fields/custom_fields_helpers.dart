import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/providers/session_providers.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

/// Загрузить кастомные поля vault-элемента из БД.
Future<List<CustomFieldEntry>> loadCustomFields(
  Object ref,
  String itemId,
) async {
  final db = await _readVaultDb(ref);
  final rows = await db.vaultItemCustomFieldsDao.getCustomFieldsByItemId(
    itemId,
  );
  return rows.map(CustomFieldEntry.fromData).toList();
}

/// Сохранить (заменить все) кастомные поля vault-элемента.
///
/// Вызывать после успешного сохранения основной сущности.
Future<void> saveCustomFields(
  Object ref,
  String itemId,
  List<CustomFieldEntry> fields,
) async {
  final db = await _readVaultDb(ref);
  await db.vaultItemCustomFieldsDao.replaceCustomFieldsForItem(
    itemId: itemId,
    fields: fields.asMap().entries.map((e) {
      return e.value.copyWith(sortOrder: e.key).toCompanion(itemId);
    }).toList(),
  );
}

Future<VaultDB> _readVaultDb(Object ref) {
  if (ref is Ref) {
    return ref.read(vaultDBProvider.future);
  }
  if (ref is WidgetRef) {
    return ref.read(vaultDBProvider.future);
  }

  throw ArgumentError.value(ref, 'ref', 'Expected Ref or WidgetRef');
}
