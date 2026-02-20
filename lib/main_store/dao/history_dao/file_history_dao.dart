import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/file_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'file_history_dao.g.dart';

/// DAO для управления историей файлов.
///
/// Table-Per-Type: общие поля в [VaultItemHistory],
/// type-specific — в [FileHistory].
@DriftAccessor(tables: [VaultItemHistory, FileHistory])
class FileHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileHistoryDaoMixin {
  FileHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории файлов
  Future<List<FileHistoryCardDto>> getAllFileHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            leftOuterJoin(
              fileHistory,
              fileHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.file))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Смотреть всю историю файлов
  Stream<List<FileHistoryCardDto>> watchFileHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            leftOuterJoin(
              fileHistory,
              fileHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.file))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить историю для конкретного файла
  Stream<List<FileHistoryCardDto>> watchFileHistoryByOriginalId(String fileId) {
    final query =
        select(vaultItemHistory).join([
            leftOuterJoin(
              fileHistory,
              fileHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(fileId) &
                vaultItemHistory.type.equalsValue(VaultItemType.file),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить полные записи истории файла
  Future<List<(VaultItemHistoryData, FileHistoryData?)>>
  getFileHistoryByOriginalId(String fileId) async {
    final query =
        select(vaultItemHistory).join([
            leftOuterJoin(
              fileHistory,
              fileHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(fileId) &
                vaultItemHistory.type.equalsValue(VaultItemType.file),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => (
            row.readTable(vaultItemHistory),
            row.readTableOrNull(fileHistory),
          ),
        )
        .toList();
  }

  /// Получить историю по действию
  Stream<List<FileHistoryCardDto>> watchFileHistoryByAction(String action) {
    final query =
        select(vaultItemHistory).join([
            leftOuterJoin(
              fileHistory,
              fileHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.file),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map((rows) => rows.map(_mapToCard).toList());
  }

  /// Получить карточки с пагинацией и поиском
  Future<List<FileHistoryCardDto>> getFileHistoryCardsByOriginalId(
    String fileId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      leftOuterJoin(
        fileHistory,
        fileHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(fileId) &
        vaultItemHistory.type.equalsValue(VaultItemType.file);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              vaultItemHistory.description.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToCard).toList();
  }

  /// Подсчитать количество записей
  Future<int> countFileHistoryByOriginalId(
    String fileId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(fileId) &
            vaultItemHistory.type.equalsValue(VaultItemType.file),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) | vaultItemHistory.description.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории файла
  Future<String> createFileHistory(CreateFileHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalFileId,
        type: VaultItemType.file,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.name,
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

      await into(fileHistory).insert(
        FileHistoryCompanion.insert(
          historyId: historyId,
          metadataId: Value(dto.metadataId),
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретного файла
  Future<int> deleteFileHistoryByFileId(String fileId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(fileId) & h.type.equalsValue(VaultItemType.file),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldFileHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.file),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deleteFileHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  FileHistoryCardDto _mapToCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);

    return FileHistoryCardDto(
      id: h.id,
      originalFileId: h.itemId,
      action: h.action.value,
      name: h.name,
      actionAt: h.actionAt,
    );
  }
}
