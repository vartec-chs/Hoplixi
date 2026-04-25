import 'package:drift/drift.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/old/models/dto/custom_field_dto.dart';
import 'package:hoplixi/db_core/db/tables/vault_item_custom_fields.dart';
import 'package:uuid/uuid.dart';

part 'custom_field_dao.g.dart';

@DriftAccessor(tables: [VaultItemCustomFields])
class CustomFieldDao extends DatabaseAccessor<MainStore>
    with _$CustomFieldDaoMixin {
  CustomFieldDao(super.db);

  /// Получить все кастомные поля элемента, упорядоченные по [sortOrder]
  Future<List<VaultItemCustomFieldsData>> getByItemId(String itemId) {
    return (select(vaultItemCustomFields)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Наблюдать за кастомными полями элемента
  Stream<List<VaultItemCustomFieldsData>> watchByItemId(String itemId) {
    return (select(vaultItemCustomFields)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Получить одно поле по ID
  Future<VaultItemCustomFieldsData?> getById(String id) {
    return (select(
      vaultItemCustomFields,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Создать новое кастомное поле и вернуть его ID
  Future<String> create(String itemId, CreateCustomFieldDto dto) async {
    final id = const Uuid().v4();
    await into(vaultItemCustomFields).insert(
      VaultItemCustomFieldsCompanion.insert(
        id: Value(id),
        itemId: itemId,
        label: dto.label,
        value: Value(dto.value),
        fieldType: Value(dto.fieldType),
        sortOrder: Value(dto.sortOrder),
      ),
    );
    return id;
  }

  /// Обновить кастомное поле. Возвращает `true` если запись найдена и обновлена.
  Future<bool> updateField(String id, UpdateCustomFieldDto dto) async {
    final companion = VaultItemCustomFieldsCompanion(
      label: dto.label != null ? Value(dto.label!) : const Value.absent(),
      value: dto.clearValue == true
          ? const Value(null)
          : dto.value != null
          ? Value(dto.value)
          : const Value.absent(),
      fieldType: dto.fieldType != null
          ? Value(dto.fieldType!)
          : const Value.absent(),
      sortOrder: dto.sortOrder != null
          ? Value(dto.sortOrder!)
          : const Value.absent(),
    );

    final count = await (update(
      vaultItemCustomFields,
    )..where((t) => t.id.equals(id))).write(companion);
    return count > 0;
  }

  /// Удалить кастомное поле по ID
  Future<bool> deleteField(String id) async {
    final count = await (delete(
      vaultItemCustomFields,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Удалить все кастомные поля элемента
  Future<int> deleteAllForItem(String itemId) {
    return (delete(
      vaultItemCustomFields,
    )..where((t) => t.itemId.equals(itemId))).go();
  }

  /// Заменить все кастомные поля элемента (bulk upsert)
  Future<void> replaceAll(
    String itemId,
    List<CreateCustomFieldDto> fields,
  ) async {
    await transaction(() async {
      await deleteAllForItem(itemId);
      for (var i = 0; i < fields.length; i++) {
        final dto = fields[i];
        final id = const Uuid().v4();
        await into(vaultItemCustomFields).insert(
          VaultItemCustomFieldsCompanion.insert(
            id: Value(id),
            itemId: itemId,
            label: dto.label,
            value: Value(dto.value),
            fieldType: Value(dto.fieldType),
            sortOrder: Value(i),
          ),
        );
      }
    });
  }

  /// Преобразовать строку БД в DTO
  CustomFieldDto toDto(VaultItemCustomFieldsData row) {
    return CustomFieldDto(
      id: row.id,
      itemId: row.itemId,
      label: row.label,
      value: row.value,
      fieldType: row.fieldType,
      sortOrder: row.sortOrder,
    );
  }
}
