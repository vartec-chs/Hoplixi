import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/contact_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/contact_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'contact_history_dao.g.dart';

/// DAO для удаления истории контактов.
@DriftAccessor(tables: [VaultItemHistory, ContactHistory])
class ContactHistoryDao extends DatabaseAccessor<MainStore>
    with _$ContactHistoryDaoMixin {
  ContactHistoryDao(super.db);

  /// Получить карточки истории контакта с пагинацией и поиском
  Future<List<ContactHistoryCardDto>> getContactHistoryCardsByOriginalId(
    String contactId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        contactHistory,
        contactHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(contactId) &
        vaultItemHistory.type.equalsValue(VaultItemType.contact);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              vaultItemHistory.description.like(q) |
              contactHistory.phone.like(q) |
              contactHistory.email.like(q) |
              contactHistory.company.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей истории контакта
  Future<int> countContactHistoryByOriginalId(
    String contactId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          contactHistory,
          contactHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(contactId) &
            vaultItemHistory.type.equalsValue(VaultItemType.contact),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            vaultItemHistory.description.like(q) |
            contactHistory.phone.like(q) |
            contactHistory.email.like(q) |
            contactHistory.company.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  /// Удалить запись истории по ID
  Future<int> deleteContactHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  /// Удалить всю историю для конкретного контакта
  Future<int> deleteContactHistoryByContactId(String contactId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(contactId) &
              h.type.equalsValue(VaultItemType.contact),
        ))
        .go();
  }

  ContactHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final c = row.readTable(contactHistory);

    return ContactHistoryCardDto(
      id: h.id,
      originalContactId: h.itemId,
      action: h.action.value,
      name: h.name,
      phone: c.phone,
      email: c.email,
      company: c.company,
      isEmergencyContact: c.isEmergencyContact,
      actionAt: h.actionAt,
    );
  }
}
