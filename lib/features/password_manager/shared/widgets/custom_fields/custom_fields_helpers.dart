import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/providers/session_providers.dart';

/// Загрузить кастомные поля vault-элемента из БД.
Future<List<CustomFieldEntry>> loadCustomFields(
  Object ref,
  String itemId,
) async {
  final db =  _readVaultDb(ref);
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
  final db =  _readVaultDb(ref);
  await db.vaultItemCustomFieldsDao.replaceCustomFieldsForItem(
    itemId: itemId,
    fields: fields.asMap().entries.map((e) {
      return e.value.copyWith(sortOrder: e.key).toCompanion(itemId);
    }).toList(),
  );
}

VaultDB _readVaultDb(Object ref) {
  if (ref is Ref) {
    return ref.watch(requiredVaultDBProvider);
  }
  if (ref is WidgetRef) {
    return ref.read(requiredVaultDBProvider);
  }

  throw ArgumentError.value(ref, 'ref', 'Expected Ref or WidgetRef');
}
