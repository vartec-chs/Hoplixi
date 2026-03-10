import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';

/// Загрузить кастомные поля vault-элемента из БД.
Future<List<CustomFieldEntry>> loadCustomFields(Ref ref, String itemId) async {
  final dao = await ref.read(customFieldDaoProvider.future);
  final rows = await dao.getByItemId(itemId);
  return rows.map(CustomFieldEntry.fromData).toList();
}

/// Сохранить (заменить все) кастомные поля vault-элемента.
///
/// Вызывать после успешного сохранения основной сущности.
Future<void> saveCustomFields(
  Ref ref,
  String itemId,
  List<CustomFieldEntry> fields,
) async {
  final dao = await ref.read(customFieldDaoProvider.future);
  await dao.replaceAll(itemId, fields.map((e) => e.toCreateDto()).toList());
}
