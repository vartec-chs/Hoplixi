import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/custom_field_dto.dart';
import 'package:hoplixi/main_store/tables/vault_item_custom_fields_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'custom_field_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, VaultItemCustomFieldsHistory])
class CustomFieldHistoryDao extends DatabaseAccessor<MainStore>
    with _$CustomFieldHistoryDaoMixin {
  CustomFieldHistoryDao(super.db);

  /// Получить снимок кастомных полей для конкретной записи истории
  Future<List<VaultItemCustomFieldsHistoryData>> getByHistoryId(
    String historyId,
  ) {
    return (select(vaultItemCustomFieldsHistory)
          ..where((t) => t.historyId.equals(historyId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Получить всю историю кастомных полей для vault item,
  /// сгруппированную по записям vault_item_history.
  ///
  /// Возвращает список пар: (запись истории vault item, список снимков полей).
  Future<List<(VaultItemHistoryData, List<VaultItemCustomFieldsHistoryData>)>>
  getFullHistoryByItemId(String itemId) async {
    // Получаем все записи vault_item_history, которые имеют
    // связанные custom field snapshots для данного item
    final historyQuery =
        select(vaultItemHistory).join([
            innerJoin(
              vaultItemCustomFieldsHistory,
              vaultItemCustomFieldsHistory.historyId.equalsExp(
                vaultItemHistory.id,
              ),
            ),
          ])
          ..where(vaultItemHistory.itemId.equals(itemId))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final rows = await historyQuery.get();

    // Группируем: один VaultItemHistoryData → N снимков полей
    final Map<
      String,
      (VaultItemHistoryData, List<VaultItemCustomFieldsHistoryData>)
    >
    grouped = {};
    for (final row in rows) {
      final history = row.readTable(vaultItemHistory);
      final fieldSnapshot = row.readTable(vaultItemCustomFieldsHistory);
      if (grouped.containsKey(history.id)) {
        grouped[history.id]!.$2.add(fieldSnapshot);
      } else {
        grouped[history.id] = (history, [fieldSnapshot]);
      }
    }

    return grouped.values.toList();
  }

  /// Наблюдать за историей кастомных полей vault item
  Stream<List<(VaultItemHistoryData, List<VaultItemCustomFieldsHistoryData>)>>
  watchFullHistoryByItemId(String itemId) {
    final historyQuery =
        select(vaultItemHistory).join([
            innerJoin(
              vaultItemCustomFieldsHistory,
              vaultItemCustomFieldsHistory.historyId.equalsExp(
                vaultItemHistory.id,
              ),
            ),
          ])
          ..where(vaultItemHistory.itemId.equals(itemId))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return historyQuery.watch().map((rows) {
      final Map<
        String,
        (VaultItemHistoryData, List<VaultItemCustomFieldsHistoryData>)
      >
      grouped = {};
      for (final row in rows) {
        final history = row.readTable(vaultItemHistory);
        final fieldSnapshot = row.readTable(vaultItemCustomFieldsHistory);
        if (grouped.containsKey(history.id)) {
          grouped[history.id]!.$2.add(fieldSnapshot);
        } else {
          grouped[history.id] = (history, [fieldSnapshot]);
        }
      }
      return grouped.values.toList();
    });
  }

  /// Преобразовать снимок строки истории в [CustomFieldDto]
  CustomFieldDto snapshotToDto(VaultItemCustomFieldsHistoryData row) {
    return CustomFieldDto(
      id: row.fieldId,
      itemId: row.historyId,
      label: row.label,
      value: row.value,
      fieldType: row.fieldType,
      sortOrder: row.sortOrder,
    );
  }
}
