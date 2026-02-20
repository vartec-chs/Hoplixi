import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/note_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/note_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'note_history_dao.g.dart';

/// DAO для управления историей заметок.
///
/// Table-Per-Type: общие поля в [VaultItemHistory],
/// type-specific — в [NoteHistory].
@DriftAccessor(tables: [VaultItemHistory, NoteHistory])
class NoteHistoryDao extends DatabaseAccessor<MainStore>
    with _$NoteHistoryDaoMixin {
  NoteHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории заметок
  Future<List<NoteHistoryCardDto>> getAllNoteHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              noteHistory,
              noteHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.note))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Смотреть всю историю заметок
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              noteHistory,
              noteHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.note))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю для конкретной заметки
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryByOriginalId(String noteId) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              noteHistory,
              noteHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(noteId) &
                vaultItemHistory.type.equalsValue(VaultItemType.note),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю по действию
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryByAction(String action) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              noteHistory,
              noteHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.note),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить карточки с пагинацией и поиском
  Future<List<NoteHistoryCardDto>> getNoteHistoryCardsByOriginalId(
    String noteId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        noteHistory,
        noteHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(noteId) &
        vaultItemHistory.type.equalsValue(VaultItemType.note);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              vaultItemHistory.description.like(q) |
              noteHistory.content.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей
  Future<int> countNoteHistoryByOriginalId(
    String noteId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          noteHistory,
          noteHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(noteId) &
            vaultItemHistory.type.equalsValue(VaultItemType.note),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            vaultItemHistory.description.like(q) |
            noteHistory.content.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории заметки
  Future<String> createNoteHistory(CreateNoteHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalNoteId,
        type: VaultItemType.note,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.title,
        description: Value(dto.description),
        categoryName: Value(dto.categoryName),
        usedCount: Value(dto.usedCount ?? 0),
        isFavorite: Value(dto.isFavorite ?? false),
        isArchived: Value(dto.isArchived ?? false),
        isPinned: Value(dto.isPinned ?? false),
        isDeleted: Value(dto.isDeleted ?? false),
        originalCreatedAt: Value(dto.originalCreatedAt),
        originalModifiedAt: Value(dto.originalModifiedAt),
      );

      await into(vaultItemHistory).insert(companion);
      final historyId = companion.id.value;

      await into(noteHistory).insert(
        NoteHistoryCompanion.insert(
          historyId: historyId,
          deltaJson: dto.deltaJson,
          content: dto.content,
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретной заметки
  Future<int> deleteNoteHistoryByNoteId(String noteId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(noteId) & h.type.equalsValue(VaultItemType.note),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldNoteHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.note),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deleteNoteHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  NoteHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);

    return NoteHistoryCardDto(
      id: h.id,
      originalNoteId: h.itemId,
      action: h.action.value,
      title: h.name,
      description: h.description,
      actionAt: h.actionAt,
    );
  }
}
