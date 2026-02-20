import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/password_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'password_history_dao.g.dart';

/// DAO для управления историей паролей.
///
/// Использует Table-Per-Type: общие поля хранятся
/// в [VaultItemHistory], type-specific —
/// в [PasswordHistory].
@DriftAccessor(tables: [VaultItemHistory, PasswordHistory])
class PasswordHistoryDao extends DatabaseAccessor<MainStore>
    with _$PasswordHistoryDaoMixin {
  PasswordHistoryDao(super.db);

  // ============================================
  // Чтение
  // ============================================

  /// Получить все записи истории паролей
  Future<List<PasswordHistoryCardDto>> getAllPasswordHistoryCards() async {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              passwordHistory,
              passwordHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.password))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    final results = await query.get();
    return results.map(_mapToPasswordHistoryCard).toList();
  }

  /// Смотреть всю историю паролей с автообновлением
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryCards() {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              passwordHistory,
              passwordHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(vaultItemHistory.type.equalsValue(VaultItemType.password))
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map(
      (rows) => rows.map(_mapToPasswordHistoryCard).toList(),
    );
  }

  /// Получить историю для конкретного пароля
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryByOriginalId(
    String passwordId,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              passwordHistory,
              passwordHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.itemId.equals(passwordId) &
                vaultItemHistory.type.equalsValue(VaultItemType.password),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map(
      (rows) => rows.map(_mapToPasswordHistoryCard).toList(),
    );
  }

  /// Получить историю по действию
  Stream<List<PasswordHistoryCardDto>> watchPasswordHistoryByAction(
    String action,
  ) {
    final query =
        select(vaultItemHistory).join([
            innerJoin(
              passwordHistory,
              passwordHistory.historyId.equalsExp(vaultItemHistory.id),
            ),
          ])
          ..where(
            vaultItemHistory.action.equals(action) &
                vaultItemHistory.type.equalsValue(VaultItemType.password),
          )
          ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)]);

    return query.watch().map(
      (rows) => rows.map(_mapToPasswordHistoryCard).toList(),
    );
  }

  /// Получить историю с пагинацией и поиском
  Future<List<PasswordHistoryCardDto>> getPasswordHistoryCardsByOriginalId(
    String passwordId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        passwordHistory,
        passwordHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(passwordId) &
        vaultItemHistory.type.equalsValue(VaultItemType.password);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              passwordHistory.login.like(q) |
              passwordHistory.email.like(q) |
              passwordHistory.url.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_mapToPasswordHistoryCard).toList();
  }

  /// Подсчитать количество записей истории
  Future<int> countPasswordHistoryByOriginalId(
    String passwordId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();
    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          passwordHistory,
          passwordHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(passwordId) &
            vaultItemHistory.type.equalsValue(VaultItemType.password),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            passwordHistory.login.like(q) |
            passwordHistory.email.like(q) |
            passwordHistory.url.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ============================================
  // Запись
  // ============================================

  /// Создать запись истории пароля
  Future<String> createPasswordHistory(CreatePasswordHistoryDto dto) async {
    return await db.transaction(() async {
      final companion = VaultItemHistoryCompanion.insert(
        itemId: dto.originalPasswordId,
        type: VaultItemType.password,
        action: ActionInHistoryX.fromString(dto.action),
        name: dto.name,
        description: Value(dto.description),
        categoryName: Value(dto.categoryName),
        usedCount: Value(dto.usedCount ?? 0),
        isArchived: Value(dto.isArchived ?? false),
        isPinned: Value(dto.isPinned ?? false),
        isFavorite: Value(dto.isFavorite ?? false),
        isDeleted: Value(dto.isDeleted ?? false),
        lastUsedAt: Value(dto.lastAccessedAt),
        originalCreatedAt: Value(dto.originalCreatedAt),
        originalModifiedAt: Value(dto.originalModifiedAt),
      );

      // Вставляем базовую запись истории
      await into(vaultItemHistory).insert(companion);

      // Получаем id из companion
      // (clientDefault уже сгенерировал UUID)
      final historyId = companion.id.value;

      await into(passwordHistory).insert(
        PasswordHistoryCompanion.insert(
          historyId: historyId,
          password: Value(dto.password),
          login: Value(dto.login),
          email: Value(dto.email),
          url: Value(dto.url),
        ),
      );

      return historyId;
    });
  }

  // ============================================
  // Удаление
  // ============================================

  /// Удалить историю для конкретного пароля
  Future<int> deletePasswordHistoryByPasswordId(String passwordId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(passwordId) &
              h.type.equalsValue(VaultItemType.password),
        ))
        .go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldPasswordHistory(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.actionAt.isSmallerThanValue(cutoff) &
              h.type.equalsValue(VaultItemType.password),
        ))
        .go();
  }

  /// Удалить запись истории по ID
  Future<int> deletePasswordHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  // ============================================
  // Маппинг
  // ============================================

  PasswordHistoryCardDto _mapToPasswordHistoryCard(TypedResult row) {
    final h = row.readTable(vaultItemHistory);
    final pw = row.readTable(passwordHistory);

    return PasswordHistoryCardDto(
      id: h.id,
      originalPasswordId: h.itemId,
      action: h.action.value,
      name: h.name,
      login: pw.login,
      email: pw.email,
      actionAt: h.actionAt,
    );
  }
}
