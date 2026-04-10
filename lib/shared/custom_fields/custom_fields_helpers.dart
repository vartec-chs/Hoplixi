import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/db_core/dao/custom_field_dao.dart';
import 'package:hoplixi/db_core/provider/dao_providers.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';

/// Загрузить кастомные поля vault-элемента из БД.
Future<List<CustomFieldEntry>> loadCustomFields(Object ref, String itemId) async {
  final dao = await _readCustomFieldDao(ref);
  final rows = await dao.getByItemId(itemId);
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
  final dao = await _readCustomFieldDao(ref);
  await dao.replaceAll(itemId, fields.map((e) => e.toCreateDto()).toList());
}

Future<CustomFieldDao> _readCustomFieldDao(Object ref) {
  if (ref is Ref) {
    return ref.read(customFieldDaoProvider.future);
  }
  if (ref is WidgetRef) {
    return ref.read(customFieldDaoProvider.future);
  }

  throw ArgumentError.value(ref, 'ref', 'Expected Ref or WidgetRef');
}
