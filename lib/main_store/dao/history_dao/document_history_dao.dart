import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/document_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/document_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'document_history_dao.g.dart';

/// DAO для управления историей документов.
///
/// Table-Per-Type: общие поля в [VaultItemHistory],
/// type-specific — в [DocumentHistory].
@DriftAccessor(tables: [VaultItemHistory, DocumentHistory])
class DocumentHistoryDao extends DatabaseAccessor<MainStore>
    with _$DocumentHistoryDaoMixin {
  DocumentHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории документов
  Future<List<DocumentHistoryCardDto>> getAllDocumentHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              documentHistory,
              documentHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.document))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Смотреть всю историю документов
  Stream<List<DocumentHistoryCardDto>> watchDocumentHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              documentHistory,
              documentHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.document))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю для конкретного документа
  Stream<List<DocumentHistoryCardDto>> watchDocumentHistoryByOriginalId(
    String documentId,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              documentHistory,
              documentHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(documentId) &
                vaultItemHistory.type.equalsValue(VaultItemType.document),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю по действию
  Stream<List<DocumentHistoryCardDto>> watchDocumentHistoryByAction(
    String action,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              documentHistory,
              documentHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.document),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить карточки с пагинацией и поиском
  Future<List<DocumentHistoryCardDto>> getDocumentHistoryCardsByOriginalId(
    String documentId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        documentHistory,
        documentHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(documentId) &
        vaultItemHistory.type.equalsValue(VaultItemType.document);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              vaultItemHistory.description.like(q) |
              documentHistory.aggregatedText.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей
  Future<int> countDocumentHistoryByOriginalId(
    String documentId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          documentHistory,
          documentHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(documentId) &
            vaultItemHistory.type.equalsValue(VaultItemType.document),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            vaultItemHistory.description.like(q) |
            documentHistory.aggregatedText.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории документа
  Future<String> createDocumentHistory(CreateDocumentHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalDocumentId,
        type: VaultItemType.document,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.title,
        description: Value(dto.description),
        categoryName: Value(dto.categoryName),
        usedCount: Value(dto.usedCount),
        isFavorite: Value(dto.isFavorite),
        isArchived: Value(dto.isArchived),
        isPinned: Value(dto.isPinned),
        isDeleted: Value(dto.isDeleted),
        lastUsedAt: Value(dto.originalLastAccessedAt),
        originalCreatedAt: Value(dto.originalCreatedAt),
        originalModifiedAt: Value(dto.originalModifiedAt),
      );

      await into(vaultItemHistory).insert(companion);
      final historyId = companion.id.value;

      await into(documentHistory).insert(
        DocumentHistoryCompanion.insert(
          historyId: historyId,
          documentType: Value(dto.documentType),
          aggregatedText: Value(dto.aggregatedText),
          pageCount: Value(dto.pageCount ?? 0),
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретного документа
  Future<int> deleteDocumentHistoryByDocumentId(String documentId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(documentId) &
              h.type.equalsValue(VaultItemType.document),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldDocumentHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.document),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deleteDocumentHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  DocumentHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final doc = row.readTable(documentHistory);

    return DocumentHistoryCardDto(
      id: h.id,
      originalDocumentId: h.itemId,
      action: h.action.value,
      title: h.name,
      documentType: doc.documentType,
      actionAt: h.actionAt,
    );
  }
}
